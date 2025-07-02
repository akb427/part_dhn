function rslt = recompare(rslt, split_curr, c_bound)
%HAMMINGDIST hamming distance between binary representations
   % n: Number of elements
   % b: Decimal representation of the warm start solution
   % hd: hamming distances for each of the solutions 1:2^n-1

%% Recompare costs and remove non-viable
for split = 1:split_curr
    if ~isempty(rslt.cand{split})
        idx_rm = find(rslt.cost{split}(:,2) > c_bound);
        rslt.cand{split}(idx_rm,:) = NaN;
        for split_new = (split+1):size(rslt.cand,2)
            if ~isempty(rslt.cand{split_new}) && ~isempty(idx_rm)
                idx_rm = find(any(rslt.cand{split_new}(:,1)==idx_rm',2));
                rslt.cand{split_new}(idx_rm,:) = NaN;
            end
        end
    end
end

end
