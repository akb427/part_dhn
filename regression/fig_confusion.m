function fig_confusion(val,yfit)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

%%
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