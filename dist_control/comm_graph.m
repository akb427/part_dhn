function [Gconv,Gred,adj_red] = comm_graph(elems,num,se)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Reduced Graph Storage
Gred = cell(1,3);
adj_red = cell(1,3);

%% Mass Flow Reduced Graph
adj_red{1} = false(num.sg+2);
for idx_sg = 1:num.sg
    if se{idx_sg}.has.refP
        adj_red{1}(idx_sg,num.sg+1) = 1;
    end
    if se{idx_sg}.has.Pset_mfree
        adj_red{1}(idx_sg,unique(se{idx_sg}.node_Pset_mfree.Graph)) = 1;
    end
end
adj_red{1}(elems.idx_plant,num.sg+2) = 1;
Gred{1} = digraph(adj_red{1});

%% Pressure Reduced Graph
adj_red{2} = false(num.sg+2);
for idx_sg = 1:num.sg
    if se{idx_sg}.has.refP
        adj_red{2}(num.sg+1,idx_sg) = 1;
    end
    if se{idx_sg}.has.Pset_mfree
        adj_red{2}(unique(se{idx_sg}.node_Pset_mfree.Graph),idx_sg) = 1;
    end
end
adj_red{2}(num.sg+2,elems.idx_plant&~elems.idx_plantP) = 1;
adj_red{2}(elems.idx_plantP,num.sg+2) = 1;
Gred{2} = digraph(adj_red{2});

%% Temperature Reduced Graph
adj_red{3} = false(num.sg+2);
for idx_sg = 1:num.sg
    if se{idx_sg}.has.refP
        adj_red{3}(idx_sg,num.sg+1) = 1;
    end
    if se{idx_sg}.has.Tin
        adj_red{3}(unique(cell2mat(se{idx_sg}.node_T.Graph')),idx_sg) = 1;
    end
end
adj_red{3}(num.sg+2,elems.idx_plant) = 1;
Gred{3} = digraph(adj_red{3});

%% Create Convergence Order Graph

Gred{3} = rmedge(Gred{3}, outedges(Gred{3},num.sg+2)); % Remove temp out of plant
Gred{1} = rmedge(Gred{1}, inedges(Gred{1},num.sg+2)); % Remove flow in to plant

% Combine Gred
Gconv = Gred{1};
Gconv = addedge(Gconv,Gred{2}.Edges);
Gconv = addedge(Gconv,Gred{3}.Edges);
Gconv = rmnode(Gconv,num.sg+1);

% Merge root and pressure driver
edge = Gconv.Edges;
edge{:,:}(edge{:,:}==num.sg+1) = find(elems.idx_plantP);
Gconv = digraph(edge,'omitselfloops');

%% Troubleshoot Plotting
% 
% figure;
% H = plot(G,'NodeLabel',G.Nodes.Idx,'EdgeLabel',G.Edges.Idx,'layout','layered','EdgeColor','k','NodeColor','k','EdgeAlpha',1);
% clr = lines(num.sg);
% for idx_sg = 1:num.sg
%     highlight(H,'Edges',sG{idx_sg}.Edges.Idx,'EdgeColor',clr(idx_sg,:),'LineWidth',5)
% end
% figure;
% H = plot(Gred,'layout','layered','Sources',num.sg+2,'Sinks',num.sg+1,'EdgeColor','k','NodeColor','k','EdgeAlpha',1);
% for idx_sg = 1:num.sg
%     highlight(H,idx_sg,'NodeColor',clr(idx_sg,:),'MarkerSize',8)
% end


end