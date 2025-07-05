function [M] = opt_comm_tfn(sn,se,sparams,params,IsSlack)
%OPT_COMM_TFN Creates function to calculate optimal subsystem operation.
%
%   [M] = OPT_COMM_TFN(sn,se,sparams,params,IsSlack)
%
%   DESCRIPTION:
%   Uses subsystem information to create the local optimal flow problem
%   CasADi function, used to solve the distributed control problem to
%   minimize overall network losses via communication.
%
%   INPUTS:
%       sn      - Structure of numeric  subsystem specifications.
%       se      - Structure of categorized subsystem elements.
%       sparams - Structure of subsystem parameters.
%       params  - Structure of problem parameters.
%       IsSlack - Binary indicating if slack should be included.
%
%   OUTPUTS:
%       M       - Casadi function to solve optimal control problem.
%
%   DEPENDENCIES: graph2ss_part.
%
%   REQUIREMENTS: CasADi

 %#ok<*CHAIN>   % This is okay in CASADI
 %#ok<*FNDSB>   % This is nessecary in CASADI

 %% Setup Problem 
import casadi.*
opti_flow = casadi.Opti();

%% Mass flow

mdot_e = opti_flow.variable(sn.edge, sn.seg);
opti_flow.subject_to(mdot_e(:)>0);
mdot_n = MX.zeros(sn.node,sn.seg);

% Water from plant
if se.has.plant
    mdot_0 = opti_flow.variable(1, sn.seg);
    opti_flow.subject_to(mdot_0(:)>0);
    mdot_n(se.lnc.plant,:) = mdot_0;
end

% Controllable flow from other subsystems
if se.has.Pset_mfree
    idx_IsIn_mfree = find(se.node_Pset_mfree.IsIn);
    idx_IsOut_mfree = find(~se.node_Pset_mfree.IsIn);
    mdot_free = opti_flow.variable(sn.node_Pset_mfree,sn.seg);
    if ~isempty(idx_IsIn_mfree)
        opti_flow.subject_to(vec(mdot_free(idx_IsIn_mfree,:))>0);
    end
    if ~isempty(idx_IsOut_mfree)
        opti_flow.subject_to(vec(mdot_free(idx_IsOut_mfree,:))<0);
    end
    mdot_n(se.node_Pset_mfree.Node_LNC,:) = mdot_free;
end

% Set flow from other subsystems
if se.has.mset
    idx_IsIn_mset = find(se.node_mset.IsIn);
    mdot_set = opti_flow.parameter(sn.node_mset,sn.seg);
    mdot_n(se.node_mset.Node_LNC,:) = mdot_set;
end

% mdot in for SS creation
if se.has.Tin
    mdot_in = MX(sn.node_Tin,sn.seg);
    if se.has.Pset_mfree && ~isempty(idx_IsIn_mfree)
        mdot_in(se.node_Pset_mfree.Idx_T(se.node_Pset_mfree.IsIn),:) = mdot_free(idx_IsIn_mfree,:);
    end
    if se.has.mset && ~isempty(idx_IsIn_mset)
        mdot_in(se.node_mset.Idx_T(se.node_mset.IsIn),:) = mdot_set(idx_IsIn_mset,:);
    end
else
    mdot_in = NaN(1,sn.seg);
end

% Water returned to the plant
if se.has.refP 
    mdot_0_out = opti_flow.variable(1,sn.seg);
    opti_flow.subject_to(mdot_0_out(:)<0);
    mdot_n(se.lnc.refP,:) = mdot_0_out;
end

%% Control variable

if se.has.user   
    valve = opti_flow.variable(sn.user, sn.seg);
    opti_flow.subject_to(params.v_min<valve(:)<=1)
    zeta_u = params.v_coeff*(1./valve-1).^2;
end

%% Pressures
Pn = opti_flow.variable(sn.node, sn.seg);
dPe = opti_flow.variable(sn.edge, sn.seg);
opti_flow.subject_to(dPe(:)>=0);
opti_flow.subject_to(Pn(:)>=0);

% Minimum pressure at plant
if se.has.plantP
    P_min = opti_flow.parameter(1,sn.seg);
    opti_flow.subject_to(Pn(se.lnc.plant,:)>=P_min);
end

% Reference pressure at term
if se.has.refP
    opti_flow.subject_to(Pn(se.lnc.refP,:)==0);
end

% Create set pressure parameter
if se.has.Pset_mfree
    num_Pin = sn.node_Pset_mfree+(se.has.plant && ~se.has.plantP);
    Pn_in = opti_flow.parameter(num_Pin,sn.seg);
    opti_flow.subject_to(Pn(se.node_Pset_mfree.Node_LNC,:)==Pn_in(1:sn.node_Pset_mfree,:));
elseif se.has.plant && ~se.has.plantP
    Pn_in = opti_flow.parameter(1,sn.seg);
end

% Plant pressure constraints
if se.has.plant && ~se.has.plantP
    if IsSlack
        P_slack = opti_flow.variable(1,sn.seg);
        opti_flow.subject_to(P_slack>=0);
        opti_flow.subject_to(Pn(se.lnc.plant,:)==Pn_in(end,:)+P_slack);
    else
        opti_flow.subject_to(Pn(se.lnc.plant,:)==Pn_in(end,:));
    end
end


%% Constraints

for idx_t = 1:sn.seg
    % KCL
    opti_flow.subject_to(sparams.I*mdot_e(:,idx_t)==mdot_n(:,idx_t));

    % Edge equations
    if se.has.nonuser
        opti_flow.subject_to(dPe(se.lnc.nonuser,idx_t) == sparams.pipes(se.lnc.nonuser,3).*mdot_e(se.lnc.nonuser,idx_t).^2);
    end
    if se.has.user
        opti_flow.subject_to(dPe(se.lnc.user,idx_t) == zeta_u(:,idx_t).*mdot_e(se.lnc.user,idx_t).^2);
    end

    % KVL
    opti_flow.subject_to(dPe(:,idx_t)==sparams.I'*Pn(:,idx_t));
end

%% Temperature Variables

if se.has.nonuser
    % Nonuser edge temperatures
    T = MX(sn.nonuser,sn.seg_T+1);
    T_ic = opti_flow.parameter(sn.nonuser,1);
    T(:,1) = T_ic;

    % Cost Calculation
    hAs = params.h*pi*sparams.pipes(se.nonuser.Edge_LNC,1).*sparams.pipes(se.nonuser.Edge_LNC,2);
    cost_Q = MX(1,1);
end

if se.has.user
    % User parameters
    Qb = opti_flow.parameter(sn.user,sn.seg);
    Cap_u = opti_flow.parameter(sn.user,sn.seg_T);
    Cap_l = opti_flow.parameter(sn.user,sn.seg_T);
    
    % SOC variables
    Qp = MX(sn.user, sn.seg_T);
    intQ = MX(sn.user,sn.seg_T+1);
    intQ_ic = opti_flow.parameter(sn.user,1);
    intQ(:,1) = intQ_ic;

    % User inedge temperatures
    T_user_inedge = MX(sn.user,sn.seg_T);
    uie_local = find(se.user_inedge.IsLocal);
    uie_nonlocal = find(~se.user_inedge.IsLocal);

    % Cost Calculation
    cost_SOC = MX(1,1);
end

T_amb = opti_flow.parameter(1,sn.seg_T);

% System Inputs
if se.has.plant && se.has.Tin
    T_0 = opti_flow.parameter(1, sn.seg_T);
    T_in = opti_flow.parameter(sn.node_Tin, sn.seg_T);
    u = [T_0;T_in;repelem(params.TsetR, sn.seg_T);T_amb];
elseif se.has.plant
    T_0 = opti_flow.parameter(1, sn.seg_T);
    u = [T_0;repelem(params.TsetR, sn.seg_T);T_amb];
else
    T_in = opti_flow.parameter(sn.node_Tin, sn.seg_T);
    u = [T_in;repelem(params.TsetR, sn.seg_T);T_amb];
end


%% Calculate Dynamics

% Controllable timestep indexing
idx_tc=0;

% Assign T_in to user inedges
if se.has.user && ~isempty(uie_nonlocal)
    T_user_inedge(uie_nonlocal,:) = T_in(se.user_inedge.idx_node_T(uie_nonlocal),:);
end

if se.has.nonuser
    for idx_t = 1:sn.seg_T
        if mod((idx_t-1)*params.dt_T,params.dt)==0
            idx_tc = idx_tc+1;
            % Update SS
            [Ad,Bd] = graph2ss_part(params,sparams,sn,se,mdot_e(:,idx_tc),mdot_in(:,idx_tc),0);
        end
        T(:,idx_t+1) = Ad*T(:,idx_t)+Bd*u(:,idx_t);
        
        % Calculate provided heat
        if se.has.user
            if ~isempty(uie_local)
                T_user_inedge(uie_local,idx_t) = T(se.user_inedge.idx_Nonuser(uie_local),idx_t+1);
            end
            Qp(:,idx_t) = params.cp*mdot_e(se.lnc.user,idx_tc).*(T_user_inedge(:,idx_t)-params.TsetR)/10^3;   % kW
            % Ensure envelope is never exceeded
            intQ(:,idx_t+1) = intQ(:,idx_t)+((Qp(:,idx_t)-Qb(:,idx_tc))*params.dt_T)/10^3; % MJ
            opti_flow.subject_to(Cap_l(:,idx_t)<=intQ(:,idx_t+1)<=Cap_u(:,idx_t));
            % Update Cost
            cost_SOC = cost_SOC+params.w_flex*sum((intQ(:,idx_t+1)./Cap_u(:,idx_t)).^2)/sn.user;
        end
        
        % Update Cost
        cost_Q = cost_Q+params.w_Q*sum(hAs.*(T(:,idx_t+1)-T_amb(:,idx_t)))*params.dt_T;
    end
    
    opti_flow.subject_to(-30<T(:)<100);
else
    for idx_t = 1:sn.seg_T
        if mod((idx_t-1)*params.dt_T,params.dt)==0
            idx_tc = idx_tc+1;
        end
        % Calculate provided heat
        Qp(:,idx_t) = params.cp*mdot_e(se.lnc.user,idx_tc).*(T_user_inedge(:,idx_t)-params.TsetR)/10^3;   % kW
        % Ensure envelope is never exceeded
        intQ(:,idx_t+1) = intQ(:,idx_t)+((Qp(:,idx_t)-Qb(:,idx_tc))*params.dt_T)/10^3; % MJ
        opti_flow.subject_to(Cap_l(:,idx_t)<=intQ(:,idx_t+1)<=Cap_u(:,idx_t));
        
        % Update Cost
        cost_SOC = cost_SOC+params.w_flex*sum((intQ(:,idx_t+1)./Cap_u(:,idx_t)).^2)/sn.user;
    end
end

%% Solver
if IsSlack
    cost = sum(P_slack);
elseif se.has.user && se.has.nonuser
    cost = cost_Q+cost_SOC;
elseif se.has.user
    cost = cost_SOC;
elseif se.has.nonuser
    cost = cost_Q;
end

opti_flow.minimize(cost);

opti_flow.solver('ipopt',struct('print_time',0,'verbose',0),struct('print_level',0,'tol',params.tol,'acceptable_tol',params.accept_tol,'dual_inf_tol',10,'max_iter',params.max_iter,'hessian_approximation','exact'));

inpt = {T_amb,mdot_e,dPe,Pn,opti_flow.lam_g};
inpt_name = {'T_amb','i_mdot_e','i_dPe','i_Pn','i_lam_g'};
outpt = {dPe,Pn,mdot_e,opti_flow.lam_g,cost};
outpt_name = {'dPe','Pn','mdot_e','lam_g','cost'};

if IsSlack
    inpt{end+1} = P_slack; inpt_name{end+1} = 'i_P_slack';
    outpt{end+1} = P_slack; outpt_name{end+1} = 'P_slack';
end

if se.has.nonuser
    inpt{end+1} = T_ic; inpt_name{end+1} = 'T_ic';
    
    outpt{end+1} = T; outpt_name{end+1} = 'T';
    outpt{end+1} = cost_Q; outpt_name{end+1} = 'cost_Q';
end

if se.has.user
    inpt{end+1} = valve; inpt_name{end+1} = 'i_valve';
    inpt{end+1} = Qb; inpt_name{end+1} = 'Qb';
    inpt{end+1} = intQ_ic; inpt_name{end+1} = 'intQ_ic';
    inpt{end+1} = Cap_u; inpt_name{end+1} = 'Cap_u';
    inpt{end+1} = Cap_l; inpt_name{end+1} = 'Cap_l';

    outpt{end+1} = zeta_u; outpt_name{end+1} = 'zeta_u';
    outpt{end+1} = valve; outpt_name{end+1} = 'valve';
    outpt{end+1} = Qp; outpt_name{end+1} = 'Qp';
    outpt{end+1} = intQ; outpt_name{end+1} = 'intQ';
    outpt{end+1} = cost_SOC; outpt_name{end+1} = 'cost_SOC';
end

if se.has.plant
    inpt{end+1} = mdot_0; inpt_name{end+1} = 'i_mdot_0';
    inpt{end+1} = T_0; inpt_name{end+1} = 'T_0';

    outpt{end+1} = mdot_0; outpt_name{end+1} = 'mdot_0';

    if se.has.plantP
        inpt{end+1} = P_min; inpt_name{end+1} = 'P_min';
    end
end

if se.has.mset
    inpt{end+1} = mdot_set; inpt_name{end+1} = 'mdot_set';
end

if se.has.Pset_mfree
    inpt{end+1} = mdot_free; inpt_name{end+1} = 'i_mdot_free';
    outpt{end+1} = mdot_free; outpt_name{end+1} = 'mdot_free';
end

if se.has.Tin
    inpt{end+1} = T_in; inpt_name{end+1} = 'T_in';
end

if se.has.Pset_mfree || (se.has.plant && ~se.has.plantP)
    inpt{end+1} = Pn_in; inpt_name{end+1} = 'Pn_in';
end

M = opti_flow.to_function('M',inpt,outpt,inpt_name,outpt_name);

end







