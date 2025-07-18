function [pd,deltaPD] = fig_partialDependence(mdl,Gcomm)
%FIG_PARTIALDEPENDENCE  Plot graph of partial dependence values.
%
%   [pd,deltaPD] = FIG_PARTIALDEPENDENCE(mdl,Gcomm)
%
%   DESCRIPTION:
%   This function takes the binary classification model and gets the
%   partial dependence of the predictor score on each communication link
%   used in the model. It then plots a graph of the communicaiton link and
%   highlights the relative change in partial dependence caused by
%   introducing that communication link. 
%
%   INPUTS:
%       mdl     - Structure of model of classifier.
%       Gcomm   - Fully connected communication graph.
%
%   OUTPUTS:
%       pd      - Cell array of partial dependence values.
%       deltaPD - Change in predictor score for each model variable.

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