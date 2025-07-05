function [sp_s] = parse_timestep(sp_s,sp,se,sn,idx_horizon,params,params_sim)
%PARSE_IG Get subsystem initial conditions from network level information.
%
%   [sp] = PARSE_IG(init,se)
%
%   DESCRIPTION:
%   Create the local initial conditions based on the network wide initial
%   conditions for a single subsystem.
%
%   INPUTS:
%       init    - Structure of initial conditions for problem.
%       se      - Structure of categorized subsystem elements.
%
%   OUTPUTS:
%       sp - Structure of subsystem parameters.

%% Timing indices
idx_i = idx_horizon:(idx_horizon-1+sn.seg);
idx_i_T = (sn.seg_T_sim*(idx_horizon-1)+1):(sn.seg_T_sim*(idx_horizon-1)+sn.seg_T);

%% Split for subgraph

sp_s.T_amb = params.T_amb(:,idx_i_T);
if se.has.nonuser
    sp_s.T_ic = params_sim.T_ic(se.idx.nonuser,:);
    % Initial Temperature Guess (will be deleted later)
    sp_s.T = repmat(sp_s.T_ic,1,sn.seg_T+1);
end
if sn.user>0
    sp_s.Qb = sp.Qb(:,idx_i);
    sp_s.Cap_l = sp.Cap_l(:,idx_i_T);
    sp_s.Cap_u = sp.Cap_u(:,idx_i_T);
    sp_s.intQ_ic = params_sim.intQ_ic(se.idx.user,:);
end
if se.has.plant
    sp_s.T_0 = params.T_0(:,idx_i_T);
end

end

