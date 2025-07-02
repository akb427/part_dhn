function [c_vec] = find_olm_fake(part,w)
%OLM_FAKE random cost to test bnb function
%   Detailed explanation goes here

warning('fake olm used')

c_slv = randi([1000, 5000]);
c_viol = randi([0 1],1);
iter = randi([5 30]);
[~, max_sz] = mode(part);

c = c_slv+w.viol*c_viol+w.iter*iter+w.sz*max_sz;
% [total, solve+iter, solve, is violation, iter, max size]
c_vec = [c c_slv+w.iter*iter c_slv c_viol iter max_sz];

end

