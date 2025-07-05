function [part_best, rslt_ml, idx_best] = bnb_regression(rslt,yfit,n_part,w_olm)
%BNB_REGRESSION branch and bound with fit prediction integrated and known solutions 
%
%   [part_best, rslt_ml, idx_best] = BNB_REGRESSION(rslt,yfit,n_part,w_olm)
%
%   Performs a branch-and-bound search with a pre-screening step
%   incorporated in yfit. It assumes all costs are knonw in rslts. 
%
%   INPUTS:
%       rslt    - Structure of results with numeric candidates and costs
%       yfit    - Cell of binary indicators of predicted convergence
%       n_part  - Number of partitions completed
%       w_olm   - Structure of parameters for the olm function.
%
%   OUTPUTS:
%       part_best - Matrix of best ml_informed element partitioning.
%       rslt_ml   - Structure containing screened candidates and costs.
%       idx_best  - Index in rslt_ml of the best-performing partition.
%
%   DEPENDENCIES: dec2part

%% Problem Setup

% Initial bounding cost
idx_best = zeros(1,2);
c_bound = Inf;

rslt_ml.cand = cell(1,n_part);
rslt_ml.cost = rslt_ml.cand;

%% Solve

for idx_split = 1:n_part
    if idx_split==1
        % Simple Prediction for first cut
        cand_pred = yfit{idx_split};
    else
        % Higher cuts must pass previous prediction
        cand_prev = rslt.cand{idx_split}(:,1);
        pass_prev = yfit{idx_split-1}(cand_prev);
        cand_pred = yfit{idx_split} & pass_prev;
    end
    rslt_ml.cand{idx_split} = rslt.cand{idx_split}(cand_pred,:);
    rslt_ml.cost{idx_split} = rslt.cost{idx_split}(cand_pred,:);
    rslt_ml.idx_old{idx_split} = find(cand_pred);

    % Find bounding cost
    c_vld = rslt_ml.cost{idx_split}(:,1);
    c_vld(logical(rslt_ml.cost{idx_split}(:,4))) = NaN;
    [c_bound_new, idx_best_row] = min(c_vld,[],'all');
    if c_bound_new< c_bound
        c_bound = c_bound_new;
        idx_best = [idx_split rslt_ml.idx_old{idx_split}(idx_best_row)];
    end
end

%% Output best partition

if ~all(idx_best == zeros(1,2))
    part_best = dec2part(idx_best(2),idx_best(1),rslt.cand(1:idx_best(1)),w_olm.minDigits)+1;
else
    error('No viable solutions found')
end
