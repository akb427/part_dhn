function [Mcen] = opt_cen_tfn(num,elems,params)
%CEN_FLEX Centralized optimal solution using flexibility
%   G: graph of network
%   params: parameters of network
%   n: structure of sizes
%   given mI, dP 

 %#ok<*CHAIN>   % This is okay in CASADI
 %#ok<*FNDSB>   % This is nessecary in CASADI
%% Setup Problem 
import casadi.*
opti_flow = casadi.Opti();

%% Flow variables

% Mass flow
mdot_e = opti_flow.variable(num.edge, num.seg);
opti_flow.subject_to(mdot_e(:)>0);
mdot_0 = opti_flow.variable(1, num.seg);

mdot_n = MX.zeros(num.node-1,num.seg);
mdot_n(elems.root,:) = mdot_0;

% Valve
valve = opti_flow.variable(num.user, num.seg);
opti_flow.subject_to(params.v_min<valve(:)<=1)
zeta_u = params.v_coeff*(1./valve-1).^2;

% Pressures
Pn = opti_flow.variable(num.node, num.seg);
dPe = opti_flow.variable(num.edge, num.seg);
opti_flow.subject_to(dPe(:)>=0);
opti_flow.subject_to(Pn(:)>=0);

% Remove overconstraint for mdot
Ired = params.I;
Ired(elems.term,:) = [];

%% Constraints

for i = 1:num.seg
    % KCL
    opti_flow.subject_to(Ired*mdot_e(:,i)==mdot_n(:,i));
    
    % KVL
    opti_flow.subject_to(dPe(:,i)==params.I'*Pn(:,i));
    % Set reference pressue
    opti_flow.subject_to(Pn(elems.term,i)==0);

    % Edge equations
    opti_flow.subject_to(dPe(elems.nonuser,i) == params.pipes(elems.nonuser,3).*mdot_e(elems.nonuser,i).^2);
    opti_flow.subject_to(dPe(elems.user,i) == zeta_u(:,i).*mdot_e(elems.user,i).^2);
end

%% Temperature Variables

T_ic = opti_flow.parameter(num.nonuser,1);
T_0 = opti_flow.parameter(1,num.seg_T);
T_amb = opti_flow.parameter(1,num.seg_T);
intQ_ic = opti_flow.parameter(num.user,1);
Qb = opti_flow.parameter(num.user,num.seg);
Cap_u = opti_flow.parameter(num.user,num.seg_T);
Cap_l = opti_flow.parameter(num.user,num.seg_T);

T = MX(num.nonuser,num.seg_T+1);
Qp = MX(num.user, num.seg_T);
intQ = MX(num.user,num.seg_T+1);

% Set initial conditions
T(:,1) = T_ic;
intQ(:,1) = intQ_ic; % MJ
hAs = params.h*pi*params.pipes(elems.nonuser,1).*params.pipes(elems.nonuser,2);

% Preallocate Cost 
cost_SOC = MX(1,1);
cost_Q = MX(1,1);

%% Calculate Dynamics
idx=0;
for i = 1:num.seg_T
    if mod((i-1)*params.dt_T,params.dt)==0
        idx = idx+1;
        % Update SS
        [Ad,Bd] = graph2ss_cen(params,num,elems,mdot_e(:,idx),0);
    end
    T(:,i+1) = Ad*T(:,i)+Bd*[T_0(1,i);params.TsetR;T_amb(1,i)];   
    % Calculate provided heat
    Qp(:,i) = params.cp*mdot_e(elems.user,idx).*(T(elems.user_inedge_idx_nonuser,i)-params.TsetR)/10^3;   % kW
    % Ensure envelope is never exceeded
    intQ(:,i+1) = intQ(:,i)+((Qp(:,i)-Qb(:,idx))*params.dt_T)/10^3; % MJ
    opti_flow.subject_to(Cap_l(:,i)<=intQ(:,i)<=Cap_u(:,i));
    % Update Cost
    cost_SOC = cost_SOC+params.w_flex*sum((intQ(:,i)./Cap_u(:,i)).^2)/num.user;
    cost_Q = cost_Q+params.w_Q*sum(hAs.*(T(:,i+1)-T_amb(:,i)))*params.dt_T;    
end

opti_flow.subject_to(-30<T(:)<100);

%% Solver

cost = cost_Q+cost_SOC;
opti_flow.minimize(cost);

opti_flow.solver('ipopt',struct('print_time',0),struct('print_level',0,'tol',params.tol,'acceptable_tol',params.accept_tol,'dual_inf_tol',10,'max_iter',params.max_iter,'hessian_approximation','exact'))

inpt = {T_ic,intQ_ic,Qb,T_amb,T_0,Cap_u,Cap_l,mdot_e,valve,dPe,mdot_0,Pn,opti_flow.lam_g};
inpt_name = {'T_ic','intQ_ic','Qb','T_amb','T_0','Cap_u','Cap_l','i_mdot_e','i_valve','i_dPe','i_mdot_0','i_Pn','i_lam_g'};
outpt = {dPe,Pn,mdot_e,valve,zeta_u,T,Qp,intQ,mdot_0,opti_flow.lam_g,cost_SOC,cost_Q,cost};
outpt_name = {'dPe','Pn','mdot_e','valve','zeta_u','T','Qp','intQ','mdot_0','lam_g','cost_SOC','cost_Q','cost'};

Mcen = opti_flow.to_function('M',inpt,outpt,inpt_name,outpt_name);

end
