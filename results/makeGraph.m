function [h, te, tv] = makeGraph(G,elems,num, params_plot)
%MAKEGRAPH  Plots the graph.
%
%   [h, te, tv] = MAKEGRAPH(G,elems,num, params_plot)
%
%   DESCRIPTION:
%   Plots the network graph G with appropriate edge styles and node
%   symbols. Adds the edge and node labels manually with predefined 
%   locations.
%
%   INPUTS:
%       G       - Digraph of the network structure.
%       elems   - Structure of categorized element.
%       num     - Structure of numeric problem specifications.
%       params_plot - Structure of plotting parameters.
%
%   OUTPUTS:
%       h   - Handle of plot.
%       te  - Handles of edge labels.
%       tv  - Handles of node labels.

%% Plot Graph

h = plot(G, 'interpreter','latex');
h.NodeLabel = '';
h.NodeColor = 'k';
h.EdgeColor = 'k';
h.LineWidth = params_plot.g.ln;
h.MarkerSize = params_plot.g.nd;
h.ArrowPosition = 0.6;
h.EdgeAlpha = 1;

% Dashed User edges
highlight(h,'Edges',elems.user, 'LineStyle',params_plot.g.lnsty(end),'LineWidth', params_plot.g.ln-.6)

% Node Icons
v_cold = unique(G.Edges.EndNodes(elems.cold,:));
mrkrs = repelem(params_plot.mrkr(1),num.node);
mrkrs(v_cold) = params_plot.mrkr(2);
h.Marker = mrkrs;

% Add Edgel Labels
offset_x = [.15 -.65 .15 1.2 .15 .7 .2 -.25 -.35 -.35 -.35 .25 -.28 1.7];
offset_y = [.95 .95 .95 2.5 .95 1.5 .5 .5 0 0 0 .5 .5 3];
theta = zeros(1,num.edge);
te = cell(1,num.edge);
for e = 1:num.edge
    n = G.Edges.EndNodes(e,2);
    x = h.XData(n)+offset_x(e);
    y = h.YData(n)+offset_y(e);
    te{e} = text(x,y,string(e));
    te{e}.Rotation = theta(e);
    te{e}.HorizontalAlignment = 'center';
    te{e}.FontSize = params_plot.ft;
    te{e}.Margin = 2;
end

% Add Node Labels
offset_x = [0.03 0.03];
offset_y = [.65 -.45];
v_num = [elems.root elems.term];
node_label = ["$v_{0^-}$" "$v_{0^+}$"];
tv = cell(1,2);
for idx_n = 1:2
    x = h.XData(v_num(idx_n))+offset_x(idx_n);
    y = h.YData(v_num(idx_n))+offset_y(idx_n);
    tv{idx_n} = text(x,y,node_label(idx_n));
    tv{idx_n}.HorizontalAlignment = 'center';
    tv{idx_n}.FontSize = params_plot.ft+2;
    tv{idx_n}.Margin = 2;
end

box on 

end