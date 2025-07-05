function [c_vec] = find_olm_fake(part,w)
%FIND_OLM_FAKE random cost to test bnb algorithm
%
%   [c_vec] = FIND_OLM_FAKE(part, w)
%
%   DESCRIPTION:
%   Test function that generates a fake cost vector, with a warning that 
%   this function was used.
%
%   INPUTS:
%       part  - network partitioning
%       w     - cost function weights
%
%   OUTPUTS:
%       c_vec - cost vector containing:
%               [total, solve+iter, solve, is violation, iter, max size]

%% Warn about function use
warning('fake olm used')

%% Generate fake cost
c_slv = randi([1000, 5000]);
c_viol = randi([0 1],1);
iter = randi([5 30]);
[~, max_sz] = mode(part);

c = c_slv+w.viol*c_viol+w.iter*iter+w.sz*max_sz;
% [total, solve+iter, solve, is violation, iter, max size]
c_vec = [c c_slv+w.iter*iter c_slv c_viol iter max_sz];

end

