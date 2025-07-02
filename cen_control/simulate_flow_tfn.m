function [M_sim] = simulate_flow_tfn(num,elems,params)
%SIMULATE_FLOW Calculate mass flow rate and pressure losses following
% given all zeta values
%   G: graph of network
%   params: parameters of network
%   n: structure of sizes
%   given mI, dP 

 %#ok<*CHAIN>   % This is okay in CASADI
 %#ok<*FNDSB>   % This is nessecary in CASADI
%% Setup Problem 
import casadi.*
opti_sim = casadi.Opti();

%% Flow variables

% Parameters
mdot_0 = opti_sim.parameter(1,num.seg_sim);
zeta_u = opti_sim.parameter(num.user, num.seg);

% Mass flow
mdot_e = opti_sim.variable(num.edge, num.seg_sim);
opti_sim.subject_to(mdot_e(:)>=0);

mdot_n = MX.zeros(num.node-1,num.seg_sim);
mdot_n(elems.root,:) = mdot_0;

% Pressures
Pn = opti_sim.variable(num.node, num.seg_sim);
opti_sim.subject_to(Pn(:)>=0);
opti_sim.subject_to(Pn(elems.term,:)==0);

dPe = opti_sim.variable(num.edge, num.seg_sim);
opti_sim.subject_to(dPe(:)>=0);

% Remove overconstraint for mdot
Ired = params.I;
Ired(elems.term,:) = [];

%% Constraints
for idx_t = 1:num.seg_sim
    % KCL
    opti_sim.subject_to(Ired*mdot_e(:,idx_t)==mdot_n(:,idx_t));
    
    % KVL
    opti_sim.subject_to(dPe(:,idx_t)==params.I'*Pn(:,idx_t));
    
    % Edge equations
    opti_sim.subject_to(dPe(elems.nonuser,idx_t) == params.pipes(elems.nonuser,3).*mdot_e(elems.nonuser,idx_t).^2);
    opti_sim.subject_to(dPe(elems.user,idx_t) == zeta_u(:,idx_t).*mdot_e(elems.user,idx_t).^2);
end

%% Preallocate Variables
% Parameters
T_ic = opti_sim.parameter(num.nonuser,1);
T_0 = opti_sim.parameter(1,num.seg_T_sim);
T_amb = opti_sim.parameter(1,num.seg_T_sim);
Qb = opti_sim.parameter(num.user,num.seg_sim);
intQ_ic = opti_sim.parameter(num.user,1);
Cap_u = opti_sim.parameter(num.user,num.seg_T);
Cap_l = opti_sim.parameter(num.user,num.seg_T);
% Storage variables
T = MX(num.nonuser,num.seg_T_sim+1);
Qp = MX(num.user, num.seg_T_sim);
intQ = MX(num.user,num.seg_T_sim+1);
% Cost variables
cost_SOC = MX(1,1);
cost_Q = MX(1,1);

% Set Initial conditions
T(:,1) = T_ic;
intQ(:,1) = intQ_ic;
hAs = params.h*pi*params.pipes(elems.nonuser,1).*params.pipes(elems.nonuser,2);

%% Calculate Dynamics
idx_tc = 0;
for idx_t = 1:num.seg_T_sim
    if mod((idx_t-1)*params.dt_T,params.dt)==0      % when mdot can change update SS
        idx_tc = idx_tc+1;
        [Ad,Bd] = graph2ss_cen(params,num,elems,mdot_e(:,idx_tc),0);
    end
    T(:,idx_t+1) = Ad*T(:,idx_t)+Bd*[T_0(1,idx_t);params.TsetR;T_amb(1,idx_t)];
    % Calculate provided heat
    Qp(:,idx_t) = params.cp*mdot_e(elems.user,idx_tc).*(T(elems.user_inedge_idx_nonuser,idx_t)-params.TsetR)/10^3; %kW
    intQ(:,idx_t+1) = intQ(:,idx_t)+((Qp(:,idx_t)-Qb(:,idx_tc))*params.dt_T)/10^3; % MJ
    % Update Cost
    cost_SOC = cost_SOC+params.w_flex*sum((intQ(:,idx_t+1)./Cap_u(:,idx_t)).^2)/num.user;
    cost_Q = cost_Q+params.w_Q*sum(hAs.*(T(:,idx_t+1)-T_amb(:,idx_t)))*params.dt_T;
    opti_sim.subject_to((Cap_l(:,idx_t)-100)<=intQ(:,idx_t+1)<=(Cap_u(:,idx_t)+100));
end

opti_sim.subject_to(-30<T(:)<100);

%% Create Function

opti_sim.minimize(cost_Q);

opti_sim.solver('ipopt',struct('print_time',0),struct('print_level',0,'tol', 1e-6))

% Required inputs and output
inpt = {T_ic,T_amb,T_0,mdot_0,zeta_u,Qb,intQ_ic,Cap_u,Cap_l};
inpt_name = {'T_ic','T_amb','T_0','mdot_0','zeta_u','Qb','intQ_ic','Cap_u','Cap_l'};
outpt = {dPe,Pn,mdot_e,T,Qp,cost_Q,intQ,cost_SOC};
outpt_name = {'dPe','Pn','mdot_e','T','Qp','cost_Q','intQ','cost_SOC'};

% Add initial guesses
inpt = [inpt {mdot_e,dPe,Pn}];
inpt_name = [inpt_name {'i_mdot_e','i_dPe','i_Pn'}];

M_sim = opti_sim.to_function('M',inpt,outpt,inpt_name,outpt_name);




