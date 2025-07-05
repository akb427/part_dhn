function v = fig_loss_T(G, params, elems, params_plot, v_sim_cen, v_sim_olm, v_sim_b)
%FIG_LOSS_T  Combines problem results and plots temperatures and losses.
%
%   v = FIG_LOSS_T(G, params, elems, params_plot, v_sim_cen, v_sim_olm, v_sim_b)
%
%   DESCRIPTION:
%   Combines the 3 simulation results into one cell array to be used in
%   further plotting. Calcualtes the total unweighted losses for each case,
%   along with the return temperature. Plots time varying losses, the
%   integral of losses, and the return temperatures.
%
%   INPUTS:
%       G       - Digraph of the network structure.
%       params  - Structure of problem parameters.
%       elems   - Structure of categorized element.
%       params_plot - Structure of plotting parameters.
%       v_sim_cen   - Structure of results from centralized case.
%       v_sim_olm   - Structure of results from olm case.
%       v_sim_b     - Structure of results from baseline case.
%
%   OUTPUTS:
%       v - Strucutre of combined results from different simulations

%% Combine Data
v = cell(1,params_plot.num_pbl);

var = {v_sim_cen v_sim_olm v_sim_b};
for idx_pbl = 1:params_plot.num_pbl
    v{idx_pbl}.loss = [var{idx_pbl}.cost_Q]/params.w_Q/10^6; % remove coefficient & scale to MJ
    v{idx_pbl}.loss = [v{idx_pbl}.loss v{idx_pbl}.loss(:,end)];

    v{idx_pbl}.T = cell2mat(arrayfun(@(x) x.T(:,1:end-1),var{idx_pbl},'UniformOutput',false));
    v{idx_pbl}.T = [v{idx_pbl}.T var{idx_pbl}(end).T(:,end)];

    v{idx_pbl}.intQ = cell2mat(arrayfun(@(x) x.intQ(:,1:end-1),var{idx_pbl},'UniformOutput',false));
    v{idx_pbl}.intQ = [v{idx_pbl}.intQ var{idx_pbl}(end).intQ(:,end)];

    v{idx_pbl}.mdot_e = [var{idx_pbl}.mdot_e];
    v{idx_pbl}.mdot_e = [v{idx_pbl}.mdot_e v{idx_pbl}.mdot_e(:,end)];
end

% Calculate Return Temperature
e_fin = inedges(G,elems.term);
e_fin_nu = find(any(elems.nonuser==e_fin));

idx_m = 0;
for idx_T = 1:params.tf/params.dt_T+1
    if mod((idx_T-1)*params.dt_T,params.dt)==0      % when mdot can change
        idx_m = idx_m+1;
    end
    for idx_pbl = 1:params_plot.num_pbl
        v{idx_pbl}.Treturn(1,idx_T) = sum(v{idx_pbl}.mdot_e(e_fin,idx_m).*v{idx_pbl}.T(e_fin_nu,idx_T))/(sum(v{idx_pbl}.mdot_e(e_fin,idx_m)));
    end
end


%% Plotting - Losses

figure('Name','Losses','Position', params_plot.pos_half)

hold on
% Plant flow
for idx_pbl = 1:params_plot.num_pbl
    p = plot(params_plot.tm, v{idx_pbl}.loss,'Linewidth',params_plot.ln,'Color',params_plot.clr(idx_pbl,:));
    p.Marker = params_plot.mrkr(idx_pbl);
    p.MarkerIndices = params_plot.idx_mrkr_m; 
    p.MarkerSize = params_plot.mrkr_sz;
    p.MarkerFaceColor = p.Color;
    p.MarkerEdgeColor ='none';
end

% Legend
L = legend('Central','OLM','Baseline');
L.Location = 'NorthWest';
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

ax.YAxis.Label.String = "Losses [$MJ$]";
ax.YAxis.Label.FontSize = params_plot.ft;
%ax.YAxis.Limits = ;

box on; grid on; hold off

%% Plotting - Losses Integral

figure('Name','Losses Total','Position', params_plot.pos_half)

hold on
% Plant flow
for idx_pbl = 1:params_plot.num_pbl
    p = plot(params_plot.tm, cumsum(v{idx_pbl}.loss),'Linewidth',params_plot.ln,'Color',params_plot.clr(idx_pbl,:));
    p.Marker = params_plot.mrkr(idx_pbl);
    p.MarkerIndices = params_plot.idx_mrkr_m; 
    p.MarkerSize = params_plot.mrkr_sz;
    p.MarkerFaceColor = p.Color;
    p.MarkerEdgeColor ='none';
end

% Legend
L = legend('Central','OLM','Baseline');
L.Location = 'NorthWest';
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

ax.YAxis.Label.String = "Losses [$MJ$]";
ax.YAxis.Label.FontSize = params_plot.ft;
%ax.YAxis.Limits = ;

box on; grid on; hold off

%% Return Temperature Figure

figure('Name','Temp','Position', params_plot.pos_half)

hold on
for idx_pbl = 1:params_plot.num_pbl
    p = plot(params_plot.tT , v{idx_pbl}.Treturn,'Linewidth',params_plot.ln,'Color',params_plot.clr(idx_pbl,:));
    p.Marker = params_plot.mrkr(idx_pbl);
    p.MarkerIndices = params_plot.idx_mrkr_T;
    p.MarkerSize = params_plot.mrkr_sz;
    p.MarkerFaceColor = p.Color;
    p.MarkerEdgeColor ='none';
end

% Legend
L = legend('Central','OLM','Baseline');
L.Location = 'NorthWest';
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

ax.YAxis.Label.String = "Temperature [$C$]";
ax.YAxis.Label.FontSize = params_plot.ft;
%ax.YAxis.Limits = ;

box on; grid on; hold off

end