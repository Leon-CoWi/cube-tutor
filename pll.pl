% pll.pl
% PLL: the top is one colour, now put the last-layer pieces in their right spots.
% After this the whole cube is solved. Uses known recipes and a table, like oll.pl.

:- ensure_loaded(oll).

% pll_alg/2: the 6 known PLL recipes. Each keeps everything below and the top colour
%   safe.
pll_alg(ua, "R U' R U R U R U' R' U' R2").
pll_alg(ub, "R2 U R U R' U' R' U' R' U R'").
pll_alg(h,  "R2 U2 R U2 R2 U2 R2 U2 R U2 R2").
pll_alg(z,  "R U' R U R U R U' R' U' R2 U' R U' R U R U R U' R' U' R2 U").
pll_alg(t,  "R U R' U' R' F R2 U' R' U' R U R' F'").
pll_alg(y,  "F R U' R' U' R U R' F' R U R' U' R' F R F'").

% pll_signature/3: how many top corners and edges each recipe moves.
pll_signature(ua, 0, 3).
pll_signature(ub, 0, 3).
pll_signature(h,  0, 4).
pll_signature(z,  0, 4).
pll_signature(t,  2, 2).
pll_signature(y,  2, 2).

% pll_names(Names): all the recipe names.
pll_names(Names) :-
    findall(Name, pll_alg(Name, _), Names).

% pll_moves(Name, Moves): a recipe as a list of moves.
pll_moves(Name, Moves) :-
    pll_alg(Name, Text),
    parse_moves(Text, Moves).

% pll_list: prints the recipes, one per line.
pll_list :-
    forall(pll_alg(Name, Text),
           ( pll_moves(Name, Moves),
             length(Moves, N),
             format("~w: ~w (~w moves)~n", [Name, Text, N]) )).

% piece_home(Solved, Cube, Positions): true if a piece looks like it does on a solved
%   cube.
piece_home(Solved, Cube, Positions) :-
    maplist(sticker_at(Solved), Positions, Colours),
    maplist(sticker_at(Cube), Positions, Colours).

% moved_counts(Cube, Corners, Edges): how many of the 4 top corners and 4 top edges are
%   not at home.
moved_counts(Cube, Corners, Edges) :-
    solved_cube(Solved),
    findall(N, ( member(N, [1,2,3,4]),
                 corner(N, _, Ps),
                 \+ piece_home(Solved, Cube, Ps) ),
            MovedCorners),
    length(MovedCorners, Corners),
    findall(N, ( member(N, [1,2,3,4]),
                 edge(N, _, Ps),
                 \+ piece_home(Solved, Cube, Ps) ),
            MovedEdges),
    length(MovedEdges, Edges).

% good_pll(Name): a recipe keeps the lower layers and top colour, and moves the pieces
%   it should.
good_pll(Name) :-
    pll_alg(Name, Text),
    scramble_cube(Text, Cube),
    cross_solved(Cube),
    f2l_pairs_solved(Cube, 4),
    oll_solved(Cube),
    moved_counts(Cube, Corners, Edges),
    pll_signature(Name, Corners, Edges).

% test_pll_algs: checks every recipe, and that no two share a name.
test_pll_algs :-
    pll_names(Names),
    length(Names, Count),
    sort(Names, Unique),
    length(Unique, Count),
    findall(Name, ( member(Name, Names), \+ good_pll(Name) ), Bad),
    (   Bad == []
    ->  format("~w PLL algorithms: names unique, each keeps the cross, 4 pairs and oriented top, and moves the pieces it should~n", [Count])
    ;   format("Problem with: ~w~n", [Bad]),
        fail
    ).

% pll_pattern_of(Cube, Pattern): the colour letters at the 21 last-layer places.
pll_pattern_of(Cube, Pattern) :-
    ll_positions(Positions),
    maplist(sticker_at(Cube), Positions, Pattern).

% derive_pll_pattern(Name, Post, Pattern): the mess a recipe fixes: turn the top, then
%   do the recipe backwards.
derive_pll_pattern(Name, Post, Pattern) :-
    solved_cube(Solved),
    pll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Post, Solved, Turned),
    apply_moves(Inverse, Turned, Cube),
    pll_pattern_of(Cube, Pattern).

% pll_case/3: one fact per recipe and last top turn: the pattern it fixes (24 in all).
:- dynamic pll_case/3.

% build_pll_cases: fills pll_case when the file loads.
build_pll_cases :-
    retractall(pll_case(_, _, _)),
    forall(( pll_alg(Name, _), pre_turn(Post) ),
           ( derive_pll_pattern(Name, Post, Pattern),
             assertz(pll_case(Name, Post, Pattern)) )).
:- build_pll_cases.

% pll_show(Pattern): draws a pattern as seen from above (front at the bottom).
pll_show(Pattern) :-
    forall(member(Row, [ [ 0,18,17,16, 0],
                         [19, 1, 2, 3,15],
                         [20, 4, 5, 6,14],
                         [21, 7, 8, 9,13],
                         [ 0,10,11,12, 0] ]),
           ( forall(member(I, Row), pll_show_cell(Pattern, I)),
             nl )).

% pll_show_cell/2: prints one square of the drawing.
pll_show_cell(_, 0) :- !,
    write('  ').

pll_show_cell(_, I) :-
    I =< 9, !,
    write('# ').

pll_show_cell(Pattern, I) :-
    nth1(I, Pattern, Letter),
    format("~w ", [Letter]).

% pll_show_case(Name): draws the mess a recipe fixes.
pll_show_case(Name) :-
    pll_case(Name, [], Pattern),
    format("Case ~w:~n", [Name]),
    pll_show(Pattern).

% test_pll_patterns: there are 24 patterns, and each recipe fixes its own.
test_pll_patterns :-
    solved_cube(Solved),
    pll_pattern_of(Solved, Done),
    findall(N-Post, pll_case(N, Post, _), Cases),
    length(Cases, Count),
    pll_names(Names),
    length(Names, K),
    Count =:= 4 * K,
    forall(pll_case(Name, Post, Pattern),
           ( Pattern \== Done,
             pll_moves(Name, Moves),
             inverse_moves(Moves, Inverse),
             apply_moves(Post, Solved, Turned),
             apply_moves(Inverse, Turned, Cube1),
             apply_moves(Moves, Cube1, Cube2),
             pll_pattern_of(Cube2, After),
             pll_pattern_of(Turned, Want),
             After == Want )),
    findall(P, pll_case(_, _, P), Patterns),
    sort(Patterns, Distinct),
    length(Distinct, D),
    format("~w case patterns (~w algorithms x 4 final U turns): none is already finished, each algorithm turns its case into the finished cube up to the U turn~n", [Count, K]),
    format("Distinct patterns: ~w of ~w~n", [D, Count]).

% test_pll_known: H and T patterns worked out by hand.
test_pll_known :-
    pll_case(h, [], PH),
    PH == [u,u,u,u,u,u,u,u,u, f,b,f, r,l,r, b,f,b, l,r,l],
    pll_case(t, [], PT),
    PT == [u,u,u,u,u,u,u,u,u, f,f,r, b,l,f, r,b,b, l,r,l],
    format("H and T patterns correct (worked out by hand)~n").

% test_pll_cases: runs the pattern tests.
test_pll_cases :-
    test_pll_patterns,
    test_pll_known,
    format("PLL pattern tests passed~n").

% move_parts(Move, Face, Quarters): splits a move into its face and number of quarter
%   turns.
move_parts(Move, Face, Quarters) :-
    atom_chars(Move, [FaceChar|Rest]),
    atom_chars(Face, [FaceChar]),
    (   Rest == []     -> Quarters = 1
    ;   Rest == ['2']  -> Quarters = 2
    ;   Rest == [p]    -> Quarters = 3
    ).

% parts_move/3: joins a face and quarter turns back into a move.
parts_move(Face, 1, Face).
parts_move(Face, 2, Move) :- atom_concat(Face, '2', Move).
parts_move(Face, 3, Move) :- atom_concat(Face, p, Move).

% merge_moves/2: joins neighbouring turns of the same face (U U becomes U2, U U'
%   vanishes).
merge_moves([], []).

merge_moves([M|Ms], Out) :-
    merge_moves(Ms, Rest),
    (   Rest = [N|Rest1],
        move_parts(M, Face, Q1),
        move_parts(N, Face, Q2)
    ->  Q is (Q1 + Q2) mod 4,
        (   Q =:= 0
        ->  Out = Rest1
        ;   parts_move(Face, Q, New),
            Out = [New|Rest1]
        )
    ;   Out = [M|Rest]
    ).

% test_merge_moves: checks the joining on 5 examples.
test_merge_moves :-
    merge_moves([u, u], [u2]),
    merge_moves([u, up], []),
    merge_moves([u2, u2], []),
    merge_moves([r, u, u, up, u2], [r, up]),
    merge_moves([r, u, rp], [r, u, rp]),
    format("Move joining correct for 5 examples~n").

% pll_match(Cube, Name, Pre, Post): finds a recipe that fits after a starting top turn.
pll_match(Cube, Name, Pre, Post) :-
    pre_turn(Pre),
    apply_moves(Pre, Cube, Turned),
    pll_pattern_of(Turned, Pattern),
    pll_case(Name, Post, Pattern).

% pll_one_alg(Cube, Name, Moves): the shortest way to solve with ONE recipe (turns
%   joined). Fails if none fits.
pll_one_alg(Cube, Name, Moves) :-
    findall(Len-Name0-Merged,
            ( pll_match(Cube, Name0, Pre, Post),
              pll_moves(Name0, Alg),
              inverse_moves(Post, Final),
              append([Pre, Alg, Final], Moves0),
              merge_moves(Moves0, Merged),
              length(Merged, Len) ),
            Found),
    Found \== [],
    msort(Found, [_-Name-Moves|_]).

% pll_auf(Cube, Turn): true if one top turn is all that is left.
pll_auf(Cube, Turn) :-
    solved_cube(Solved),
    pre_turn(Turn),
    apply_moves(Turn, Cube, After),
    After == Solved,
    !.

% pll_fixed_ok(Cube, Moves): after the moves the whole cube is solved.
pll_fixed_ok(Cube, Moves) :-
    apply_moves(Moves, Cube, After),
    solved_cube(Solved),
    After == Solved.

% pll_match_report(Scramble): scrambles a cube and says how the last layer gets solved.
pll_match_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    (   pll_auf(Cube, [])
    ->  format("The cube is already solved~n")
    ;   pll_auf(Cube, Turn)
    ->  scramble_text(Turn, Text),
        format("Only a U turn is needed: ~w~n", [Text])
    ;   pll_one_alg(Cube, Name, Moves)
    ->  length(Moves, N),
        scramble_text(Moves, Text),
        format("Case: ~w. Moves (~w): ~w~n", [Name, N, Text]),
        (   pll_fixed_ok(Cube, Moves)
        ->  format("Check on the real cube: solved~n")
        ;   format("Check on the real cube: FAILED~n")
        )
    ;   format("No single table algorithm fixes this last layer~n")
    ).

% pll_case_cube(Name, Post, Cube): the cube a recipe fixes.
pll_case_cube(Name, Post, Cube) :-
    solved_cube(Solved),
    pll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Post, Solved, Turned),
    apply_moves(Inverse, Turned, Cube).

% test_pll_match_cases: every case with every starting turn must be matched and solved.
test_pll_match_cases :-
    findall(Name-Post-Pre,
            ( pll_case(Name, Post, _), pre_turn(Pre) ),
            Combos),
    length(Combos, Count),
    forall(member(Name-Post-Pre, Combos),
           ( pll_case_cube(Name, Post, Case),
             inverse_moves(Pre, Back),
             apply_moves(Back, Case, Cube),
             pll_one_alg(Cube, _, Moves),
             pll_fixed_ok(Cube, Moves) )),
    format("6 algorithms x 4 final turns x 4 starting turns = ~w cubes: each one matched and solved by a table algorithm~n", [Count]).

% random_pll_cube(Cube): a random last layer: 2 random recipes, then a random top turn.
random_pll_cube(Cube) :-
    solved_cube(Solved),
    pll_scramble(2, Solved, Cube1),
    findall(T, pre_turn(T), Turns),
    random_member(Turn, Turns),
    apply_moves(Turn, Cube1, Cube).

% pll_scramble/3: does N random recipes, each after a random top turn.
pll_scramble(0, Cube, Cube).

pll_scramble(N, Cube0, Cube) :-
    N > 0,
    pll_names(Names),
    random_member(Name, Names),
    findall(T, pre_turn(T), Turns),
    random_member(Turn, Turns),
    pll_moves(Name, Moves),
    apply_moves(Turn, Cube0, Cube1),
    apply_moves(Moves, Cube1, Cube2),
    N1 is N - 1,
    pll_scramble(N1, Cube2, Cube).

% test_pll_match_random(N): N random last layers: solved, one turn, no match (allowed),
%   or matched and solved.
test_pll_match_random(N) :-
    findall(R,
            ( between(1, N, _),
              random_pll_cube(Cube),
              (   pll_auf(Cube, [])
              ->  R = solved
              ;   pll_auf(Cube, _)
              ->  R = only_u
              ;   pll_one_alg(Cube, _, Moves)
              ->  (   pll_fixed_ok(Cube, Moves)
                  ->  R = fixed
                  ;   R = broken
                  )
              ;   R = no_match
              ) ),
            Rs),
    length(Rs, N),
    \+ memberchk(broken, Rs),
    msort(Rs, Sorted),
    sort(Rs, Kinds),
    findall(K-C, ( member(K, Kinds),
                   include(==(K), Sorted, Same),
                   length(Same, C) ),
            Counts),
    format("~w random last layers. Results: ~w~n", [N, Counts]).

% test_pll_matching: runs the matching tests.
test_pll_matching :-
    test_merge_moves,
    test_pll_match_cases,
    test_pll_match_random(200),
    format("PLL matching tests passed~n").

% pll_option/3: one way to use a recipe: its moves, and how they shuffle the 21
%   stickers.
:- dynamic pll_option/3.

% build_pll_options: fills pll_option when the file loads.
build_pll_options :-
    retractall(pll_option(_, _, _)),
    forall(( pll_alg(Name, _), pre_turn(Pre) ),
           ( pll_moves(Name, Alg),
             append(Pre, Alg, Moves),
             ll_map(Moves, Map),
             assertz(pll_option(Name, Moves, Map)) )).
:- build_pll_options.

% perm_parity(List, Parity): 0 if the list is shuffled an even way, 1 if odd.
perm_parity(List, Parity) :-
    findall(x, ( nth1(I, List, A), nth1(J, List, B), I < J, A > B ), Inversions),
    length(Inversions, N),
    Parity is N mod 2.

% slot_places/3: the sticker positions of a top corner or edge slot.
slot_places(corner, Slot, Places) :- corner(Slot, _, Places).
slot_places(edge,   Slot, Places) :- edge(Slot, _, Places).

% place_slot(Kind, Perm, Solved, I, Cube0, Cube): puts the piece of another slot into
%   this slot.
place_slot(Kind, Perm, Solved, I, Cube0, Cube) :-
    nth1(I, Perm, Source),
    slot_places(Kind, I, Target),
    slot_places(Kind, Source, From),
    maplist(sticker_at(Solved), From, Colours),
    put_all(Target, Colours, Cube0, Cube).

% permute_slots(Kind, Perm, Solved, Cube0, Cube): does that for slots 1 to 4.
permute_slots(Kind, Perm, Solved, Cube0, Cube) :-
    numlist(1, 4, Slots),
    foldl(place_slot(Kind, Perm, Solved), Slots, Cube0, Cube).

% all_pll_cubes(Cubes): one cube for every legal way to arrange the top pieces (288).
all_pll_cubes(Cubes) :-
    solved_cube(Solved),
    numlist(1, 4, Slots),
    findall(Cube,
            ( permutation(Slots, CornerPerm),
              permutation(Slots, EdgePerm),
              perm_parity(CornerPerm, Parity),
              perm_parity(EdgePerm, Parity),
              permute_slots(corner, CornerPerm, Solved, Solved, Cube1),
              permute_slots(edge, EdgePerm, Solved, Cube1, Cube) ),
            Cubes).

% pll_dist/2, pll_next/3: tables: how many recipes a pattern needs (pll_dist), and the
%   best recipe to use next (pll_next).
:- dynamic pll_dist/2, pll_next/3.

% build_pll_table: fills the table, starting from the solved cube and going outward.
build_pll_table :-
    retractall(pll_dist(_, _)),
    retractall(pll_next(_, _, _)),
    all_pll_cubes(Cubes),
    maplist(pll_pattern_of, Cubes, Patterns0),
    sort(Patterns0, Patterns),
    solved_cube(Solved),
    findall(Goal,
            ( pre_turn(Turn),
              apply_moves(Turn, Solved, Turned),
              pll_pattern_of(Turned, Goal) ),
            Goals),
    forall(member(G, Goals), assertz(pll_dist(G, 0))),
    pll_fill(Patterns, 0).

% pll_fill(Patterns, D): gives distance D+1 to patterns that reach a distance D pattern
%   with one recipe.
pll_fill(Patterns, D) :-
    D1 is D + 1,
    findall(Len-P-opt(Name, Moves),
            ( member(P, Patterns),
              \+ pll_dist(P, _),
              pll_option(Name, Moves, Map),
              pattern_step(P, Map, Q),
              pll_dist(Q, D),
              length(Moves, Len) ),
            Found0),
    msort(Found0, Found1),
    pick_first(Found1, [], Found),
    (   Found == []
    ->  true
    ;   forall(member(P-opt(Name, Moves), Found),
               ( assertz(pll_dist(P, D1)),
                 assertz(pll_next(P, Name, Moves)) )),
        pll_fill(Patterns, D1)
    ).
:- build_pll_table.

% pll_solve_steps(Cube, Steps): the steps to solve the last layer: nothing, one top
%   turn, one recipe, or a chain.
pll_solve_steps(Cube, Steps) :-
    (   pll_auf(Cube, [])
    ->  Steps = []
    ;   pll_auf(Cube, Turn)
    ->  Steps = [step(pll, auf, Turn)]
    ;   pll_one_alg(Cube, Name, Moves)
    ->  Steps = [step(pll, Name, Moves)]
    ;   pll_chain(Cube, Steps)
    ).

% pll_chain/2: uses the table: do the best recipe, check it is one step closer, repeat.
pll_chain(Cube, [step(pll, Name, Merged)|Rest]) :-
    pll_pattern_of(Cube, Pattern),
    pll_dist(Pattern, D),
    pll_next(Pattern, Name, Moves),
    apply_moves(Moves, Cube, Cube1),
    pll_pattern_of(Cube1, Pattern1),
    pll_dist(Pattern1, D1),
    D1 =:= D - 1,
    merge_moves(Moves, Merged),
    pll_solve_steps(Cube1, Rest).

% pll_steps_moves/2: all the moves of all the steps, in order.
pll_steps_moves([], []).

pll_steps_moves([step(_, _, M)|Steps], Moves) :-
    pll_steps_moves(Steps, Rest),
    append(M, Rest, Moves).

% solve_pll(Cube, Moves): all the PLL moves in one list.
solve_pll(Cube, Moves) :-
    pll_solve_steps(Cube, Steps),
    pll_steps_moves(Steps, Moves).

% pll_solve_report(Scramble): scrambles, solves the last layer and checks it on the real
%   cube.
pll_solve_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    (   pll_solve_steps(Cube, Steps)
    ->  (   Steps == []
        ->  format("The cube is already solved~n")
        ;   forall(nth1(I, Steps, step(_, Case, Moves)),
                   ( length(Moves, N),
                     scramble_text(Moves, Text),
                     format("Step ~w (~w): ~w moves: ~w~n", [I, Case, N, Text]) )),
            pll_steps_moves(Steps, All),
            (   pll_fixed_ok(Cube, All)
            ->  format("Check on the real cube: solved~n")
            ;   format("Check on the real cube: FAILED~n")
            )
        )
    ;   format("This cube is not covered (are the first two layers solved and the top oriented?)~n")
    ).

% test_pll_table: there are exactly 288 arrangements and each has a way to solved.
test_pll_table :-
    all_pll_cubes(Cubes),
    length(Cubes, 288),
    forall(member(C, Cubes), legal_cube(C)),
    maplist(pll_pattern_of, Cubes, Patterns0),
    sort(Patterns0, Patterns),
    length(Patterns, 288),
    findall(P, ( member(P, Patterns), \+ pll_dist(P, _) ), Missing),
    length(Missing, NotCovered),
    (   NotCovered =:= 0
    ->  findall(D, pll_dist(_, D), Ds),
        msort(Ds, SortedDs),
        sort(Ds, Kinds),
        findall(K-N, ( member(K, Kinds),
                       include(==(K), SortedDs, Same),
                       length(Same, N) ),
                Counts),
        format("288 last-layer arrangements, all covered. Algorithms needed (number-of-arrangements): ~w~n", [Counts])
    ;   format("Not covered: ~w of 288 arrangements~n", [NotCovered]),
        fail
    ).

% test_pll_all_cubes: solves all 288 cubes and checks each on the real cube.
test_pll_all_cubes :-
    all_pll_cubes(Cubes),
    findall(N,
            ( member(Cube, Cubes),
              pll_solve_steps(Cube, Steps),
              pll_steps_moves(Steps, Moves),
              pll_fixed_ok(Cube, Moves),
              length(Steps, N) ),
            Ns),
    length(Ns, 288),
    max_list(Ns, Most),
    sum_list(Ns, Total),
    Avg is Total / 288,
    format("All 288 cubes solved and checked on the full cube. Most steps: ~w, average: ~2f~n", [Most, Avg]).

% test_pll_random(N): N random last layers must all be solved.
test_pll_random(N) :-
    findall(Steps,
            ( between(1, N, _),
              random_pll_cube(Cube),
              pll_solve_steps(Cube, Steps),
              pll_steps_moves(Steps, Moves),
              pll_fixed_ok(Cube, Moves) ),
            All),
    length(All, N),
    format("~w random last layers: all solved and checked on the full cube~n", [N]).

% test_pll_solver: runs the solver tests.
test_pll_solver :-
    test_pll_table,
    test_pll_all_cubes,
    test_pll_random(200),
    format("PLL solver tests passed~n").