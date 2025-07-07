function [G_ln,elem_ln,num_ln] = linegraph(G,elems,num,wp)
%LINEGRAPH Creates the linegraph of G.
%
%   [G_ln,elem_ln,num_ln] = LINEGRAPH(G,elems,num,wp)
%
%   DESCRIPTION:
%   Creates the linegraph of G by switching the edges to nodes.
%   Additionally creates the element and numeric structures related to this
%   linegraph.
%
%   INPUTS:
%       G       - Graph to be converted
%       elems   - Structure of categorized element.
%       num     - Structure of numeric problem specifications.
%       wp      - Vector of edge weights
%
%   OUTPUTS:
%       G_ln    - Weighted diagraph linegraph of G
%       elem_ln - Structure of categorized element for G_ln.
%       num_ln  - Structure of numeric problem specifications for G_ln.

%% Get Line Graph
ne = numedges(G);
G.Edges.Idx = (1:ne)';
adj_new = zeros(ne);

% Adjust user edge weight
wp(elems.user) = 1;

for i = 1:ne
    on = G.Edges.EndNodes(i,2);
    adj_new(i,on==G.Edges.EndNodes(:,1)) = wp(i);
end

G_ln = digraph(adj_new);

%% Get edge and node info

elem_ln = elems;
num_ln = num;
num_ln.node = numnodes(G_ln);
num_ln.edge = numedges(G_ln);
num_ln.nonuser = num_ln.node-num_ln.user;

G_ln.Edges.Idx = (1:num_ln.edge)';
G_ln.Nodes.Idx = (1:num_ln.node)';

elem_ln.root_node = find(indegree(G_ln)==0)';
elem_ln.term_node = find(outdegree(G_ln)==0)';

%% Plot for troubleshooting

%plot(G,'EdgeLabel',G.Edges.Idx);figure;plot(G_ln,'layout','layered','NodeLabel',G_ln.Nodes.Idx);

end