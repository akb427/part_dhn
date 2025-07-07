function fig_olm(data, rslt_b, params_plot, is_save)
%FIG_OLM  Plot mPoA vs iterations, plotted by max partition size.
%
%   FIG_OLM(data, rslt_b, params_plot, is_save)
%
%   DESCRIPTION:
%   Creates a set of figures, divided by maximum partitions size, comparing
%   the iterations  to convergence and the modified price of anarchy to
%   show the distribution of converging solution costs. Also highlighting 
%   olm-minimizing solution and baseline case. Additionally includes a 
%   vertical figure of the lowest cost solutions. 
%
%   INPUTS:
%       data        - Structure of seach statistics.
%       rslt_b      - Structure of baseline results.
%       params_plot - Strucutre of plotting parameters.
%       is_save     - Binary indicator of saving figures.

%% Found partitons

% OLM
sz_best = data.max_sz(data.idx_best_all);
c_best = data.cost(data.idx_best_all);
iter_best = data.iter(data.idx_best_all);

%% Plot Iterations

% Plot data by max size
for idx_sz = min(data.max_sz_conv):max(data.max_sz_conv)
    %nexttile
    f = figure('Name','Costs, sz = '+string(idx_sz),'Position',params_plot.cost.pos);
    % Extract data
    d_sz = data.iter_conv(data.max_sz_conv==idx_sz);
    d_cost = data.cost_conv(data.max_sz_conv==idx_sz);
    d_n_part = data.n_part_conv(data.max_sz_conv==idx_sz);
    hold on
    % Plot by number of partitions
    for idx_part = 2:max(data.n_part_conv)
        s = scatter(d_sz(d_n_part==idx_part),d_cost(d_n_part==idx_part),'filled',params_plot.mrkr(idx_part-1));
        s.SizeData = params_plot.cost.mrkr_sz;
        s.MarkerFaceColor = params_plot.clr(idx_part-1,:);
        if s.Marker=="square"
            s.SizeData = params_plot.cost.mrkr_sz+2;
        end
    end
    % Add point for olm-minimizing
    if idx_sz == sz_best
        s = scatter(iter_best,c_best,'filled',"pentagram");
        s.MarkerFaceColor = "k";
        s.SizeData = params_plot.cost.star_sz+10;
        L = legend(s,'OLM-Minimizing');
        L.FontSize = params_plot.ft_accent;
        rectangle(gca,'Position', [1.6, .995, .8, .02], 'EdgeColor', 'k', 'LineWidth', .5);
    end
    % Add point for Baseline
    if idx_sz == rslt_b.max_sz
        s = scatter(rslt_b.iter,rslt_b.cost,'filled',"x");
        s.MarkerEdgeColor = "k";
        s.LineWidth = 1.5;
        L = legend(s,'Baseline');
        L.FontSize = params_plot.ft_accent;
    end

    ax = gca;
    ax.Position = params_plot.cost.pos_ax;
    ax.FontSize = params_plot.ft_accent;
    ax.YLim = [.99 1.3];
    ax.XLim = [1.5 20.5];

    ax.XLabel.String = "$c_{iter}$";
    ax.XLabel.FontSize = params_plot.ft;

    ax.YLabel.String = "$c_{mPoA}$";
    ax.YLabel.FontSize = params_plot.ft;

    % title("$c_{sz}$ = "+string(idx_sz))
    box on; grid on; hold off

    if idx_sz == max(data.max_sz_conv)
        % Create Legend
        L = legend(ax,string(2:max(data.n_part_conv)));
        L.NumColumns = 2;
        L.FontSize = params_plot.ft_accent;
        L.Title.String = "\# of Partitons";
        L.Title.FontSize = params_plot.ft;
        L.Location = 'NorthEast';
    end
    
    % Save
    if is_save
        fl = params_plot.cost.sv_loc+filesep+"cost_sz_"+string(idx_sz);
        saveas(f,fl,'epsc')
    end

end

%% Plot of only 2 iterations

figure('Name','Cost Zoomed','Position',params_plot.cost.pos_zoom)

% Extract data
idx_sim = data.iter_conv == iter_best & data.max_sz_conv == sz_best;
d_iter = data.iter_conv(idx_sim);
d_cost = data.cost_conv(idx_sim);
d_n_part = data.n_part_conv(idx_sim);
hold on
% Plot by number of partitions
for idx_part = 2:max(data.n_part_conv)
    s = scatter(d_iter(d_n_part==idx_part),d_cost(d_n_part==idx_part),'filled',params_plot.mrkr(idx_part-1));
    s.SizeData = params_plot.cost.mrkr_sz;
    s.MarkerFaceColor = params_plot.clr(idx_part-1,:);
    if s.Marker=="square"
        s.SizeData = params_plot.cost.mrkr_sz+2;
    end
end

% OLM Minimizing
s = scatter(iter_best,c_best,'filled',"pentagram");
s.MarkerFaceColor = "k";
s.SizeData = params_plot.cost.star_sz+10;

% Axis
ax1 = gca;
ax1.FontSize = params_plot.ft_accent;
ax1.YLim = [min(d_cost)-.0005 max(d_cost)+.0005];
ax1.XLim = [1.9 2.1];
ax1.XTick = 2;

ax1.XLabel.String = "$c_{iter}$";
ax1.XLabel.FontSize = params_plot.ft;

ax1.YLabel.String = "$c_{mPoA}$";
ax1.YLabel.FontSize = params_plot.ft;

box on; grid on; hold off

end
