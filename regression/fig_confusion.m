function fig_confusion(val,yfit)
%FIG_CONFUSION  Plot confusion matrices for each level of paritioning.
%
%   FIG_ROC(val,yfit,scores)
%
%   DESCRIPTION:
%   Plot confusion matrices for each level of paritioning.
%
%   INPUTS:
%       val     - Cell of validation data tables
%       yfit    - Cell of predicted convergence values

%% Calculate and plot confusion matrices
n_part = size(val,2);

figure('Name','Confusion')
cols = ceil(sqrt(n_part));
rows = ceil(n_part/cols);
tiledlayout(rows, cols);

for idx_cut = 1:n_part
    nexttile
    cm = confusionchart(val{idx_cut}.IsConverge,yfit{idx_cut});
    cm.FontName = 'Times';
    cm.FontSize = 14;
    title(string(idx_cut+1)+" Partitions")
end


end