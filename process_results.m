%% Load case study
clc, clear, close all
pth = pwd;
pth_split = split(pth, string(filesep));

addpath(genpath(fullfile(pth_split{1:end})))

%% Get Results from bnb

load("sim_4user_params","w_olm","G","elems","num","params","init")
%load("rslts_olm")


%% Get partitions

% [part_uw,part_w] = part_ss(G,params,num,elems) % does not work as it splits mass flow and temp
% part_uwG = partition_edges(G, ones(num.edge,1),elems,num);
% part_wG = partition_edges(G,params.pipes(:,4),elems,num);

G_ln = linegraph(G,elems,num,params.pipes(:,4));
[part_wG] = modularity_max(G_ln);
part_wG = [part_wG 1];

load('rslt_3_26','rslt','part_olm','idx_best');

%% Run Simulations with all 3

% Time parameters
params_sim = params;
num_sim = num;
params_sim.tf_sim = 10*60;
num_sim.seg_sim = params_sim.tf_sim/params_sim.dt;
num_sim.step_sim = num_sim.seg_sim+1;
num_sim.seg_T_sim = params_sim.tf_sim/params_sim.dt_T;
num_sim.step_T_sim = num_sim.seg_T_sim+1;
params_sim.tf = 12*60*60;
num_sim.horizon = (params_sim.tf)/params_sim.tf_sim;
params_sim.max_iter = 3000;
params_sim.max_iter_slack = 4000;

% Solve 
% cen_sim = solve_cen_flex(num_sim,elems,params_sim,init);
% [c_b,v_b,v_sim_b] = find_olm_sim(part_wG,G,elems,num_sim,params_sim,init,w_olm);
% [v_sim_cen,c_cen] = truncate_cen(v_sim_b,cen_sim,num_sim,params_sim,elems);
% [c_olm,v_olm,v_sim_olm] = find_olm_sim(part_olm,G,elems,num_sim,params_sim,init,w_olm);

%% Load
load("cen_sim2");
load("base_sim3");
load("olm_sim2");

% [rslt_b.c,rslt_b.v,rslt_b.v_sim] = find_olm(part_wG,G,elems,num,params,init,w_olm);
rslt_b.iter = rslt_b.c(1,5);
rslt_b.cost = rslt_b.c(1,3)/cen_sim(1).cost;
rslt_b.max_sz = rslt_b.c(1,6);

%% Plotting line graph
[G_ln,elems_ln,num_ln] = linegraph2(G,elems,num);

%% Timing parameters
% Timing
params_plot.tm = datetime(2018,1,28)+seconds(0:params_sim.dt:params_sim.tf);
params_plot.tT = datetime(2018,1,28)+seconds(0:params_sim.dt_T:params_sim.tf);
params_plot.idx_mrkr_m = 1:(3600/params_sim.dt):size(params_plot.tm,2);
params_plot.idx_mrkr_T = 1:(3600/params_sim.dt_T):size(params_plot.tT,2);

% Time Axis
params_plot.x.format = 'HH';
params_plot.x.label = "Time [hr]";
params_plot.x.tick = datetime(2018,1,28)+hours(0:2:params_sim.tf);
params_plot.x.lim = datetime(2018,1,28)+seconds([0 params_sim.tf]);

%% Plotting parameters
params_plot.num_pbl = 3; % number of cases being plotted

% Plot Settings
params_plot.clr = lines(7);
params_plot.clr_u = params_plot.clr(params_plot.num_pbl+1:end,:);
params_plot.ln = 1.25;
params_plot.mrkr = ["o" "square" "^" "diamond"];
params_plot.mrkr_sz = 6;
params_plot.ft = 12;
params_plot.ft_accent = 11;
params_plot.pos = [360,250,560,275];
params_plot.pos2 = [360,250,560,.75*275];
params_plot.pos_half = [360,280,325,240];

% Legend
params_plot.leg.icon_width = 20;
params_plot.leg.ln = 2;
params_plot.leg.columns = 2;

% Cost Plots
params_plot.cost.pos = [725,1225,320,185];
params_plot.cost.pos_zoom = [1225,975,165,350];
params_plot.cost.pos_ax = [0.149398332436879,0.234460411104976,0.75560166756312,0.690539588895024];
params_plot.cost.pos_wide = [350,879,1290,244];
params_plot.cost.mrkr_sz = 36;
params_plot.cost.star_sz = 50;
params_plot.cost.sv_loc = "C:\Users\akb42\OneDrive - The Ohio State University\DistrictHeatingNetwork\Publications\Partitioning DHN\bnb_costs_sz";

% Graph Plots
params_plot.g.pos = [360,200,380,320];
params_plot.g.clr = [params_plot.clr(7,:);params_plot.clr(1,:);params_plot.clr(5,:);[0 0 0]];
params_plot.g.lnsty = ["-","-","-",":"];
params_plot.g.ln = 2.5;
params_plot.g.nd = 7;

% Communication graph
params_plot.comm.clr = [.4118 .4118 .4118; params_plot.clr(2,:); params_plot.clr(6,:)];
params_plot.comm.lnsty = [":","-.","-"];
params_plot.comm.nd = 16;
params_plot.comm.pos = [330,120,550,400];
params_plot.comm.ln = 1;

%% Line graph
params_plot.lg.ln = 2;
params_plot.lg.num_node_label = num.user+2;
params_plot.lg.offset_x_node = [.2 .2 -.2 -.3 .03 .03];
params_plot.lg.offset_y_node = [0 0 0 0 .6 -.5];
params_plot.lg.v_num = [elems_ln.user elems_ln.root elems_ln.term];
params_plot.lg.node_label = [elems_ln.user "$v_{0^-}$" "$v_{0^+}$"];
params_plot.lg.xlim  = [0.55,6.24];
params_plot.lg.ylim = [0.12,10];

%% Plot results

[rslt, data] = convergence_stats(rslt,idx_best,cen_sim(1).cost,params_plot);
fig_olm2(data, rslt_b, params_plot)

fig_graph(G,elems,num_sim, params_plot);
[~,selems,~,~,num,elems] = subgraph_params(G,part_olm,elems,num,params);
%fig_commgraph(elems,num,selems,params_plot);
fig_graph_ln(G_ln,elems_ln,num_ln,params_plot)

fig_part(G,elems,num_sim,part_olm,params_plot);
fig_part(G,elems,num_sim,part_wG,params_plot);

fig_demand(params_sim,num_sim,elems,params_plot)

v_all = fig_loss_T(G, params_sim, elems, params_plot, v_sim_cen(1:num_sim.horizon), v_sim_olm(1:num_sim.horizon), v_sim_b(1:num_sim.horizon));
fig_SOE(elems,num_sim,params_plot,v_all)
fig_flow(num_sim,elems,params_plot,v_all)

% total losses (MJ)
loss = cellfun(@(x)sum(x.loss(1:end-1),'all'),v_all);
fprintf('In the OLM, the losses increased %.1f%% .\n',(loss(2)-loss(1))/loss(1)*100);
fprintf('In the baseline, the losses increased %.1f%% .\n',(loss(3)-loss(1))/loss(1)*100);

% Percent capacity
fprintf('The centalized used %.1f%% of its capacity.\n',sum(sqrt([v_sim_cen(1:num_sim.horizon).cost_SOC]*num_sim.user/params_sim.w_flex)));
fprintf('The OLM used %.1f%% of its capacity.\n',sum(sqrt([v_sim_olm(1:num_sim.horizon).cost_SOC]*num_sim.user/params_sim.w_flex)));
fprintf('The baseline used %.1f%% of its capacity.\n',sum(sqrt([v_sim_b(1:num_sim.horizon).cost_SOC]*num_sim.user/params_sim.w_flex)));

% total cost
fprintf('Total Cost in centralized: %.2e\n', sum([v_sim_cen(1:num_sim.horizon).cost_SOC]+[v_sim_cen(1:num_sim.horizon).cost_Q]));
fprintf('Total Cost in OLM: %.2e\n', sum([v_sim_olm(1:num_sim.horizon).cost_SOC]+[v_sim_olm(1:num_sim.horizon).cost_Q]));
fprintf('Total Cost in baseline: %.2e\n', sum([v_sim_b(1:num_sim.horizon).cost_SOC]+[v_sim_b(1:num_sim.horizon).cost_Q]));

%% Similiarly performing

% cost_lim = 712.35;
% sol_explore = [];
% part = [];
% c_close = [];
% pth = pwd; 

% for idx_split = 1:numel(rslt.cost)
%     sol_sim = find(rslt.cost{idx_split}(:,1)<cost_lim);
%     sol_explore = [sol_explore; repelem(idx_split,numel(sol_sim),1) sol_sim];
%     for idx_cand = sol_sim'
%         sv_name = [idx_split idx_cand];
%         file_name = pth+append(filesep,"olm_saves",filesep)+"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat";
%         [c_close(end+1,:),part(end+1,:)] = load_data(file_name,w_olm);
%         fig_part(G,elems,num_sim,part(end,:),params_plot);
%     end
% end