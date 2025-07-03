function bnb_split(w_olm,G,elems,num,params,init,cand_tbs)
%BNB_SPLIT branch and bound algorithm for finding optimal partitioning, 
%split for super computer 
%
%   BNB_SPLIT(w_olm, G, elems, num, params, init, cand_tbs)
%
%   Performs a branch-and-bound search to find the partitioning of a
%   DHN with layout G that minimizes the optimality loss
%   metric (OLM), with parameters w_olm. The algorithm explores a subset 
%   of partitions, prunes nonconverging or suboptimal branches.
%
%   INPUTS:
%       w_olm    - Structure ofparameters for the olm function.
%       G        - Digraph representing the network structure.
%       elems    - Structure containing categorized element.
%       num      - Structure containing numeric problem specifications.
%       params   - Structure of problem parameters.
%       init     - Initial guesses for olm calculation.
%       cand_tbs - Subset of candidates to explore 
%
%   DEPENDENCIES: dec2part, find_olm,load_data, generate_cand
%   REQUIREMENTS: Parallel Computing Toolbox, ParforProgressbar

%% Load current results or create them
pth = pwd;
file_name = pth+append(filesep,"rslts_curr.mat");
if (exist(file_name,'file')==2)
    load(file_name,'rslt')
else
    rslt.cand = cell(1,num.edge);
    rslt.cost = rslt.cand;
    cand_int_list = generate_2cuts(num.edge+1,elems);
    rslt.cand{1} = [zeros(numel(cand_int_list),1) cand_int_list'];
end

%% Solve

idx_split = find(~cellfun(@isempty,rslt.cand),1,'last');

ppm = ParforProgressbar(numel(cand_unsolve),'showWorkerProgress',true,'progressBarUpdatePeriod',60);

parfor idx_cand = 1:size(cand_tbs,1) 
    cand_i = cand_tbs(idx_cand);
    cand_bin = dec2part(cand_i,idx_split, rslt.cand(1:idx_split), w_olm.minDigits)+1;
    sv_name = [idx_split cand_i];
    file_name = pth+append(filesep,"olm_saves",filesep,"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat");
    if ~(exist(file_name,'file')==2)
        try
            find_olm(cand_bin,G,elems,num,params,init,w_olm,sv_name);
            ppm.increment();
        catch
            disp(cand_i)
        end
    end
end

end
