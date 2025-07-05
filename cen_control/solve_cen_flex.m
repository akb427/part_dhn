function [v_cen] = solve_cen_flex(num,elems,params,init)
%SOLVE_CEN_FLEX  Solve the centralized MPC problem for the DHN.
%
%   [v_cen] = SOLVE_CEN_FLEX(num,elems,params,init)
%
%   DESCRIPTION:
%   Solves the mpc problem for the centralized case using building
%   flexibility. Loops over num.horizon iterations, solving with a num.seg
%   timestep. 
%
%   INPUTS:
%       num     - Structure containing numeric problem specifications.
%       elems   - Structure containing categorized element.
%       params  - Structure of problem parameters.
%       init    - Strucutre of initial conditions for the problem.
%
%   OUTPUTS:
%       v_cen   - Strucutre of centralized step solutions.
%
%   DEPENDENCIES:
%       opt_cen_tfn

%% Create Function
Mcen = opt_cen_tfn(num,elems,params);

v_cen(num.horizon) = struct('Pn',0,'Qp',0,'T',0,'cost_Q',0,'cost_SOC',0,'cost',0,'dPe',0,'valve',0,'zeta_u',0,'intQ',0,'mdot_e',0,'mdot_0',0,'status',0,'valid',0,'lam_g',0);

%% Initial conditions
       
params_step.i_mdot_e = init.mdot_e;
params_step.i_dPe = init.dPe;
params_step.i_Pn = init.Pn;

params_step.i_mdot_0 = sum(init.mdot_e(elems.edge_plant,:));
params_step.i_valve = init.valve;
params_step.T_ic = init.T;
params_step.intQ_ic = init.intQ;

%% Solve function over time
for idx_horizon = 1:num.horizon
    tic
        % Timing indices
        idx_i = idx_horizon:(idx_horizon-1+num.seg);
        idx_i_T = (num.seg_T_sim*(idx_horizon-1)+1):(num.seg_T_sim*(idx_horizon-1)+num.seg_T);
        % Get variables for current timestep
        params_step.Qb = params.Qb(:,idx_i);
        params_step.T_amb = params.T_amb(:,idx_i_T);
        params_step.T_0 = params.T_0(:,idx_i_T);
        params_step.Cap_u = params.Cap_u(:,idx_i_T);
        params_step.Cap_l = params.Cap_l(:,idx_i_T);

        % Run Simulation
        vt = Mcen.call(params_step);
        vt.status = Mcen.stats.return_status;
        vt.valid = Mcen.stats.success;
        v_cen(idx_horizon) = structfun(@full,vt,'UniformOutput',false);
        
        while ~v_cen(idx_horizon).valid
            params_step.i_mdot_e = v_cen(idx_horizon).mdot_e;
            params_step.i_valve = v_cen(idx_horizon).valve;
            params_step.i_dPe = v_cen(idx_horizon).dPe;
            params_step.i_mdot_0 = v_cen(idx_horizon).mdot_0;
            params_step.i_Pn = v_cen(idx_horizon).Pn;
            params_step.i_lam_g = v_cen(idx_horizon).lam_g;
            vt = Mcen.call(params_step);
            vt.status = Mcen.stats.return_status;
            vt.valid = Mcen.stats.success;
            v_cen(idx_horizon) = structfun(@full,vt,'UniformOutput',false);
        end

        % initial values for next optimization
        params_step.T_ic = v_cen(idx_horizon).T(:,num.step_T_sim);
        params_step.intQ_ic = v_cen(idx_horizon).intQ(:,num.step_T_sim+1);
        params_step.i_mdot_e = [v_cen(idx_horizon).mdot_e(:,num.step_sim:end) repmat(v_cen(idx_horizon).mdot_e(:,end),1,num.seg_sim)];
        params_step.i_valve = [v_cen(idx_horizon).valve(:,num.step_sim:end) repmat(v_cen(idx_horizon).valve(:,end),1,num.seg_sim)];
        params_step.i_dPe = [v_cen(idx_horizon).dPe(:,num.step_sim:end) repmat(v_cen(idx_horizon).dPe(:,end),1,num.seg_sim)];
        params_step.i_mdot_0 = [v_cen(idx_horizon).mdot_0(:,num.step_sim:end) repmat(v_cen(idx_horizon).mdot_0(:,end),1,num.seg_sim)];
        params_step.i_Pn = [v_cen(idx_horizon).Pn(:,num.step_sim:end) repmat(v_cen(idx_horizon).Pn(:,end),1,num.seg_sim)];
        params_step.i_lam_g = v_cen(idx_horizon).lam_g;
        toc
end

end