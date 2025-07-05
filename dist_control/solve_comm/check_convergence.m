function [delta_var, stat, isconverge] = check_convergence(rslts, isconverge, se, delta_min, Gconv)
%CHECK_CONVERGENCE  Check convergence of subsystems.
%
%   [delta_var, stat, isconverge] = CHECK_CONVERGENCE(rslts, isconverge, se, delta_min, Gconv)
%
%   DESCRIPTION:
%   Checks if change in results meets a convergence criteria and if all
%   upstream subsystems have converged.
%
%   INPUTS:
%       rslts       - Array of structures with subsytem results.
%       isconverge  - Vector of binary indicators of convergence.
%       se          - Structure containing categorized subsystem element.
%       delta_min   - Vector of convergence thresholds by variable type.
%       Gconv       - Graph showing subsystem convergence hierarchy.
%
%   OUTPUTS:
%       delta_var   - Matrix of variable change by variable type and subgraph.
%       stat        - Strings of solution outcome from CasAdi.
%       isconverge  - Updated vecotr of binary indicators of convergence.

%%
delta_var = zeros(4,numel(isconverge));
stat = cellfun(@(x)x.status,rslts(2,:),'UniformOutput',false);

for idx_sg = find(~isconverge)
    delta_var(1,idx_sg) = abs(rslts{2,idx_sg}.cost-rslts{1,idx_sg}.cost);
    if se{idx_sg}.has.plant
        delta_var(2,idx_sg) = max(abs(rslts{2,idx_sg}.mdot_0-rslts{1,idx_sg}.mdot_0),[],'all');
    end
    if se{idx_sg}.has.Pset_mfree
        % Chosen Flow
        delta_var(3,idx_sg) = max(abs(rslts{2,idx_sg}.mdot_free-rslts{1,idx_sg}.mdot_free),[],'all');
        % Dictated Pressure
        node = se{idx_sg}.node_Pset_mfree.Node_LNC;
        delta_var(4,idx_sg) = max(abs(rslts{2,idx_sg}.Pn(node,:)-rslts{1,idx_sg}.Pn(node,:)),[],'all');
    end
end

%% Convergence Graph Analysis

% Find simultaneous solves
bins_labels = conncomp(Gconv, 'Type', 'strong');

% Find convergence order
G_bins = condensation(Gconv);

%% Convergence Check

% Iterate through the bins in order
for bin = toposort(G_bins)
    sg_pred = find(bins_labels==predecessors(G_bins, bin));
    % if the upstream graphs are converged
    if isempty(sg_pred) || all(isconverge(sg_pred))
        sg_tbc = find(bins_labels == bin);
        isconverge(sg_tbc) = all(all(delta_var(:,sg_tbc)<delta_min) & ismember(stat(sg_tbc),{'Solve_Succeeded','Solved_To_Acceptable_Level'}));
    end
end

end

