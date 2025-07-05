function [v_nom] = solve_cen_nom(num,elems,params,init)
%SOLVE_CEN_FLEX  Solve the centralized MPC problem meeting nominal demands.
%
%   [v_cen] = SOLVE_CEN_FLEX(num,elems,params,init)
%
%   DESCRIPTION:
%   Solves the mpc problem for the centralized case without building
%   flexibility, only meeting nominal demands. Loops over num.horizon 
%   iterations, solving with a num.seg timestep. Tries multiple tolerances
%   to help with problem convergence.
%
%   INPUTS:
%       num     - Structure containing numeric problem specifications.
%       elems   - Structure containing categorized element.
%       params  - Structure of problem parameters.
%       init    - Strucutre of initial conditions for the problem.
%
%   OUTPUTS:
%       v_nom   - Strucutre of centralized nominal step solutions.
%
%   DEPENDENCIES:
%       nom_cen_tfn

%% Create Function
M_cen = cell(1,3);
tol = [ 1e-4  1e-3 1e-5];
for idx_tol = 1:3
    params.tol = tol(idx_tol);
    M_cen{idx_tol} = nom_cen_tfn(num,elems,params);
end

v_nom(num.horizon) = struct('Pn',0,'Qp',0,'T',0,'cost_Q',0,'dPe',0,'mdot_e',0,'zeta_u',0,'mdot_0',0,'lam_g',0,'status',0,'valid',0,'valve',0);

%% Initial conditions
       
params_step.i_mdot_e = init.mdot_e;
params_step.i_dPe = init.dPe;
params_step.i_Pn = init.Pn;

params_step.i_mdot_0 = sum(init.mdot_e(elems.edge_plant,:));
params_step.i_valve = init.valve;
params_step.T_ic = init.T;

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

        % Run Simulation
        vt = M_cen{1}.call(params_step);
        vt.status = M_cen{1}.stats.return_status;
        vt.valid = M_cen{1}.stats.success;
        v_nom(idx_horizon) = structfun(@full,vt,'UniformOutput',false);

        % try to restore validity
        if ~v_nom(idx_horizon).valid
            for idx_tol = [2 3 1 1 1]
                params_step.i_mdot_e = v_nom(idx_horizon).mdot_e;
                params_step.i_dPe = v_nom(idx_horizon).dPe;
                params_step.i_Pn = v_nom(idx_horizon).Pn;
                params_step.i_mdot_0 = v_nom(idx_horizon).mdot_0;
                params_step.i_valve = v_nom(idx_horizon).valve;
                params_step.i_lam_g = v_nom(idx_horizon).lam_g;
                vt = M_cen{idx_tol}.call(params_step);
                vt.status = M_cen{idx_tol}.stats.return_status;
                vt.valid = M_cen{idx_tol}.stats.success;
                v_nom(idx_horizon) = structfun(@full,vt,'UniformOutput',false);
                if v_nom(idx_horizon).valid
                    break
                end
            end
            if ~v_nom(idx_horizon).valid
                error('can not solve')
            end       
        end
        
        % initial values for next optimization
        params_step.T_ic = v_nom(idx_horizon).T(:,num.seg_T_sim);
        params_step.i_mdot_e = [v_nom(idx_horizon).mdot_e(:,num.step_sim:end) repmat(v_nom(idx_horizon).mdot_e(:,end),1,num.seg_sim)];
        params_step.i_valve = [v_nom(idx_horizon).valve(:,num.step_sim:end) repmat(v_nom(idx_horizon).valve(:,end),1,num.seg_sim)];
        params_step.i_dPe = [v_nom(idx_horizon).dPe(:,num.step_sim:end) repmat(v_nom(idx_horizon).dPe(:,end),1,num.seg_sim)];
        params_step.i_mdot_0 = [v_nom(idx_horizon).mdot_0(:,num.step_sim:end) repmat(v_nom(idx_horizon).mdot_0(:,end),1,num.seg_sim)];
        params_step.i_Pn = [v_nom(idx_horizon).Pn(:,num.step_sim:end) repmat(v_nom(idx_horizon).Pn(:,end),1,num.seg_sim)];
        params_step.i_lam_g = v_nom(idx_horizon).lam_g;
        toc
end

end