function [sg,se,sn,sp] = divide_graph(idx_sg,G,part,elems,num,params)
%DIVIDE_GRAPH splits a graph according to part and labels appropriate
%elements.
%
%   [sg,se,sn,sp] = DIVIDE_GRAPH(idx_sg,G,part,elems,num,params)
%
%   DESCRIPTION:
%   Finds the description of the subsystem in the considered partition of
%   the overall system. Gets information about local and overal indexing to
%   be used in the distributed control problem.
%
%   INPUTS:
%       idx_sg  - Number of subgraph being considered.
%       G       - Digraph of the network structure.
%       part    - Vector of elements groups.
%       elems   - Structure of categorized element.
%       num     - Structure of numeric problem specifications.
%       params  - Structure of problem parameters.
%
%   OUTPUTS:
%       sg  - Digraph of subsytem elements.
%       se  - Structure of subsystem elements.
%       sn  - Structure of subsystem numeric specifications.
%       sp  - Structure of subsystem parameters.
%
%   SEE ALSO: subgraph_params

%% Create Identity Indicator

var_name = ["plant","plantP","refP","user","nonuser"];
se.has = cell2struct(num2cell(false(size(var_name))), cellstr(var_name), 2);
se.lnc = struct;
se.idx = struct;

%% Get subgraph elements

% Isolate subgraph
sg = rmedge(G,setdiff(G.Edges.Idx,find(part==idx_sg)));
sg = rmnode(sg,find(indegree(sg)+outdegree(sg)==0));
se.edge = sg.Edges.Idx';
se.node = sg.Nodes.Idx';

% Extract elements
se.user = intersect(se.edge,elems.user);
se.bypass = intersect(se.edge,elems.bypass);
se.hot = intersect(se.edge,elems.hot);
se.cold = intersect(se.edge,elems.cold);
se.nonuser = intersect(se.edge,elems.nonuser);

% Root nodes
se.lnc.root = find(indegree(sg)==0)';
se.root = se.node(se.lnc.root);
% Terminal node
se.lnc.term = find(outdegree(sg)==0)';
se.term = se.node(se.lnc.term);

% Plant
se.has.plant = ismember(elems.root,se.node);
if se.has.plant
    [~,se.lnc.plant] = ismember(elems.root,se.node);
    se.edge_plant = intersect(se.edge,elems.edge_plant);
    [~, se.lnc.edge_plant] = ismember(se.edge_plant,se.edge);
end

%% Local naming convention
[~,se.lnc.user] = ismember(se.user,se.edge);
[~,se.lnc.bypass] = ismember(se.bypass,se.edge);
[~,se.lnc.nonuser] = ismember(se.nonuser,se.edge);

%% Indexing in overall lists

[~,se.idx.user] = ismember(se.user,elems.user);
[~,se.idx.nonuser] = ismember(se.nonuser,elems.nonuser);

%% Number of elements
sn = num;
sn.edge = numel(se.edge);
sn.node = numel(se.node);
sn.user = numel(se.user);
sn.nonuser = numel(se.nonuser);

%% Additional Classifications

se.has.user = sn.user>0;
se.has.nonuser = sn.nonuser>0;

%% Pressure Designations

% Reference pressure
[se.has.refP,se.lnc.refP] = ismember(elems.term, se.node);
% Plant pressure
se.has.plantP = part(1,end)==idx_sg;

%% Subgraph Parameters

sp.I = -incidence(sg);
sp.pipes = params.pipes(se.edge,:);
sp.TsetR = params.TsetR;

sp.Qb = params.Qb(se.idx.user,:);
sp.Cap_l = params.Cap_l(se.idx.user,:);
sp.Cap_u = params.Cap_u(se.idx.user,:);

end

