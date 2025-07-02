function fig_part(G,elems,num,part,params_plot)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Properties
n_part = max(part);

%% Partitioned Graph

figure('Name','Graph Part')
set(gcf,'Position',params_plot.g.pos)
hold on

% Legend
for i = 1:n_part
    if i>=3
        plot(nan, nan,'Color',params_plot.clr(i,:),'LineWidth',1)
    else
        p = plot(nan, nan,'Color',params_plot.clr(i,:),'LineWidth',1);
        %p.Marker = params_plot.mrkr(i);
        %p.MarkerSize = 10;
        %p.MarkerEdgeColor = 'k';
    end
end

L = legend("$\mathcal{V}^{\left\{"+string(1:n_part)+"\right\}}$\enspace",'AutoUpdate','off','Orientation','horizontal','Location','southoutside');
L.IconColumnWidth = params_plot.leg.icon_width;
L.FontSize = params_plot.ft;
set(gca,'xtick',[],'ytick',[])

[h,te,tv] = makeGraph(G,elems,num,params_plot);

% Highlight Partitions
for i = 1:n_part
    highlight(h,'Edges',part(1:end-1)==i, 'EdgeColor',params_plot.clr(i,:))
end

% Add Shapes to edge labels
% for e = 1:num.edge+1
%     if part(e)<3
%         if part(e) == 1 % circle
%             crv = [1 1];
%         elseif part(e)==2  % rectangle
%             crv = [0 0];
%         end
%         if e>num.edge % node
%             extent = get(tv{e-num.edge}, 'Extent');
%             nshrink = .1;
%         else
%             extent = get(te{e}, 'Extent');
%             nshrink = 0;
%         end
%         margin = 0.03;
%         rectangle('Position', [extent(1)-margin, extent(2), extent(3)+2*margin, extent(4)-nshrink], 'Curvature', crv ,...
%            'EdgeColor', 'k', 'LineWidth', 0.5);
%     end
% end

box on
hold off

end