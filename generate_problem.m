

%% Add Paths
pth = pwd;
pth_split = split(pth, string(filesep));

addpath(pth+append(filesep+"cen_control"))

%% Problem setup

G = digraph([1 1 2 2 3 3 4 4 5 6 7 8 8 9],[2 8 3 7 4 6 5 5 6 7 10 9 9 10]);
elems.user = [4 6];

% Mass flow timing parameters
params.tf_opt = 1*60*60;       % [s]
params.dt = 10*60;
num.seg = params.tf_opt/params.dt;
num.step = num.seg+1;
% Temperature timing parameters
params.dt_T = 30;
num.seg_T = params.tf_opt/params.dt_T;
num.step_T = num.seg_T+1;

% Simulation timing parameters
params.tf = (12+1)*60*60;
params.tf_sim = 1*60*60;
num.seg_sim = params.tf_sim/params.dt;
num.step_sim = num.seg_sim+1;
num.seg_T_sim = params.tf_sim/params.dt_T;
num.step_T_sim = num.seg_T_sim+1;

% Loop Iterations
num.horizon = (params.tf)/params.tf_sim;

[G,num,elems,params,temp_prof] = generate_params4(G,num,elems, params);

% Cost weights
params.w_T = 10^-2;
params.w_Q = 3*10^-6;
params.w_flex = 5;

% Valve settings
params.v_min = 0.01;
params.v_coeff = sqrt(params.pipes(14,3));

params.valve_closed = 10^5;
params.zeta_max = 3.3*10^6;
params.zeta_min = 0;

% Minimum mass flow
params.mdot_plant_min = 0.05;

params.w_P = 100;

% Pressure Drops
n_step = (params.tf-params.tf_opt)/params.tf_sim;

% Problem solver settings
params.tol =  1e-6;
params.accept_tol = 1e-5;
params.max_iter = 800;%0;
params.max_iter_slack = 1000;

%% Initial Conditions
params.tf = 12*60*60;
num.horizon = (params.tf-params.tf_opt)/params.tf_sim+1;

% Initial conditions (to be replaced with in situ values)
init.T = params.T_0(1)*ones(num.nonuser,1);
init.T(any(elems.cold==elems.nonuser',2),1) = params.TsetR;
init.T(any(elems.user_outedge==elems.nonuser',2),1) = params.TsetR;

% Initial guesses (to be replaced by centralized solution)
init.mdot_e = ones(num.edge,num.seg);
init.dPe = ones(num.edge,num.seg);
init.Pn = 50*ones(num.node,num.seg);
init.valve = ones(num.user,num.seg);

% nominl flow for temp
cen_nom = solve_cen_nom(num,elems,params,init);

%% IC for partitioning
% Shorten optimization horizon
params.tf = 1*60*60;
num.horizon = (params.tf-params.tf_opt)/params.tf_sim+1;

% Initial conditions
init.T = cen_nom(end).T(:,end);

% Initial guesses (to be replaced by centralized solution)
init.mdot_e = cen_nom(end).mdot_e(:,1:num.seg);
init.dPe = cen_nom(end).dPe(:,1:num.seg);
init.Pn = cen_nom(end).Pn(:,1:num.seg);
init.valve = cen_nom(end).valve(:,1:num.seg);

% Initial used capacity
init.intQ = [.08; -.1; .02; -.04].*params.Cap_u(:,1);

%% Cost function parameters

% Weights for fitness functions
w_olm.iter = 20;
w_olm.sz = 30;
w_olm.viol = 10^5;
w_olm.minDigits = num.edge+1;
% Convergence limit
w_olm.delta_min = [.5; .3; .2; 5];
w_olm.delta_min_rlx = [5; .8; .5; 10];
% Max iterations
w_olm.n_iter_max = 20;
w_olm.n_iter_max_slack = 20;

%% Save

save("sim_4user_params_"+string(datetime('today', 'Format', 'MM_dd')))