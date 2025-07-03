function cand_bin = dec2part(idx_row, split_fin, cand_all, minDigits)
%DEC2PART  converts the numeric partition description to the system 
%partitioning vector.
%
%   cand_bin = DEC2PART(idx_row, split_fin, cand_all, minDigits)
%
%   DESCRIPTION:
%   Converts the sequence of partitions into a single vector where the
%   index of the vector is the element and the number is the grouping
%
%   INPUTS:
%       idx_row   - row of partitioing in split_fin
%       split_fin - level of partitioning
%       cand_all  - List of all partitionings
%       minDigits - number of elements to be partitioned
%
%   OUTPUTS:
%       cand_bin - numeric partitioning

%% Gather sequence
cand_dec = zeros(1,split_fin);
for idx_split = split_fin:-1:2
    cand_dec(1,idx_split) = cand_all{1,idx_split}(idx_row,2);
    idx_row = cand_all{1,idx_split}(idx_row,1);
end
cand_dec(1,1) = cand_all{1,1}(idx_row,2);

%% Expand sequence
cand_bin= dec2bin(cand_dec(1,1),minDigits)-'0';
for idx_split = 2:split_fin
    n_split = sum(cand_bin==idx_split-1,2);
    new_digits = dec2bin(cand_dec(1,idx_split),n_split)-'0'+idx_split-1;
    cand_bin(cand_bin==idx_split-1)=new_digits;
end

end