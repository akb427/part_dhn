% Resolve converged solutions with initial guesses that are less accurate
%% Problem Setup
load('ws_03_18.mat')

% Load current results or create them
pth = pwd;
file_name = pth+append(filesep,"olm_saves_initcen",filesep,"rslts_03_03.mat");
load(file_name,'rslt');
rslt_old = rslt;

%% To be solved list

idx_invld = logical(rslt_old.cost{1}(:,4));

rslt.cand = cell(1,num.edge);
rslt.cost = rslt.cand;
rslt.cand{1} = [zeros(sum(~idx_invld),2);rslt_old.cand{1}(idx_invld,:)];

save('rslts_curr_nc','rslt')

%% Split 

idx_split = 1;
n_cand = size(rslt.cand{idx_split},1); 

is_solved = false(n_cand,1);
for idx_cand = 1:n_cand
    sv_name = [idx_split idx_cand];
    file_name = pth+append(filesep,"olm_saves",filesep,"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat");
    is_solved(idx_cand) = (exist(file_name,'file')==2);
end

cand_unsolve = find(~is_solved);

%% Split list

% Compute sizes
n_tbs = size(cand_unsolve,1);
n_com = 3;                          % number of super computer sessions to be taken out
n_local = 2000;                     % number to be run on simulation computer (faster)
n_nlocal = n_tbs-n_local;
base_sz = floor(n_nlocal/n_com);    % Base size of each cell
extra = mod(n_nlocal,n_com);        % Number of extra elements to distribute

% Split
cand_unsolve_split = mat2cell(cand_unsolve, [n_local (base_sz+1)*ones(1,extra) base_sz*ones(1,n_com-extra)]);

%% Save
clearvars -except cand_unsolve_split

load('ws_02_20.mat')
save("ws_"+string(datetime('today', 'Format', 'MM_dd')))

%% Check solved percent
idx_split = 1;
n_com = numel(cand_unsolve_split);
is_solved = cell(1,n_com);
for idx_com = 1:n_com
    n_cand_i = size(cand_unsolve_split{idx_com},1);
    is_solved{idx_com} = false(n_cand_i,1);
    for idx_cand = 1:n_cand_i
        sv_name = [idx_split cand_unsolve_split{idx_com}(idx_cand,2)];
        file_name = pth+append(filesep,"olm_saves",filesep,"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat");
        file_name2 = pth+append(filesep,"Modified3",filesep,"olm_saves",filesep,"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat");
        is_solved{idx_com}(idx_cand) = (exist(file_name,'file')==2) || (exist(file_name2,'file')==2);
    end
end