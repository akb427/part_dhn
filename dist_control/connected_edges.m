function [selems,snum] = connected_edges(elems,selems,snum,sG,G,part)
%CONNECTED_EDGES Get edges connected to current subgraph and associated nodes

%% Get Up & Down Info

% num_sg = numel(selems);
% [selems, snum] = cellfun(@(sn,idx_sg)upstream_edges(elems,selems,sn,idx_sg,G,part),snum,num2cell(1:num_sg),'UniformOutput',false);
% [selems, snum] = cellfun(@(sn,idx_sg)downstream_edges(elems,selems,sn,idx_sg,G,part),snum,num2cell(1:num_sg),'UniformOutput',false);

%% Parse for Relavent Variables

[selems, snum]= cellfun(@Tin,selems,snum,'UniformOutput',false);
[selems, snum]= cellfun(@Pset_mfree,selems,snum,'UniformOutput',false);
[selems, snum]= cellfun(@mset,selems,snum,'UniformOutput',false);
selems = cellfun(@user_inedge,selems,snum,'UniformOutput',false);

selems = cellfun(@Tss,selems,snum,sG,'UniformOutput',false);

%% In Temperature info

    function [se,sn] = Tin(se,sn)
    % Upstream Edges
    node_nonterm = setdiff(se.node,se.term); % All the nonterminal nodes in the subgraph
    up_edge = arrayfun(@(v) inedges(G, v)', node_nonterm, 'UniformOutput', false);
    up_edge = cellfun(@(e_set)setdiff(e_set,se.edge),up_edge,'UniformOutput',false); % Remove edges in graph
    all_local = cellfun(@isempty, up_edge);
    se.has.Tin =  any(~all_local);

    if se.has.Tin
        sn.node_Tin = sum(~all_local);
        % Table setup
        var_name = ["Node","Node_LNC","Num_UpEdge","UpEdge","UpEdge_LNC","IsUser","Graph","Idx_Nonuser"];
        var_type = ["uint8","uint8","uint8","cell","cell","cell","cell","cell",];
        se.node_T = table('Size',[sn.node_Tin numel(var_name)],'VariableNames',var_name,'VariableTypes',var_type);

        % Get node properties
        se.node_T.Node = node_nonterm(~all_local)';
        [~,se.node_T.Node_LNC] = ismember(se.node_T.Node,se.node);

        % Non-Local Upstream edges
        se.node_T.UpEdge = up_edge(~all_local)';
        se.node_T.Graph = cellfun(@(e_set) arrayfun(@(e)part(1,e),e_set),se.node_T.UpEdge,'UniformOutput',false);
        se.node_T.Num_UpEdge = cellfun(@numel,se.node_T.UpEdge);
        [~,se.node_T.UpEdge_LNC] = cellfun(@(e_set,g_set) arrayfun(@(e,g) ismember(e,selems{g}.edge),e_set,g_set),se.node_T.UpEdge,se.node_T.Graph,'UniformOutput',false);
        
        % Identify Types
        se.node_T.IsUser = cellfun(@(e_set) arrayfun(@(e)ismember(e,elems.user),e_set),se.node_T.UpEdge,'UniformOutput',false);
        se.node_T.IsHot = cellfun(@(e_set) any(arrayfun(@(e)ismember(e,elems.hot),e_set)),se.node_T.UpEdge);
        
        % Indexing in nonuser edges
        [~,se.node_T.Idx_Nonuser] = cellfun(@(e_set,g_set) arrayfun(@(e,g) ismember(e,selems{g}.nonuser),e_set,g_set),se.node_T.UpEdge,se.node_T.Graph,'UniformOutput',false);
    else
        sn.node_Tin = 0;
    end
    end

%% Pressure Control Info (down then up)

    function [se,sn] = Pset_mfree(se,sn)
    % Upstream Hot Edges
    up_node_hot = setdiff(se.node,se.term); % All the nonterminal nodes in the subgraph
    up_edge_hot = arrayfun(@(v) inedges(G, v)', up_node_hot, 'UniformOutput', false);
    up_edge_hot = cellfun(@(e_set)setdiff(e_set,se.edge),up_edge_hot,'UniformOutput',false); % Remove edges in graph
    up_edge_hot = cellfun(@(e_set)intersect(e_set,elems.hot),up_edge_hot,'UniformOutput',false); % Get only hot edges
    all_local_hot = cellfun(@isempty, up_edge_hot);
    up_node_hot = up_node_hot(~all_local_hot);
    up_edge_hot = cell2mat(up_edge_hot(~all_local_hot));

    % Downstream Cold Edges
    down_node_cold = setdiff(se.node,se.root); % All the nonroot nodes in the subgraph
    down_edge_cold = arrayfun(@(v) outedges(G, v)', down_node_cold, 'UniformOutput', false);
    down_edge_cold = cellfun(@(e_set)setdiff(e_set,se.edge),down_edge_cold,'UniformOutput',false); % Remove edges in graph
    down_edge_cold = cellfun(@(e_set)intersect(e_set,elems.cold),down_edge_cold,'UniformOutput',false); % Get only cold edges
    all_local_cold = cellfun(@isempty, down_edge_cold);
    down_node_cold = down_node_cold(~all_local_cold);
    down_edge_cold = cell2mat(down_edge_cold(~all_local_cold));

    se.has.Pset_mfree = ~isempty(up_node_hot)||~isempty(down_node_cold);
    if se.has.Pset_mfree
        sn.node_Pset_mfree = numel(up_node_hot)+numel(down_node_cold);

        % Table setup
        var_name = ["Node","Node_LNC","Edge","Graph","Idx_Graph","IsIn","Idx_T"];
        var_type = ["uint8","uint8","uint8","uint8","uint8","logical","double"];
        se.node_Pset_mfree = table('Size',[sn.node_Pset_mfree numel(var_name)],'VariableNames',var_name,'VariableTypes',var_type);

        % Store in table
        se.node_Pset_mfree.Node = [up_node_hot down_node_cold]';
        [~,se.node_Pset_mfree.Node_LNC] = ismember(se.node_Pset_mfree.Node,se.node);
        se.node_Pset_mfree.Edge = [up_edge_hot down_edge_cold]';
        se.node_Pset_mfree.Graph = part(1,se.node_Pset_mfree.Edge)';
        [~,se.node_Pset_mfree.Idx_Graph] = arrayfun(@(G,v) ismember(v,selems{G}.node), se.node_Pset_mfree.Graph, se.node_Pset_mfree.Node);
        se.node_Pset_mfree.IsIn = [true(numel(up_node_hot),1); false(numel(down_node_cold),1)];
        
        % Index of Tin
        [~,se.node_Pset_mfree.Idx_T(se.node_Pset_mfree.IsIn)] = arrayfun(@(v) ismember(v,se.node_T.Node),se.node_Pset_mfree.Node(se.node_Pset_mfree.IsIn));
    else
        sn.node_Pset_mfree = 0;
    end
    end


%% Flow Set Info

    function [se,sn] = mset(se,sn)
    % Upstream Cold Edges
    up_node_cold = setdiff(se.node,se.term); % All the nonterminal nodes in the subgraph
    up_edge_cold = arrayfun(@(v) inedges(G, v)', up_node_cold, 'UniformOutput', false);
    up_edge_cold = cellfun(@(e_set)setdiff(e_set,se.edge),up_edge_cold,'UniformOutput',false); % Remove edges in graph
    up_edge_cold = cellfun(@(e_set)setdiff(e_set,elems.hot),up_edge_cold,'UniformOutput',false); % Get only non-hot edges
    all_local = cellfun(@isempty, up_edge_cold);
    up_node_cold = up_node_cold(~all_local);
    up_edge_cold = up_edge_cold(~all_local);

    % Downstream Hot Edges
    down_node_hot = setdiff(se.node,se.root); % All the nonroot nodes in the subgraph
    down_edge_hot = arrayfun(@(v) outedges(G, v)', down_node_hot, 'UniformOutput', false);
    down_edge_hot = cellfun(@(e_set)setdiff(e_set,se.edge),down_edge_hot,'UniformOutput',false); % Remove edges in graph
    down_edge_hot = cellfun(@(e_set)setdiff(e_set,elems.cold),down_edge_hot,'UniformOutput',false); % Get only non-cold edges
    all_local = cellfun(@isempty, down_edge_hot);
    down_node_hot = down_node_hot(~all_local);
    down_edge_hot = down_edge_hot(~all_local);

    se.has.mset = ~isempty(up_node_cold)||~isempty(down_node_hot);

    if se.has.mset
        edge = [up_edge_cold down_edge_hot];
        sn.node_mset = numel(up_node_cold)+numel(down_node_hot);

        % Table setup
        var_name = ["Node","Node_LNC","Num_Graph","Graph","Idx_free","IsIn","Idx_T"];
        var_type = ["uint8","uint8","uint8","cell","cell","logical","double"];
        se.node_mset = table('Size',[sn.node_mset numel(var_name)],'VariableNames',var_name,'VariableTypes',var_type);

        % Store in table
        se.node_mset.Node = [up_node_cold down_node_hot]';
        [~,se.node_mset.Node_LNC] = ismember(se.node_mset.Node,se.node);
        se.node_mset.IsIn = [true(numel(up_node_cold),1); false(numel(down_node_hot),1)];

        % Control Graph and Index
        se.node_mset.Graph = cellfun(@(e_set)unique(part(1,e_set)),edge','UniformOutput',false);
        [~,se.node_mset.Idx_free] = cellfun(@(v,G_set)arrayfun(@(g)ismember(v, selems{g}.node_Pset_mfree.Node),G_set),num2cell(se.node_mset.Node),se.node_mset.Graph,'UniformOutput',false);
        se.node_mset.Num_Graph = cellfun(@numel,se.node_mset.Graph);

        % Index in Tin
        [~,se.node_mset.Idx_T(se.node_mset.IsIn)] = arrayfun(@(v) ismember(v,se.node_T.Node),se.node_mset.Node(se.node_mset.IsIn));
    else
        sn.node_mset = 0;
    end
    end

%% User In Edges
    function [se] = user_inedge(se,sn)
    if se.has.user
        % Table setup
        var_name = ["InEdge","idx_Nonuser","idx_node_T","IsLocal"];
        var_type = ["uint8","double","double","logical"];
        se.user_inedge = table('Size',[sn.user numel(var_name)],'VariableNames',var_name,'VariableTypes',var_type);
        
        % Inedge information
        se.user_inedge.InEdge = elems.user_inedge(se.idx.user)';
        se.user_inedge.IsLocal = ismember(se.user_inedge.InEdge,se.edge);
        
        % Relavent indexing
        [~,se.user_inedge.idx_Nonuser(se.user_inedge.IsLocal)] = ismember(se.user_inedge.InEdge(se.user_inedge.IsLocal),se.nonuser);
        se.user_inedge.idx_node_T(~se.user_inedge.IsLocal) = arrayfun(@(e_i) find(cellfun(@(e_list)ismember(e_i,e_list),se.node_T.UpEdge)),se.user_inedge.InEdge(~se.user_inedge.IsLocal));
    end
    end


%% State Space Creation

    function [se] = Tss(se,sn,sG)
        if se.has.nonuser
            nonuser = se.nonuser';
            se = rmfield(se,"nonuser");
            % Table setup
            var_name = ["Edge","Edge_LNC","Innode","Innode_LNC","IsPlant",...
                "Inedge","IsSingle",...
                "HasNonuserIn","Inedge_nonuser_LNC","Inedge_nonuser_idx",...
                "HasUserIn","Inedge_user_LNC",...
                "HasNonLocal","Idx_Tin"];
            var_type = ["uint8","uint8","uint8","uint8","logical",...
                "cell","logical",...
                "logical","cell","cell",...
                "logical","cell"...
                "logical","uint8"];
            se.nonuser = table('Size',[sn.nonuser numel(var_name)],'VariableNames',var_name,'VariableTypes',var_type);

            % Characterisitcs of Nonuser Edge
            se.nonuser.Edge = nonuser;
            se.nonuser.Edge_LNC = se.lnc.nonuser';
            se.nonuser.Innode_LNC = sG.Edges.EndNodes(se.nonuser.Edge_LNC,1);
            se.nonuser.Innode = se.node(se.nonuser.Innode_LNC)';
            
            % Edge Leaving plant
            if se.has.plant
                se.nonuser.IsPlant = ismember(se.nonuser.Edge,se.edge_plant);
            end
            
            % Inedges
            se.nonuser.Inedge = arrayfun(@(e) inedges(G,e), se.nonuser.Innode,'UniformOutput',false);

            % Local nonuser Inedges
            inedge_nonuser = cellfun(@(e_set) intersect(e_set,se.nonuser.Edge),se.nonuser.Inedge,'UniformOutput',false);
            se.nonuser.HasNonuserIn = cellfun(@(e_set) ~isempty(e_set), inedge_nonuser);
            [~,se.nonuser.Inedge_nonuser_LNC] = cellfun(@(e_set) arrayfun(@(e)ismember(e,se.edge),e_set),inedge_nonuser,'UniformOutput',false);
            [~,se.nonuser.Inedge_nonuser_idx] = cellfun(@(e_set) arrayfun(@(e)ismember(e,se.nonuser.Edge),e_set),inedge_nonuser,'UniformOutput',false);

            % Local User Inedges
            inedge_user = cellfun(@(e_set) intersect(e_set,se.user),se.nonuser.Inedge,'UniformOutput',false);
            se.nonuser.HasUserIn = cellfun(@(e_set) ~isempty(e_set), inedge_user);
            [~,se.nonuser.Inedge_user_LNC] = cellfun(@(e_set) arrayfun(@(e)ismember(e,se.edge),e_set),inedge_user,'UniformOutput',false);

            % Non-Local Inedges
            if se.has.Tin
                [se.nonuser.HasNonLocal,se.nonuser.Idx_Tin] = ismember(se.nonuser.Innode,se.node_T.Node);
            end
            % Need Mass flow scaling
            se.nonuser.IsSingle = cellfun(@(e_in,e_nu,e_u) isscalar(e_in)||(isempty(e_nu)&&isempty(e_u)), se.nonuser.Inedge,inedge_nonuser,inedge_user)&~se.nonuser.IsPlant;
        end
    end

end

