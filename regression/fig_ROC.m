function fig_ROC(val,yfit,scores)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

%% Get Values

[fpRate, tpRate, ~, AUC, ~] = perfcurve(val.IsConverge, scores(:,2), 1);
operatingIdx = find(yfit == 1);  % predicted positives
tp = sum(val.IsConverge(operatingIdx) == 1) / sum(val.IsConverge == 1);
fp = sum(val.IsConverge(operatingIdx) == 0) / sum(val.IsConverge == 0);


%% Plot Results
clr = lines(1);
ft = 14;
figure('Name','ROC');
hold on
plot(fpRate, tpRate, 'LineWidth', 2,'Color', clr);
plot(fp, tp, 'o','Color',clr,'MarkerFaceColor', clr, 'MarkerSize', 8);
lgd = legend(sprintf('ROC Curve (AUC = %.3f)', AUC), 'Operating Point', ...
             'Location', 'southeast','Autoupdate','off');
plot([0 1], [0 1], 'k--');

xlabel('False Positive Rate','FontSize',ft);
ylabel('True Positive Rate','FontSize',ft);
lgd.FontSize = ft-2;
ax = gca;
ax.FontSize = ft-2;
box on; grid on; hold off;
ylim([-.1 1.1])
xlim([-.1 1.1])

end