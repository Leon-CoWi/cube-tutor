% f2l.pl
% F2L (first two layers): join each white corner with its middle edge and
% put the pair in its slot. Four pairs, and the bottom two layers are done.
% Same idea as cross.pl, with a table of how far each pair is from home.

:- ensure_loaded(cross).

% corner_current_positions(Cube, Name, Positions): the 3 sticker spots of a corner piece
%   right now (white sticker first).
corner_current_positions(Cube, Name, Positions) :-
    corner(Home, Name, _),
    corner_state(Cube, Slot, Home, Twist),
    corner(Slot, _, SlotPositions),
    rotate_left(SlotPositions, Twist, Positions).

% corner_at_positions(Positions, SlotName, Twist): which corner slot 3 spots are in, and
%   how twisted (0, 1 or 2).
corner_at_positions(Positions, SlotName, Twist) :-
    once(( corner(_, SlotName, SlotPositions),
           between(0, 2, Twist),
           rotate_left(SlotPositions, Twist, Positions) )).

% f2l_pair_positions(Cube, Slot, CornerPositions, EdgePositions): where the corner and
%   the edge of a pair slot are now.
f2l_pair_positions(Cube, Slot, CornerPositions, EdgePositions) :-
    f2l_slot(Slot, CornerName, EdgeName),
    corner_current_positions(Cube, CornerName, CornerPositions),
    edge_current_positions(Cube, EdgeName, EdgePositions).

% pair_report(Scramble, Slot): scrambles a cube and prints where the pair pieces went.
pair_report(Scramble, Slot) :-
    scramble_cube(Scramble, Cube),
    f2l_slot(Slot, CornerName, EdgeName),
    f2l_pair_positions(Cube, Slot, CP, EP),
    corner_at_positions(CP, CornerSlot, Twist),
    edge_at_positions(EP, EdgeSlot, Flip),
    format("Pair ~w: corner ~w is in slot ~w (twist ~w), edge ~w is in slot ~w (flip ~w)~n",
           [Slot, CornerName, CornerSlot, Twist, EdgeName, EdgeSlot, Flip]).

% test_corner_tracking: follows each corner through random moves and checks the finder
%   agrees.
test_corner_tracking :-
    solved_cube(S),
    forall(corner(_, N1, H1),
           corner_current_positions(S, N1, H1)),
    forall(between(1, 100, _),
           ( random_scramble(20, Ms),
             apply_moves(Ms, S, C),
             forall(corner(_, Name, Home),
                    ( track_positions(Ms, Home, Now),
                      corner_current_positions(C, Name, Got),
                      Got == Now )) )),
    format("Corner locator matches the cube: solved, and 100 random scrambles x 8 corners~n").

% test_pair_known: pair locations worked out by hand.
test_pair_known :-
    forall(member(t(Scramble, Want),
                  [ t("",   w(dfr, 0, fr, 0)),
                    t("R",  w(urf, 2, ur, 0)),
                    t("R2", w(ubr, 0, br, 0)) ]),
           ( scramble_cube(Scramble, C),
             f2l_pair_positions(C, fr, CP, EP),
             corner_at_positions(CP, CornerSlot, Twist),
             edge_at_positions(EP, EdgeSlot, Flip),
             w(CornerSlot, Twist, EdgeSlot, Flip) == Want )),
    format("Pair locations correct for 3 known cubes (solved, R, R2)~n").

% test_pairs: runs the pair locator tests.
test_pairs :-
    test_corner_tracking,
    test_pair_known,
    format("Pair locator tests passed~n").

% pair_home_state(Slot, State): the spots of a solved pair (3 corner spots, then 2 edge
%   spots).
pair_home_state(Slot, State) :-
    f2l_slot(Slot, CornerName, EdgeName),
    corner(_, CornerName, CornerPositions),
    edge(_, EdgeName, EdgePositions),
    append(CornerPositions, EdgePositions, State).

% positions_key(Positions, Key): turns a list of spots into one number, so it is quick
%   to find in the table.
positions_key(Positions, Key) :-
    positions_key(Positions, 0, Key).

% positions_key/3: helper that makes the number.
positions_key([], Key, Key).

positions_key([P|Ps], Key0, Key) :-
    Key1 is Key0 * 55 + P,
    positions_key(Ps, Key1, Key).

% pair_dist/3: table: how many moves a pair needs to get home.
:- dynamic pair_dist/3.

% build_pair_dist(Slot): builds the table for one slot: start from solved and go
%   outward, one move at a time.
build_pair_dist(Slot) :-
    pair_home_state(Slot, Home),
    positions_key(Home, Key),
    assertz(pair_dist(Slot, Key, 0)),
    bfs_level(Slot, [Home], 0).

% bfs_level/3: tries every move on the states D moves away; new ones are D+1 moves away.
bfs_level(_, [], _).

bfs_level(Slot, Frontier, D) :-
    Frontier \== [],
    D1 is D + 1,
    findall(Next,
            ( member(State, Frontier),
              move_name(Move, _, _),
              move_positions(Move, State, Next),
              positions_key(Next, Key),
              \+ pair_dist(Slot, Key, _),
              assertz(pair_dist(Slot, Key, D1)) ),
            NextFrontier),
    bfs_level(Slot, NextFrontier, D1).

% build_pair_dist_table: builds the table for all four slots (runs once when the file
%   loads).
build_pair_dist_table :-
    retractall(pair_dist(_, _, _)),
    forall(f2l_slot(Slot, _, _), build_pair_dist(Slot)).
:- build_pair_dist_table.

% item_dist(Name, Positions, D): how many moves this piece (or pair) needs to get home
%   by itself.
item_dist(Name, Positions, D) :-
    (   memberchk(Name, [dr, df, dl, db])
    ->  Positions = [A, B],
        edge_dist(Name, A, B, D)
    ;   positions_key(Positions, Key),
        pair_dist(Name, Key, D)
    ).

% f2l_close_enough/2: true if it can still get home in R moves.
f2l_close_enough(R, it(Name, Positions)) :-
    item_dist(Name, Positions, D),
    D =< R.

% f2l_move_item/3: where it is after one move.
f2l_move_item(Move, it(Name, Positions), it(Name, Positions1)) :-
    move_positions(Move, Positions, Positions1).

% pair_item_now/3: the pair as it is on the cube now.
pair_item_now(Cube, Slot, it(Slot, State)) :-
    f2l_pair_positions(Cube, Slot, CornerPositions, EdgePositions),
    append(CornerPositions, EdgePositions, State).

% pair_item_home/2: the pair when solved.
pair_item_home(Slot, it(Slot, State)) :-
    pair_home_state(Slot, State).

% cross_item_home/2: a cross edge when solved.
cross_item_home(Name, it(Name, Positions)) :-
    edge_goal(Name, Positions).

% all_pair_states(States): every way a pair can sit: 24 corner x 24 edge = 576.
all_pair_states(States) :-
    findall(State,
            ( corner(_, _, CornerSlot),
              between(0, 2, Twist),
              rotate_left(CornerSlot, Twist, CornerPositions),
              edge(_, _, EdgeSlot),
              ( EdgePositions = EdgeSlot ; reverse(EdgeSlot, EdgePositions) ),
              append(CornerPositions, EdgePositions, State) ),
            States).

% pair_histogram(Slot, Counts): how many ways sit at each move count.
pair_histogram(Slot, Counts) :-
    findall(D, pair_dist(Slot, _, D), Ds),
    sort(Ds, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Ds, Same),
                   length(Same, N) ),
            Counts).

% test_pair_table: each table is complete, one move changes the distance by at most 1,
%   every state has a step closer.
test_pair_table :-
    all_pair_states(States),
    length(States, 576),
    forall(f2l_slot(Slot, _, _),
           ( pair_home_state(Slot, Home),
             item_dist(Slot, Home, 0),
             findall(K, pair_dist(Slot, K, _), Ks),
             length(Ks, 576),
             forall(member(S, States),
                    ( item_dist(Slot, S, D),
                      findall(DN, ( move_name(M, _, _),
                                    move_positions(M, S, N),
                                    item_dist(Slot, N, DN) ),
                              DNs),
                      forall(member(DN, DNs), abs(D - DN) =< 1),
                      D1 is D - 1,
                      ( D =:= 0 ; memberchk(D1, DNs) ) )) )),
    format("Pair distance tables: 4 slots x 576 states, neighbours differ by at most 1, every state has a step closer~n").

% descend(Cube, Slot, Moves): solves a pair by always taking a move one step closer, on
%   the real cube.
descend(Cube, Slot, Moves) :-
    pair_item_now(Cube, Slot, it(_, State)),
    item_dist(Slot, State, D),
    (   D =:= 0
    ->  Moves = []
    ;   D1 is D - 1,
        once(( move_name(M, _, _),
               apply_move(M, Cube, Cube1),
               pair_item_now(Cube1, Slot, it(_, State1)),
               item_dist(Slot, State1, D1) )),
        Moves = [M|Rest],
        descend(Cube1, Slot, Rest)
    ).

% test_pair_descent: following the table must solve the pair in exactly the promised
%   moves.
test_pair_descent :-
    solved_cube(S),
    forall(between(1, 100, _),
           ( random_scramble(25, Ms),
             apply_moves(Ms, S, C),
             forall(f2l_slot(Slot, _, _),
                    ( pair_item_now(C, Slot, it(_, State)),
                      item_dist(Slot, State, D),
                      descend(C, Slot, Down),
                      length(Down, D),
                      apply_moves(Down, C, C2),
                      f2l_pair_solved(C2, Slot) )) )),
    format("Following the table solves the pair on the full cube: 100 random cubes x 4 slots~n").

% test_pair_search_tables: runs the pair table tests.
test_pair_search_tables :-
    test_pair_table,
    test_pair_descent,
    format("Pair table tests passed~n").

% f2l_dfs/5: tries move lists, never turns D, and stops early on tries that cannot work.
f2l_dfs(0, _, Goal, Goal, []).

f2l_dfs(Depth, Prev, Items, Goal, [Move|Rest]) :-
    Depth > 0,
    move_name(Move, Face, _),
    Face \== d,
    ok_order(Prev, Face),
    maplist(f2l_move_item(Move), Items, Next),
    Depth1 is Depth - 1,
    maplist(f2l_close_enough(Depth1), Next),
    f2l_dfs(Depth1, Face, Next, Goal, Rest).

% f2l_search(Start, Home, KeptItems, Moves): shortest moves (up to 10) for the pair
%   while kept items end up back in place.
f2l_search(Start, Home, KeptItems, Moves) :-
    once(( between(0, 10, Depth),
           f2l_dfs(Depth, none, [Start|KeptItems], [Home|KeptItems], Moves) )).

% solve_pair_keeping(Cube, Slot, KeptEdges, KeptPairs, Moves): moves that solve a pair
%   while the kept cross edges and pairs stay solved.
solve_pair_keeping(Cube, Slot, KeptEdges, KeptPairs, Moves) :-
    pair_item_now(Cube, Slot, Start),
    pair_item_home(Slot, Home),
    maplist(cross_item_home, KeptEdges, EdgeItems),
    maplist(pair_item_home, KeptPairs, PairItems),
    append(EdgeItems, PairItems, KeptItems),
    f2l_search(Start, Home, KeptItems, Moves).

% corner_layer(Cube, Slot, Layer): top or bottom, from the corner slot name.
corner_layer(Cube, Slot, Layer) :-
    f2l_slot(Slot, CornerName, _),
    corner_current_positions(Cube, CornerName, CP),
    corner_at_positions(CP, CornerSlot, _),
    (   sub_atom(CornerSlot, 0, 1, _, u)
    ->  Layer = top
    ;   Layer = bottom
    ).

% edge_layer(Cube, Slot, Layer): top, middle or bottom.
edge_layer(Cube, Slot, Layer) :-
    f2l_slot(Slot, _, EdgeName),
    edge_current_positions(Cube, EdgeName, EP),
    edge_at_positions(EP, EdgeSlot, _),
    (   sub_atom(EdgeSlot, 0, 1, _, u)
    ->  Layer = top
    ;   memberchk(EdgeSlot, [fr, fl, bl, br])
    ->  Layer = middle
    ;   Layer = bottom
    ).

% case_name/3: the name for each pair of layers (corner layer, edge layer).
case_name(top,    top,    both_in_top).
case_name(top,    middle, corner_top_edge_middle).
case_name(bottom, top,    corner_bottom_edge_top).
case_name(bottom, middle, corner_bottom_edge_middle).
case_name(_,      bottom, edge_in_bottom).

% valid_pair_case/1: the names a pair case is allowed to have.
valid_pair_case(solved).
valid_pair_case(both_in_top).
valid_pair_case(corner_top_edge_middle).
valid_pair_case(corner_bottom_edge_top).
valid_pair_case(corner_bottom_edge_middle).
valid_pair_case(edge_in_bottom).

% pair_case(Cube, Slot, Case): the name of the situation a pair is in now.
pair_case(Cube, Slot, Case) :-
    (   f2l_pair_solved(Cube, Slot)
    ->  Case = solved
    ;   corner_layer(Cube, Slot, CL),
        edge_layer(Cube, Slot, EL),
        once(case_name(CL, EL, Case))
    ).

% pair_case_report(Scramble, Slot): scrambles a cube and prints the case of one pair.
pair_case_report(Scramble, Slot) :-
    scramble_cube(Scramble, Cube),
    pair_case(Cube, Slot, Case),
    format("Pair ~w: ~w~n", [Slot, Case]).

% f2l_steps(Cube, Steps): solves the four pairs in the order fr, fl, bl, br (cross must
%   be done).
f2l_steps(Cube, Steps) :-
    f2l_steps_from(Cube, [fr, fl, bl, br], [], Steps).

% f2l_steps_from/4: solves the slots still to do, keeping the ones done.
f2l_steps_from(_, [], _, []).

f2l_steps_from(Cube, [Slot|Rest], Done, [step(Slot, Case, Moves)|Steps]) :-
    pair_case(Cube, Slot, Case),
    solve_pair_keeping(Cube, Slot, [dr, df, dl, db], Done, Moves),
    apply_moves(Moves, Cube, Cube1),
    f2l_steps_from(Cube1, Rest, [Slot|Done], Steps).

% f2l_steps_moves/2: all the moves of the steps, in one list.
f2l_steps_moves([], []).

f2l_steps_moves([step(_, _, M)|Steps], Moves) :-
    f2l_steps_moves(Steps, Rest),
    append(M, Rest, Moves).

% solve_f2l(Cube, Moves): all the F2L moves in one list.
solve_f2l(Cube, Moves) :-
    f2l_steps(Cube, Steps),
    f2l_steps_moves(Steps, Moves).

% solve_pair_report(Scramble, Slot): scrambles, solves the cross and one pair, and
%   checks it.
solve_pair_report(Scramble, Slot) :-
    scramble_cube(Scramble, C0),
    solve_cross(C0, CrossMoves),
    apply_moves(CrossMoves, C0, C1),
    solve_pair_keeping(C1, Slot, [dr, df, dl, db], [], Moves),
    length(Moves, N),
    scramble_text(Moves, Text),
    format("Pair ~w: ~w moves: ~w~n", [Slot, N, Text]),
    apply_moves(Moves, C1, C2),
    (   f2l_pair_solved(C2, Slot), cross_solved(C2)
    ->  format("Check on the real cube: pair solved, cross still solved~n")
    ;   format("Check on the real cube: FAILED~n")
    ).

% solve_f2l_report(Scramble): scrambles, solves the cross and all four pairs, and checks
%   it.
solve_f2l_report(Scramble) :-
    scramble_cube(Scramble, C0),
    solve_cross(C0, CrossMoves),
    apply_moves(CrossMoves, C0, C1),
    solve_f2l(C1, Moves),
    length(Moves, N),
    scramble_text(Moves, Text),
    format("F2L solution (~w moves): ~w~n", [N, Text]),
    apply_moves(Moves, C1, C2),
    (   cross_solved(C2), f2l_pairs_solved(C2, 4)
    ->  format("Check on the real cube: cross still solved, 4 pairs solved~n")
    ;   format("Check on the real cube: FAILED~n")
    ).

% solve_f2l_steps_report(Scramble): same, with one line per pair and its case.
solve_f2l_steps_report(Scramble) :-
    scramble_cube(Scramble, C0),
    solve_cross(C0, CrossMoves),
    apply_moves(CrossMoves, C0, C1),
    f2l_steps(C1, Steps),
    forall(member(step(Slot, Case, Moves), Steps),
           ( length(Moves, N),
             scramble_text(Moves, Text),
             format("Pair ~w (~w): ~w moves: ~w~n", [Slot, Case, N, Text]) )),
    f2l_steps_moves(Steps, All),
    apply_moves(All, C1, C2),
    (   cross_solved(C2), f2l_pairs_solved(C2, 4)
    ->  format("Check on the real cube: cross still solved, 4 pairs solved~n")
    ;   format("Check on the real cube: FAILED~n")
    ).

% test_first_pair(N): N random cubes: the first pair is solved, never shorter than the
%   table says.
test_first_pair(N) :-
    solved_cube(S),
    statistics(cputime, T0),
    findall(L,
            ( between(1, N, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, C0),
              solve_cross(C0, CrossMoves),
              apply_moves(CrossMoves, C0, C1),
              pair_item_now(C1, fr, it(_, State)),
              item_dist(fr, State, D0),
              solve_pair_keeping(C1, fr, [dr, df, dl, db], [], Sol),
              length(Sol, L),
              L >= D0,
              apply_moves(Sol, C1, C2),
              f2l_pair_solved(C2, fr),
              cross_solved(C2) ),
            Ls),
    length(Ls, N),
    statistics(cputime, T1),
    max_list(Ls, Longest),
    Secs is T1 - T0,
    format("~w random cubes, first pair solved keeping the cross. Longest: ~w moves. Time: ~1f seconds~n",
           [N, Longest, Secs]).

% test_f2l_random(N): N random cubes: cross and all four pairs solved, nothing broken.
test_f2l_random(N) :-
    solved_cube(S),
    statistics(cputime, T0),
    findall(L,
            ( between(1, N, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, C0),
              solve_cross(C0, CrossMoves),
              apply_moves(CrossMoves, C0, C1),
              solve_f2l(C1, Sol),
              apply_moves(Sol, C1, C2),
              cross_solved(C2),
              f2l_pairs_solved(C2, 4),
              length(Sol, L) ),
            Ls),
    length(Ls, N),
    statistics(cputime, T1),
    sum_list(Ls, Total),
    max_list(Ls, Longest),
    Avg is Total / N,
    Secs is T1 - T0,
    format("~w random cubes: cross + 4 pairs solved every time. F2L moves: average ~1f, longest ~w. Time: ~1f seconds~n",
           [N, Avg, Longest, Secs]).

% test_f2l_search: runs the F2L search tests (slow).
test_f2l_search :-
    test_first_pair(100),
    test_f2l_random(50),
    format("F2L search tests passed~n").

% test_pair_case_known: case names worked out by hand.
test_pair_case_known :-
    forall(member(t(Scramble, Slot, Want),
                  [ t("",        fr, solved),
                    t("R",       fr, both_in_top),
                    t("R2",      fr, corner_top_edge_middle),
                    t("F",       fr, edge_in_bottom),
                    t("R U R'",  fr, both_in_top),
                    t("R",       fl, solved) ]),
           ( scramble_cube(Scramble, C),
             pair_case(C, Slot, Got),
             Got == Want )),
    format("Case names correct for 6 known cubes~n").

% test_pair_cases_random: 800 random cases: every name valid, "solved" only when really
%   solved.
test_pair_cases_random :-
    solved_cube(S),
    findall(Case,
            ( between(1, 200, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, C),
              f2l_slot(Slot, _, _),
              pair_case(C, Slot, Case),
              valid_pair_case(Case),
              (   Case == solved
              ->  f2l_pair_solved(C, Slot)
              ;   \+ f2l_pair_solved(C, Slot)
              ) ),
            Cases),
    length(Cases, 800),
    msort(Cases, Sorted),
    sort(Cases, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Sorted, Same),
                   length(Same, N) ),
            Counts),
    format("800 pair cases named, all valid. Counts: ~w~n", [Counts]).

% test_pair_cases: runs the case name tests.
test_pair_cases :-
    test_pair_case_known,
    test_pair_cases_random,
    format("Pair case tests passed~n").

% check_steps/3: replays the steps on the real cube and checks label, pair, cross and
%   earlier pairs.
check_steps(_, [], _).

check_steps(Cube, [step(Slot, Case, Moves)|Steps], Done) :-
    pair_case(Cube, Slot, Case),
    valid_pair_case(Case),
    apply_moves(Moves, Cube, Cube1),
    f2l_pair_solved(Cube1, Slot),
    cross_solved(Cube1),
    forall(member(D, Done), f2l_pair_solved(Cube1, D)),
    check_steps(Cube1, Steps, [Slot|Done]).

% count_kinds(List, Counts): counts how many times each item shows up in a list.
count_kinds(List, Counts) :-
    msort(List, Sorted),
    sort(List, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Sorted, Same),
                   length(Same, N) ),
            Counts).

% test_f2l_steps(N): N random cubes: 4 steps each, every step replays correctly.
test_f2l_steps(N) :-
    solved_cube(S),
    statistics(cputime, T0),
    findall(Steps,
            ( between(1, N, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, C0),
              solve_cross(C0, CrossMoves),
              apply_moves(CrossMoves, C0, C1),
              f2l_steps(C1, Steps),
              Steps = [step(fr, _, _), step(fl, _, _), step(bl, _, _), step(br, _, _)],
              check_steps(C1, Steps, []) ),
            All),
    length(All, N),
    statistics(cputime, T1),
    append(All, Flat),
    findall(L, ( member(step(_, _, M), Flat), length(M, L) ), Ls),
    max_list(Ls, Longest),
    findall(Case, member(step(_, Case, _), Flat), Cases),
    count_kinds(Cases, Counts),
    Secs is T1 - T0,
    format("~w random cubes: every step replayed on the full cube (label right, pair solved, cross and earlier pairs kept). Longest step: ~w moves. Time: ~1f seconds~n",
           [N, Longest, Secs]),
    format("Case counts: ~w~n", [Counts]).