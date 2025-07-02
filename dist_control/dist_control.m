function [v_sim,v] = dist_control(M,Gconv,num,elems,params,snum,selems,sparams,init,w)
%COMM_FLEX solve the communication based control of a partitioned DHN

%% Problem setup 
% Simulation Function
M_sim = simulate_flow_tfn(num,elems,params);

% Initial conditions
params_sim.T_ic = init.T;
params_sim.intQ_ic = init.intQ;

% Preallocate storage
params_sim.zeta_u = zeros(num.user,num.seg_sim);
params_sim.i_mdot_e = zeros(num.edge,num.seg_sim);
params_sim.i_dPe = zeros(num.edge,num.seg_sim);
params_sim.i_Pn = zeros(num.node,num.seg_sim);

v(num.horizon) = struct('rslts',0,'iter',0,'delta',0,'isconverge',0,'sparams_step',0);
v_sim(num.horizon) = struct('Pn',0,'Qp',0,'T',0,'cost_Q',0,'cost_SOC',0,'dPe',0,'intQ',0,'mdot_e',0,'status',0,'valid',0);%'cost',0,

% Initial conditions and guesses
sparams_step = cell(num.sg,1);
for idx_sg = 1:num.sg
    sparams_step{idx_sg} = parse_ig(init,selems{idx_sg});
end
sparams_step{elems.idx_plantP}.P_min = zeros(1,num.seg);

%% Loop Through Time

for idx_horizon = 1:num.horizon
    % Get variables for current timestep
    for idx_sg = 1:num.sg
        sparams_step{idx_sg} = parse_timestep(sparams_step{idx_sg},sparams{idx_sg},selems{idx_sg},snum{idx_sg},idx_horizon,params,params_sim);
    end
    
    % Iterative optimization
    [v(idx_horizon), idx_P_slack, P_min] = solve_comm(M,num,elems,params,snum,selems,sparams_step,Gconv,w);
    % if ~v(idx_horizon).isconverge % if it did not converge
    %     % warning("Problem "+num2str(idx_horizon)+" did not converge")
    %     % Find lowest change index
    %     delta_weighted = cellfun(@(x)sum(x./w.delta_min,'all'), v(idx_horizon).delta(1,2:end));
    %     delta_weighted(~cellfun(@(y)all(arrayfun(@(x) v(idx_horizon).rslts{x}.valid,y)),v.delta(2,2:end))) = nan;
    %     if all(isnan(delta_weighted))
    %         idx_min = v(idx_horizon).iter;
    %     else
    %         [~,idx_min] = min(delta_weighted);
    %         idx_min = v.delta{2,idx_min+1};
    %     end
    %     rslts_i = (arrayfun(@(x) v(idx_horizon).rslts{idx_min(x), x}, 1:num.sg,'UniformOutput',false));
    % else
    if v(idx_horizon).isconverge
        rslts_i = (arrayfun(@(x) v(idx_horizon).rslts{v(idx_horizon).iter(x), x}, 1:num.sg,'UniformOutput',false));
        % Solve Simulation
        [v_sim(idx_horizon), params_sim, ~] = simulate_flow(M_sim, params_sim, params, rslts_i, num, selems, idx_horizon);
    else
        v_sim(idx_horizon) =[];
        break
    end
    
    % Initial Guesses
     for idx_sg = 1:num.sg
        sparams_step{idx_sg} = update_ig_ext(sparams_step{idx_sg}, rslts_i{idx_sg}, selems{idx_sg}, idx_P_slack(idx_sg));
     end
    % minimum pressure
    sparams_step{elems.idx_plantP}.P_min = [P_min(2:end) 0];
end

end