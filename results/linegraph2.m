function [G_ln,elem_ln,num_ln] = linegraph(G,elems,num)
%DHN_LINEGRAPH 

%% Get Line Graph
ne = numedges(G);
G.Edges.Idx = (1:ne)';
adj_new = zeros(ne+2);

for i = 1:ne
    on = G.Edges.EndNodes(i,2);
    adj_new(i,on==G.Edges.EndNodes(:,1)) = 1;
end

% Add plant
adj_new(ne+1,G.Edges.EndNodes(:,1)==elems.root) = 1;
adj_new(G.Edges.EndNodes(:,2)==elems.term, ne+2) = 1;

G_ln = digraph(adj_new);

%% Get edge and node info

elem_ln = elems;
num_ln = num;
num_ln.node = numnodes(G_ln);
num_ln.edge = numedges(G_ln);
num_ln.nonuser = num_ln.node-num_ln.user;

G_ln.Edges.Idx = (1:num_ln.edge)';
G_ln.Nodes.Idx = (1:num_ln.node)';

elem_ln.root = ne+1;
elem_ln.term = ne+2;

%% Plot for troubleshooting

%plot(G,'EdgeLabel',G.Edges.Idx);figure;plot(G_ln,'layout','layered','NodeLabel',G_ln.Nodes.Idx);

end