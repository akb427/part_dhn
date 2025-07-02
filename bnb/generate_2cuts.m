function [cand_list] = generate_2cuts(minDigits,elems)
%FIND_2CUTS find bipartitions that are valid according to the plant 
%pressure assignment
    % minDigits: Number of elements to be partitioned
    % cand_list: List of valid solutions sorted by similarity to cand_int_ig

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