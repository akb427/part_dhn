function fig_commgraph(elems,num,se,params_plot)
%FIG_COMMGRAPH  Plot of communication graph with communication directions 
%highlighted.
%
%   FIG_COMMGRAPH(elems,num,se,params_plot)
%
%   DESCRIPTION:
%   Plots the communication graph to show the direction of communication
%   between different subsystems in the distributed control problem.
%
%   INPUTS:
%       elems       - Structure of categorized element.
%       num         - Structure of numeric problem specifications.
%       se          - Structures of categorized subgraph elements.
%       params_plot - Structure of plotting parameters.
%
%   DEPENDENCIES: comm_graph

%% Create Communication Graphs

[Gconv,Gcomm,~] = comm_graph(elems,num,se);

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
set(gcf,'Position',params_plot.comm.pos)
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
h = plot(Gconv,'XData',x_coord, 'YData',y_coord);
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
    highlight(h,'Edges',Gconv.Edges.Idx==idx_g,'LineWidth',1.5,'EdgeColor',params_plot.comm.clr(idx_g,:),'LineStyle', params_plot.comm.lnsty(idx_g));
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