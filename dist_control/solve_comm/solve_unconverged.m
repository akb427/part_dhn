function [rslts] = solve_unconverged(isconverge,sparams_step,Ma, selems, idx_P_slack)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% Get unconverged problems
num_p = sum(~isconverge);
sparams_step_tbc = sparams_step(~isconverge);
M_tbc = Ma(~isconverge);
rslts = cell(1,num_p);
solve_list = find(~isconverge);

%% Solve unconverged problems
parfor idx_p = 1:num_p
    % Remove T since it does not enter the function
    if isfield(sparams_step_tbc{idx_p},'T')
        sparams_step_tbc{idx_p} = rmfield(sparams_step_tbc{idx_p},'T');
    end

    % Solve Problem
    sol = M_tbc{idx_p}.call(sparams_step_tbc{idx_p});
    sol.status = M_tbc{idx_p}.stats.return_status;
    sol.valid = M_tbc{idx_p}.stats.success;
    sol.iterations = M_tbc{idx_p}.stats.iter_count;
    sol = structfun(@full,sol,'UniformOutput',false);

    % Retry incorrectly solved prolems
    cntr_retry=0;
    while ~ismember(sol.status,{'Solve_Succeeded';'Infeasible_Problem_Detected';'Solved_To_Acceptable_Level'})&&cntr_retry<2
        idx_sg = solve_list(idx_p);
        sparams_step_tbc{idx_p} = update_ig(sparams_step_tbc{idx_p}, sol, selems{idx_sg}, idx_P_slack(idx_sg));
        if isfield(sparams_step_tbc{idx_p},'T')
            sparams_step_tbc{idx_p} = rmfield(sparams_step_tbc{idx_p},'T');
        end
        sol = M_tbc{idx_p}.call(sparams_step_tbc{idx_p});
        sol.status = M_tbc{idx_p}.stats.return_status;
        sol.valid = M_tbc{idx_p}.stats.success;
        sol.iterations = M_tbc{idx_p}.stats.iter_count;
        sol = structfun(@full,sol,'UniformOutput',false);
        cntr_retry = cntr_retry+1;
    end

    % Store solution
    rslts{1,idx_p} = sol;
end

end