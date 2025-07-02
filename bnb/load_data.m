function [c_vec, part] = load_data(file,w)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Load

load(file,'part','v_sim','v');

%% Extract data

conv = v.isconverge;
c_viol = ~conv;
if conv
    c_slv = v_sim.cost_Q+v_sim.cost_SOC; % using simulation cost, could use optimization cost
else
    c_slv = 0;
end

iter = max(v.iter);
sz = accumarray(part',1);
min_sz = max(sz(1:end-1));
max_sz = max(sz);

c = c_slv+w.viol*c_viol+w.iter*iter+w.sz*max_sz;
c_min_sz = c_slv+w.viol*c_viol+w.iter*iter+w.sz*min_sz;

% [total, min size, solve, is violation, iter, max size]
c_vec = [c c_min_sz c_slv c_viol iter max_sz min_sz];

end