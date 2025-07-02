function [sp] = parse_ig(init,se)
%PARSE_IG Summary of this function goes here
%   Detailed explanation goes here

%% Parse Initial Guesses for subgraph

sp.i_mdot_e = init.mdot_e(se.edge,:);
sp.i_dPe = init.dPe(se.edge,:);
sp.i_Pn = init.Pn(se.node,:);
if se.has.plant
    sp.i_mdot_0 = sum(init.mdot_e(se.edge_plant,:),1);
end
if se.has.user
    sp.i_valve = init.valve(se.idx.user,:);
end
if se.has.Pset_mfree
    sp.i_mdot_free = init.mdot_e(se.node_Pset_mfree.Edge,:);
    sp.i_mdot_free(~se.node_Pset_mfree.IsIn,:) = -sp.i_mdot_free(~se.node_Pset_mfree.IsIn,:);
end

end

