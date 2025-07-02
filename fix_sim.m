
%% Load Files
pth = "C:\Users\akb42\OneDrive - The Ohio State University\DistrictHeatingNetwork\Project Codes\Partitioning 3 - DHN";
folderPath = pth+"\olm_saves";

% Get a list of all .mat files matching "part_#.mat"
files =dir(fullfile(folderPath, 'part_*.mat'));
n_files = numel(files);
data = cell(1,n_files);

for idx_file = 1:n_files
    data{idx_file} = load(folderPath+filesep+files(idx_file).name);
end

%% Simulation parameters

M_sim = simulate_flow_tfn(num,elems,params);

% Initial conditions
params_sim.T_ic = init.T;
params_sim.intQ_ic = init.intQ;

% Preallocate storage
params_sim.zeta_u = zeros(num.user,num.seg_sim);
params_sim.i_mdot_e = zeros(num.edge,num.seg_sim);
params_sim.i_dPe = zeros(num.edge,num.seg_sim);
params_sim.i_Pn = zeros(num.node,num.seg_sim);

idx_horizon = 1;

%% Resolve simulation

tbresolve = find(cellfun(@(x)~isscalar(x.v_sim.cost_Q),data));

num_all = num;
elems_all = elems;

parfor idx_rs = 1:numel(tbresolve)
    num = num_all;
    elems = elems_all;
    idx_horizon = 1;
    rs = tbresolve(idx_rs);
    data_i = load(folderPath+filesep+files(rs).name,'part','v');
    [~,selems,snum,sparams,num,elems] = subgraph_params(G,data_i.part,elems,num,params);
    if ~data_i.v(idx_horizon).isconverge % if it did not converge
        delta_weighted = cellfun(@(x)sum(x./w_olm.delta_min,'all'), data_i.v(idx_horizon).delta(1,2:end));
        delta_weighted(~cellfun(@(y)all(arrayfun(@(x) data_i.v(idx_horizon).rslts{x}.valid,y)),data_i.v.delta(2,2:end))) = nan;
        if all(isnan(delta_weighted))
            idx_min = data_i.v(idx_horizon).iter;
        else
            [~,idx_min] = min(delta_weighted);
            idx_min = data_i.v.delta{2,idx_min+1};
        end
        rslts_i = (arrayfun(@(x) data_i.v(idx_horizon).rslts{idx_min(x), x}, 1:num.sg,'UniformOutput',false));
    else
        rslts_i = (arrayfun(@(x) data_i.v(idx_horizon).rslts{data_i.v(idx_horizon).iter(x), x}, 1:num.sg,'UniformOutput',false));
    end
    [data_i.v_sim, ~, ~] = simulate_flow(M_sim, params_sim, params, rslts_i, num, selems, idx_horizon);
    save(folderPath+filesep+files(rs).name,"-fromstruct",data_i)
end


%% Fix Saves

idx_split = 2;
load('rslts_old.mat')
rslt_old = rslt;
load('rslts_curr.mat')

for idx_split = 1:2
    [~,idx_old] = ismember(rslt.cand{idx_split},rslt_old.cand{idx_split},'rows');
    for idx_new = 1:numel(idx_old)
        if idx_old(idx_new)~=0
            sv_name = [idx_split idx_old(idx_new)];
            file_old = pth+append(filesep,"olm_saves_tbf",filesep)+"part_"+string(sv_name(1))+"_"+string(sv_name(2))+".mat";
            if exist(file_old,'file')==2
                file_new = pth+append(filesep,"olm_saves",filesep)+"part_"+string(sv_name(1))+"_"+string(idx_new)+".mat";
                stat = movefile(file_old,file_new);
            end
        end
    end
end