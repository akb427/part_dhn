function [c_vec, part] = load_data(file,w)
%LOAD_DATA  Load partitioning results from file.
%
%   [c_vec, part] = LOAD_DATA(file,w)
%
%   DESCRIPTION:
%   Loads data in prescribed files and returns cost vector and partition in
%   vector form.
%
%   INPUTS:
%       file    - String of file to be loaded. 
%       w       - Sturture of weights for olm terms.
%
%   OUTPUTS:
%       c_vec   - Cost vector for partition
%                 [total, min size, solve, is violation, iter, max size]
%       part    - Vector of partitioned elements
%
%   SEE ALSO: bnb, find_olm

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

%% Combine into cost vector

c = c_slv+w.viol*c_viol+w.iter*iter+w.sz*max_sz;
c_min_sz = c_slv+w.viol*c_viol+w.iter*iter+w.sz*min_sz;

% [total, min size, solve, is violation, iter, max size]
c_vec = [c c_min_sz c_slv c_viol iter max_sz min_sz];

end