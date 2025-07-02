function fig_demand(params,num,elems,params_plot)
%FIG_DEMAND Summary of this function goes here
%   Detailed explanation goes here

%% Timing

nt = size(params_plot.tm,2);

%% Plot
figure('Name','Qb','Position',params_plot.pos)

hold on
for idx_u = 1:num.user
    p = plot(params_plot.tm,params.Qb(idx_u,1:nt),'Linewidth', params_plot.ln, 'Color',params_plot.clr_u(idx_u,:));
    p.Marker = params_plot.mrkr(idx_u);
    p.MarkerIndices = params_plot.idx_mrkr_m;
    p.MarkerSize = params_plot.mrkr_sz;
    p.MarkerFaceColor = p.Color;
    p.MarkerEdgeColor ='none';
end

% Legend
L = legend("$e_{"+string(elems.user)+"}$",'Orientation','horizontal');
L.Location = 'North';
L.FontSize = params_plot.ft_accent;

% Axes
ax = gca;
ax.FontSize = params_plot.ft_accent;

ax.XTick = params_plot.x.tick;

ax.XAxis.Label.String = params_plot.x.label;
ax.XAxis.Label.FontSize = params_plot.ft;
ax.XAxis.TickLabelFormat = params_plot.x.format;
ax.XAxis.Limits = params_plot.x.lim;
ax.XAxis.SecondaryLabel.Visible='off';

ax.YAxis.Label.String = "Heat Demand [$kW$]";
ax.YAxis.Label.FontSize = params_plot.ft;
ax.YAxis.Limits = [0 60];

box on; grid on; hold off

end

