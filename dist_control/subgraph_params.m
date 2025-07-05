function [sG,selems,snum,sparams,num,elems] = subgraph_params(G,part,elems,num,params)
%SUBGRAPH_PARAMS Coordinates the creation of subgraphs from system
%partition.
%
%   [sG,selems,snum,sparams,num,elems] = SUBGRAPH_PARAMS(G,part,elems,num,params)
%
%   DESCRIPTION:
%   Coordinates the creation of subgraphs from system partition. Creates
%   the subgraph information and information about how the subgraphs are
%   connected to faciliate the creation of distributed control problem
%   based on the communciation scheme.
%
%   INPUTS:
%       G       - Digraph of the network structure.
%       part    - Vector of elements groups.
%       elems   - Structure of categorized elements.
%       num     - Structure of numeric problem specifications.
%       params  - Structure of problem parameters.
%
%   OUTPUTS:
%       sG      - Digraphs of subsytems elements.
%       selems  - Structures of subsystems elements.
%       snum    - Structures of subsystems numeric specifications
%       sparams - Structures of subsystems parameters.
%       num     - Updated structure of numeric problem specifications.
%       elems   - Updated structure of categorized elements.
%
%   DEPENDENCIES: connected_edges, divide_graph

%% Call Functions
num.sg = max(part);

% Divide graph into parts
[sG,selems,snum,sparams] = arrayfun(@(sg) divide_graph(sg,G,part,elems,num,params),1:num.sg,'UniformOutput',false);

% Get info about how edges are connected
[selems, snum] = connected_edges(elems,selems,snum,sG,G,part);

% Identify pressure types
elems.idx_plantP = cellfun(@(x)x.has.plantP,selems);
elems.idx_plant = cellfun(@(x)x.has.plant,selems);

end