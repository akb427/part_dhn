function cand_bin = dec2part(idx_row, split_fin, cand_all, minDigits)
%HAMMINGDIST hamming distance between binary representations
   % n: Number of elements
   % b: Decimal representation of the warm start solution
   % hd: hamming distances for each of the solutions 1:2^n-1

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