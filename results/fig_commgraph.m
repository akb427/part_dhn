function [Gcomm] = fig_commgraph(G,elems,num,params_plot)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% Create Communication Graphs

Gcomm = cell(1,3);
adj_comm = cell(1,3);
% mass flow
adj_comm{1} = false(num.edge+2);
for idx_edge = 1:num.edge
   out_node = G.Edges.EndNodes(idx_edge,2);
    if out_node==elems.term
        adj_comm{1}(idx_edge,num.edge+2) = 1;
    else
        if ismember(idx_edge,elems.hot)
            adj_comm{1}(outedges(G,out_node),idx_edge) = 1;
        else
            adj_comm{1}(idx_edge,outedges(G,out_node)) = 1;
        end
    end
end
adj_comm{1}(num.edge+1,outedges(G,elems.root)) = 1; % outedges of root
Gcomm{1} = digraph(adj_comm{1});

% Pressure
adj_comm{2} = false(num.edge+2);
for idx_edge = 1:num.edge
    out_node = G.Edges.EndNodes(idx_edge,2);
    if out_node==elems.term  % connected to reference pressure
        adj_comm{2}(num.edge+2,idx_edge) = 1;
    else
        if ismember(idx_edge,elems.hot)
            adj_comm{2}(idx_edge,outedges(G,out_node)) = 1;
        else
            adj_comm{2}(outedges(G,out_node),idx_edge) = 1;
        end
    end
end
adj_comm{2}(num.edge+1,outedges(G,elems.root)) = 1;
Gcomm{2} = digraph(adj_comm{2});

% Temperature
adj_comm{3} = false(num.edge+2);
for idx_edge = 1:num.edge
    in_node = G.Edges.EndNodes(idx_edge,1);
    if in_node == elems.root
        adj_comm{3}(num.edge+1,idx_edge) = 1; % outedges of root
    else
        adj_comm{3}(inedges(G,in_node),idx_edge) = 1;
    end
    if G.Edges.EndNodes(idx_edge,2)==elems.term
        adj_comm{3}(idx_edge,num.edge+2) = 1;
    end
end
Gcomm{3} = digraph(adj_comm{3});

for idx_g = 1:3
    Gcomm{idx_g}.Edges.("Idx") = idx_g*ones(numedges(Gcomm{idx_g}),1);
end
% Combine
G_all = Gcomm{1};
G_all = addedge(G_all,Gcomm{2}.Edges);
G_all = addedge(G_all,Gcomm{3}.Edges);


%% Properties

node_labels = repelem("",1,num.edge+2);
node_okay = [4 6 8 13];
node_labels(node_okay) = string(node_okay);

% Coordinates
coord = layoutcoords(Gcomm{3},'layered',Sources=num.edge+1,Sinks=num.edge+2,AssignLayers='asap');
x_coord = coord(:,1);
y_coord = coord(:,2);
y_coord(6) = y_coord(8);
y_coord(4) = y_coord(8);

%% Communication Graph

figure('Name','Communication Graph')
set(gcf,'Position',params_plot.g.pos)
hold on;

% Legend
lgd = ["$\dot{m}$\enspace","$P$\enspace","$T$\enspace"];
for i = 1:3
    plot(nan, nan,'Color',params_plot.comm.clr(i,:),'LineWidth',params_plot.leg.ln,'LineStyle', params_plot.comm.lnsty(i))
end
L = legend(lgd,'AutoUpdate','off','Orientation','horizontal','Location','southoutside');
L.IconColumnWidth = params_plot.leg.icon_width;
L.FontSize = params_plot.ft;
set(gca,'xtick',[],'ytick',[])

% Plot
h = plot(G_all,'XData',x_coord, 'YData',y_coord);
h.NodeLabel = node_labels;
h.Interpreter = 'latex';
h.NodeFontSize = params_plot.ft;
h.EdgeColor = 'k';
h.NodeColor = 'k';
h.EdgeAlpha = 1;
h.MarkerSize = params_plot.g.nd;
h.LineWidth = params_plot.comm.ln;
h.ArrowPosition = .6;
h.ArrowSize = 9;
h.EdgeAlpha = 1;

for idx_g = 1:3
    highlight(h,'Edges',G_all.Edges.Idx==idx_g,'LineWidth',1.5,'EdgeColor',params_plot.comm.clr(idx_g,:),'LineStyle', params_plot.comm.lnsty(idx_g));
end

% Manually add node labels
node_fix = setdiff(1:num.edge, node_okay);
node_labels = [string(node_fix) "$v_{0^-}$" "$v_{0^+}$"];
node_fix = [node_fix num.edge+1 num.edge+2];
offset_x = [-.2 .2 -.2 -.2 -.2 -.2 -.3 -.3 -.4 .3 0 0];
offset_y = [.4 .4 .4 .4 0 -.4 -.5 -.5 0 -.5 .6 -.5];

for idx_n = 1:numel(node_labels)
    v = node_fix(idx_n);
    x = h.XData(v)+offset_x(idx_n);
    y = h.YData(v)+offset_y(idx_n);
    t = text(x,y,node_labels(idx_n));
    t.HorizontalAlignment = 'center';
    t.FontSize = h.NodeFontSize;
end

box on; hold off;

end