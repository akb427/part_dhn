function comm_link = get_commlink(part,I)
    ne = size(I,2);
    comm_link = false(1,ne);
    for idx_e = 1:ne
        pi = part(I(:,idx_e));
        comm_link(1,idx_e) = pi(1)==pi(2);
    end
end