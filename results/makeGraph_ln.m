function [h,tv] = makeGraph_ln(G,elems,num, params_plot)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

%% Plot Graph

h = plot(G, 'interpreter','latex');
h.NodeLabel = '';
h.NodeColor = 'k';
h.EdgeColor = 'k';
h.LineWidth = params_plot.lg.ln;
h.MarkerSize = params_plot.g.nd;
h.ArrowPosition = 0.6;
h.EdgeAlpha = 1;

% Node Icons
mrkrs = repelem(params_plot.mrkr(1),num.node);
mrkrs(elems.cold) = params_plot.mrkr(2);
mrkrs(elems.bypass) = params_plot.mrkr(3);
mrkrs(elems.user) = params_plot.mrkr(4);
mrkrs(elems.root) = params_plot.mrkr(1);
mrkrs(elems.term) = params_plot.mrkr(2);
h.Marker = mrkrs;

% Add Node Labels
offset_x = params_plot.lg.offset_x_node;
offset_y = params_plot.lg.offset_y_node;
v_num = params_plot.lg.v_num;
num_v = params_plot.lg.num_node_label;
tv = cell(1,num_v);
for idx_n = 1:num_v
    x = h.XData(v_num(idx_n))+offset_x(idx_n);
    y = h.YData(v_num(idx_n))+offset_y(idx_n);
    tv{idx_n} = text(x,y,params_plot.lg.node_label(idx_n));
    tv{idx_n}.HorizontalAlignment = 'center';
    tv{idx_n}.FontSize = params_plot.ft;
    tv{idx_n}.Margin = 2;
end

box on 

end