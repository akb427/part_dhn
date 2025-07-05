function [sp] = parse_ig(init,se)
%PARSE_IG Get subsystem initial conditions from network level information.
%
%   [sp] = PARSE_IG(init,se)
%
%   DESCRIPTION:
%   Create the local initial conditions based on the network wide initial
%   conditions for a single subsystem.
%
%   INPUTS:
%       init    - Structure of initial conditions for problem.
%       se      - Structure of categorized subsystem elements.
%
%   OUTPUTS:
%       sp - Structure of subsystem parameters.

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

