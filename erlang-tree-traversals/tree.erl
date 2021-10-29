-module(tree).

-compile(export_all).

map(Fun, List) ->
    lists:foldr(fun (E, Acc) -> [Fun(E) | Acc] end, [], List).

-type tree(V) :: none | {node, V, tree(V), tree(V)}.

-spec tree_map(fun((tree(V)) -> tree(V)), tree(V)) -> tree(V).
tree_map(Fun, none) -> Fun(none);
tree_map(Fun, {node, V, Left, Right}) ->
    Fun({node, V, tree_map(Fun, Left), tree_map(Fun, Right)}).

test_tree_map() ->
    none = tree_map(fun (E) -> E end, none),
    {node, 2, none, none} = tree_map(fun
                                         (none) -> none;
                                         ({node, V, none, none}) -> {node, V * 2, none, none}
                                     end, {node, 1, none, none}),
    %% tree_map cannot express the following!
    %[5,4,3,2,1] = tree_map(fun (none) -> end, ).
    {node, 10,
     {node, 8,
      {node, 4, none, none},
      {node, 2, none, none}},
     {node, 6, none, none}} = tree_map(fun
                                           (none) -> none;
                                           ({node, V, Left, Right}) -> {node, V * 2, Left, Right}
                                       end,
                                       {node, 5,
                                        {node, 4,
                                         {node, 2, none, none},
                                         {node, 1, none, none}},
                                        {node, 3, none, none}}),
    {node, 4,
     none,
     {node, 2, none, none}} = tree_map(fun
                                           (none) -> none;
                                           ({node, 3, _, _}) -> none;
                                           ({node, _, _, _} = N) -> N
                                       end, {node, 4,
                                             {node, 3, none, none},
                                             {node, 2, none, none}}).

-spec tree_foldr(fun((tree(V), Acc) -> Acc), Acc, tree(V)) -> Acc.
tree_foldr(Fun, Acc, none) -> Fun(none, Acc);
tree_foldr(Fun, Acc, {node, V, Left, Right}) ->
    LAcc = tree_foldr(Fun, Acc, Left),
    RAcc = tree_foldr(Fun, LAcc, Right),
    Fun({node, V, none, none}, RAcc).

test_tree_foldr() ->
    none = tree_foldr(fun (E, _) -> E end, ok, none),
    {node, 2, none, none} = tree_foldr(fun
                                           (none, _) -> none;
                                           ({node, V, none, none}, _) -> {node, V * 2, none, none}
                                       end, ok, {node, 1, none, none}),
    %% tree_foldr cannot express the following!
    [5,4,3,2,1] = tree_foldr(fun
                                 (none, Acc) -> Acc;
                                 ({node, V, _, _}, Acc) -> [V | Acc]
                             end, [], {node, 5,
                                       {node, 3,
                                        {node, 1, none, none},
                                        {node, 2, none, none}},
                                       {node, 4, none, none}}),
    [5,4,2,1] = tree_foldr(fun
                               (none, Acc) -> Acc;
                               ({node, 3, _, _}, Acc) -> Acc;
                               ({node, V, _, _}, Acc) -> [V | Acc]
                           end, [], {node, 5,
                                     {node, 3,
                                      {node, 1, none, none},
                                      {node, 2, none, none}},
                                     {node, 4, none, none}}).
    %% As can be seen above, it's possible to skip a particular node
    %% from leaving a trace in the Acc, but it's not possible to completely
    %% cut off a particular tree branch, as we'd like to do below.
    %{node, 4,
    % none,
    % {node, 2, none, none}} = tree_foldr(fun
    %                                         (none) -> none;
    %                                       ({node, 3, _, _}) -> none;
    %                                       ({node, _, _, _} = N) -> N
    %                                     end, {node, 4,
    %                                           {node, 3, none, none},
    %                                           {node, 2, none, none}}).
