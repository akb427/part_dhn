function [cand_list] = generate_2cuts(minDigits,elems)
%FIND_2CUTS find bipartitions that are valid according to the plant 
%pressure assignment
%
%   [cand_list] = GENERATE_2CUTS(minDigits,elems)
%
%   DESCRIPTION:
%   Partitions system elements ensuring that the plant is assigned to a
%   partiton shared by one of the pipes leaving the plant
%
%   INPUTS:
%       minDigits - Number of elements to be partitioned
%       elems     - Structure containing categorized elements.
%
%   OUTPUTS:
%       cand_list - List of valid solutions

%% Find Valid Candidates
% all possible unique cuts
cand_list = 1:(2^(minDigits-1) - 1);

% eliminate infeasible partitions based on pressure assignments
vld = false(size(cand_list));
for i = 1:size(cand_list,2)
    cand = dec2bin(cand_list(i),minDigits)-'0'+1;
    vld(i) = any(cand(elems.edge_plant) == cand(end));
end
cand_list = cand_list(vld);

end