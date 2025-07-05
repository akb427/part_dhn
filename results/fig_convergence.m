function fig_convergence(rslts,cntr,num,params,v_nom)
%FIG_CONVERGENCE  Plots convergence steps for troubleshooting.
%
%   FIG_CONVERGENCE(rslts,cntr,num,params,v_nom)
%
%   DESCRIPTION:
%   Shows subsystem behavior as the system iterates to nash equilibrium.
%   Shows mass flow rate, friction coefficients, valve positions, costs,
%   solver status, and pressures.
%
%   INPUTS:
%       rslts   - Structure of problem results
%       cntr    - Number of iterations completed
%       num     - Structure of numeric problem specifications.
%       params  - Structure of problem parameters.
%       v_nom   - Vector of nominal results (optional)
%
%   SEE ALSO: solve_comm

%% Zeta U
figure('Name','zeta_u')
tiledlayout(2,ceil(num.sg/2));
isvalve = find(cellfun(@(x)isfield(x,'valve'),rslts(1,:)));
for idx_sg = isvalve
    nexttile
    hold on
    for idx_ts = 1:num.seg
        vec = cell2mat(cellfun(@(x)x.zeta_u(:,idx_ts)', rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
        plot(vec)
    end
    title("G_"+num2str(idx_sg))
    box on; grid on; hold off
    ylabel('Friction Coefficient')
    xlabel('Iteration')
end


%% Valve
if isfield(rslts{1,idx_sg},'valve')
    figure('Name','valve')
    tiledlayout(2,ceil(num.sg/2));
    for idx_sg = isvalve
        nexttile
        hold on
        for idx_ts = 1:num.seg
            vec = cell2mat(cellfun(@(x)x.valve(:,idx_ts)', rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
            plot(vec)
        end
        title("G_"+num2str(idx_sg))
        box on; grid on; hold off
        ylabel('Friction Coefficient')
        xlabel('Iteration')
    end
end
%% Plant Mass Flow
figure('Name','m_0')
tiledlayout(2,ceil(num.sg/2));

for idx_sg = 1:num.sg
    nexttile
    hold on
    for idx_ts = 1:num.seg
        if isfield(rslts{1,idx_sg},'mdot_0')
            vec = cell2mat(cellfun(@(x)x.mdot_0(:,idx_ts)', rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
            plot(vec)
        end
        if isfield(rslts{1,idx_sg},'mdot_in_free')
            vec = cell2mat(cellfun(@(x)x.mdot_in_free(:,idx_ts)', rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
            plot(vec)
        end
    end
    title("G_"+num2str(idx_sg))
    box on; grid on; hold off
    ylabel('Mass Flow Rate [kg/s]')
    xlabel('Iteration')
end

%% Total plant mass flow
figure('Name','m_0_total')
tiledlayout(2,ceil(num.sg/2));
for idx_sg = 1:num.sg
    nexttile
    hold on
    if isfield(rslts{1,idx_sg},'mdot_0')
        vec = cell2mat(cellfun(@(x)sum(x.mdot_0)', rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
        plot(vec)
    end
    if isfield(rslts{1,idx_sg},'mdot_free')
        vec = cell2mat(cellfun(@(x)sum(x.mdot_free,2)', rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
        plot(vec)
    end
    title("G_"+num2str(idx_sg))
    box on; grid on; hold off
    ylabel('Mass Flow Rate [kg/s]')
    xlabel('Iteration')
end

%% Total Mass Flow
figure('Name','Total Flow')
hold on
idx_m0 = cellfun(@(x)isfield(x,'mdot_0'),rslts(1,:));
max_cnt = max(cntr);
vec = zeros(max_cnt,num.sg);
for idx_ts = 1:num.seg
    for idx_sg = find(idx_m0)
        vec(1:cntr(idx_sg),idx_sg) = cellfun(@(x)x.mdot_0(1,idx_ts)', rslts(1:cntr(idx_sg),idx_sg));
        if cntr(idx_sg)<max_cnt
            vec(cntr(idx_sg)+1:max_cnt,idx_sg) = vec(cntr(idx_sg),idx_sg);
        end
    end
    vec = sum(vec,2);
    plot(vec)
    vec = zeros(max_cnt,num.sg);
end

if nargin==5
    yline(v_nom.mI,'Linewidth',2)
    legend('Communication','Centralized')
end
box on; grid on; hold off
title('Plant Mass Flow')
ylabel('Mass Flow Rate [kg/s]')
xlabel('Iteration')


%% Cost

figure('Name','Costs')
tiledlayout(2,ceil(num.sg/2));
leg = {'Q','SOC','Tot'};
for idx_sg = 1:num.sg
    nexttile
    hold on
    flds = [isfield(rslts{1,idx_sg},'cost_Q') isfield(rslts{1,idx_sg},'cost_SOC') isfield(rslts{1,idx_sg},'cost')];
    if flds(1)
        vec = cell2mat(cellfun(@(x)x.cost_Q, rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
        plot(vec)
    end
    if flds(2)
        vec = cell2mat(cellfun(@(x)x.cost_SOC, rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
        plot(vec)
    end
    if flds(3)
        vec = cell2mat(cellfun(@(x)x.cost, rslts(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
        plot(vec)
    end
    title("G_"+num2str(idx_sg))
    legend(leg(flds));
    box on; grid on; hold off
    ylabel('Cost Losses')
    xlabel('Iteration')
end

%% Status
stat_opt = {'Solve_Succeeded', 'Infeasible_Problem_Detected', 'Error_In_Step_Computation', 'Restoration_Failed', 'Maximum_Iterations_Exceeded'};
stat_label = {'Solved Succeeded', 'Infeasible Problem Detected', 'Error In Step Computation', 'Restoration Failed', 'Maximum Iterations Exceeded'};
figure('Name','Status')
tiledlayout(2,ceil(num.sg/2));

for idx_sg = 1:num.sg
    nexttile;  % move to the next tile (subplot)
    
    % Extract the status from each cell in the current column.
    % This returns a cell array of characters.
    statuses = cellfun(@(s) s.status, rslts(1:cntr(idx_sg), idx_sg), 'UniformOutput', false);
    
    % Convert the cell array of statuses to a categorical array.
    % The order {'w','x','y','z'} is specified and the categorical
    % variable is set as ordinal.
    catStatuses = categorical(statuses, stat_opt, 'Ordinal', true);
    
    % For plotting, convert the categorical array to numeric values.
    % This converts 'w' -> 1, 'x' -> 2, etc.
    y_numeric = double(catStatuses);
    
    % Create an x vector using the cell row indices.
    x = (1:cntr(idx_sg))';
    
    % Plot using a scatter plot.
    scatter(x, y_numeric, 50, 'filled');
    xlabel('Iteration');
    ylabel('Status');
    title("G_"+num2str(idx_sg))
    
    % Adjust the y-axis so that the tick labels show the status characters.
    set(gca, 'YTick', 1:4, 'YTickLabel', stat_label);
    
    % Optionally, adjust axis limits for clarity.
    %xlim([1, cntr(idx_sg)]);
    ylim([0.5, 4.5]);
    box on; grid on; hold off
end

%% Set flow in
isset = find(cellfun(@(x)isfield(x,'mdot_set'),params(1,:)));
if ~ isempty(isset)
    figure('Name','mdot_set')
    tiledlayout(2,ceil(numel(isset)/2));
    for idx_sg = isset
        nexttile
        hold on
        for idx_ts = 1:num.seg
            vec = cell2mat(cellfun(@(x)x.mdot_set(:,idx_ts)', params(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
            plot(vec)
        end
        title("G_"+num2str(idx_sg))
        box on; grid on; hold off
        ylabel('Flow Rate')
        xlabel('Iteration')
    end
else
    disp('No mdot_set')
end

%% Set pressures
isset = find(cellfun(@(x)isfield(x,'Pn_in'),params(1,:)));
if ~isempty(isset)
    figure('Name','Pin')
    tiledlayout(2,ceil(numel(isset)/2));
    for idx_sg = isset
        nexttile
        hold on
        for idx_ts = 1:num.seg
            vec = cell2mat(cellfun(@(x)x.Pn_in(:,idx_ts)', params(1:cntr(idx_sg),idx_sg),'UniformOutput',false));
            plot(vec)
        end
        title("G_"+num2str(idx_sg))
        box on; grid on; hold off
        ylabel('Node Pressure')
        xlabel('Iteration')
    end
else
    disp('No Pin')
end

end