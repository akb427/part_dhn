function [part_best, rslt, idx_best] = bnb(w_olm,G,elems,num,params,init)
%BNB branch and bound algorithm for finding optimal partitioning 
%
%   [part_best, rslt, idx_best] = BNB(w_olm, G, elems, num, params, init)
%
%   Performs a branch-and-bound search to find the partitioning of a
%   DHN with layout G that minimizes the optimality loss
%   metric (OLM), with parameters w_olm. The algorithm explores the space of
%   possible partitions, prunes nonconverging or suboptimal branches, and
%   returns the best partition found.
%
%   INPUTS:
%       w_olm   - Structure ofparameters for the olm function.
%       G       - Digraph representing the network structure.
%       elems   - Structure containing categorized element.
%       num     - Structure containing numeric problem specifications.
%       params  - Structure of problem parameters.
%       init    - Initial guesses for olm calculation.
%
%   OUTPUTS:
%       part_best - Matrix of element partitioning.
%       rslt      - Structure containing all candidates and costs.
%       idx_best  - Index in rslt of the best-performing partition.
%
%   DEPENDENCIES: dec2part, find_olm,load_data, generate_cand
%   REQUIREMENTS: Parallel Computing Toolbox, ParforProgressbar

%% Problem Setup
pth = pwd;
file_name = pth+append(filesep,"rslts_curr.mat");
% if (exist(file_name,'file')==2)
%     load(file_name,'rslt')
% else
%     rslt.cand = cell(1,num.edge);
%     rslt.cost = rslt.cand;
%     rslt.part = rslt.cand;
%     First round partitioning
%     cand_int_list = generate_2cuts(num.edge+1,elems);
%     rslt.cand{1} = [zeros(numel(cand_int_list),1) cand_int_list'];
% end

load(file_name,'rslt')
rslt.cand(2:end) = {[]};
rslt.cost = cell(1,num.edge);
rslt.part = cell(1,num.edge);

% Initial bounding cost
idx_best = zeros(1,2);
c_bound = Inf;

%% Solve

for idx_split = 1:num.edge
    n_cand = size(rslt.cand{idx_split},1); 
    c_split = nan(n_cand,7);
    part_split = nan(n_cand,num.edge+1);

    % Check if solved
    is_solved = false(n_cand,1);
    for idx_cand = 1:n_cand
        sv_name = [idx_split idx_cand];
        file_name = pth+append(filesep,"olm_saves",filesep,"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat");
        is_solved(idx_cand) = (exist(file_name,'file')==2);
    end

    % Solve all split level solutions
    cand_unsolve = find(~is_solved);
    if numel(cand_unsolve)>0
        ppm = ParforProgressbar(numel(cand_unsolve),'showWorkerProgress',true,'progressBarUpdatePeriod',60);
        parfor idx_cand = 1:numel(cand_unsolve) 
            cand_i = cand_unsolve(idx_cand);
            cand_bin = dec2part(cand_i,idx_split, rslt.cand(1:idx_split), w_olm.minDigits)+1;
            sv_name = [idx_split cand_i];
            %c_split(idx_cand,:) = find_olm_fake(cand_bin,w_olm);
            try
            find_olm(cand_bin,G,elems,num,params,init,w_olm,sv_name);
            ppm.increment();
            catch
                disp(cand_i)
            end
        end
    end
    
    % Load Results
    if isempty(rslt.cost{idx_split})
        for idx_cand = 1:n_cand
            sv_name = [idx_split idx_cand];
            file_name = pth+append(filesep,"olm_saves",filesep)+"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat";
            [c_split(idx_cand,:), part_split(idx_cand,:)] = load_data(file_name,w_olm);
        end
        rslt.cost{idx_split} = c_split;
        rslt.part{idx_split} = part_split;
    end

    % Find bounding cost
    c_vld = rslt.cost{idx_split}(:,1);
    c_vld(logical(rslt.cost{idx_split}(:,4))) = NaN;
    [c_bound_new, idx_best_row] = min(c_vld,[],'all');
    if c_bound_new< c_bound
        c_bound = c_bound_new;
        idx_best = [idx_split idx_best_row];
    end

    % Find candidates to be cut further
    if idx_split<num.edge && isempty(rslt.cand{idx_split+1})
        if idx_split<num.edge
            tbe = find(~rslt.cost{idx_split}(:,4) & rslt.cost{idx_split}(:,2)<=c_bound);
            rslt = generate_cand(tbe, idx_split, rslt, elems, w_olm);
        end
        %save("rslts_curr","rslt");
        if isempty(rslt.cand{idx_split+1})
            break
        end
    end
end

%% Output best partition

if ~all(idx_best == zeros(1,2))
    part_best = dec2part(idx_best(2),idx_best(1),rslt.cand(1:idx_best(1)),w_olm.minDigits)+1;
else
    error('No viable solutions found')
end
