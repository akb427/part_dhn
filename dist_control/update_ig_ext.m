function [sp_s] = update_ig_ext(sp_s, rslts_i, se, is_slack)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

%%

sp_s.i_mdot_e = [rslts_i.mdot_e(:,2:end) rslts_i.mdot_e(:,end)];
sp_s.i_dPe = [rslts_i.dPe(:,2:end) rslts_i.dPe(:,end)];
sp_s.i_Pn = [rslts_i.Pn(:,2:end) rslts_i.Pn(:,end)];

% Gradient and Slack variables
if is_slack && isfield(sp_s,'i_lam_g')
    sp_s = rmfield(sp_s,'i_lam_g');
elseif ~is_slack
    sp_s.i_lam_g = rslts_i.lam_g;
end

% For subgraphs connected to plant
if se.has.plant
    % Initial guesses
    sp_s.i_mdot_0 = [rslts_i.mdot_0(:,2:end) rslts_i.mdot_0(:,end)];
end
% For subgraphs with users
if se.has.user
    sp_s.i_valve = [rslts_i.valve(:,2:end) rslts_i.valve(:,end)];
end

% For subgraphs with mfree
if se.has.Pset_mfree
    sp_s.i_mdot_free = [rslts_i.mdot_free(:,2:end) rslts_i.mdot_free(:,end)];
end

% Add T for variable passing (to be removed before each solve)
if se.has.nonuser
    sp_s.T = [rslts_i.T(:,2:end) rslts_i.T(:,end)];
end

end