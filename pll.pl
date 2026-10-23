% pll.pl
% PLL = Permute the Last Layer.
% Goal: the top face is already one colour. Now move the last-layer pieces
% into their right places. After this the whole cube is solved.
% This file loads oll.pl, which gives us the helpers for patterns and U turns.
:- ensure_loaded(oll).

% ---------- The list of algorithms ----------
% pll_alg(Name, Text): a named algorithm.
% Every one of them keeps the cross, the 4 F2L pairs and the finished top.
% They only move last-layer pieces around.
pll_alg(ua, "R U' R U R U R U' R' U' R2").
pll_alg(ub, "R2 U R U R' U' R' U' R' U R'").
pll_alg(h,  "R2 U2 R U2 R2 U2 R2 U2 R U2 R2").
pll_alg(z,  "R U' R U R U R U' R' U' R2 U' R U' R U R U R U' R' U' R2 U").
pll_alg(t,  "R U R' U' R' F R2 U' R' U' R U R' F'").
pll_alg(y,  "F R U' R' U' R U R' F' R U R' U' R' F R F'").

% pll_signature(Name, Corners, Edges)
% On a solved cube, how many of the 4 top corners and 4 top edges
% does the algorithm move away from home?
pll_signature(ua, 0, 3).
pll_signature(ub, 0, 3).
pll_signature(h,  0, 4).
pll_signature(z,  0, 4).
pll_signature(t,  2, 2).
pll_signature(y,  2, 2).

% pll_names(-Names): all the algorithm names, in the same order as above.
pll_names(Names) :-
    findall(Name, pll_alg(Name, _), Names).

% pll_moves(+Name, -Moves): the algorithm turned into a list of moves.
pll_moves(Name, Moves) :-
    pll_alg(Name, Text),
    parse_moves(Text, Moves).

% pll_list: prints the list, one line per algorithm.
pll_list :-
    forall(pll_alg(Name, Text),
           ( pll_moves(Name, Moves),
             length(Moves, N),
             format("~w: ~w (~w moves)~n", [Name, Text, N]) )).

% ---------- Test: the list of algorithms ----------

% piece_home(+Solved, +Cube, +Positions)
% The piece whose stickers are at Positions looks exactly like it does
% on a solved cube (so it is at home).
piece_home(Solved, Cube, Positions) :-
    maplist(sticker_at(Solved), Positions, Colours),
    maplist(sticker_at(Cube), Positions, Colours).

% moved_counts(+Cube, -Corners, -Edges)
% How many of the 4 top corners and the 4 top edges are NOT at home.
% (Slots 1 to 4 of corner/3 and edge/3 are the top ones.)
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

% good_pll(+Name)
% On a solved cube the algorithm must keep the cross, the 4 pairs and the
% finished top, and it must move exactly as many corners and edges as
% its signature says.
good_pll(Name) :-
    pll_alg(Name, Text),
    scramble_cube(Text, Cube),
    cross_solved(Cube),
    f2l_pairs_solved(Cube, 4),
    oll_solved(Cube),
    moved_counts(Cube, Corners, Edges),
    pll_signature(Name, Corners, Edges).

% test_pll_algs
% Checks every algorithm, and that no two share a name.
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

% ---------- Patterns made from the inverse ----------

% pll_pattern_of(+Cube, -Pattern)
% The colour letters at the 21 last-layer places (the same places as
% ll_positions in oll.pl): the 9 top stickers, then the top rows of F, R, B
% and L. When the top is finished, the first 9 are all u. The other 12 tell
% where each piece sits.
pll_pattern_of(Cube, Pattern) :-
    ll_positions(Positions),
    maplist(sticker_at(Cube), Positions, Pattern).

% derive_pll_pattern(+Name, +Post, -Pattern)
% The mess that algorithm Name fixes (up to a last U turn called Post).
% Start from a solved cube, turn the top layer by Post, then do the
% algorithm BACKWARDS.
derive_pll_pattern(Name, Post, Pattern) :-
    solved_cube(Solved),
    pll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),                 % inverse_moves is in oll.pl
    apply_moves(Post, Solved, Turned),
    apply_moves(Inverse, Turned, Cube),
    pll_pattern_of(Cube, Pattern).

% pll_case(Name, Post, Pattern)
% 6 algorithms x 4 last turns = 24 facts, built when this file loads.
% Post is [], [u], [u2] or [up].
:- dynamic pll_case/3.

build_pll_cases :-
    retractall(pll_case(_, _, _)),
    forall(( pll_alg(Name, _), pre_turn(Post) ),   % pre_turn is in oll.pl
           ( derive_pll_pattern(Name, Post, Pattern),
             assertz(pll_case(Name, Post, Pattern)) )).

:- build_pll_cases.

% ---------- Looking at a pattern ----------

% pll_show(+Pattern)
% Draws it as if you look down on the cube, with the F face at the bottom.
% The middle 3x3 is the top face (#). The edge around it shows colour letters.
% The numbers are places in the pattern list (0 = empty corner of the drawing).
pll_show(Pattern) :-
    forall(member(Row, [ [ 0,18,17,16, 0],
                         [19, 1, 2, 3,15],
                         [20, 4, 5, 6,14],
                         [21, 7, 8, 9,13],
                         [ 0,10,11,12, 0] ]),
           ( forall(member(I, Row), pll_show_cell(Pattern, I)),
             nl )).

pll_show_cell(_, 0) :- !,
    write('  ').
pll_show_cell(_, I) :-
    I =< 9, !,
    write('# ').
pll_show_cell(Pattern, I) :-
    nth1(I, Pattern, Letter),
    format("~w ", [Letter]).

% pll_show_case(+Name)
% Draws the mess that algorithm Name fixes (with no last U turn needed).
pll_show_case(Name) :-
    pll_case(Name, [], Pattern),
    format("Case ~w:~n", [Name]),
    pll_show(Pattern).

% ---------- Tests: the patterns ----------

% test_pll_patterns
% There must be 24 patterns and none is the finished cube.
% Each algorithm must turn each of its patterns into the finished cube,
% up to the last U turn.
test_pll_patterns :-
    solved_cube(Solved),
    pll_pattern_of(Solved, Done),
    findall(N-Post, pll_case(N, Post, _), Cases),
    length(Cases, Count),
    pll_names(Names),
    length(Names, K),
    Count =:= 4 * K,                               % every algorithm, every last turn
    forall(pll_case(Name, Post, Pattern),
           ( Pattern \== Done,                     % the case is not already solved
             pll_moves(Name, Moves),
             inverse_moves(Moves, Inverse),
             apply_moves(Post, Solved, Turned),
             apply_moves(Inverse, Turned, Cube1),    % make the mess...
             apply_moves(Moves, Cube1, Cube2),       % ...then fix it
             pll_pattern_of(Cube2, After),
             pll_pattern_of(Turned, Want),           % up to the last U turn
             After == Want )),
    findall(P, pll_case(_, _, P), Patterns),
    sort(Patterns, Distinct),
    length(Distinct, D),
    format("~w case patterns (~w algorithms x 4 final U turns): none is already finished, each algorithm turns its case into the finished cube up to the U turn~n", [Count, K]),
    format("Distinct patterns: ~w of ~w~n", [D, Count]).

% test_pll_known
% Two patterns I worked out by hand, face by face
% (F row, R row, B row, L row; the first 9 are the top, all u).
%   H swaps UF with UB and UR with UL, so the middle sticker of each side
%   shows the colour of the opposite side.
%   T swaps the corners UFR and UBR and the edges UR and UL.
test_pll_known :-
    pll_case(h, [], PH),
    PH == [u,u,u,u,u,u,u,u,u, f,b,f, r,l,r, b,f,b, l,r,l],
    pll_case(t, [], PT),
    PT == [u,u,u,u,u,u,u,u,u, f,f,r, b,l,f, r,b,b, l,r,l],
    format("H and T patterns correct (worked out by hand)~n").

test_pll_cases :-
    test_pll_patterns,
    test_pll_known,
    format("PLL pattern tests passed~n").

% ---------- Joining turns that sit next to each other ----------

% move_parts(+Move, -Face, -Quarters)
% Splits a move into its face and how many quarter turns.
% u -> u,1    u2 -> u,2    up -> u,3
move_parts(Move, Face, Quarters) :-
    atom_chars(Move, [FaceChar|Rest]),
    atom_chars(Face, [FaceChar]),
    (   Rest == []     -> Quarters = 1
    ;   Rest == ['2']  -> Quarters = 2
    ;   Rest == [p]    -> Quarters = 3
    ).

% parts_move(+Face, +Quarters, -Move)
% The other way round: face + quarter turns -> move.
parts_move(Face, 1, Face).
parts_move(Face, 2, Move) :- atom_concat(Face, '2', Move).
parts_move(Face, 3, Move) :- atom_concat(Face, p, Move).

% merge_moves(+Moves, -Merged)
% Moves of the same face that sit next to each other become one move
% (U U -> U2, U U' -> nothing, U2 U -> U').
% It works from the right so joins can chain: U U U' U2 -> U'.
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

test_merge_moves :-
    merge_moves([u, u], [u2]),
    merge_moves([u, up], []),
    merge_moves([u2, u2], []),
    merge_moves([r, u, u, up, u2], [r, up]),
    merge_moves([r, u, rp], [r, u, rp]),            % different faces: nothing changes
    format("Move joining correct for 5 examples~n").

% ---------- Matching a cube to a case ----------

% pll_match(+Cube, -Name, -Pre, -Post)
% After turning the top layer by Pre, the cube's pattern is the pattern
% of the case (Name, Post).
pll_match(Cube, Name, Pre, Post) :-
    pre_turn(Pre),                                 % pre_turn is in oll.pl
    apply_moves(Pre, Cube, Turned),
    pll_pattern_of(Turned, Pattern),
    pll_case(Name, Post, Pattern).

% pll_one_alg(+Cube, -Name, -Moves)
% The shortest way to solve the cube with ONE algorithm from the list:
% the Pre turn, the algorithm, then the turn that undoes Post.
% (The case was made from a cube turned by Post, so after the algorithm
% the cube is still turned by Post.) Turns that sit next to each other
% are joined. Fails if no algorithm in the list fits.
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

% pll_auf(+Cube, -Turn)
% The cube is solved after the U turn Turn.
% (AUF = adjust the U face. Sometimes one top turn is all that is left.)
pll_auf(Cube, Turn) :-
    solved_cube(Solved),
    pre_turn(Turn),
    apply_moves(Turn, Cube, After),
    After == Solved,
    !.

% pll_fixed_ok(+Cube, +Moves)
% After doing Moves, the whole cube is solved.
pll_fixed_ok(Cube, Moves) :-
    apply_moves(Moves, Cube, After),
    solved_cube(Solved),
    After == Solved.

% pll_match_report(+Scramble)
% Scrambles a solved cube and says how the last layer gets solved.
% (Just for trying things out.)
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

% ---------- Tests: the matching ----------

% pll_case_cube(+Name, +Post, -Cube)
% The cube that algorithm Name (with last turn Post) fixes.
pll_case_cube(Name, Post, Cube) :-
    solved_cube(Solved),
    pll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Post, Solved, Turned),
    apply_moves(Inverse, Turned, Cube).

% test_pll_match_cases
% For every case and every starting U turn, make a cube.
% Then check that an algorithm is found and that it solves the cube.
test_pll_match_cases :-
    findall(Name-Post-Pre,
            ( pll_case(Name, Post, _), pre_turn(Pre) ),
            Combos),
    length(Combos, Count),
    forall(member(Name-Post-Pre, Combos),
           ( pll_case_cube(Name, Post, Case),
             inverse_moves(Pre, Back),
             apply_moves(Back, Case, Cube),         % the case, turned out of place
             pll_one_alg(Cube, _, Moves),
             pll_fixed_ok(Cube, Moves) )),
    format("6 algorithms x 4 final turns x 4 starting turns = ~w cubes: each one matched and solved by a table algorithm~n", [Count]).

% random_pll_cube(-Cube)
% A random last layer: a solved cube, then 2 random algorithms from the
% list (each after a random U turn), then one more random U turn.
random_pll_cube(Cube) :-
    solved_cube(Solved),
    pll_scramble(2, Solved, Cube1),
    findall(T, pre_turn(T), Turns),
    random_member(Turn, Turns),
    apply_moves(Turn, Cube1, Cube).

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

% test_pll_match_random(+N)
% N random last layers. Each one must be one of these:
%   - already solved
%   - needs only a U turn
%   - no single algorithm fits (this is allowed)
%   - a match is found, and it really solves the cube
% A match that does NOT solve the cube makes the test fail.
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

test_pll_matching :-
    test_merge_moves,
    test_pll_match_cases,
    test_pll_match_random(200),
    format("PLL matching tests passed~n").

% ---------- The PLL solver ----------

% pll_option(Name, Moves, Map)
% One way to use the list: a U turn followed by algorithm Name, as one list
% of Moves. Map tells how those moves shuffle the 21 pattern places
% (see ll_map in oll.pl). 6 x 4 = 24 facts, built when the file loads.
:- dynamic pll_option/3.

build_pll_options :-
    retractall(pll_option(_, _, _)),
    forall(( pll_alg(Name, _), pre_turn(Pre) ),
           ( pll_moves(Name, Alg),
             append(Pre, Alg, Moves),
             ll_map(Moves, Map),
             assertz(pll_option(Name, Moves, Map)) )).

:- build_pll_options.

% ---- All 288 possible last-layer arrangements ----

% perm_parity(+List, -Parity)
% 0 if the list is an even permutation, 1 if odd.
% (Counts the pairs that are out of order.)
perm_parity(List, Parity) :-
    findall(x, ( nth1(I, List, A), nth1(J, List, B), I < J, A > B ), Inversions),
    length(Inversions, N),
    Parity is N mod 2.

% slot_places(+Kind, +Slot, -Places)
% The sticker places of a top corner slot or top edge slot (1 to 4).
% The first place is on the top face and the others go clockwise,
% so a piece keeps its orientation when it moves.
slot_places(corner, Slot, Places) :- corner(Slot, _, Places).
slot_places(edge,   Slot, Places) :- edge(Slot, _, Places).

% place_slot(+Kind, +Perm, +Solved, +I, +Cube0, -Cube)
% Slot I gets the piece that lives in slot Perm[I] on a solved cube.
place_slot(Kind, Perm, Solved, I, Cube0, Cube) :-
    nth1(I, Perm, Source),
    slot_places(Kind, I, Target),
    slot_places(Kind, Source, From),
    maplist(sticker_at(Solved), From, Colours),
    put_all(Target, Colours, Cube0, Cube).             % put_all is in oll.pl

% permute_slots(+Kind, +Perm, +Solved, +Cube0, -Cube)
% Does that for slots 1 to 4.
permute_slots(Kind, Perm, Solved, Cube0, Cube) :-
    numlist(1, 4, Slots),
    foldl(place_slot(Kind, Perm, Solved), Slots, Cube0, Cube).

% all_pll_cubes(-Cubes)
% One cube for every legal way to arrange the top corners and top edges
% (their orientation stays solved). That is 24 x 24 / 2 = 288, because the
% corner arrangement and the edge arrangement must have the same parity.
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

% ---- The table: how many algorithms each arrangement needs ----

% pll_dist(Pattern, D): this pattern needs D algorithms (then maybe a last U turn).
% pll_next(Pattern, Name, Moves): the best next algorithm for this pattern.
:- dynamic pll_dist/2, pll_next/3.

build_pll_table :-
    retractall(pll_dist(_, _)),
    retractall(pll_next(_, _, _)),
    all_pll_cubes(Cubes),
    maplist(pll_pattern_of, Cubes, Patterns0),
    sort(Patterns0, Patterns),
    solved_cube(Solved),
    findall(Goal,                                  % the solved cube, and its 3 U turns
            ( pre_turn(Turn),
              apply_moves(Turn, Solved, Turned),
              pll_pattern_of(Turned, Goal) ),
            Goals),
    forall(member(G, Goals), assertz(pll_dist(G, 0))),
    pll_fill(Patterns, 0).

% pll_fill(+Patterns, +D)
% Look at every pattern that has no distance yet. If one option takes it to
% a pattern that is D away, it is D+1 away (and we save that option).
% Repeat until nothing new shows up. (Same idea as fill_levels in oll.pl.)
pll_fill(Patterns, D) :-
    D1 is D + 1,
    findall(Len-P-opt(Name, Moves),
            ( member(P, Patterns),
              \+ pll_dist(P, _),
              pll_option(Name, Moves, Map),
              pattern_step(P, Map, Q),              % pattern_step is in oll.pl
              pll_dist(Q, D),
              length(Moves, Len) ),
            Found0),
    msort(Found0, Found1),                          % shortest options first
    pick_first(Found1, [], Found),                  % one option per pattern (oll.pl)
    (   Found == []
    ->  true
    ;   forall(member(P-opt(Name, Moves), Found),
               ( assertz(pll_dist(P, D1)),
                 assertz(pll_next(P, Name, Moves)) )),
        pll_fill(Patterns, D1)
    ).

:- build_pll_table.

% ---- Solving ----

% pll_solve_steps(+Cube, -Steps)
% The cube must have the first two layers solved and the top finished.
% Each step is step(pll, Name, Moves). A step named auf is just one U turn.
% Fails if the cube is not covered by the table.
pll_solve_steps(Cube, Steps) :-
    (   pll_auf(Cube, [])
    ->  Steps = []                                  % already solved
    ;   pll_auf(Cube, Turn)
    ->  Steps = [step(pll, auf, Turn)]              % only a U turn left
    ;   pll_one_alg(Cube, Name, Moves)
    ->  Steps = [step(pll, Name, Moves)]            % one algorithm is enough
    ;   pll_chain(Cube, Steps)                      % otherwise, chain several
    ).

% pll_chain(+Cube, -Steps)
% Does the table's best algorithm on the real cube, checks that the new
% pattern is exactly one step closer, then carries on.
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

% pll_steps_moves(+Steps, -Moves)
% Puts all the moves of all the steps into one list, in order.
pll_steps_moves([], []).
pll_steps_moves([step(_, _, M)|Steps], Moves) :-
    pll_steps_moves(Steps, Rest),
    append(M, Rest, Moves).

% solve_pll(+Cube, -Moves)
% All the PLL moves in one list.
solve_pll(Cube, Moves) :-
    pll_solve_steps(Cube, Steps),
    pll_steps_moves(Steps, Moves).

% pll_solve_report(+Scramble)
% Scrambles a solved cube, solves the last layer, and checks it on the real cube.
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

% ---------- Tests: the solver ----------

% test_pll_table
% There must be exactly 288 arrangements (each from a real legal cube, all
% different), and each one must have a way to the solved cube.
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

% test_pll_all_cubes
% Solves all 288 cubes and checks each answer on the real 54-sticker cube.
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

% test_pll_random(+N)
% N random last layers. All must be solved.
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

test_pll_solver :-
    test_pll_table,
    test_pll_all_cubes,
    test_pll_random(200),
    format("PLL solver tests passed~n").