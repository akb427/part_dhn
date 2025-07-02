function [v_sim_cen,c_cen] = truncate_cen(v_sim_cen,cen_sim,num,params,elems)
%TRUNCATE_CEN In the centralized optimization case, a seperate simulation
%step is not performed as the centralized solution is exact. Therefor the
%output data is the entire prediction horizon. This function truncates that
%data to just the simulation horizon.

for idx_horizon = 1:num.horizon
    v_sim_cen(idx_horizon).status = cen_sim(idx_horizon).status;
    v_sim_cen(idx_horizon).valid = cen_sim(idx_horizon).valid;
    % Flow timestep
    v_sim_cen(idx_horizon).Pn = cen_sim(idx_horizon).Pn(:,1:num.seg_sim);
    v_sim_cen(idx_horizon).dPe = cen_sim(idx_horizon).dPe(:,1:num.seg_sim);
    v_sim_cen(idx_horizon).mdot_e = cen_sim(idx_horizon).mdot_e(:,1:num.seg_sim);
    % Temp timestep
    v_sim_cen(idx_horizon).Qp = cen_sim(idx_horizon).Qp(:,1:num.seg_T_sim);
    v_sim_cen(idx_horizon).T = cen_sim(idx_horizon).T(:,1:num.seg_T_sim+1);
    v_sim_cen(idx_horizon).intQ = cen_sim(idx_horizon).intQ(:,1:num.seg_T_sim+1);
    % Cost calculations
    idx_i_T = (num.seg_T_sim*(idx_horizon-1)+1):(num.seg_T_sim*(idx_horizon-1)+num.seg_T_sim);
    Cap_u = params.Cap_u(:,idx_i_T);
    T_amb = params.T_amb(:,idx_i_T);
    hAs = params.h*pi*params.pipes(elems.nonuser,1).*params.pipes(elems.nonuser,2);

    v_sim_cen(idx_horizon).cost_SOC = params.w_flex*sum((v_sim_cen(idx_horizon).intQ(:,1:end-1)./Cap_u).^2,'all')/num.user;
    v_sim_cen(idx_horizon).cost_Q = params.w_Q*sum(hAs.*(v_sim_cen(idx_horizon).T(:,2:end)-T_amb),'all')*params.dt_T;    
end

c_cen = sum([v_sim_cen.cost_Q]+[v_sim_cen.cost_SOC],'all');
end

