function [rslt, idx_best, c_bound] = explore_down(row_tbs, split, rslt, idx_best, c_bound, G,elems,num,params,init,w_olm)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

%% Problem setup

split_new = split+1;
cand_bin = dec2part(row_tbs,split,rslt.cand(1:split), w_olm.minDigits);
% Label as branched
rslt.cand{split}(row_tbs,3) = 2;

%% Explore Cadidates

if sum(cand_bin==split,2)>1 % if it can be cut further
    n_split = sum(cand_bin==split,2); % Number of elements to be split
    for int_cand = 1:2^(n_split-1)-1
        if rslt.cost{split}(row_tbs,2)<c_bound
            cand_new = cand_bin;
            cand_new(cand_new==split) = dec2bin(int_cand,n_split)-'0'+split;
            cand_new = cand_new+1;
            if any(cand_new(elems.edge_plant) == cand_new(end)) % if the pressure control is valid
                if ismember([row_tbs int_cand],rslt.cand{split_new}(:,1:2),'rows')  % if it has been explored
                    [~, idx_rslt] = ismember([row_tbs int_cand],rslt.cand{split_new}(:,1:2),'rows');
                    rslt.cand{split_new}(idx_rslt,3) = 1;
                    c_i = rslt.cost{split_new}(idx_rslt,:);
                else % if not
                    idx_rslt = size(rslt.cand{split_new},1)+1;
                    rslt.cand{split_new}(idx_rslt,:) = [row_tbs int_cand 1];
                    sv_name = [split_new idx_rslt];
                    file_name = pwd+append(filesep,"olm_saves_depth",filesep)+"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat";
                    if exist(file_name,'file')==2% if it is in the file
                        c_i = load_data(file_name,w_olm);
                    else
                        c_i = find_olm(cand_new,G,elems,num,params,init,w_olm,sv_name);
                    end
                    rslt.cost{split_new}(idx_rslt,:) = c_i;
                end
                if c_i(1)<c_bound % if this is the new bounding cost, explore branch
                    c_bound = c_i(1);
                    idx_best = [split_new idx_rslt];
                    [rslt, idx_best, c_bound] = explore_down(idx_rslt, split_new, rslt, idx_best, c_bound, G,elems,num,params,init,w_olm);
                end
            end
        else
            disp('branch terminated')
            break
        end
    end
end




end