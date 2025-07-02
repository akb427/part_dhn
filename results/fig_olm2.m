function fig_olm2(data, rslt_b, params_plot)

%% Found partitons

% OLM
sz_best = data.max_sz(data.idx_best_all);
c_best = data.cost(data.idx_best_all);
iter_best = data.iter(data.idx_best_all);

%% Plot Iterations
idx_f = 0;
n_plot = 5;

% Plot data by max size
for idx_sz = 1:(max(data.max_sz_conv)-min(data.max_sz_conv)+1)
    % Make figure
    if mod(idx_sz,n_plot) == 1
        figure('Name','Conv Cost','Position',params_plot.cost.pos_wide)
        idx_f = idx_f+1;
        hold on
    end

    % Extract data
    sz = min(data.max_sz_conv)-1+idx_sz;
    d_sz = data.iter_conv(data.max_sz_conv==sz);
    d_sz = d_sz+20*(idx_sz-n_plot*(idx_f-1)-1);
    d_cost = data.cost_conv(data.max_sz_conv==sz);
    d_n_part = data.n_part_conv(data.max_sz_conv==sz);

    % Plot by number of partitions
    for idx_part = 2:max(data.n_part_conv)
        s(idx_part-1) = scatter(d_sz(d_n_part==idx_part),d_cost(d_n_part==idx_part),'filled',params_plot.mrkr(idx_part-1));
        s(idx_part-1).SizeData = params_plot.cost.mrkr_sz;
        s(idx_part-1).MarkerFaceColor = params_plot.clr(idx_part-1,:);
        if s(idx_part-1).Marker=="square"
            s(idx_part-1).SizeData = params_plot.cost.mrkr_sz+2;
        end
    end

    % Add point for olm-minimizing
    if sz == sz_best
        s_olm = scatter(iter_best+20*(idx_sz-n_plot*(idx_f-1)-1),c_best,'filled',"pentagram");
        s_olm.MarkerFaceColor = "k";
        s_olm.SizeData = params_plot.cost.star_sz+10;
        % L = legend(s_olm,'OLM-Minimizing','AutoUpdate','off');
        % L.FontSize = params_plot.ft_accent;
        %rectangle(gca,'Position', [1.6, .995, .8, .02], 'EdgeColor', 'k', 'LineWidth', .5);
    end
    % Add point for Baseline
    if sz == rslt_b.max_sz
        s_b = scatter(rslt_b.iter+20*(idx_sz-n_plot*(idx_f-1)-1),rslt_b.cost,'filled',"x");
        s_b.MarkerEdgeColor = "k";
        s_b.LineWidth = 1.5;
        % L = legend(s_b,'Baseline','AutoUpdate','off');
        % L.FontSize = params_plot.ft_accent;
    end
 
    if sz == max(data.max_sz_conv)
        % Create Legend
        L = legend([s s_olm s_b],[string(2:max(data.n_part_conv))+"-Cut" "OLM" "Baseline"]);
        L.NumColumns = 2;
        L.Orientation = 'Horizontal';
        L.FontSize = params_plot.ft_accent;
        L.Title.FontSize = params_plot.ft;
        L.Location = 'NorthEast';
        L.Position(2) = L.Position(2)-.1;
    end

    ax = gca;
    t = text(10+20*(idx_sz-n_plot*(idx_f-1)-1),1.25,"$c_{sz}$="+string(sz));
    t.HorizontalAlignment = "center";
    t.FontSize = params_plot.ft;
    if mod(idx_sz,5)==0
        ax.FontSize = params_plot.ft_accent;
        ax.YLim = [.99 1.27];
        ax.XLim = [0 20*n_plot+.5];
        ax.XTick = 5:5:20*n_plot+.5;
        ax.XTickLabel = repmat(5:5:20,1,n_plot);
        ax.XLabel.String = "$c_{iter}$";
        ax.XLabel.FontSize = params_plot.ft;
        ax.YLabel.String = "$c_{mPoA}$";
        ax.YLabel.FontSize = params_plot.ft;
        grid on; box on; hold off
    else
        xline(ax,20*(idx_sz-n_plot*(idx_f-1))+.5)
    end
end

end
