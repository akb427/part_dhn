
clc, clear, close all

%% Load Problem information

load("ws_03_18","w_olm","G","elems","num","params","init")

%% Add subfolders to path

pth = pwd;
pth_split = split(pth, string(filesep));

addpath(pth+append(filesep,"dist_control"))
addpath(pth+append(filesep,"dist_control")+append(filesep,"solve_comm"))
addpath(pth+append(filesep,"bnb"))
addpath(pth+append(filesep,"cen_control"))
addpath(fullfile(pth_split{1:4})+append(filesep,"casadi-3.6.3-windows64-matlab2018b"))
addpath(fullfile(pth_split{1:4})+append(filesep,"ProgressBar"))


%% Optimized case via BnB
idx_com = 1;

%bnb_split1(w_olm,G,elems,num,params,init,cand_unsolve_split{idx_com});
[part_olm, rslt, idx_best] = bnb(w_olm,G,elems,num,params,init);
%save('rslts_olm','part_olm','rslt','idx_best')

%% Single Partition test


% cand_int = 62;
% cand_bin = dec2bin(cand_int,w_olm.minDigits)-'0'+1;
% %cand_bin = [1 2 ones(1,5) 2 ones(1,3) 2 3 3 1];
% c_i = find_olm(cand_bin,G,elems,num,params,init,w_olm);
% load("C:\Users\akb42\OneDrive - The Ohio State University\DistrictHeatingNetwork\Project Codes\Partitioning 3 - DHN\olm_saves\part_2_1073.mat")
%c_i = find_olm(part,G,elems,num,params,init,w_olm);

%% Depth bnb
% clc
% load("ws_04_10","w_olm","G","elems","num","params","init")
% G_ln = linegraph(G,elems,num,params.pipes(:,4));
% [part_wG] = modularity_max(G_ln);
% part_wG = [part_wG 1];
% init.part = part_wG;
% init.part(part_wG==2) = 1;
% init.part(part_wG==3) = 2;
% init.part = init.part-1;
% 
% [part_olm, rslt, idx_best] = bnb_depth(w_olm,G,elems,num,params,init);
% 
% save('rslt_depth');