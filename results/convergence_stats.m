function [rslt,data] = convergence_stats(rslt,idx_best,c_cen,params_plot)
%CONVERGENCE_STATS  statistics about BnB results.
%
%   [rslt,data] = CONVERGENCE_STATS(rslt,idx_best,c_cen,params_plot)
%
%   DESCRIPTION:
%   Takes results of bnb partitioning algorithm, finds statistics and plots
%   bar graph showing number of solutions explored and percent converged
%   for this solution set.
%
%   INPUTS:
%       rslt        - Strucutre of cand and costs for bnb algorithm.
%       idx_best    - Numeric index of best partition in rslt.
%       c_cen       - Numeric cost of centralized solution.
%       params_plot - Structure of parameters for creating plots.
%
%   OUTPUTS:
%       rslt - rslt trimmed to only include solved cut level.
%       data - Structure of statistics about solution method.

%% Remove empty cells

idx_slv = ~cellfun(@isempty,rslt.cost);
rslt.cost = rslt.cost(idx_slv);
rslt.cand = rslt.cand(idx_slv);

%% Extract data

data.conv = ~cell2mat(cellfun(@(x) x(:,4),rslt.cost,'UniformOutput',false)');
data.iter = cell2mat(cellfun(@(x) x(:,5),rslt.cost,'UniformOutput',false)');
data.cost = cell2mat(cellfun(@(x) x(:,3),rslt.cost,'UniformOutput',false)')/c_cen;
data.max_sz = cell2mat(cellfun(@(x) x(:,6),rslt.cost,'UniformOutput',false)');
data.n_part = repelem(2:sum(idx_slv)+1,cellfun(@(x)size(x,1),rslt.cost))';

data.iter_conv = data.iter(data.conv);
data.cost_conv = data.cost(data.conv);
data.max_sz_conv = data.max_sz(data.conv);
data.n_part_conv = data.n_part(data.conv);

%% Convert idx_best
max_part = max(data.n_part);
[data.n_solved,~] = cellfun(@size,rslt.cost);
data.n_solved_conv = cellfun(@(x) sum(~x(:,4)),rslt.cost);
conv_percnt = [100*data.n_solved_conv./data.n_solved; 100-100*data.n_solved_conv./data.n_solved];

data.idx_best_all = sum(data.n_solved(1:(idx_best(1)-1)))+idx_best(2);
data.idx_best_conv = sum(data.conv(1:data.idx_best_all));

%% Plot partitioned explored by cut
figure('Name','Solv Num','Position',params_plot.pos_half);

b1 = bar(2:max_part, data.n_solved, 'FaceColor', params_plot.clr(1,:), 'BarWidth', 0.8);
xlim([1.5, max_part+0.5]);
ylim([0 2.75*10^4])
set(gca,'FontSize',params_plot.ft_accent);
xlabel('\# of Partitions','FontSize',params_plot.ft);
ylabel('\# of Solutions','FontSize',params_plot.ft);

box on; grid on

b1.Labels =compose("%d", data.n_solved);
b1.Interpreter = 'latex';
b1.LabelLocation = 'end-outside';
b1.LabelColor = 'k';
b1.FontSize = params_plot.ft_accent;

%% Plot the percentage stacked bar chart
figure('Name','Conv Percent','Position',params_plot.pos_half);

b2 = bar(2:max_part, conv_percnt, 'stacked', 'BarWidth', 0.8);
xlim([1.5, max_part+0.5]);
set(gca,'FontSize',params_plot.ft_accent);
xlabel('\# of Partitions','FontSize',params_plot.ft);
ylabel('\% of Solutions','FontSize',params_plot.ft);
legend({'Converged', 'Not Converged'}, 'Location', 'northwest',FontSize = params_plot.ft_accent);
colororder([params_plot.clr(5,:); params_plot.clr(2,:)]);
ylim([0 100])
box on; grid on;

% Add labels to converged bars
b2(1).Labels =compose("%.1f\\%%", conv_percnt(1, :));
b2(1).Interpreter = 'latex';
b2(1).LabelLocation = 'end-outside';
b2(1).LabelColor = 'w';
b2(1).FontSize = params_plot.ft_accent;

% Add labels to unconverged bar
for idx_part = 1:size(conv_percnt, 1)
    text(idx_part+1, conv_percnt(1,idx_part)+conv_percnt(2,idx_part)/2, sprintf('%.1f', conv_percnt(2,idx_part))+"\%", ...
        'HorizontalAlignment', 'center', 'Color', 'white','FontSize',params_plot.ft_accent);
end

end