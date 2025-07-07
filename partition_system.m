%PARTITION_SYSTEM  Runs the system partitioning problem.
%
%   DESCRIPTION:
%   Runner for the system partitioning problem. Loads in the problem
%   parameters, and adds the nessecary paths. It solves the bnb or split
%   bnb algorithm (if using a supercomputer).
%
%   DEPENDENCIES: bnb, bnb_split
%
%   SEE ALSO: generate_problem.

%%
clc, clear, close all

%% Load Problem information

load("sim_4user_params","w_olm","G","elems","num","params","init")

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
