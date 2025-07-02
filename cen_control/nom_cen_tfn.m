function [Mnom] = nom_cen_tfn(num,elems,params)
%OPTIMIZE_FLOW Calculate mass flow rate and pressure losses following
% nominal demand
%   G: graph of network
%   params: parameters of network
%   n: structure of sizes
%   given mI, dP 

%% Setup Problem 
import casadi.*
opti_flow = casadi.Opti();

%% Flow variables

% Mass flow
mdot_e = opti_flow.variable(num.edge, num.seg);
opti_flow.subject_to(mdot_e(:)>=0);

mdot_0 = opti_flow.variable(1,num.seg);
opti_flow.subject_to(mdot_0(:)>0);

mdot_n = MX.zeros(num.node-1,num.seg);
mdot_n(elems.root,:) = mdot_0;

% Control Variable
valve = opti_flow.variable(num.user, num.seg);
opti_flow.subject_to(params.v_min<valve(:)<=1)
zeta_u = params.v_coeff*(1./valve-1).^2;

% Pressures
Pn = opti_flow.variable(num.node, num.seg);
opti_flow.subject_to(Pn(:)>=0);

dPe = opti_flow.variable(num.edge, num.seg);
opti_flow.subject_to(dPe(:)>=0);

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
%% Temperature Dynamics

T_ic = opti_flow.parameter(num.nonuser,1);
T_0 = opti_flow.parameter(1,num.seg_T);
T_amb = opti_flow.parameter(1,num.seg_T);
Qb = opti_flow.parameter(num.user,num.seg);

T = MX(num.nonuser,num.seg_T+1);
Qp = MX(num.user, num.seg_T);

hAs = params.h*pi*params.pipes(elems.nonuser,1).*params.pipes(elems.nonuser,2);
T(:,1) = T_ic;

cost_Q = MX(1,1);

%% Calculate Dynamics
idx = 0;
for i = 1:num.seg_T
    if mod((i-1)*params.dt_T,params.dt)==0      % when mdot can change
        idx = idx+1;
        % Update SS
        [Ad,Bd] = graph2ss_cen(params,num,elems,mdot_e(:,idx),0);
        T(:,i+1) = Ad*T(:,i)+Bd*[T_0(1,i);params.TsetR;T_amb(1,i)];
        % Calculate provided heat
        Qp(:,i) = params.cp*mdot_e(elems.user,idx).*(T(elems.user_inedge_idx_nonuser,i)-params.TsetR)/1000;
        % Ensure provided heat is equal to demanded heat 
        opti_flow.subject_to(Qp(:,i)==Qb(:,idx));
        cost_Q = cost_Q+params.w_Q*sum(hAs.*(T(:,i)-T_amb(:,i)));
    else
        T(:,i+1) = Ad*T(:,i)+Bd*[T_0(1,i);params.TsetR;T_amb(1,i)];
        % Calculate provided heat
        Qp(:,i) = params.cp*mdot_e(elems.user,idx).*(T(elems.user_inedge_idx_nonuser,i)-params.TsetR)/1000;
        cost_Q = cost_Q+params.w_Q*sum(hAs.*(T(:,i)-T_amb(:,i)));
    end
end

%opti_flow.subject_to(-30<T(:)<100);

%% Solve zeta for minimum

opti_flow.minimize(cost_Q);

opti_flow.solver('ipopt',struct('print_time',0),struct('print_level',0,'tol',params.tol,'acceptable_tol',params.accept_tol,'dual_inf_tol',10,'max_iter',params.max_iter,'hessian_approximation','exact'))
%opti_flow.solver('ipopt',struct(),struct('tol', 1e-2,'max_iter', 100000))


inpt = {T_ic,Qb,T_amb,T_0,mdot_e,valve,dPe,mdot_0,Pn,opti_flow.lam_g};
inpt_name = {'T_ic','Qb','T_amb','T_0','i_mdot_e','i_valve','i_dPe','i_mdot_0','i_Pn','i_lam_g'};
outpt = {dPe,Pn,mdot_e,valve,zeta_u,T,Qp,mdot_0,opti_flow.lam_g,cost_Q};
outpt_name = {'dPe','Pn','mdot_e','valve','zeta_u','T','Qp','mdot_0','lam_g','cost_Q'};

Mnom = opti_flow.to_function('M',inpt,outpt,inpt_name,outpt_name);

end





