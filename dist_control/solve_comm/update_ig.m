function [sp_s] = update_ig(sp_s, rslts_i, se, is_slack)
%UPDATE_IG  Update initial guesses for dmpc problem.
%
%   [sp_s] = UPDATE_IG(sp_s, rslts_i, se, is_slack)
%
%   DESCRIPTION:
%   Update the initial guesses for the next solution interation based on
%   the values in rslts_i for a single subsystem.
%
%   INPUTS:
%       sp_s     - Structure of subsystem parameters.
%       rslts_i  - Stucture of subsystem results.
%       se       - Structure containing categorized subsystem element.
%       is_slack - Binary variable indicating if there is slack pressure.
%
%   OUTPUTS:
%       sp_s     - Updated structure of subsystem parameters.

%% Update Initial Guesses

    sp_s.i_mdot_e = rslts_i.mdot_e;
    sp_s.i_dPe = rslts_i.dPe;
    sp_s.i_Pn = rslts_i.Pn;
    
    % Remove infeasible values
    sp_s.i_mdot_e(sp_s.i_mdot_e<0)=1;
    sp_s.i_dPe(sp_s.i_dPe<0)=0;

    % Gradient and Slack variables
    if is_slack && ~isfield(rslts_i,'P_slack')
        % Remove gradient vector if problem type changed
        if isfield(sp_s,'i_lam_g')
            sp_s = rmfield(sp_s,'i_lam_g');
        end
    elseif is_slack && isfield(rslts_i,'P_slack')
        % Update gradient and Pslack if still solving slack problem
        sp_s.i_P_slack = rslts_i.P_slack;
        sp_s.i_lam_g = rslts_i.lam_g;
    elseif ~is_slack && isfield(rslts_i,'P_slack')
        % Remove gradient vector if problem type changed
        if isfield(sp_s,'i_lam_g')
            sp_s = rmfield(sp_s,'i_lam_g');
        end
        % Remove slack vector if problem type changed
        if isfield(sp_s,'i_P_slack')
            sp_s = rmfield(sp_s,'i_P_slack');
        end
    else
        % Update gradient vector
        sp_s.i_lam_g = rslts_i.lam_g;
    end

    % For subgraphs connected to plant
    if se.has.plant
        % Plant mass flow
        sp_s.i_mdot_0 = rslts_i.mdot_0;
        if se.has.plantP
            % Guess higher than Pmin
            idx_lower = sp_s.i_Pn(se.lnc.plant,:)<sp_s.P_min;
            sp_s.i_Pn(se.lnc.plant,idx_lower) = sp_s.P_min(1,idx_lower);
        end
    end

    % For subgraphs with users
    if se.has.user
        sp_s.i_valve = rslts_i.valve;
        sp_s.i_valve(sp_s.i_valve<.01) = .01;
    end
    
    % For subgraphs with mfree
    if se.has.Pset_mfree
        sp_s.i_mdot_free = rslts_i.mdot_free;
    end

    % Add T for variable passing (to be removed)
    if se.has.nonuser
        sp_s.T = rslts_i.T;
    end
end


