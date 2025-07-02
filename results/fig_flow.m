function fig_flow(num,elems,params_plot,v)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here


%% Combine Mass Flow Rates
for idx_pbl = 1:params_plot.num_pbl
    v{idx_pbl}.mdot_0 = sum(v{idx_pbl}.mdot_e(elems.edge_plant,:),1);
    v{idx_pbl}.mdot_by = sum(v{idx_pbl}.mdot_e(elems.bypass,:),1);
    v{idx_pbl}.mdot_u = v{idx_pbl}.mdot_e(elems.user,:);
end

%% Plotting - Plant & Bypass

figure('Name','mdot 0',Position = params_plot.pos)

hold on
% Plant flow
for idx_pbl = 1:params_plot.num_pbl
    p = plot(params_plot.tm, v{idx_pbl}.mdot_0,'Linewidth',params_plot.ln,'Color',params_plot.clr(idx_pbl,:));
    p.Marker = params_plot.mrkr(idx_pbl);
    p.MarkerIndices = params_plot.idx_mrkr_m;
    p.MarkerSize = params_plot.mrkr_sz;
    p.MarkerFaceColor = p.Color;
    p.MarkerEdgeColor ='none';
end

% Plot for legend only
plot(nan,nan,'k','Linewidth',params_plot.ln)
%plot(nan,nan,':k','Linewidth',params_plot.ln)

L = legend('Centralized','OLM','Baseline');%,'Plant','Bypass','Autoupdate','off');
L.Location = 'NorthWest';
L.FontSize = params_plot.ft_accent;

% Bypass flow
% for idx_pbl = 1:params_plot.num_pbl
%     p = plot(params_plot.tm, v{idx_pbl}.mdot_by,':','Linewidth',params_plot.ln,'Color',params_plot.clr(idx_pbl,:));
%     p.Marker = params_plot.mrkr(idx_pbl);
%     p.MarkerIndices = params_plot.idx_mrkr_m;
%     p.MarkerSize = params_plot.mrkr_sz;
%     p.MarkerFaceColor = p.Color;
%     p.MarkerEdgeColor ='none';
% end

box on; grid on; hold off

% Axes
ax = gca;
ax.FontSize = params_plot.ft_accent;

ax.XTick = params_plot.x.tick;

ax.XAxis.Label.String = params_plot.x.label;
ax.XAxis.Label.FontSize = params_plot.ft;
ax.XAxis.TickLabelFormat = params_plot.x.format;
ax.XAxis.Limits = params_plot.x.lim;
ax.XAxis.SecondaryLabel.Visible='off';

ax.YAxis.Label.String = "Mass Flow Rate [$kg/s$]";
ax.YAxis.Label.FontSize = params_plot.ft;
%ax.YAxis.Limits = ;

box on; grid on; hold off

%% Plotting - User By Solution
ttl = {'Centralized', 'OLM','Baseline'};

for idx_pbl = 1:params_plot.num_pbl
    figure('Name',ttl{idx_pbl}+" mdot user",Position=params_plot.pos2)
    hold on
    for idx_u = 1:num.user
        p = plot(params_plot.tm, v{idx_pbl}.mdot_u(idx_u,:),'Linewidth',params_plot.ln,'Color',params_plot.clr_u(idx_u,:));
        p.Marker = params_plot.mrkr(idx_u);
        p.MarkerIndices = params_plot.idx_mrkr_m;
        p.MarkerSize = params_plot.mrkr_sz;
        p.MarkerFaceColor = p.Color;
        p.MarkerEdgeColor ='none';
    end

    % Legend
    if idx_pbl == 1
        L = legend("$e_{"+string(elems.user)+"}$",'Orientation','horizontal');
        L.Location = 'NorthWest';
        L.FontSize = params_plot.ft_accent;
    end
    
    % Axes
    ax = gca;
    ax.FontSize = params_plot.ft_accent;
    
    ax.XTick = params_plot.x.tick;
    ax.XAxis.Limits = params_plot.x.lim;
    % if idx_pbl == params_plot.num_pbl
        ax.XAxis.Label.String = params_plot.x.label;
        ax.XAxis.Label.FontSize = params_plot.ft;
        ax.XAxis.TickLabelFormat = params_plot.x.format;
        ax.XAxis.SecondaryLabel.Visible='off';
    % else
    %     ax.XAxis.TickLabels={};
    % end

    ax.YAxis.Label.String = "Mass Flow Rate [$kg/s$]";
    ax.YAxis.Label.FontSize = params_plot.ft;
    ax.YAxis.Limits = [0 0.6];
    
    box on; grid on; hold off

end
end