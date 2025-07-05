function [rslt] = generate_cand(tbe, split, rslt, elems, w_olm)
%FUNCTION_NAME  One-line summary of what the function does.
%
%   [out1, out2, ...] = FUNCTION_NAME(in1, in2, ...)
%
%   DESCRIPTION:
%   Briefly explain the purpose of the function, what it computes, or how it
%   fits into the overall workflow. Mention any important assumptions or side
%   effects (e.g., plotting, modifying global variables, saving files).
%
%   INPUTS:
%       in1  - Description of input 1 (type, format, units if applicable)
%       in2  - Description of input 2
%       ...  - Additional inputs as needed
%
%   OUTPUTS:
%       out1 - Description of output 1 (what it represents)
%       out2 - Description of output 2
%       ...  - Additional outputs as needed
%
%   EXAMPLE USAGE:
%       [best_part, results] = my_partition_solver(G, params);
%
%   DEPENDENCIES:
%       List other custom functions this function calls, if any.
%
%   SEE ALSO:
%       RelatedFunction1, RelatedFunction2

%% Problem setup

split_new = split+1;
idx_add = 0;

for tbe_i = tbe' % over all possible candidates
    cand_bin = dec2part(tbe_i,split,rslt.cand(1:split), w_olm.minDigits);
    if sum(cand_bin==split,2)>1 % if it can be cut further
        n_split = sum(cand_bin==split,2); % Number of elements to be split
        for int_cand = 1:2^(n_split-1)-1
            cand_new = cand_bin;
            cand_new(cand_new==split) = dec2bin(int_cand,n_split)-'0'+split;
            cand_new = cand_new+1;
            if any(cand_new(elems.edge_plant) == cand_new(end)) % if the pressure control is valid
                idx_add = idx_add+1;
                rslt.cand{split_new}(idx_add,:) = [tbe_i int_cand];
            end
        end
    end
end

end