% f2l.pl
% F2L = First Two Layers.
% Goal: join each white corner with its matching middle edge and put
% the pair in its slot. Do this 4 times and the bottom two layers are done.
% This file loads cross.pl (which loads stages.pl, cube.pl and moves.pl).
:- ensure_loaded(cross).

% ---------- Finding where the pieces are ----------

% corner_current_positions(+Cube, +Name, -Positions)
% Where are the 3 stickers of corner Name right now?
% They come in the same order as in corner/3 (the white sticker is first).
corner_current_positions(Cube, Name, Positions) :-
    corner(Home, Name, _),                      % the corner's own number
    corner_state(Cube, Slot, Home, Twist),      % which slot is it in, and how twisted?
    corner(Slot, _, SlotPositions),
    rotate_left(SlotPositions, Twist, Positions).

% corner_at_positions(+Positions, -SlotName, -Twist)
% Given 3 sticker spots, which corner slot are they in, and how twisted?
% Twist is 0, 1 or 2. Twist 0 means the white sticker is on the top or bottom face.
corner_at_positions(Positions, SlotName, Twist) :-
    once(( corner(_, SlotName, SlotPositions),
           between(0, 2, Twist),
           rotate_left(SlotPositions, Twist, Positions) )).

% f2l_pair_positions(+Cube, +Slot, -CornerPositions, -EdgePositions)
% Where are the two pieces (corner and edge) that belong in this slot?
% (f2l_slot/3 in stages.pl tells which corner and edge go with which slot.)
f2l_pair_positions(Cube, Slot, CornerPositions, EdgePositions) :-
    f2l_slot(Slot, CornerName, EdgeName),
    corner_current_positions(Cube, CornerName, CornerPositions),
    edge_current_positions(Cube, EdgeName, EdgePositions).

% pair_report(+Scramble, +Slot)
% Scrambles a solved cube and prints where the pair's two pieces went.
% (Just for trying things out.)
pair_report(Scramble, Slot) :-
    scramble_cube(Scramble, Cube),
    f2l_slot(Slot, CornerName, EdgeName),
    f2l_pair_positions(Cube, Slot, CP, EP),
    corner_at_positions(CP, CornerSlot, Twist),
    edge_at_positions(EP, EdgeSlot, Flip),
    format("Pair ~w: corner ~w is in slot ~w (twist ~w), edge ~w is in slot ~w (flip ~w)~n",
           [Slot, CornerName, CornerSlot, Twist, EdgeName, EdgeSlot, Flip]).

% ---------- Tests: finding the pieces ----------

% test_corner_tracking
% Start from a solved cube and do random moves. We follow each corner
% move by move, then check that the locator finds it in the same place.
test_corner_tracking :-
    solved_cube(S),
    forall(corner(_, N1, H1),
           corner_current_positions(S, N1, H1)),     % solved cube: every corner is home
    forall(between(1, 100, _),
           ( random_scramble(20, Ms),
             apply_moves(Ms, S, C),
             forall(corner(_, Name, Home),
                    ( track_positions(Ms, Home, Now),
                      corner_current_positions(C, Name, Got),
                      Got == Now )) )),
    format("Corner locator matches the cube: solved, and 100 random scrambles x 8 corners~n").

% test_pair_known
% Answers I worked out by hand from the move tables.
% w(CornerSlot, Twist, EdgeSlot, Flip)
test_pair_known :-
    forall(member(t(Scramble, Want),
                  [ t("",   w(dfr, 0, fr, 0)),     % solved: both pieces at home
                    t("R",  w(urf, 2, ur, 0)),     % R lifts the pair up to the top
                    t("R2", w(ubr, 0, br, 0)) ]),  % R2 sends it to the back
           ( scramble_cube(Scramble, C),
             f2l_pair_positions(C, fr, CP, EP),
             corner_at_positions(CP, CornerSlot, Twist),
             edge_at_positions(EP, EdgeSlot, Flip),
             w(CornerSlot, Twist, EdgeSlot, Flip) == Want )),
    format("Pair locations correct for 3 known cubes (solved, R, R2)~n").

test_pairs :-
    test_corner_tracking,
    test_pair_known,
    format("Pair locator tests passed~n").

% ---------- The distance table for a pair ----------

% A pair "state" is a list of 5 spots:
% the 3 corner stickers first, then the 2 edge stickers.

% pair_home_state(+Slot, -State)
% The state when the pair is solved (both pieces at home).
pair_home_state(Slot, State) :-
    f2l_slot(Slot, CornerName, EdgeName),
    corner(_, CornerName, CornerPositions),
    edge(_, EdgeName, EdgePositions),
    append(CornerPositions, EdgePositions, State).

% positions_key(+Positions, -Key)
% Turns a list of spots into ONE number, so looking it up is fast.
% Every spot is less than 55, so counting in base 55 gives
% each list its very own number.
positions_key(Positions, Key) :-
    positions_key(Positions, 0, Key).

positions_key([], Key, Key).
positions_key([P|Ps], Key0, Key) :-
    Key1 is Key0 * 55 + P,
    positions_key(Ps, Key1, Key).

% pair_dist(Slot, Key, D)
% A pair of this slot, in the state with this key, needs D moves to get home.
% The builder below adds these facts when the file loads.
:- dynamic pair_dist/3.

% build_pair_dist(+Slot)
% Builds the table for one slot. We start from the solved pair and
% move outward, level by level (breadth-first search).
build_pair_dist(Slot) :-
    pair_home_state(Slot, Home),
    positions_key(Home, Key),
    assertz(pair_dist(Slot, Key, 0)),
    bfs_level(Slot, [Home], 0).

% bfs_level(+Slot, +Frontier, +D)
% Frontier = all the states that are D moves from home.
% Try every move on each one. Any state we have never seen is D+1 moves away.
bfs_level(_, [], _).                              % nothing new, we are done
bfs_level(Slot, Frontier, D) :-
    Frontier \== [],
    D1 is D + 1,
    findall(Next,
            ( member(State, Frontier),
              move_name(Move, _, _),
              move_positions(Move, State, Next),
              positions_key(Next, Key),
              \+ pair_dist(Slot, Key, _),         % never seen before
              assertz(pair_dist(Slot, Key, D1)) ),% save it right away
            NextFrontier),
    bfs_level(Slot, NextFrontier, D1).

% build_pair_dist_table
% Builds the table for all four slots. Runs once, when this file loads.
build_pair_dist_table :-
    retractall(pair_dist(_, _, _)),
    forall(f2l_slot(Slot, _, _), build_pair_dist(Slot)).

:- build_pair_dist_table.

% ---------- Items the search keeps watching ----------
% An "item" is it(Name, Positions): one thing the search keeps an eye on.
%   - a cross edge: it(df, [A, B])        (Name is dr, df, dl or db)
%   - an F2L pair:  it(fr, [5 spots])     (Name is the slot: fr, fl, bl, br)

% item_dist(+Name, +Positions, -D)
% How many moves does this item need to get home, by itself?
% (Ignores everything else on the cube.)
item_dist(Name, Positions, D) :-
    (   memberchk(Name, [dr, df, dl, db])
    ->  Positions = [A, B],
        edge_dist(Name, A, B, D)                 % table from cross.pl
    ;   positions_key(Positions, Key),
        pair_dist(Name, Key, D)
    ).

% f2l_close_enough(+R, +Item)
% True if the item can still get home within R moves.
f2l_close_enough(R, it(Name, Positions)) :-
    item_dist(Name, Positions, D),
    D =< R.

% f2l_move_item(+Move, +Item, -NewItem)
% The item after doing one move.
f2l_move_item(Move, it(Name, Positions), it(Name, Positions1)) :-
    move_positions(Move, Positions, Positions1).

% pair_item_now(+Cube, +Slot, -Item)
% The pair's item as it is on the cube right now.
% pair_item_home(+Slot, -Item)
% The pair's item when it is solved.
pair_item_now(Cube, Slot, it(Slot, State)) :-
    f2l_pair_positions(Cube, Slot, CornerPositions, EdgePositions),
    append(CornerPositions, EdgePositions, State).

pair_item_home(Slot, it(Slot, State)) :-
    pair_home_state(Slot, State).

% cross_item_home(+Name, -Item)
% A cross edge, sitting solved.
cross_item_home(Name, it(Name, Positions)) :-
    edge_goal(Name, Positions).

% ---------- Tests: the distance table ----------

% all_pair_states(-States)
% Every possible state of a pair.
% Corner: 8 slots x 3 twists = 24. Edge: 12 slots x 2 flips = 24.
% 24 x 24 = 576 states.
all_pair_states(States) :-
    findall(State,
            ( corner(_, _, CornerSlot),
              between(0, 2, Twist),
              rotate_left(CornerSlot, Twist, CornerPositions),
              edge(_, _, EdgeSlot),
              ( EdgePositions = EdgeSlot ; reverse(EdgeSlot, EdgePositions) ),
              append(CornerPositions, EdgePositions, State) ),
            States).

% pair_histogram(+Slot, -Counts)
% How many states sit at each distance (0 moves, 1 move, 2 moves, ...).
pair_histogram(Slot, Counts) :-
    findall(D, pair_dist(Slot, _, D), Ds),
    sort(Ds, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Ds, Same),
                   length(Same, N) ),
            Counts).

% test_pair_table
% Each table must be complete and make sense. That means:
%   - one move changes the distance by 1 at most
%   - every state (except solved) has a move that gets one step closer
test_pair_table :-
    all_pair_states(States),
    length(States, 576),
    forall(f2l_slot(Slot, _, _),
           ( pair_home_state(Slot, Home),
             item_dist(Slot, Home, 0),
             findall(K, pair_dist(Slot, K, _), Ks),
             length(Ks, 576),                          % every state has a distance
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

% descend(+Cube, +Slot, -Moves)
% Solves the pair by always picking a move the table says is one step closer.
% Every move is done on the REAL 54-sticker cube, so this
% checks the table against the real cube.
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

% test_pair_descent
% On random cubes, following the table must solve the pair in exactly
% as many moves as the table said.
test_pair_descent :-
    solved_cube(S),
    forall(between(1, 100, _),
           ( random_scramble(25, Ms),
             apply_moves(Ms, S, C),
             forall(f2l_slot(Slot, _, _),
                    ( pair_item_now(C, Slot, it(_, State)),
                      item_dist(Slot, State, D),
                      descend(C, Slot, Down),
                      length(Down, D),                 % same number of moves as promised
                      apply_moves(Down, C, C2),
                      f2l_pair_solved(C2, Slot) )) )),  % and the pair is really solved
    format("Following the table solves the pair on the full cube: 100 random cubes x 4 slots~n").

test_pair_search_tables :-
    test_pair_table,
    test_pair_descent,
    format("Pair table tests passed~n").

% ---------- Searching for the moves to solve one pair ----------

% f2l_dfs(+Depth, +PrevFace, +Items, +Goal, -Moves)
% Same idea as keep_dfs in cross.pl. Items = everything we watch
% (the pair we are solving, the cross edges, the pairs already done).
% Goal = where they all must end up. Two differences from cross.pl:
%  - an item can be a whole pair (corner + edge), not just an edge
%  - we never turn the D face. F2L does not need it, and skipping it
%    makes the search faster.
f2l_dfs(0, _, Goal, Goal, []).
f2l_dfs(Depth, Prev, Items, Goal, [Move|Rest]) :-
    Depth > 0,
    move_name(Move, Face, _),
    Face \== d,
    ok_order(Prev, Face),                        % from cross.pl
    maplist(f2l_move_item(Move), Items, Next),
    Depth1 is Depth - 1,
    maplist(f2l_close_enough(Depth1), Next),     % drop paths that can't finish in time
    f2l_dfs(Depth1, Face, Next, Goal, Rest).

% f2l_search(+Start, +Home, +KeptItems, -Moves)
% Finds the shortest moves (up to 10) that take the pair from Start to Home,
% while every kept item ends up back where it is now.
f2l_search(Start, Home, KeptItems, Moves) :-
    once(( between(0, 10, Depth),
           f2l_dfs(Depth, none, [Start|KeptItems], [Home|KeptItems], Moves) )).

% solve_pair_keeping(+Cube, +Slot, +KeptEdges, +KeptPairs, -Moves)
% Moves that solve the pair of this slot, while the cross edges in KeptEdges
% and the pairs in KeptPairs end up solved again.
solve_pair_keeping(Cube, Slot, KeptEdges, KeptPairs, Moves) :-
    pair_item_now(Cube, Slot, Start),
    pair_item_home(Slot, Home),
    maplist(cross_item_home, KeptEdges, EdgeItems),
    maplist(pair_item_home, KeptPairs, PairItems),
    append(EdgeItems, PairItems, KeptItems),
    f2l_search(Start, Home, KeptItems, Moves).

% ---------- Naming the situation of a pair ----------
% Before solving a pair we say what situation it is in.
% We just look at which layer each of its two pieces is in.

% corner_layer(+Cube, +Slot, -Layer)
% Layer is top or bottom.
% The corner's slot name tells us: a name starting with u (urf, ufl, ...)
% is in the top layer. A name starting with d (dfr, dlf, ...) is in the bottom.
corner_layer(Cube, Slot, Layer) :-
    f2l_slot(Slot, CornerName, _),
    corner_current_positions(Cube, CornerName, CP),
    corner_at_positions(CP, CornerSlot, _),
    (   sub_atom(CornerSlot, 0, 1, _, u)
    ->  Layer = top
    ;   Layer = bottom
    ).

% edge_layer(+Cube, +Slot, -Layer)
% Layer is top, middle or bottom.
% Top edges: ur uf ul ub.  Middle edges: fr fl bl br.  Bottom edges: dr df dl db.
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

% case_name(+CornerLayer, +EdgeLayer, -Case)
% The name for each combination of layers.
case_name(top,    top,    both_in_top).
case_name(top,    middle, corner_top_edge_middle).
case_name(bottom, top,    corner_bottom_edge_top).
case_name(bottom, middle, corner_bottom_edge_middle).
case_name(_,      bottom, edge_in_bottom).       % only happens when the cross is not solved

% valid_pair_case(?Case): the only names a case is allowed to have.
valid_pair_case(solved).
valid_pair_case(both_in_top).
valid_pair_case(corner_top_edge_middle).
valid_pair_case(corner_bottom_edge_top).
valid_pair_case(corner_bottom_edge_middle).
valid_pair_case(edge_in_bottom).

% pair_case(+Cube, +Slot, -Case)
% The name of the situation this pair is in right now.
pair_case(Cube, Slot, Case) :-
    (   f2l_pair_solved(Cube, Slot)
    ->  Case = solved
    ;   corner_layer(Cube, Slot, CL),
        edge_layer(Cube, Slot, EL),
        once(case_name(CL, EL, Case))
    ).

% pair_case_report(+Scramble, +Slot)
% Scrambles a solved cube, then prints the case of the pair for this slot.
% (Just for trying things out.)
pair_case_report(Scramble, Slot) :-
    scramble_cube(Scramble, Cube),
    pair_case(Cube, Slot, Case),
    format("Pair ~w: ~w~n", [Slot, Case]).

% ---------- The four pairs as step records ----------
% A step is step(Slot, Case, Moves):
%   which pair, what situation it was in BEFORE we solved it,
%   and the moves that solved it.

% f2l_steps(+Cube, -Steps)
% The cube must already have its cross solved.
% Solves the four pairs one after another, in the order fr, fl, bl, br.
f2l_steps(Cube, Steps) :-
    f2l_steps_from(Cube, [fr, fl, bl, br], [], Steps).

% f2l_steps_from(+Cube, +ToDo, +Done, -Steps)
% ToDo = slots still to solve. Done = slots already solved.
f2l_steps_from(_, [], _, []).                    % nothing left to solve
f2l_steps_from(Cube, [Slot|Rest], Done, [step(Slot, Case, Moves)|Steps]) :-
    pair_case(Cube, Slot, Case),                 % name the situation first
    solve_pair_keeping(Cube, Slot, [dr, df, dl, db], Done, Moves),
    apply_moves(Moves, Cube, Cube1),
    f2l_steps_from(Cube1, Rest, [Slot|Done], Steps).

% f2l_steps_moves(+Steps, -Moves)
% Puts the moves of all the steps into one list, in order.
f2l_steps_moves([], []).
f2l_steps_moves([step(_, _, M)|Steps], Moves) :-
    f2l_steps_moves(Steps, Rest),
    append(M, Rest, Moves).

% solve_f2l(+Cube, -Moves)
% All the F2L moves in one list, built from the steps.
solve_f2l(Cube, Moves) :-
    f2l_steps(Cube, Steps),
    f2l_steps_moves(Steps, Moves).

% solve_pair_report(+Scramble, +Slot)
% Scrambles, solves the cross, then solves the pair for this slot
% (keeping the cross) and checks it on the real cube.
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

% solve_f2l_report(+Scramble)
% Scrambles, solves the cross, then all four pairs, and checks the
% result on the real cube.
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

% solve_f2l_steps_report(+Scramble)
% Same as solve_f2l_report, but prints one line per pair with its case.
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

% ---------- Tests: the F2L search ----------

% test_first_pair(+N)
% N random cubes with the cross solved. Solve the first pair (slot fr)
% and keep the cross. The answer can't be shorter than the table
% distance, and it must really solve the pair on the full cube.
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
              L >= D0,                           % never shorter than the table says
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

% test_f2l_random(+N)
% N random cubes: solve the cross, then all four pairs.
% No pair may break the cross or an earlier pair
% (we check the final cube on the full 54 stickers).
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

test_f2l_search :-
    test_first_pair(100),
    test_f2l_random(50),
    format("F2L search tests passed~n").

% ---------- Tests: the case names ----------

% test_pair_case_known
% Cases I worked out by hand.
%   R:  the pair is lifted out, both pieces are on the top layer
%   R2: the corner is on top, the edge went to the back middle slot
%   F:  the corner and the edge both go down (the edge to df)
test_pair_case_known :-
    forall(member(t(Scramble, Slot, Want),
                  [ t("",        fr, solved),
                    t("R",       fr, both_in_top),
                    t("R2",      fr, corner_top_edge_middle),
                    t("F",       fr, edge_in_bottom),
                    t("R U R'",  fr, both_in_top),
                    t("R",       fl, solved) ]),         % R does not touch slot fl
           ( scramble_cube(Scramble, C),
             pair_case(C, Slot, Got),
             Got == Want )),
    format("Case names correct for 6 known cubes~n").

% test_pair_cases_random
% 200 random cubes x 4 pairs = 800 cases. Every name must be valid,
% and "solved" must show up exactly when the pair is really solved.
% Then it prints how many times each case appeared.
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

test_pair_cases :-
    test_pair_case_known,
    test_pair_cases_random,
    format("Pair case tests passed~n").

% ---------- Tests: the step records ----------

% check_steps(+Cube, +Steps, +Done)
% Replays the steps on the REAL cube. For each step it checks:
%   - the case name matches what the cube really looked like
%   - the pair is solved afterwards
%   - the cross and all earlier pairs are still solved
check_steps(_, [], _).
check_steps(Cube, [step(Slot, Case, Moves)|Steps], Done) :-
    pair_case(Cube, Slot, Case),                 % name matches the cube
    valid_pair_case(Case),
    apply_moves(Moves, Cube, Cube1),
    f2l_pair_solved(Cube1, Slot),                % this pair is solved now
    cross_solved(Cube1),                         % the cross is still there
    forall(member(D, Done), f2l_pair_solved(Cube1, D)),   % earlier pairs too
    check_steps(Cube1, Steps, [Slot|Done]).

% count_kinds(+List, -Counts)
% Counts how many times each different item shows up in the list.
count_kinds(List, Counts) :-
    msort(List, Sorted),
    sort(List, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Sorted, Same),
                   length(Same, N) ),
            Counts).

% test_f2l_steps(+N)
% N random cubes: solve the cross, then get F2L as step records.
% Each cube must give exactly 4 steps in the order fr, fl, bl, br,
% and every step must replay correctly on the full cube.
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