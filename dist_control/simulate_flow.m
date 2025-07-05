function [v_sim, params_sim, is_fail] = simulate_flow(Msim, params_sim, params, rslts_i, num, se, idx_horizon)
%SIMULATE_FLOW  Simulate network behavior based on control inputs.
%
%   [v_sim, params_sim, is_fail] = SIMULATE_FLOW(M_sim, params_sim, params, rslts_i, num, se, idx_horizon)
%
%   DESCRIPTION:
%   Simulates network response to set inital mass flow rate and valve
%   positions. Parses this information from the distributed control 
%   results. Uses a pre-defined CasADi function to resolve network
%   pressures and flows. Returns the simulation results and an updated
%   initial conditions for the next control step. 
%
%   INPUTS:
%       Msim        - CasADi functions for simulating network flow.
%       params_sim  - Structure of simulation parameters.
%       params      - Structure of problem parameters.
%       rslts_i     - Structures of subsystem results from distributed
%                     optimization
%       num         - Structure of numeric problem specifications.
%       se          - Structures of subsystem categorized elements.
%       idx_horizon - Numeric index of current problem step.
%
%   OUTPUTS:
%       v_sim       - Structure of simulation results.
%       params_sim  - Structure of simulation parameters with new initial
%                     conditions.
%       is_fail     - Binary indicator if simulation converged.

%% Timing indices
   
idx_i_sim = idx_horizon:(idx_horizon-1+num.seg_sim);
idx_i_T_sim = (num.seg_T_sim*(idx_horizon-1)+1):(num.seg_T_sim*(idx_horizon-1)+num.seg_T_sim);

%% Simulation Parameters

params_sim.T_amb = params.T_amb(:,idx_i_T_sim);
params_sim.T_0 = params.T_0(:,idx_i_T_sim);
params_sim.Cap_u = params.Cap_u(:,idx_i_T_sim);
params_sim.Cap_l = params.Cap_l(:,idx_i_T_sim);
params_sim.Qb = params.Qb(:,idx_i_sim);

params_sim.mdot_0 = sum(cell2mat(cellfun(@(x)x.mdot_0(:,1:num.seg_sim),rslts_i(cellfun(@(x)x.has.plant,se)),'UniformOutput',false)'),1);
for idx_sg = find(cellfun(@(x)x.has.user,se))
    params_sim.zeta_u(se{idx_sg}.idx.user,:) = rslts_i{idx_sg}.zeta_u(:,1:num.seg_sim);
end

%% Simulation initial guesses
for idx_sg = 1:num.sg
    params_sim.i_mdot_e(se{idx_sg}.edge,:) = rslts_i{idx_sg}.mdot_e(:,1:num.seg_sim);
    params_sim.i_mdot_e(params_sim.i_mdot_e<0)=1e-3;
    params_sim.i_dPe(se{idx_sg}.edge,:) = rslts_i{idx_sg}.dPe(:,1:num.seg_sim);
    params_sim.i_Pn(se{idx_sg}.node,:) = rslts_i{idx_sg}.Pn(:,1:num.seg_sim);
end

%% Call function
vsim_i = Msim.call(params_sim);
vsim_i.status = Msim.stats.return_status;
vsim_i.valid = Msim.stats.success;
v_sim = structfun(@full,vsim_i,'UniformOutput',false);
% If call fails
if ~vsim_i.valid
    params_sim.i_mdot_e = ones(num.edge,1);
    vsim_i = Msim.call(params_sim);
    vsim_i.status = Msim.stats.return_status;
    vsim_i.valid = Msim.stats.success;
end

is_fail = ~vsim_i.valid;
v_sim = structfun(@full,vsim_i,'UniformOutput',false);

%% Extract Results

% initial values for next time step
params_sim.T_ic = v_sim.T(:,end);
params_sim.intQ_ic = v_sim.intQ(:,end);

end

