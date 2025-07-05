function [sp] = create_pass_var(selems,sn,sparams,idx_sg,idx_plantP,TsetR)
%CREATE_PASS_VAR create elements needed to be passes to neighboring
%subgraphs based on previous time step results.
%
%   [sp] = CREATE_PASS_VAR(selems,sn,sparams,idx_sg,idx_plantP,TsetR)
%
%   DESCRIPTION:
%   Create elements needed to be passes to neighboring subgraphs based on
%   previous time step results. Updated according to information passing
%   rules.
%
%   INPUTS:
%       selems      - Structures containing categorized subsystems element.
%       sn          - Structures containing numeric subsystems specifications.
%       sparams     - Structures containing subsystem problem parameters.
%       idx_sg      - Numeric index of subsystem being considered.
%       idx_plantP  - Numeric index of subsystem controlling plant pressure.
%       TsetR       - Numeric set return temperature of users HEX.
%
%   OUTPUTS:
%       sp          - Structure of subsystem parameter being considered.

%% Current Subgraph

sp  = sparams{idx_sg};
se = selems{idx_sg};

%% Pass Temperature

if se.has.Tin
    T_in = zeros(sn.node_Tin,sn.seg_T);
    for row = 1:sn.node_Tin
        if se.node_T.Num_UpEdge(row)==1
            if se.node_T.IsUser{row}
                T_in(row,:) = TsetR;
            else
                T_in(row,:) = sparams{se.node_T.Graph{row}}.T(se.node_T.Idx_Nonuser{row},2:end);
            end
        else
            Graph = se.node_T.Graph{row};
            IsUser = se.node_T.IsUser{row};
            T_up = zeros(se.node_T.Num_UpEdge(row),sn.seg_T);
            if any(IsUser)
                T_up(IsUser,:) = TsetR;
            end
            if any(~IsUser)
                T_up(~IsUser,:) = cell2mat(arrayfun(@(G,e) sparams{G}.T(e, 2:end), Graph(~IsUser),se.node_T.Idx_Nonuser{row}(~IsUser),'UniformOutput',false));
            end
            m_up = cell2mat(arrayfun(@(G,e) repelem(sparams{G}.i_mdot_e(e,:),1,sn.seg_T/sn.seg),Graph, se.node_T.UpEdge_LNC{row},'UniformOutput',false)');
            T_in(row,:) = sum(T_up.*m_up)./sum(m_up,1);
        end
    end
end

%% Pass Pressure

Pn_in = [];
if se.has.Pset_mfree
    Pset = arrayfun(@(G,v) sparams{G}.i_Pn(v,:),se.node_Pset_mfree.Graph,se.node_Pset_mfree.Idx_Graph,'UniformOutput',false);
    Pn_in = [Pn_in; cell2mat(Pset)];
end
if se.has.plant && ~se.has.plantP
    Pn_in = [Pn_in; sparams{idx_plantP}.i_Pn(selems{idx_plantP}.lnc.plant,:)];
end

%% Pass mass flow

if se.has.mset
    mdot_set = zeros(sn.node_mset, sn.seg);
    for row = 1:sn.node_mset
        mdot_set(row,:) = sum(cell2mat(arrayfun(@(G,v) sparams{G}.i_mdot_free(v,:),...   % Function to get mass flow of node
        se.node_mset.Graph{row},se.node_mset.Idx_free{row},'UniformOutput',false)'),1);   % Graphs in control of node and Index of the node in those graphs 
    end
    mdot_set = -mdot_set;
end

%% Add to sp

% Temperature
if se.has.Tin && isfield(sp,"T_in")
    sp.T_in = (sp.T_in+T_in)./2;
elseif se.has.Tin
    sp.T_in = T_in;
end  

% Mass flow
if se.has.mset && isfield(sp,"mdot_set")
    sp.mdot_set = (sp.mdot_set+mdot_set)/2;
elseif se.has.mset
    sp.mdot_set = mdot_set;
end

% Pressure
if any([se.has.Pset_mfree (se.has.plant && ~se.has.plantP)]) && isfield(sp,"Pn_in")
    if (se.has.plant && ~se.has.plantP)
        Pn_in(1:end-1,:) = (Pn_in(1:end-1,:)+sp.Pn_in(1:end-1,:))./2; % Don't average plantP, its not cooperative
        sp.Pn_in = Pn_in;
    else
        sp.Pn_in = (sp.Pn_in+Pn_in)./2;
    end
elseif any([se.has.Pset_mfree (se.has.plant && ~se.has.plantP)])
    sp.Pn_in = Pn_in;
end

end
