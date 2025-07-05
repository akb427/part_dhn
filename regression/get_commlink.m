function [comm_link] = get_commlink(part,I)
%GET_COMMLINK  Communication links between partitioned elements.
%
%   [comm_link] = GET_COMMLINK(part,I)
%
%   DESCRIPTION:
%   Get information about what elements have knowledge of others preferred
%   behaviors based on the system partitioning.
%
%   INPUTS:
%       part    - Vector of partition being considered
%       I       - Graph incidence matrix
%
%   OUTPUTS:
%       comm_link - Binary vector of if communication exists between
%       elements

%% Find links 
    ne = size(I,2); % number of elements
    comm_link = false(1,ne);
    for idx_e = 1:ne
        pi = part(I(:,idx_e));
        comm_link(1,idx_e) = pi(1)==pi(2);
    end
end