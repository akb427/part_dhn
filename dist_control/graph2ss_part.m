function [Ad,Bd] = graph2ss_part(params,sparams,sn,se,mdot_e,mdot_in,ismat)
%GRAPH2SS Convert graph, parameters and mass flow rates to state space
%matrices
%   G: graph of network
%   params: network params
%   n: strucutre to store size elements
%   mdot_e: mass flow rate in edges
%   ismat: true if no casadi variables are to be used

%#ok<*FNDSB> % needed in casadi
import casadi.*

%% Coefficients
if ismat
    c = zeros(sn.nonuser,3);
else
    c = MX(sn.nonuser,3);
end
c(:,1) = mdot_e(se.nonuser.Edge_LNC).*sparams.pipes(se.nonuser.Edge_LNC,4);
c(:,2) = (params.h*pi*sparams.pipes(se.nonuser.Edge_LNC,1).*sparams.pipes(se.nonuser.Edge_LNC,2)).*sparams.pipes(se.nonuser.Edge_LNC,4)./params.cp;
c(:,3) = -(c(:,1)+c(:,2));

%% A matrix
if ismat
    A = zeros(sn.nonuser);
else
    A = MX(sn.nonuser,sn.nonuser);
end

% Diagonal elements
A(1:sn.nonuser+1:end) = c(:,3);
% Local nonuser inedges
for row = find(se.nonuser.HasNonuserIn)'
    if se.nonuser.IsSingle(row)
        A(row,se.nonuser.Inedge_nonuser_idx{row}) = c(row,1);
    else
        A(row,se.nonuser.Inedge_nonuser_idx{row}) = mdot_e(se.nonuser.Inedge_nonuser_LNC{row})./mdot_e(se.nonuser.Edge_LNC(row))*c(row,1);
    end
end

%% B
% Preallocate B
num_colB = se.has.plant+sn.node_Tin+1; % columns for plant, neighbors, TsetR
if ismat
    B = zeros(sn.nonuser,num_colB);
else
    B = MX(sn.nonuser,num_colB);
end

% Populate B

% Plant
if se.has.plant % (always single)
    B(find(se.nonuser.IsPlant),1) = c(find(se.nonuser.IsPlant),1);
end

% Neighbors
for row = find(se.nonuser.HasNonLocal)'
    if se.nonuser.IsSingle(row)
        B(row,se.nonuser.Idx_Tin(row)+se.has.plant) = c(row,1);
    else
        B(row,se.nonuser.Idx_Tin(row)+se.has.plant) = mdot_in(se.nonuser.Idx_Tin(row))/mdot_e(se.nonuser.Edge_LNC(row))*c(row,1);
    end
end

% TsetR
for row = find(se.nonuser.HasUserIn)'
    % ratio of flow rate from user to edge flow (users can't be single)
    B(row,end) = mdot_e(se.nonuser.Inedge_user_LNC{row},1)/mdot_e(se.nonuser.Edge_LNC(row),1)*c(row,1);
end

% Heat transfer to ambient
E = c(:,2);

%% Discretization

Ad = (MX.eye(size(A,1))+A*params.dt_T);
Bd = params.dt_T*[B,E];

end