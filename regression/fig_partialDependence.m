function [pd,deltaPD] = fig_partialDependence(mdl,Gcomm)
%FIG_PARTIALDEPENDENCE  Plot graph of partial dependence values.
%
%   [pd,deltaPD] = FIG_PARTIALDEPENDENCE(mdl,Gcomm)
%
%   DESCRIPTION:
%   Briefly explain the purpose of the function, what it computes, or how it
%   fits into the overall workflow. Mention any important assumptions or side
%   effects (e.g., plotting, modifying global variables, saving files).
%
%   INPUTS:
%       mdl     - Structure of model of classifier
%       Gcomm   - Fully connected communication graph
%
%   OUTPUTS:
%       pd      - Description of output 1 (what it represents)
%       deltaPD - Description of output 2

%% Get Partial Dependence Values

pd = cellfun(@(x) partialDependence(mdl.ClassificationEnsemble, x, {'true'}), mdl.RequiredVariables, 'UniformOutput',false);
deltaPD = cellfun(@(x) x(2)-x(1),pd);

node_label = {'$F_2$', '$F_1$', '$F_3$', '$U_2$', '$F_4$', '$U_3$','$U_4$', '$By_2$', '$R_4$', '$R_3$', '$R_2$','$U_1$', '$By_1$' '$R_1$', '$v_{0^-}$'};

%% Plot Results

cmap = sky;
importanceNorm = (deltaPD - min(deltaPD)) / (max(deltaPD) - min(deltaPD) + eps);
edge_color = interp1(linspace(0,1,256), cmap, importanceNorm);

figure;
h = plot(Gcomm, 'Layout', 'force');
h.EdgeColor = edge_color;
h.NodeLabel = node_label;
h.Interpreter = 'latex';
h.NodeFontSize = 16;
h.EdgeFontSize = 14;
h.LineWidth = 1.5;
h.MarkerSize = 4;
h.EdgeAlpha = 1;

% Add colorbar
colormap(cmap);
colorbar;
clim([min(deltaPD), max(deltaPD)]);

end