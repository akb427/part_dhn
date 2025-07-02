function [sG,selems,snum,sparams,num,elems] = subgraph_params(G,part,elems,num,params)
%SUBGRAPH_PARAMS Creates subgraphs from G based on the desired system
%partition, identify important elements in each subgraph

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