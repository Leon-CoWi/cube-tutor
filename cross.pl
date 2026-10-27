% cross.pl
% The cross solver: finds moves that put the four white edges (dr, df, dl, db)
% on the bottom, each matching its side colour.
% Idea: try 0 moves, then 1, then 2... and stop early on tries that cannot work,
% using a table of how far each edge is from home.

:- ensure_loaded(stages).

% where_is_edge(Cube, Name, SlotName, Flip): where the edge that belongs in spot Name is
%   now, and if it is flipped (0 no, 1 yes).
where_is_edge(Cube, Name, SlotName, Flip) :-
    edge(Home, Name, _),
    edge_state(Cube, Slot, Home, Flip),
    edge(Slot, SlotName, _).

% cross_edge_places(Cube, Places): where the four cross edges are, as a list like
%   [dr-fr-0, ...].
cross_edge_places(Cube, Places) :-
    findall(Name-Slot-Flip,
            ( member(Name, [dr, df, dl, db]),
              where_is_edge(Cube, Name, Slot, Flip) ),
            Places).

% cross_edges_report(Scramble): scrambles a cube and prints where the four cross edges
%   ended up.
cross_edges_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    cross_edge_places(Cube, Places),
    forall(member(Name-Slot-Flip, Places),
           format("~w: at ~w, flip ~w~n", [Name, Slot, Flip])).

% test_where: the edge finder must give the right answers.
test_where :-
    solved_cube(S),
    forall(member(N, [dr, df, dl, db]),
           where_is_edge(S, N, N, 0)),
    scramble_cube("F", C1),
    where_is_edge(C1, df, fl, 1),
    scramble_cube("R", C2),
    where_is_edge(C2, dr, fr, 0),
    forall(between(1, 100, _),
           ( random_scramble(25, Ms),
             apply_moves(Ms, S, C),
             cross_edge_places(C, L),
             length(L, 4),
             findall(Sl, member(_-Sl-_, L), Slots),
             sort(Slots, Distinct),
             length(Distinct, 4) )),
    format("Edge locator correct: solved cube, F, R, and 100 random cubes~n").

% compute_move_position(Move, Pos, NewPos): where a sticker goes after one move (slow
%   way, used once to build the table).
compute_move_position(Move, Pos, NewPos) :-
    move_name(Move, Face, Times),
    move_perm(Face, Perm),
    times_position(Times, Perm, Pos, NewPos).

% times_position/4: follows one sticker through a table, N times.
times_position(0, _, Pos, Pos).

times_position(N, Perm, Pos, NewPos) :-
    N > 0,
    once(nth1(Mid, Perm, Pos)),
    N1 is N - 1,
    times_position(N1, Perm, Mid, NewPos).

% move_to/3: the fast table: move, spot, new spot.
:- dynamic move_to/3.

% build_move_table: fills the fast table for all 18 moves and 54 spots.
build_move_table :-
    retractall(move_to(_, _, _)),
    forall(( move_name(M, _, _), between(1, 54, P) ),
           ( compute_move_position(M, P, N),
             assertz(move_to(M, P, N)) )).
:- build_move_table.

% move_position(Move, Pos, NewPos): where a sticker goes after one move (fast table
%   lookup).
move_position(Move, Pos, NewPos) :-
    move_to(Move, Pos, NewPos).

% move_positions(Move, Positions, NewPositions): the same for a list of spots.
move_positions(Move, Positions, NewPositions) :-
    maplist(move_position(Move), Positions, NewPositions).

% track_positions/3: follows a list of spots through a list of moves.
track_positions([], Positions, Positions).

track_positions([Move|Rest], Positions, Final) :-
    move_positions(Move, Positions, Next),
    track_positions(Rest, Next, Final).

% edge_at_positions/3: which edge slot two sticker spots are in, and if flipped.
edge_at_positions([A, B], SlotName, Flip) :-
    (   edge(_, SlotName, [A, B]) -> Flip = 0
    ;   edge(_, SlotName, [B, A]) -> Flip = 1
    ).

% track_edge_report(Scramble, Name): follows one edge through the moves in the text and
%   prints where it ends up.
track_edge_report(Scramble, Name) :-
    parse_moves(Scramble, Moves),
    edge(_, Name, Home),
    track_positions(Moves, Home, Now),
    edge_at_positions(Now, Slot, Flip),
    format("Edge ~w: positions ~w -> ~w, slot ~w, flip ~w~n",
           [Name, Home, Now, Slot, Flip]).

% test_tracking_known: follows spots through moves; answers worked out by hand.
test_tracking_known :-
    forall(member(t(Scramble, Name, Want),
                  [ t("R",   dr, [24, 13]),
                    t("R2",  dr, [6, 11]),
                    t("R'",  dr, [49, 15]),
                    t("F",   df, [42, 22]),
                    t("R F", dr, [26, 29]) ]),
           ( parse_moves(Scramble, Moves),
             edge(_, Name, Home),
             track_positions(Moves, Home, Got),
             Got == Want )),
    format("Tracking matches 5 known moves (R, R2, R', F, R F)~n").

% test_tracking_vs_cube: following all 54 spots must match really moving a numbered
%   cube.
test_tracking_vs_cube :-
    numlist(1, 54, All),
    forall(between(1, 100, _),
           ( random_scramble(20, Ms),
             apply_moves(Ms, All, After),
             track_positions(Ms, All, Tracked),
             forall(nth1(P, Tracked, NewP),
                    nth1(NewP, After, P)) )),
    format("Tracking matches the full cube: 100 random move lists~n").

% test_tracking_edges: following each cross edge must match the edge finder.
test_tracking_edges :-
    solved_cube(S),
    forall(between(1, 100, _),
           ( random_scramble(20, Ms),
             apply_moves(Ms, S, C),
             forall(member(Name, [dr, df, dl, db]),
                    ( edge(_, Name, Home),
                      track_positions(Ms, Home, Now),
                      edge_at_positions(Now, Slot, Flip),
                      where_is_edge(C, Name, Slot, Flip) )) )),
    format("Tracking matches the edge locator: 100 random scrambles, 4 edges each~n").

% test_tracking: runs all the tracking tests.
test_tracking :-
    test_tracking_known,
    test_tracking_vs_cube,
    test_tracking_edges,
    format("Tracking tests passed~n").

% edge_goal(Name, Goal): the two spots an edge sits on when solved.
edge_goal(Name, Goal) :-
    edge(_, Name, Goal).

% edge_current_positions(Cube, Name, Positions): the two spots where an edge piece is
%   right now.
edge_current_positions(Cube, Name, Positions) :-
    where_is_edge(Cube, Name, Slot, Flip),
    edge(_, Slot, SlotPositions),
    (   Flip =:= 0
    ->  Positions = SlotPositions
    ;   reverse(SlotPositions, Positions)
    ).

% edge_search(Positions, Goal, Moves): fewest moves to bring one edge home (tries 0
%   moves, then 1, then 2, up to 6).
edge_search(Positions, Goal, Moves) :-
    once(( between(0, 6, Depth),
           edge_dfs(Depth, none, Positions, Goal, Moves) )).

% edge_dfs/5: tries every move list of exactly Depth moves.
edge_dfs(0, _, Goal, Goal, []).

edge_dfs(Depth, PrevFace, Positions, Goal, [Move|Rest]) :-
    Depth > 0,
    move_name(Move, Face, _),
    Face \== PrevFace,
    move_positions(Move, Positions, Next),
    Depth1 is Depth - 1,
    edge_dfs(Depth1, Face, Next, Goal, Rest).

% solve_edge(Cube, Name, Moves): moves that bring one cross edge home (other edges may
%   move).
solve_edge(Cube, Name, Moves) :-
    edge_current_positions(Cube, Name, Positions),
    edge_goal(Name, Goal),
    edge_search(Positions, Goal, Moves).

% solve_edge_report(Scramble, Name): scrambles, solves one cross edge, prints and checks
%   it.
solve_edge_report(Scramble, Name) :-
    scramble_cube(Scramble, Cube),
    solve_edge(Cube, Name, Moves),
    length(Moves, N),
    (   Moves == []
    ->  format("Edge ~w is already home: 0 moves~n", [Name])
    ;   scramble_text(Moves, Text),
        format("Edge ~w: ~w move(s): ~w~n", [Name, N, Text])
    ),
    apply_moves(Moves, Cube, After),
    (   where_is_edge(After, Name, Name, 0)
    ->  format("Check on the real cube: edge ~w is home~n", [Name])
    ;   format("Check on the real cube: FAILED~n")
    ).

% all_edge_states(States): every way an edge can sit: 12 spots x 2 flips = 24.
all_edge_states(States) :-
    findall(Pos,
            ( edge(_, _, SlotPos),
              ( Pos = SlotPos ; reverse(SlotPos, Pos) ) ),
            States).

% edge_dist/4: table: how many moves an edge needs to get home.
:- dynamic edge_dist/4.

% build_edge_dist_table: fills the edge distance table (runs once when the file loads).
build_edge_dist_table :-
    retractall(edge_dist(_, _, _, _)),
    all_edge_states(States),
    forall(( member(Name, [dr, df, dl, db]),
             member([A, B], States) ),
           ( edge_goal(Name, Goal),
             edge_search([A, B], Goal, Ms),
             length(Ms, D),
             assertz(edge_dist(Name, A, B, D)) )).
:- build_edge_dist_table.

% test_edge_search_exhaustive: solves every position of each cross edge and checks the
%   shortest lengths.
test_edge_search_exhaustive :-
    all_edge_states(States),
    length(States, 24),
    forall(member(Name, [dr, df, dl, db]),
           ( edge_goal(Name, Goal),
             findall(D, ( member(S, States),
                          edge_search(S, Goal, Ms),
                          length(Ms, D) ),
                     Ds),
             length(Ds, 24),
             findall(K-N, ( between(0, 3, K),
                            include(==(K), Ds, Same),
                            length(Same, N) ),
                     Counts),
             Counts == [0-1, 1-6, 2-13, 3-4] )),
    format("All 24 states of all 4 cross edges solved: 1 at 0 moves, 6 at 1, 13 at 2, 4 at 3~n").

% test_solve_edge_random: random cubes: each edge solved and checked on the full cube.
test_solve_edge_random :-
    solved_cube(S),
    forall(between(1, 200, _),
           ( random_scramble(25, Ms),
             apply_moves(Ms, S, C),
             forall(member(Name, [dr, df, dl, db]),
                    ( solve_edge(C, Name, Sol),
                      length(Sol, L),
                      L =< 3,
                      apply_moves(Sol, C, C2),
                      where_is_edge(C2, Name, Name, 0) )) )),
    format("200 random scrambles x 4 edges: each edge solved in 3 moves or fewer, checked on the full cube~n").

% test_edge_search: runs the edge search tests.
test_edge_search :-
    test_edge_search_exhaustive,
    test_solve_edge_random,
    format("Edge search tests passed~n").

% home_item/2: the info about an edge when it is solved.
home_item(Name, e(Name, A, B)) :-
    edge(_, Name, [A, B]).

% now_item/3: the info about an edge on this cube.
now_item(Cube, Name, e(Name, A, B)) :-
    edge_current_positions(Cube, Name, [A, B]).

% move_item/3: the info after one move.
move_item(Move, e(Name, A, B), e(Name, A1, B1)) :-
    move_position(Move, A, A1),
    move_position(Move, B, B1).

% close_enough/2: true if the edge could still get home in R moves.
close_enough(R, e(Name, A, B)) :-
    edge_dist(Name, A, B, D),
    D =< R.

% ok_order(Prev, Face): skips useless move orders (same face twice, or opposite faces in
%   both orders).
ok_order(Prev, Face) :-
    Face \== Prev,
    \+ member(Prev-Face, [d-u, l-r, b-f]).

% keep_dfs/5: like edge_dfs for many edges, and stops early on tries that cannot work.
keep_dfs(0, _, Goal, Goal, []).

keep_dfs(Depth, Prev, Items, Goal, [Move|Rest]) :-
    Depth > 0,
    move_name(Move, Face, _),
    ok_order(Prev, Face),
    maplist(move_item(Move), Items, Next),
    Depth1 is Depth - 1,
    maplist(close_enough(Depth1), Next),
    keep_dfs(Depth1, Face, Next, Goal, Rest).

% keep_search(Start, Home, KeptItems, Moves): fewest moves for one edge while the edges
%   to keep end up home (up to 8 moves).
keep_search(Start, Home, KeptItems, Moves) :-
    once(( between(0, 8, Depth),
           keep_dfs(Depth, none, [Start|KeptItems], [Home|KeptItems], Moves) )).

% solve_edge_keeping(Cube, Name, Kept, Moves): moves that bring an edge home and keep
%   the already-solved edges home.
solve_edge_keeping(Cube, Name, Kept, Moves) :-
    now_item(Cube, Name, Start),
    home_item(Name, Home),
    maplist(home_item, Kept, KeptItems),
    keep_search(Start, Home, KeptItems, Moves).

% position_face(Pos, Face): which face a sticker spot belongs to.
position_face(Pos, Face) :-
    once(( face_start(Face, S),
           Pos > S,
           Pos =< S + 9 )).

% slot_layer(Slot, Layer): is an edge spot in the top, middle or bottom layer.
slot_layer(Slot, Layer) :-
    (   memberchk(Slot, [ur, uf, ul, ub]) -> Layer = top
    ;   memberchk(Slot, [dr, df, dl, db]) -> Layer = bottom
    ;   Layer = middle
    ).

% valid_case/1: the six situations a cross edge can be in.
valid_case(solved).
valid_case(top_white_up).
valid_case(top_white_side).
valid_case(middle_layer).
valid_case(bottom_wrong_slot).
valid_case(bottom_flipped).

% edge_case(Cube, Name, Case): which of the six situations an edge is in right now.
edge_case(Cube, Name, Case) :-
    edge_current_positions(Cube, Name, [A, B]),
    edge_at_positions([A, B], Slot, _),
    position_face(A, WhiteFace),
    slot_layer(Slot, Layer),
    (   Slot == Name, WhiteFace == d -> Case = solved
    ;   Layer == bottom, WhiteFace == d -> Case = bottom_wrong_slot
    ;   Layer == bottom -> Case = bottom_flipped
    ;   Layer == middle -> Case = middle_layer
    ;   WhiteFace == u -> Case = top_white_up
    ;   Case = top_white_side
    ).

% cross_steps(Cube, Steps): the cross as steps step(Edge, Case, Moves), in the order df,
%   dr, db, dl.
cross_steps(Cube, Steps) :-
    cross_steps_from(Cube, [df, dr, db, dl], [], Steps).

% cross_steps_from/4: solves the edges still to do, keeping the ones already done.
cross_steps_from(_, [], _, []).

cross_steps_from(Cube, [Name|Rest], Done, [step(Name, Case, M1)|Steps]) :-
    edge_case(Cube, Name, Case),
    solve_edge_keeping(Cube, Name, Done, M1),
    apply_moves(M1, Cube, Cube1),
    cross_steps_from(Cube1, Rest, [Name|Done], Steps).

% steps_moves(Steps, Moves): all the moves of all the steps, in order.
steps_moves(Steps, Moves) :-
    findall(M, member(step(_, _, M), Steps), Lists),
    append(Lists, Moves).

% solve_cross(Cube, Moves): the moves that make the cross.
solve_cross(Cube, Moves) :-
    cross_steps(Cube, Steps),
    steps_moves(Steps, Moves).

% solve_cross_report(Scramble): scrambles, solves the cross, shows the moves and checks
%   them.
solve_cross_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    solve_cross(Cube, Moves),
    length(Moves, N),
    scramble_text(Moves, Text),
    format("Cross solution (~w moves): ~w~n", [N, Text]),
    apply_moves(Moves, Cube, After),
    (   cross_solved(After)
    ->  format("Check on the real cube: cross solved~n")
    ;   format("Check on the real cube: FAILED~n")
    ).

% cross_steps_report(Scramble): scrambles, then shows each step with its case.
cross_steps_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    cross_steps(Cube, Steps),
    length(Steps, Total),
    forall(nth1(I, Steps, step(Name, Case, Moves)),
           ( scramble_text(Moves, Text),
             length(Moves, N),
             format("Step ~w of ~w: edge ~w, case ~w, ~w moves: ~w~n",
                    [I, Total, Name, Case, N, Text]) )).

% test_cross_easy: easy scrambles where the answer is known.
test_cross_easy :-
    forall(member(Scramble-Want,
                  [ ""-0, "U"-0, "R"-1, "R2"-1, "F"-1,
                    "D"-1, "D2"-1, "L"-1, "B"-1 ]),
           ( scramble_cube(Scramble, C),
             solve_cross(C, Moves),
             length(Moves, Want),
             apply_moves(Moves, C, After),
             cross_solved(After) )),
    format("Cross solver: 9 easy scrambles solved in the expected number of moves~n").

% test_cases: the case names must be right on cubes worked out by hand.
test_cases :-
    forall(member(t(Scramble, Name, Want),
                  [ t("",     dr, solved),
                    t("U",    dr, solved),
                    t("R",    dr, middle_layer),
                    t("F",    df, middle_layer),
                    t("R2",   dr, top_white_up),
                    t("R' B", dr, top_white_side),
                    t("D",    df, bottom_wrong_slot),
                    t("R F",  dr, bottom_flipped) ]),
           ( scramble_cube(Scramble, C),
             edge_case(C, Name, Got),
             Got == Want )),
    format("Case labels correct for 8 known cubes (all 6 labels)~n").

% steps_ok/3: replays the steps on the full cube; each edge and earlier edges must be
%   home.
steps_ok(_, [], _).

steps_ok(Cube, [step(Name, Case, Moves)|Rest], Done) :-
    valid_case(Case),
    (   Case == solved -> Moves == [] ; Moves \== [] ),
    apply_moves(Moves, Cube, Cube1),
    forall(member(E, [Name|Done]), where_is_edge(Cube1, E, E, 0)),
    steps_ok(Cube1, Rest, [Name|Done]).

% test_cross_full(N): N random scrambles; every step replayed and the final cross must
%   be solved.
test_cross_full(N) :-
    solved_cube(S),
    statistics(cputime, T0),
    findall(Steps,
            ( between(1, N, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, C),
              cross_steps(C, Steps),
              length(Steps, 4),
              steps_ok(C, Steps, []),
              steps_moves(Steps, Sol),
              apply_moves(Sol, C, After),
              cross_solved(After) ),
            AllSteps),
    length(AllSteps, N),
    statistics(cputime, T1),
    findall(L, ( member(Steps, AllSteps),
                 steps_moves(Steps, Sol),
                 length(Sol, L) ),
            Ls),
    sum_list(Ls, Total),
    max_list(Ls, Longest),
    Avg is Total / N,
    Secs is T1 - T0,
    format("~w random scrambles: every step replayed on the full cube, cross solved every time~n", [N]),
    format("Moves per cross: average ~1f, longest ~w. Time: ~1f seconds~n", [Avg, Longest, Secs]),
    findall(Case, ( member(Steps, AllSteps), member(step(_, Case, _), Steps) ), Cases),
    sort(Cases, Kinds),
    format("Cases met (4 per scramble):~n"),
    forall(member(K, Kinds),
           ( include(==(K), Cases, Same),
             length(Same, Count),
             format("  ~w: ~w~n", [K, Count]) )).

% test_cross: runs the cross solver tests.
test_cross :-
    test_cross_easy,
    test_cases,
    test_cross_full(500),
    format("Cross solver tests passed~n").

% test_last_edge: the hardest case: the last edge in each of the 18 places left.
test_last_edge :-
    all_edge_states(States),
    maplist(home_item, [df, dr, db], Kept),
    home_item(dl, Home),
    statistics(cputime, T0),
    findall(Len,
            ( member([A, B], States),
              \+ ( member(e(_, KA, KB), Kept), memberchk(A, [KA, KB]) ),
              keep_search(e(dl, A, B), Home, Kept, Ms),
              length(Ms, Len) ),
            Lens),
    statistics(cputime, T1),
    length(Lens, 18),
    msort(Lens, Sorted),
    max_list(Lens, Longest),
    Secs is T1 - T0,
    format("Last cross edge: all 18 possible states solved. Lengths: ~w~n", [Sorted]),
    format("Longest: ~w moves. Time: ~1f seconds~n", [Longest, Secs]).