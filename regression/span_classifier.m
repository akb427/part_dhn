function [precision,recall] = span_classifier(rslt,n_cand,n_comm)
%SPAN_CLASSIFIER  Function to test the sensitivity of the classifier.
%
%   [precision,recall] = SPAN_CLASSIFIER(rslt,n_cand,n_comm)
%
%   DESCRIPTION:
%   Function to test the sensitivity of the classifier to number of
%   training points and number of learners via precision, recall and
%   accuracy. Plots the results.
%
%   INPUTS:
%       rslt    - Stucture of cand and cost for total bnb search.
%       n_cand  - Vector of number of partitions in each cut set.
%       n_comm  - Number of communication links in the problem.
%
%   OUTPUTS:
%       precision   - Vector of TP/(TP+FP) for each parameter set.
%       recall      - Vector of TP/(TP+FN) for each parameter set.
%
%   DEPENDENCIES: trainClassifier

%% Problem Setup
q_train = [100 500 1000 2000 5000];
n_q_train = numel(q_train);

q_learner = [5 30 100];
n_q_learner = numel(q_learner);

costMatrix = [0 1; 4 0];
n_rpt = 10;

mdl = {cell(n_q_train,n_q_learner,n_rpt)};
precision = zeros(n_q_train,n_q_learner,n_rpt);
recall = precision;
accuracy = precision;
time_train = precision;

%% Try different parameters
idx_split = 1;

for idx_rpt = 1:n_rpt
    for idx_qt = 1:n_q_train
        % Data Subset
        idx_train = randi([1 n_cand(1)],1,q_train(idx_qt));
        train = array2table(categorical(rslt.comm_link{1}(idx_train,:)), 'VariableNames', "Link_"+string(1:n_comm));
        train.IsConverge = (~rslt.cost{1}(idx_train,4));
    
        idx_val = setdiff(1:n_cand(idx_split),idx_train);
        val = array2table(categorical(rslt.comm_link{idx_split}(idx_val,:)), 'VariableNames', "Link_"+string(1:n_comm));
        val.IsConverge = (~rslt.cost{idx_split}(idx_val,4));
    
        for idx_ql = 1:n_q_learner
            % Train Model
            tic
            [mdl{idx_qt,idx_ql,idx_rpt}, ~] = trainClassifier(train,costMatrix,q_learner(idx_ql));
            time_train(idx_qt,idx_ql,idx_rpt) = toc;
            % Get Results
            [yfit, ~] = mdl{idx_qt,idx_ql,idx_rpt}.predictFcn(val(:,1:end-1));
            c = confusionmat(val.IsConverge,yfit);
            precision(idx_qt,idx_ql,idx_rpt) = c(2,2)/(c(2,2)+c(1,2));
            recall(idx_qt,idx_ql,idx_rpt) = c(2,2)/(c(2,2)+c(2,1));
            accuracy(idx_qt,idx_ql,idx_rpt)  = (c(1,1)+c(2,2))/sum(c,'all');
        end
    end
end

%% Average

precision_mean = mean(precision, 3);
precision_std  = std(precision, 0, 3);

accuracy_mean = mean(accuracy, 3);
accuracy_std  = std(accuracy, 0, 3);

recall_mean = mean(recall, 3);
recall_std  = std(recall, 0, 3);

time_mean = mean(time_train, 3);
time_std  = std(time_train, 0, 3);

%% Plot Results

figure('Name', 'Hyperparameter')
tiledlayout(4,1,"TileSpacing","tight")
clr = lines(n_q_learner);
ft = 12;
ln = 1;
mk = 3;

nexttile; hold on
for idx_ql = 1:n_q_learner
    errorbar(q_train, accuracy_mean(:, idx_ql), accuracy_std(:, idx_ql), 'o-', ...
        'Color', clr(idx_ql,:), 'MarkerFaceColor', clr(idx_ql,:),'LineWidth',ln,'MarkerSize',mk);
end
ylabel('Accuracy','FontSize',ft);
lgd = legend(string(q_learner),'Location', 'southeast','FontSize',ft-2,'Autoupdate','off');
lgd.Title.String = '\# of Learners';
xticks(q_train);
ax = gca;
ax.FontSize = ft-2;
ax.XLim = [0 max(q_train)];
ax.YLim = [.8 .95];
set(ax, 'XTickLabel', []);
box on; grid on; hold off;

nexttile; hold on
for idx_ql = 1:n_q_learner
    errorbar(q_train, precision_mean(:, idx_ql), precision_std(:,idx_ql), 'o-', ...
        'Color', clr(idx_ql,:), 'MarkerFaceColor', clr(idx_ql,:),'LineWidth',ln,'MarkerSize',mk);
end
ylabel('Precision','FontSize',ft);
xticks(q_train);
ax = gca;
ax.FontSize = ft-2;
ax.XLim = [0 max(q_train)];
ax.YLim = [.2 .8];
set(gca, 'XTickLabel', []); 
box on; grid on; hold off;

nexttile; hold on;
for idx_ql = 1:n_q_learner
    errorbar(q_train, recall_mean(:, idx_ql), recall_std(:,idx_ql), 'o-', ...
            'Color',clr(idx_ql,:), 'MarkerFaceColor', clr(idx_ql,:),'LineWidth',ln,'MarkerSize',mk);
end
ylabel('Recall','FontSize',ft);
xticks(q_train);
ax = gca;
ax.FontSize = ft-2;
ax.XLim = [0 max(q_train)];
ax.YLim = [0 .9];
set(gca, 'XTickLabel', []); 
box on; grid on; hold off;

nexttile; hold on;
for idx_ql = 1:n_q_learner
    errorbar(q_train, time_mean(:, idx_ql), time_std(:,idx_ql), 'o-', ...
            'Color',clr(idx_ql,:), 'MarkerFaceColor', clr(idx_ql,:),'LineWidth',ln,'MarkerSize',mk);
end
ylabel('Time [s]','FontSize',ft);
xticks(q_train);
ax = gca;
ax.FontSize = ft-2;
ax.XLim = [0 max(q_train)];
ax.YLim = [0 45];
box on; grid on; hold off;

xlabel('Number of Training Points','FontSize',ft);


end 