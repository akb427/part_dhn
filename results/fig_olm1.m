function fig_olm1(data,params_plot)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
%% Plot Iterations

figure('Name','Conv Cost','Position',params_plot.pos)

% Inset position
ySet = 0.2;
hSet = 0.7;
xSet = 0.07;
wSet = .1;

% Plot all data
ogAx = axes('Position', [xSet+wSet+.15, ySet, 1-wSet-xSet-.15-.02, hSet]);
hold on
for idx = 2:max(data.n_part_conv)
    s = scatter(data.iter_conv(data.n_part_conv==idx),data.cost_conv(data.n_part_conv==idx),'filled',params_plot.mrkr(idx-1));
    if idx-1 == 2
        s.SizeData = s.SizeData+2;
    end
end
ogAx.FontSize = params_plot.ft_accent;
ogAx.YLim = [.99 1.3];
ogAx.XLim = [1.5 20.5];
ogAx.YLabel.String = "$c_{mPoA}$";
ogAx.YLabel.FontSize = params_plot.ft;
ogAx.XLabel.String = "$c_{iter}$";
ogAx.XLabel.FontSize = params_plot.ft;
box on; grid on; hold off

% Create Legend
L = legend(ogAx,string(2:max(data.n_part_conv)));
L.NumColumns = 2;
L.FontSize = params_plot.ft_accent;
L.Title.String = "\# of Partitions";
L.Title.FontSize = params_plot.ft;
L.Location = 'North';

% Add popout
insetAx = axes('Position', [xSet, ySet+.05, wSet, hSet-.05]); % position [x y width height]
hold on
for idx = 2:max(data.n_part_conv)
    s = scatter(insetAx, data.iter_conv(data.n_part_conv==idx),data.cost_conv(data.n_part_conv==idx),'filled',params_plot.mrkr(idx-1));
    if idx-1 == 2
        s.SizeData = s.SizeData+2;
    end
end
hold off
box on; grid on;
insetAx.XLim = [1.6, 3.3];
insetAx.YLim = [1 1.012];
insetAx.XTick = [2 3];
insetAx.FontSize = params_plot.ft-4;

% Draw Rectangle on original plot
rectangle(ogAx,'Position', [insetAx.XLim(1), insetAx.YLim(1), diff(insetAx.XLim), diff(insetAx.YLim)], 'EdgeColor', 'k', 'LineWidth', .7);

rectX_norm(1) = ogAx.Position(1) + (insetAx.XLim(1) - ogAx.XLim(1)) / (ogAx.XLim(2) - ogAx.XLim(1)) * ogAx.Position(3);
rectX_norm(2) = ogAx.Position(1) + (insetAx.XLim(2) - ogAx.XLim(1)) / (ogAx.XLim(2) - ogAx.XLim(1)) * ogAx.Position(3);

rectY_norm(1) = ogAx.Position(2) + (insetAx.YLim(1) - ogAx.YLim(1)) / (ogAx.YLim(2) - ogAx.YLim(1)) * ogAx.Position(4);
rectY_norm(2) = ogAx.Position(2) + (insetAx.YLim(2) - ogAx.YLim(1)) / (ogAx.YLim(2) - ogAx.YLim(1)) * ogAx.Position(4);

% Draw Lines
annotation('line', [rectX_norm(1), insetAx.Position(1)+insetAx.Position(3)], [rectY_norm(2), insetAx.Position(2)+insetAx.Position(4)]);
annotation('line', [rectX_norm(2), insetAx.Position(1)+insetAx.Position(3)], [rectY_norm(1), insetAx.Position(2)]);

hold off
end