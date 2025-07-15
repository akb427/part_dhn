%REGRESSION  Uses regression to predict convergence of solved bnb problem.
%
%   DESCRIPTION:
%   Uses regression to predict convergence of solved bnb problem. Performs
%   a sensititivy analysis of the regression tool and outputs the
%   statistics over all solved partitions. Uses the developed regression
%   tool to perform a reduced bnb search. Plots results for publication
%   using params_plot from process_results.
%
%   DEPENDENCIES: bnb_regression, compare_convergence, convergence_stats,
%   dec2part, fig_confusion, fig_partialDependence, fig_ROC, get_commlink.
%
%   SEE ALSO: generate_problem, partition_system, process results.

%% Setup
clc, clear, close all

pth = pwd;
addpath(fullfile(pth, 'bnb'));
addpath(fullfile(pth, 'regression'));

%% Load Data

pth = pwd;
load('sim_4user_params','num','w_olm')
load(pth+append(filesep,"rslts_curr.mat"),'rslt','idx_best')
% trim data
idx_slv = ~cellfun(@isempty,rslt.cost);
rslt.cost = rslt.cost(idx_slv);
rslt.cand = rslt.cand(idx_slv);

%% Prepare Data
n_part = size(rslt.cand,2);
[n_cand,~] = cellfun(@size, rslt.cand);

rslt.part = cell(1,n_part);
rslt.comm_link = cell(1,n_part);

num.v = num.edge+1;
Gcomm = graph(ones(num.v)-eye(num.v));
I = abs(full(incidence(Gcomm)));
n_comm = size(I,2);

for idx_split = 1:n_part
    rslt.part{idx_split} = zeros(n_cand(idx_split), w_olm.minDigits);
    rslt.comm_link{idx_split} = false(n_cand(idx_split), n_comm);
    for idx_cand = 1:n_cand(idx_split)
        % Partitions
        rslt.part{idx_split}(idx_cand,:) = dec2part(idx_cand,idx_split, rslt.cand(1:idx_split), w_olm.minDigits)+1;
        % Communication links
        rslt.comm_link{idx_split}(idx_cand,:) = get_commlink(rslt.part{idx_split}(idx_cand,:),logical(I));
    end
end

%% Train Classifier

% % Data Subset
% n_train = 1000;
% idx_train = randi([1 n_cand(1)],1,n_train);
% train = array2table(categorical(rslt.comm_link{1}(idx_train,:)), 'VariableNames', "Link_"+string(1:n_comm));
% train.IsConverge = (~rslt.cost{1}(idx_train,4));
% 
% % Train Model
% costMatrix = [0 1; 4 0];
% numLearner = 30;
% [mdl, ~] = trainClassifier(train,costMatrix,numLearner);
% [yfit_train,~] = mdl.predictFcn(train(:,1:end-1));

load('rslt_regression')
train = mdl.ClassificationEnsemble.X;
train.Isconverge = mdl.ClassificationEnsemble.Y;
[yfit_train,~] = mdl.predictFcn(train(:,1:end-1));

%% Check misclassifications

yfit = cell(1,n_part);
scores = cell(1,n_part);
val = cell(1,n_part);
mdl.precision = zeros(1,n_part);
mdl.recall = mdl.precision;
mdl.accuracy = mdl.precision;

for idx_split = 1:n_part
    % Data in Table
    % if idx_split == 1
    %     idx_val = setdiff(1:n_cand(idx_split),idx_train);
    %     val{idx_split} = array2table(categorical(rslt.comm_link{idx_split}(idx_val,:)), 'VariableNames', "Link_"+string(1:n_comm));
    %     val{idx_split}.IsConverge = (~rslt.cost{idx_split}(idx_val,4));
    % else
        val{idx_split} = array2table(categorical(rslt.comm_link{idx_split}), 'VariableNames', "Link_"+string(1:n_comm));
        val{idx_split}.IsConverge = (~rslt.cost{idx_split}(:,4));
    % end

    % Run Model
    [yfit{idx_split},scores{idx_split}] = mdl.predictFcn(val{idx_split}(:,1:end-1));
    wrong = val{idx_split}.IsConverge~=yfit{idx_split};
    wrong_shouldbeconverged = find(wrong&val{idx_split}.IsConverge); % worse
    wrong_shouldbefailed = find(wrong&~val{idx_split}.IsConverge);     %okay
    right_converged = find(~wrong&val{idx_split}.IsConverge);
    right_failed = find(~wrong&~val{idx_split}.IsConverge);

    % Metrics
    c = confusionmat(val{idx_split}.IsConverge,yfit{idx_split});
    mdl.precision(1,idx_split) = c(2,2)/(c(2,2)+c(1,2));
    mdl.recall(1,idx_split) = c(2,2)/(c(2,2)+c(2,1));
    mdl.accuracy(1,idx_split)  = (c(1,1)+c(2,2))/sum(c,'all');

    % Print Results
    fprintf('For the %d cut, the model was %.1f%% accurate with %.1f%% false negatives.\n', ...
        idx_split, 100*(1-sum(wrong)/numel(wrong)), 100*(numel(wrong_shouldbeconverged)/sum(wrong)));
end

c = confusionmat(vertcat(val{:}).IsConverge,vertcat(yfit{:}));
mdl.precision_all = c(2,2)/(c(2,2)+c(1,2));
mdl.recall_all = c(2,2)/(c(2,2)+c(2,1));
mdl.accuracy_all  = (c(1,1)+c(2,2))/sum(c,'all');


%% Regression BnB

[part_ml, rslt_ml, idx_best_ml] = bnb_regression(rslt,yfit,n_part,w_olm);

n_og = sum(cellfun(@numel,rslt.cand));
n_ml = sum(cellfun(@numel,rslt_ml.cand));
n_ml = n_ml+sum(~yfit_train);
fprintf('There was %.1f%% reduction in solutions searched.\n', (n_og-n_ml)/n_og*100);

n_iter_og = sum(cellfun(@(x) sum(x(:,5)),rslt.cost));
n_iter_ml = sum(cellfun(@(x) sum(x(:,5)),rslt_ml.cost));
n_iter_ml = n_iter_ml+20*sum(~yfit_train);
fprintf('There was an %.1f%% reduction in iterations.\n',(n_iter_og-n_iter_ml)/n_iter_og*100);

%% Plot Results

[pd,deltaPD] = fig_partialDependence(mdl,Gcomm);
fig_confusion(val,yfit)
fig_ROC(vertcat(val{:}),vertcat(yfit{:}), vertcat(scores{:}))
%span_classifier(rslt,n_cand,n_comm);

load("cen_sim2");

[~, data_og] = convergence_stats(rslt,idx_best,cen_sim(1).cost,params_plot);
[~, data_ml] = convergence_stats(rslt_ml,idx_best_ml,cen_sim(1).cost,params_plot);

compare_convergence(data_og,data_ml, rslt, rslt_ml,cen_sim(1).cost)

%save('rslt_regression','mdl')