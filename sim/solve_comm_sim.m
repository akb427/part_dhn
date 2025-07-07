function [v, idx_Pslack, P_min] = solve_comm_sim(M,num,elems,params,sn,se,sparams_step, Gconv,w)
%SOVLE_COMM_SIM  Coordinates the iterative solving of a step of the dmpc problem.
%
%   [v, idx_P_slack, P_min] = SOLVE_COMM_SIM(M,num,elems,params,sn,se,sparams_step, Gconv,w)
%
%   DESCRIPTION:
%   Loops through iterations attempting to find the NE solution to the
%   distributed control problem. Creates variables and intial guesses
%   to be passed between each subystem at each solution iteration. Limits 
%   iterations to max in w. Will activate restoration prodeduring if 
%   converging but infeasible. 
%
%   INPUTS:
%       M       - CasADi functions for optimizing each subsystem.
%       num     - Structure of numeric problem specifications.
%       elems   - Structure of categorized element.
%       params  - Structure of problem parameters.
%       sn      - Structures of subsystem numeric problem specifications.
%       se      - Structures of subsystem categorized elements.
%       sparams_step - Structures of subsystem problem parameters at current time step.
%       Gconv   - Graph of convergence hierarchy.
%       w       - Structure of convergence information.
%
%   OUTPUTS:
%       v       - Structure of the iterative solution results.
%       idx_Pslack - Indicator of subsystem with slack pressure active.
%       P_min   - Vector of minimum plant pressures.
%
%   DEPENDENCIES: check_convergence, create_pass_var, 
%   solve_unconverged_sim, update_ig


%% Preallocate Variables

isconverge = false(1,num.sg);
Ma = M.gen;
n_iter_max = w.n_iter_max;

cntr = zeros(1,num.sg);
rslts = cell(n_iter_max,num.sg);
sparams_step_all = cell(n_iter_max,num.sg);
delta_var = cell(2,n_iter_max*num.sg);
idx_delta = 0;

is_slack = false;
idx_Pslack = false(1,num.sg);

%% Perform Calculation

while any(~isconverge) && max(cntr)<n_iter_max
    % Update iteration count
    cntr(1,~isconverge) = cntr(1,~isconverge)+1;
    
    % Create Variables as inputs
    for idx_sg = 1:num.sg
        sparams_step{idx_sg} = create_pass_var(se,sn{idx_sg},sparams_step,idx_sg,elems.idx_plantP,params.TsetR);
    end

    % Solve Problem and Distribute Results
    rslts_new = solve_unconverged_sim(isconverge,sparams_step,Ma, se, idx_Pslack);
    idx_loop = 0;
    for idx_sg = find(~isconverge)
        idx_loop = idx_loop+1;
        rslts{cntr(idx_sg),idx_sg} = rslts_new{1,idx_loop};
    end
    
    % Check for convergence
    if all(cntr>1)
        idx_delta = idx_delta+1;
        % Calculate Delta and check for convergence
        rslts_i = [rslts(sub2ind(size(rslts),cntr-1,1:num.sg));rslts(sub2ind(size(rslts),cntr,1:num.sg))]; % [previous; current]
        [delta_var{1,idx_delta}, stat, isconverge] = check_convergence(rslts_i, isconverge, se, w.delta_min, Gconv);
        delta_var{2,idx_delta} = cntr;

        % Check on the slack status
        stat_good = ismember(stat,{'Solve_Succeeded';'Solved_To_Acceptable_Level'});
        stat_bad = strcmp(stat,'Infeasible_Problem_Detected');
        isconverge_rlx = all(delta_var{1,idx_delta}<w.delta_min_rlx,'all');
        % If the slack problem has converged & Pmin should be updated
        if is_slack && all(stat_good) && isconverge_rlx
            P_plant = cell2mat(cellfun(@(rsltsP,seP)rsltsP.Pn(seP.lnc.plant,:),rslts_i(2,idx_Pslack),se(idx_Pslack),'UniformOutput',false));
            sparams_step{elems.idx_plantP}.P_min = max(P_plant,[],1)+.05;
            % Remove slack
            isconverge = false(1,num.sg); idx_Pslack = false(1,num.sg); is_slack = false;
            Ma = M.gen;
            if max(cntr) == n_iter_max
                n_iter_max = n_iter_max+1;
            end
        % If the original problem has converged, but is not solving
        elseif isconverge_rlx && any(stat_bad & elems.idx_plant & ~elems.idx_plantP & ~idx_Pslack)
            idx_Pslack(stat_bad & elems.idx_plant & ~elems.idx_plantP) = 1;
            Ma(idx_Pslack) = M.slack(idx_Pslack);
            is_slack = true;
            n_iter_max = w.n_iter_max_slack;
        end
    end
    
    % Update Initial Guesses
     for idx_sg = 1:num.sg
        sparams_step_all{cntr(idx_sg),idx_sg} = sparams_step{idx_sg}; % Store for troubleshooting
        sparams_step{idx_sg} = update_ig(sparams_step{idx_sg}, rslts{cntr(idx_sg),idx_sg}, se{idx_sg}, idx_Pslack(idx_sg));
     end
   
end


%% Output Results
%fig_convergence(rslts,cntr,num)
v.rslts= rslts(1:max(cntr),:);
v.iter = cntr;
v.delta = delta_var(:,1:idx_delta);
v.isconverge = all(isconverge);
v.sparams_step = sparams_step_all(1:max(cntr),:);
P_min = sparams_step{elems.idx_plantP}.P_min;

end