function [G,num,elems,params,temp_prof] = generate_params4(G,num,elems,params)
%GENERATE_PARAMS4  Generate parameters for network components.
%
%   [G,num,elems,params,temp_prof] = GENERATE_PARAMS4(G,num,elems,params)
%
%   DESCRIPTION:
%   Generate parameters for network components in the four user case study. 
%   Allows for time-varying flexibility envelopes. Format of params.pipes:
%   [L D zetaB zetaF mdot Lbypass Dbypass mdotbypass]. Format of
%   params.users: [mu Q Ls1 Ls2 Ls3 Ds1 Ds2 Ds3]. Loads heat demand and
%   temperature profiles from file. Some network parameters are hard coded.
%
%   INPUTS:
%       G       - Digraph of the network structure.
%       num     - Structure of numeric problem specifications.
%       elems   - Structure of categorized element.
%       params  - Structure of problem parameters.
%
%   OUTPUTS:
%       G       - Digraph of the network structure.
%       num     - Structure of numeric problem specifications.
%       elems   - Structure of categorized element.
%       params  - Structure of problem parameters.
%       temp_prof   - Structure of flexibility profiles.
%
%   EXAMPLE USAGE:
%       [best_part, results] = my_partition_solver(G, params);
%
%   DEPENDENCIES:
%       List other custom functions this function calls, if any.
%
%   SEE ALSO:
%       RelatedFunction1, RelatedFunction2

%% Path
path = pwd;

% Split the path by file separator
path = strsplit(path, filesep);

% Remove the last x folders
path = fullfile(path{1:end-2});
path = path+"\Building Data\";

%% Timing

time = 0:params.dt:params.tf;
time_T = 0:params.dt_T:params.tf;

date_start = datetime(2018,1,28);
date_end = datetime(2018,2,4);
delta_date = seconds(date_end-date_start);

%% Graph 
params.I = -incidence(G);
num.node = numnodes(G);
num.edge = numedges(G);
G.Edges.Idx = (1:num.edge)';
G.Nodes.Idx = (1:num.node)';

elems.root = find(indegree(G)==0);
elems.term = find(outdegree(G)==0);

[~,ia,~] = unique(G.Edges.EndNodes,'rows');
elems.bypass = setdiff(1:num.edge,ia);

for i = elems.bypass
    u = find(all(G.Edges.EndNodes(i,:)==G.Edges.EndNodes,2));
    elems.user = [elems.user u(u~=i)];
end
elems.nonuser = setdiff(1:num.edge,elems.user);

num.user = numel(elems.user);
num.nonuser = numel(elems.nonuser);

vhot = find(outdegree(G)>1)';
vcold = find(indegree(G)>1)';

G_cold = flipedge(subgraph(G,vcold));
G_hot = subgraph(G, vhot);
P = isomorphism(G_hot,G_cold);
G_cold = reordernodes(G_cold,P);
elems.hot = (G_hot.Edges.Idx)';
elems.cold = (G_cold.Edges.Idx)';

elems.edge_plant = outedges(G,elems.root)';

%% Inedges and outedges of users

elems.user_inedge = zeros(1,num.user);
elems.user_outedge = zeros(1,num.user);
idx = 0;
for i = elems.user
    idx = idx+1;
    elems.user_inedge(idx) = inedges(G,G.Edges.EndNodes(i,1));
    elems.user_outedge(idx) = outedges(G,G.Edges.EndNodes(i,2));
end

elems.user_inedge_idx_nonuser = find(any(elems.user_inedge==elems.nonuser',2));

%% State Space Parameters

% Table setup
var_name = ["Edge","IsPlant",...
    "Inedge","IsSingle",...
    "HasNonuserIn","Inedge_nonuser","Inedge_nonuser_idx",...
    "HasUserIn","Inedge_user"];
var_type = ["uint8","logical",...
    "cell","logical",...
    "logical","cell","cell",...
    "logical","cell"];
elems.nonuser_ss = table('Size',[num.nonuser numel(var_name)],'VariableNames',var_name,'VariableTypes',var_type);

% Characterisitcs of Nonuser Edge
elems.nonuser_ss.Edge = elems.nonuser';

% Edge Leaving plant
elems.nonuser_ss.IsPlant = ismember(elems.nonuser_ss.Edge,elems.edge_plant);

% Inedges
elems.nonuser_ss.Inedge = arrayfun(@(e) inedges(G,e), G.Edges.EndNodes(elems.nonuser_ss.Edge,1),'UniformOutput',false);

% Local nonuser Inedges
elems.nonuser_ss.Inedge_nonuser = cellfun(@(e_set) intersect(e_set,elems.nonuser_ss.Edge),elems.nonuser_ss.Inedge,'UniformOutput',false);
elems.nonuser_ss.HasNonuserIn = cellfun(@(e_set) ~isempty(e_set), elems.nonuser_ss.Inedge_nonuser);
[~,elems.nonuser_ss.Inedge_nonuser_idx] = cellfun(@(e_set) arrayfun(@(e)ismember(e,elems.nonuser_ss.Edge),e_set),elems.nonuser_ss.Inedge_nonuser,'UniformOutput',false);

% Local User Inedges
elems.nonuser_ss.Inedge_user = cellfun(@(e_set) intersect(e_set,elems.user),elems.nonuser_ss.Inedge,'UniformOutput',false);
elems.nonuser_ss.HasUserIn = cellfun(@(e_set) ~isempty(e_set), elems.nonuser_ss.Inedge_user);

% Need Mass flow scaling
elems.nonuser_ss.IsSingle = cellfun(@(e_in) isscalar(e_in), elems.nonuser_ss.Inedge)&~elems.nonuser_ss.IsPlant;

%% Network parameters

params.p = 971;
params.cp = 4179;
params.h = 1.5;
params.mI = num.user*5;

% params.T_0 = 3*sawtooth(t*pi/600,.1)+80;
%params.T_0 = 80*ones(1,n.step_T);
params.T_0 = 80*ones(1,numel(time_T));
params.TsetR = 30;

%% Building parameters
% pcpV = [197*10^6;190*10^6;185*10^6;202*10^6;217*10^6;108*10^6;124*10^6;126*10^6;130*10^6;146*10^6;127*10^6;183*10^6;163*10^6;209*10^6;179*10^6]; 
% pcpV = [1/7.7983e-7;1/1.0719e-6];
% pcpV = pcpV(1:n.u,1);

% Flexibible hours
idx_day = floor(time_T/(24*60*60))+1;
idx_hr = mod(floor(time_T/3600),24);

t_all = false(num.user,length(time_T));

t_res = false(size(time_T));
t_res(idx_day~=1&idx_day~=7&idx_hr<18&idx_hr>9)=1;
nr = find(ismember(elems.user,[8 10 12 13 20 22 24 25 57 59 60]))';
t_all(nr,:) = repmat(t_res,numel(nr),1);

t_com = false(size(time_T));
t_com(~(idx_day~=1&idx_day~=7&idx_hr<18&idx_hr>6)) = 1;
nr = find(ismember(elems.user,[49 51]))';
t_all(nr,:) = repmat(t_com,numel(nr),1);

t_retail = false(size(time_T));
t_retail(idx_hr>22|idx_hr<6)=1;
nr = find(ismember(elems.user,[38 41 44 54]))';
t_all(nr,:) = repmat(t_retail,numel(nr),1);

% Store Profiles
temp_prof.res = t_res;
temp_prof.com = t_com;
temp_prof.retail = t_retail;
temp_prof.med = false(size(t_res));

% Temperature Limits
T_all = zeros(size(t_all));
T_all(t_all) = 2;%4 for time varying flex
T_all(~t_all) = 2;

% Get Capacity
e_select = 1:4;
load(path+"Cbuild.mat",'pcpV');

params.Cap_l = pcpV(e_select,:).*-T_all/10^6; %MJ
params.Cap_u = pcpV(e_select,:).*T_all/10^6;  %MJ

params.w_flex = diag(1./pcpV*10^3);

%% Pipe Parameters
lambda = 1;%0.01;

% pipes = [L(1) D(2) zeta(3) 1/pV(4)]
params.pipes = zeros(num.edge, 3);
params.pipes(elems.hot,1) = [60 80 20 20]; 
params.pipes(elems.bypass,1) = 3;
params.pipes(elems.cold,1) = params.pipes(elems.hot,1);
params.pipes(:,2) = .40*ones(num.edge,1);
params.pipes(elems.bypass,2) = .15;
params.pipes(elems.user,2) = 0;
params.pipes(:,3) = lambda*params.pipes(:,1)./params.pipes(:,2)./(2*params.p*(pi/4*params.pipes(:,2).^2).^2);
params.pipes(:,4) = 1./params.p./(pi/4.*params.pipes(:,2).^2.*params.pipes(:,1));

%% Heat Demand
load(path+"heat profiles.mat",'Qb','t');
Qb = Qb(:,t>=date_start & t<=date_end);
time_Qb_orig = 0:15*60:delta_date;
params.Qb = interp1(time_Qb_orig, Qb', time)'; %kW
params.Qb = params.Qb(e_select,:);

%% Ambient Temperature

T_amb = readmatrix(path+"USA_IL_Chicago-Midway.AP_Tamb.xlsx")';
time_amb_orig = datetime(2018,1,1,0,0,0)+seconds(T_amb(1,:));
T_amb= T_amb(2,time_amb_orig>=date_start & time_amb_orig<=date_end);
time_amb_orig = 0:60*60:delta_date;
%params.Tamb = interp1(tamb, Tamb, 0:params.dt_T:24*60*60);
params.T_amb = interp1(time_amb_orig, T_amb, time_T);

end