function fig_SOE(elems,num,params_plot,v)
%FIG_SOE  Plots used state of energy by building.
%
%   FIG_SOE(elems,num,params_plot,v)
%
%   DESCRIPTION:
%   Plots used state of energy by building, demonstrating the difference
%   between the three simulation cases.
%
%   INPUTS:
%       elems   - Structure of categorized element.
%       num     - Structure of numeric problem specifications.
%       params_plot - Structure of plotting parameters
%       v       - Strucutre of combined results
%
%   SEE ALSO: fig_loss_T

%% Plotting
ttl = "e_"+string(elems.user);
for idx_u = 1:num.user
    figure(Name=ttl(idx_u)+" intQ",Position = params_plot.pos_half)
    hold on
    for idx_pbl = 1:params_plot.num_pbl
        p = plot(params_plot.tT, v{idx_pbl}.intQ(idx_u,:));
        p.LineWidth = params_plot.ln;
        p.Color = params_plot.clr(idx_pbl,:);
        p.Marker = params_plot.mrkr(idx_pbl);
        p.MarkerIndices = params_plot.idx_mrkr_T;
        p.MarkerSize = params_plot.mrkr_sz;
        p.MarkerFaceColor = p.Color;
        p.MarkerEdgeColor ='none';
    end

    % Legend
    if idx_u==1
        L = legend('Centralized','OLM','Baseline');
        L.Location = 'NorthWest';
        L.FontSize = params_plot.ft_accent;
    end

    % Axes
    ax = gca;
    ax.FontSize = params_plot.ft_accent;
    
    ax.XTick = params_plot.x.tick;
    ax.XAxis.Limits = params_plot.x.lim;
    %if idx_u > num.user/2
        ax.XAxis.Label.String = params_plot.x.label;
        ax.XAxis.Label.FontSize = params_plot.ft;
        ax.XAxis.TickLabelFormat = params_plot.x.format;
        ax.XAxis.SecondaryLabel.Visible='off';
    %else
    %    ax.XAxis.TickLabels={};
    %end
    
    %if mod(idx_u,2)== 1
        ax.YAxis.Label.String = "Used Flexibility [$kJ$]";
        ax.YAxis.Label.FontSize = params_plot.ft;
        %ax.YAxis.Limits = ;
    %end
    
    box on; grid on; hold off
end


end