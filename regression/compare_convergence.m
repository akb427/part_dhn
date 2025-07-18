function compare_convergence(data1,data2,rslt1, rslt2, c_cen)
%COMPARE_CONVERGENCE  Compare convergence rates between 2 solution sets.
%
%   COMPARE_CONVERGENCE(data1,data2,rslt1, rslt2, c_cen)
%
%   DESCRIPTION:
%   Plot a bar graph showing the number of partitions explored by level of
%   partitioning and a stacked bar chart comparing the percentage converged
%   split by number of partitions for each of two cases.
%
%   INPUTS:
%       data1  - Stuture of statistics about first solution method.
%       data2  - Stuture of statistics about second solution method.
%       rslt1  - Structure of cand and costs for first solution method.
%       rslt2  - Structure of cand and costs for first solution method.
%       c_cen  - Centralized cost for normalization. 

%% Prepare Data
n_pbl = 2;
max_size = max([data1.n_part; data2.n_part]);

data_all = {data1,data2};
n_solved = cell(1,n_pbl);
n_solved_conv = cell(1,n_pbl);
conv_percnt = cell(1,n_pbl);

for idx_pbl = 1:n_pbl
    n_solved{idx_pbl} = accumarray(data_all{idx_pbl}.n_part(:)-1, 1, [max_size-1, 1]);
    n_solved_conv{idx_pbl} = accumarray(data_all{idx_pbl}.n_part(:)-1, data_all{idx_pbl}.conv(:), [max_size-1, 1]);
    conv_percnt{idx_pbl} = [100*n_solved_conv{idx_pbl}./n_solved{idx_pbl}, 100-100*n_solved_conv{idx_pbl}./n_solved{idx_pbl}];
end

%% Plot Searched Trials
ft = 14;

figure('Name','Trials','Position',[1125,1102,472,265]);
b = bar(2:max_size, cell2mat(n_solved), 'grouped', 'BarWidth', 1,'Interpreter','latex','GroupWidth',.9);
lgd = legend({'Original', 'Learning-Enhanced'}, 'Location', 'northeast');
lgd.FontSize = ft-2;
ylim([0 3*10^4])
xlim([1.5, max_size+0.5]);
ax = gca;
ax.FontSize = ft-2;
xlabel('\# of Partitions','FontSize',ft);
ylabel('\# of Trials','FontSize',ft);
box on; grid on;

% Add counts on top of bars
for idx_pbl = 1:n_pbl
    b(idx_pbl).Labels = n_solved{idx_pbl};
end

%% Plot Convergence rate - stacked bar
clr_green = [0.4667 0.6745 0.1882;...
0.5490 0.7882 0.2314;...
0.7294 0.8745 0.5373;...
0.3255 0.4706 0.1333;...
0.1961 0.2824 0.0784];

clr_red = [0.8510 0.3255 0.0980;...
0.9294 0.5608 0.3961;...
0.9529 0.7020 0.5922;...
0.6196 0.2392 0.0706;...
0.4157 0.1608 0.0471];

clr = [clr_red(1:max_size-1,:); clr_green(1:max_size-1,:)];
ttl_list = {'Original','\begin{tabular}{l}Learning-\\Enhanced\end{tabular}'};

% Prepare Data
data = zeros(2,2*(max_size-1));
labels = repmat(string(2:max_size)+"-Cut",2,2);
for idx_pbl = 1:n_pbl
    n_conv = n_solved_conv{idx_pbl};
    n_nconv = n_solved{idx_pbl}-n_solved_conv{idx_pbl};
    
    % Combine small categories
    if idx_pbl == 1
        % Combine final 3 bins
        n_conv(end-2) = n_conv(end-2)+n_conv(end-1)+n_conv(end);
        n_conv(end-1) = 0;
        n_conv(end) = 0;

        labels(idx_pbl,end-2) = string(max_size-2)+","+string(max_size-1)+","+string(max_size)+"-Cut";
        labels(idx_pbl,end-1) = "";
        labels(idx_pbl,end) = "";
    else
        % Combine final 2 bins
        n_conv(end-1) = n_conv(end-1)+n_conv(end);
        n_conv(end) = 0;

        labels(idx_pbl,end-1) = string(max_size-1)+","+string(max_size)+"-Cut";
        labels(idx_pbl,end) = "";
    end

    % Combine converged + unconverged into one vector
    data(idx_pbl,:) = [n_nconv; n_conv];
end

% Normalize Data
data = data./sum(data, 2);  % Each row sums to 1

figure('Name','Convergence','Position',[240,1283,800,292]);
hold on
b = barh(data,'stacked','FaceColor','flat');
for i = 1:8
    b(i).CData = clr(i,:);
end
yticks(1:2);
yticklabels(ttl_list);
ylim([0.5,2.5])
set(gca, 'YTickLabel', ttl_list, 'FontSize', ft-2, 'FontName', 'Times');
set(gca, 'YTickLabelRotation', 90);
xlabel('\% of Problems','FontSize', ft);
xlim([0 1])
xticks(0:.25:1);
xticklabels(string(0:25:100)+"\%")

for row = 1:size(data,1)
    x_offset = 0;  % Start from the beginning of the bar
    for col = 1:size(data,2)
        if data(row, col) > 0.05  % Skip small segments to avoid clutter
            % Get center position of the current bar segment
            x_center = x_offset + data(row, col) / 2;
            text(x_center, row, labels(row, col), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', ft-2, ...
                'FontName', 'Times');
        elseif data(row,col)>.01
             % Get center position of the current bar segment
            x_center = x_offset + data(row, col) / 2;
            text(x_center, row, labels(row, col), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', ft-4, ...
                'FontName', 'Times','Rotation',-45);
        end
        x_offset = x_offset + data(row, col);
    end
end

% Patches for red and green
h_red = patch(NaN, NaN, [0.8 0.2 0.2], 'DisplayName', 'Unconverged');
h_green = patch(NaN, NaN, [0.2 0.6 0.2], 'DisplayName', 'Converged');

% Create the legend and attach it to the tiledlayout
lgd = legend([h_red, h_green],'Interpreter', 'latex','Location','NorthWest','Orientation','Horizontal');
lgd.FontSize = ft-2;

box on; grid on; hold off

%% Plot Iterations

figure('Name','Conv Cost','Position',[630,1005,560,310])
hold on
clr = lines(max_size-1);

for idx_part = 1:max_size-1
    scatter(NaN,NaN, 'filled','MarkerFaceColor',clr(idx_part,:));
end
scatter(NaN,NaN,'filled','k');
scatter(NaN,NaN,'x','k','LineWidth',0.8);
lgd = legend([string(2:max_size) "found", "not found"],'AutoUpdate','off');
lgd.FontSize = ft-2;
title(lgd,'\# of Partitions')

for idx_part = 1:max_size-1
    idx_conv = find(~rslt1.cost{idx_part}(:,4));
    if idx_part<=numel(rslt2.idx_old)
        idx_inML = intersect(rslt2.idx_old{idx_part},idx_conv);
    else
        idx_inML = [];
    end
    idx_n_inML = setdiff(idx_conv,idx_inML);
    scatter(rslt1.cost{idx_part}(idx_inML,5),rslt1.cost{idx_part}(idx_inML,3)/c_cen,'filled','MarkerFaceColor',clr(idx_part,:))
    scatter(rslt1.cost{idx_part}(idx_n_inML,5),rslt1.cost{idx_part}(idx_n_inML,3)/c_cen,'x','MarkerEdgeColor',clr(idx_part,:),'LineWidth',1)
end


ylim([.99 1.3])
xlim([1.5 20.5])
ax = gca;
ax.FontSize = ft-2;
ylabel('$c_{mPoA}$','FontSize',ft)
xlabel('$c_{iter}$','FontSize',ft)
box on; grid on; hold off

end