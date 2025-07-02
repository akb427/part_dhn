function [part_best, rslt, idx_best] = bnb_depth(w_olm,G,elems,num,params,init)
%BNB Summary of this function goes here
%   part_i: initial partioning, should be a one cut
% Depth first search to eliminate more solutions, not parallizable

%% Problem Setup
pth = pwd;

% Previous results
file_name = pth+append(filesep,"rslt_3_26.mat");
load(file_name,'rslt');

% Add third column
for split = 1:size(rslt.cand,2)
    if ~isempty(rslt.cand{split})
        rslt.cand{split}(:,3) = 0;
    end
end

%% First step
split = 1;
% All 2 cut candidates must be evaluated
rslt.cand{1}(:,3) = 1;
% Find the best 2 cut candidate
idx_best = ones(1,2);
[c_bound, idx_best(2)] = min(rslt.cost{1}(:,1));
% Explore down branch
[rslt, idx_best, c_bound] = explore_down(idx_best(2), split, rslt, idx_best, c_bound, G,elems,num,params,init,w_olm);

%% Next Steps

for split = 1:num.edge-1
    if ~isempty(rslt.cost{split})
        [~,cand_sort] = sort(rslt.cost{split}(:,2));
        for idx_cand = cand_sort'
            c_i = rslt.cost{split}(idx_cand,2);
            tbe_i = rslt.cand{split}(idx_cand,3);
            if c_i<c_bound && tbe_i==1
                [rslt, idx_best, c_bound] = explore_down(idx_cand, split, rslt, idx_best, c_bound, G,elems,num,params,init,w_olm);
            end
        end
    end
end

%% Check number of solved
num_explored = zeros(1,num.edge-1);
for split = 1:num.edge-1
    if ~isempty(rslt.cost{split})
        num_explored(split) = nnz(rslt.cand{split}(:,3));
    end
end

%% Output best partition

if ~all(idx_best == zeros(1,2))
    part_best = dec2part(idx_best(2),idx_best(1),rslt.cand(1:idx_best(1)),w_olm.minDigits)+1;
else
    error('No viable solutions found')
end
