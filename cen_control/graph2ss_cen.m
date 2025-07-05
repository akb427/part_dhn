function [Ad,Bd] = graph2ss_cen(params,num,elems,mdot_e,ismat)
%GRAPH2SS_CEN Convert network description to discrete state space matrices
%
%   [Ad,Bd] = GRAPH2SS_CEN(params,num,elems,mdot_e,ismat)
%
%   DESCRIPTION:
%   Converts newtork information into state space matrices, containing
%   current mass flow rate in the pipes. Works for both a numeric matrix
%   (ismat=1) and casadi variables (ismat=2).
%
%   INPUTS:
%       params  - Structure of problem parameters.
%       num     - Structure containing numeric problem specifications.
%       elems   - Structure containing categorized element.
%       mdot_e  - Vector of mass flow rate in edges.
%       ismat   - Numeric indicator of casadi or numeric.
%
%   OUTPUTS:
%       Ad      - Discrete time state transition matrix
%       Bd      - Discrete time state-input matrix
%
%   REQUIREMENTS: CasADi (if ismat=2)

%#ok<*FNDSB> % needed in casadi
import casadi.*

%% Coefficients
if ismat==1
    c = zeros(num.nonuser,3);
elseif ismat==2
    c = sym(zeros(num.nonuser,3));
else
    c = MX(num.nonuser,3);
end
c(:,1) = mdot_e(elems.nonuser).*params.pipes(elems.nonuser,4);
c(:,2) = (params.h*pi*params.pipes(elems.nonuser,1).*params.pipes(elems.nonuser,2)).*params.pipes(elems.nonuser,4)./params.cp;
c(:,3) = -(c(:,1)+c(:,2));

%% A matrix
if ismat==1
    A = zeros(num.nonuser);
elseif ismat==2
    A = sym(zeros(num.nonuser));
else
    A = MX(num.nonuser,num.nonuser);
end

% Diagonal elements
A(1:num.nonuser+1:end) = c(:,3);

% Nonuser inedges
for row = find(elems.nonuser_ss.HasNonuserIn)'
    if elems.nonuser_ss.IsSingle(row)
        A(row,elems.nonuser_ss.Inedge_nonuser_idx{row}) = c(row,1);
    else
        A(row,elems.nonuser_ss.Inedge_nonuser_idx{row}) = mdot_e(elems.nonuser_ss.Inedge_nonuser{row})./mdot_e(elems.nonuser_ss.Edge(row))*c(row,1);
    end
end

%% B
% Preallocate B
if ismat==1
    B = zeros(num.nonuser,2);
elseif ismat==2
    B = sym(zeros(num.nonuser,2));
else
    B = MX(num.nonuser,2);
end

% Populate B

% Plant
idx_plant = find(elems.nonuser_ss.IsPlant);
B(idx_plant,1) = c(idx_plant,1);

% TsetR
for row = find(elems.nonuser_ss.HasUserIn)'
    % ratio of flow rate from user to edge flow (users can't be single)
    B(row,end) = mdot_e(elems.nonuser_ss.Inedge_user{row},1)/mdot_e(elems.nonuser_ss.Edge(row),1)*c(row,1);
end

% Heat transfer to ambient
E = c(:,2);

%% Discretization
if ismat
    Ad = (eye(size(A,1))+A*params.dt_T);
else
    Ad = (MX.eye(size(A,1))+A*params.dt_T);
end
Bd = params.dt_T*[B,E];
end