function fig_graph_ln(G,elems,num,params_plot)
%FIG_GRAPH_LN  Plots the DHN line graph with node sets highlighted.
%
%   FIG_GRAPH_LN(G,elems,num,params_plot)
%
%   DESCRIPTION:
%   Plot the DHN described by G, highlighting the feeding, return, bypass,
%   and user nodes, as indicated in the legend. The nodes of the graph are
%   the network elements.
%
%   INPUTS:
%       G       - Digraph of the network linegraph.
%       elems   - Structure of categorized element.
%       num     - Structure of numeric problem specifications.
%       params_plot - Structure of plotting parameters.
%
%   DEPENDENCIES: makeGraph_ln

%% Case Study Graph

% Create Plot
figure('Name','Graph')
set(gcf,'Position',params_plot.g.pos)
hold on

% Legend
for i =1:4
    p = plot([nan nan],[nan nan],LineStyle="none",Marker=params_plot.mrkr(i));
    p.MarkerFaceColor=params_plot.g.clr(i,:);
    p.MarkerEdgeColor=params_plot.g.clr(i,:);
    p.MarkerSize = params_plot.mrkr_sz;
    if p.Marker=="square"
        p.MarkerSize = p.MarkerSize+2;
    end
end
L = legend('Feeding', 'Return', 'Bypass', 'User','AutoUpdate','off');
L.Orientation = 'horizontal';
L.Location = 'southoutside';
L.IconColumnWidth = params_plot.leg.icon_width;
L.FontSize = params_plot.ft;
L.NumColumns = params_plot.leg.columns;
L.IconColumnWidth = params_plot.leg.icon_width;
set(gca,'xtick',[],'ytick',[])

[h,~] = makeGraph_ln(G,elems,num,params_plot);

ax = gca;
ax.XLim  = params_plot.lg.xlim;
ax.YLim = params_plot.lg.ylim;

% Highlight sets
var = ["hot" "cold" "bypass" "user"];
for idx_elem = 1:4
    highlight(h,elems.(var(idx_elem)), 'NodeColor',params_plot.g.clr(idx_elem,:))
end

highlight(h,elems.root, 'NodeColor',params_plot.g.clr(1,:))
highlight(h,elems.term, 'NodeColor',params_plot.g.clr(2,:))

hold off

end