function [rslt] = generate_cand(tbe, split, rslt, elems, w_olm)
%GENERATE_CAND  Finds all valid further partitions of listed partitions .
%
%   [rslt] = GENERATE_CAND(tbe, split, rslt, elems, w_olm)
%
%   DESCRIPTION:
%   Loops over candidates, generating additional cut solutions, checking
%   that they are valid with relation to the plant, and adding their
%   decimal representation to the rslt.cand cell.
%
%   INPUTS:
%       tbe     - Numeric index of  candidates to be further partitioned.
%       split   - Current level of cuts in the partition.
%       rslt    - Structure of cand and cost.
%       elems   - Strucutre containing categoriezed elements.
%       w_olm   - Structure of parameters for the olm function.
%
%   OUTPUTS:
%       rslt    - Structure of cand and cost with new cand.
%
%   DEPENDENCIES: dec2part

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