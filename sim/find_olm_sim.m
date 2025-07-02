function [c_vec,v,v_sim] = find_olm_sim(part,G,elems,num,params,init,w,sv_name)
%FIND_OLM Find the OLM for a specific partition
%   part: partition to be explored
%   init: initial conditions to be used for optimization
%   w: weighting terms
%   c_vec: cost vector of form [total, min size, solve, is violation, iter, max size]


%% Partitioned System Parameters

[~,selems,snum,sparams,num,elems] = subgraph_params(G,part,elems,num,params);
Gconv = comm_graph(elems,num,selems);

%% Optimization functions

M.gen = cell(1,num.sg);
for idx_sg = 1:num.sg
    M.gen{idx_sg} = opt_comm_tfn(snum{idx_sg},selems{idx_sg},sparams{idx_sg},params,false);
end

% Feasibility restoration functions
idx_P_slack = find(elems.idx_plant&~elems.idx_plantP)';
if ~isempty(idx_P_slack)
    M.slack = cell(1,num.sg);
    for idx_sg = idx_P_slack
        M.slack{idx_sg} = opt_comm_tfn(snum{idx_sg},selems{idx_sg},sparams{idx_sg},params,true);
    end
end

%% Find cost

[v_sim,v] = dist_control_sim(M,Gconv,num,elems,params,snum,selems,sparams,init,w);

% save results
if nargin == 8
    pth_split = split(pwd, filesep);
    pth = fullfile(pth_split{1:7});

    save(pwd+append(filesep,"olm_saves",filesep)+"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat",'part','v_sim','v');
end


%% Get cost

if nargin<8
    % pull out cost types
    c_slv = sum([v_sim.cost_Q],'all')+sum([v_sim.cost_SOC],'all'); %using simulation cost, could use optimization cost
    c_viol = any(~[v.isconverge]);
    iter = sum([v.iter],'all');
    sz = accumarray(part',1);
    max_sz = max(sz);
    
    c = c_slv+w.viol*c_viol+w.iter*iter+w.sz*max_sz;
    
    c_min_sz = c_slv+w.viol*c_viol+w.iter*iter+w.sz*max(sz(1:end-1));
    
    
    % [total, min size, solve, is violation, iter, max size]
    c_vec = [c c_min_sz c_slv c_viol iter max_sz];
end

end

