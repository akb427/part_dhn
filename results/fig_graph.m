function fig_graph(G,elems,num,params_plot)
%FIG_GRAPH  Plots the DHN graph with edge sets highlighted.
%
%   FIG_GRAPH(G,elems,num,params_plot)
%
%   DESCRIPTION:
%   Plot the DHN described by G, highlighting the feeding, return, bypass,
%   and user edges, as indicated in the legend. The edges of the graph are
%   the network elements.
%
%   INPUTS:
%       G       - Digraph of the network structure.
%       elems   - Structure of categorized element.
%       num     - Structure of numeric problem specifications.
%       params_plot - Structure of plotting parameters.
%
%   DEPENDENCIES: makeGraph

%% Case Study Graph

% Create Plot
figure('Name','Graph')
set(gcf,'Position',params_plot.g.pos)
hold on

% Legend
for i =1:4
    plot([nan nan], [nan nan],'Color',params_plot.g.clr(i,:),'LineWidth',params_plot.leg.ln,'LineStyle',params_plot.g.lnsty(i))
end
L = legend('Feeding ($\bullet,\bullet$)\enspace', 'Return ($\rule{.8ex}{.8ex},\rule{.8ex}{.8ex}$)', 'Bypass ($\bullet,\rule{.8ex}{.8ex}$)\enspace', 'User ($\bullet,\rule{.8ex}{.8ex}$)','AutoUpdate','off','Orientation','horizontal','Location','southoutside');
L.IconColumnWidth = params_plot.leg.icon_width;
L.FontSize = params_plot.ft;
L.NumColumns = 2;
set(gca,'xtick',[],'ytick',[])

[h,~,~] = makeGraph(G,elems,num,params_plot);

% Highlight sets
var = ["hot" "cold" "bypass" "user"];
for idx_elem = 1:4
    highlight(h,'Edges',elems.(var(idx_elem)), 'EdgeColor',params_plot.g.clr(idx_elem,:))
end

hold off

end