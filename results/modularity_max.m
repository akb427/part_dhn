function [part] = modularity_max(G)
%MODULARITY_MAX Modularity maximizing partition.
%
%   [part] = MODULARITY_MAX(G)
%
%   DESCRIPTION: Recursive bi-partioing of G to maximize the modularity of
%   the resulting partitioned system based on Jogwar Daoutidis 2017
%
%   INPUTS:
%       G   - Weighted digraph to be partitioned.
%
%   OUTPUTS:
%       part    - Vector of element partitioning.

%% First divide

m = numedges(G);

k_in = indegree(G);
k_out = outdegree(G);

A = adjacency(G);
B = A-1/m*k_in*k_out';

[eig_max,~] = eigs(B+B',1,'largestreal');
s = sign(eig_max);

c1 = find(eig_max>0);
c2 = find(eig_max<0);
Q = 1/(4*m)*s'*(B+B')*s;
c_list = 1:numel(eig_max);
[c1,c2,~,~] = fine_tune(c1,c2,s,Q,B,c_list);

c = subdivide_community([],c1);
c = subdivide_community(c,c2);

%% Convert to indexing

part = zeros(1, numnodes(G));
for i = 1:numel(c)
    part(c{i}) = i;
end

%% Subfunctions
    function [c] = subdivide_community(c,c_hold)
    B_sub = B(c_hold,c_hold);
    Bg = B_sub -1/2*diag(sum(B_sub)+sum(B_sub,2)');
    [x_max,~] = eigs(Bg+Bg',1,'largestreal');
    si = sign(x_max);

    c1i = c_hold(x_max>0);
    c2i = c_hold(x_max<0);
    dQ = 1/(4*m)*si'*(Bg+Bg')*si;
    [c1i,c2i,~,dQ] = fine_tune(c1i,c2i,si,dQ,Bg,c_hold);
    if dQ>1e-3
        c = subdivide_community(c,c1i);
        c = subdivide_community(c,c2i);
    else
        c{end+1}= sort(c_hold)';
    end
    end

    function [c1i, c2i, si, Qi] = fine_tune(c1i,c2i,si,Qi,Bi,c_list)
    rst = 0;                                                                % flag to run fine_tune again
    for ii = randperm(numel(c_list))                                        % perform fine tuning in a random order
        s_new = si;                                                         % set up new s vector
        s_new(ii) = s_new(ii)*-1;                                           % change one element of s to other community
        Q_new = 1/(4*m)*s_new'*(Bi+Bi')*s_new;                              % calculate Q for new s
        if Q_new>Qi                                                         % if new subdivision is an improvement
            rst = 1;                                                            % flag to run fine_tune again
            si = s_new;                                                         % save new s
            Qi = Q_new;                                                         % save new Q
            if si(ii)<0                                                         % if the node has been moved into c2
                c1i(c1i==c_list(ii))=[];                                            % remove the element from c1
                c2i = [c2i; c_list(ii)];                                            % add the element to c2
            else                                                                % else if the node has been moved into c1
                c2i(c2i==c_list(ii))=[];                                            % remove the element from c2
                c1i = [c1i; c_list(ii)];                                            % add the element to c1
            end
        end
    end
    if rst ==1                                                              % if changes were made
        [c1i, c2i, si, Qi] = fine_tune(c1i,c2i, si, Qi,Bi,c_list);              % rerun the fine-tuning
    end
    end

end

