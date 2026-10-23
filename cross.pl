% cross.pl
% THE CROSS SOLVER: finds moves that put the four white edges (dr, df, dl, db)
% on the bottom face, each one matching its side color.
% Loads stages.pl, which loads cube.pl and moves.pl.
:- ensure_loaded(stages).

% ---------- Where is each cross edge? ----------

% where_is_edge(+Cube, +Name, -Slot, -Flip)
% The edge piece that BELONGS in spot Name is now sitting in spot Slot,
% and Flip says if it is flipped (0 = no, 1 = yes).
% Flip 0 means its two stickers are in the same order as when solved.
% (This is our own way of counting, not the "good edge / bad edge" idea
% you may know from cubing.)
where_is_edge(Cube, Name, SlotName, Flip) :-
    edge(Home, Name, _),                  % the number of the piece's home spot
    edge_state(Cube, Slot, Home, Flip),   % which spot is holding that piece?
    edge(Slot, SlotName, _).              % turn that spot's number into its name

% cross_edge_places(+Cube, -Places)
% Where are the four cross edges? Gives a list like [dr-fr-0, df-df-0, ...]
% which reads "edge dr is in spot fr, not flipped".
cross_edge_places(Cube, Places) :-
    findall(Name-Slot-Flip,
            ( member(Name, [dr, df, dl, db]),
              where_is_edge(Cube, Name, Slot, Flip) ),
            Places).

% cross_edges_report(+Scramble): scrambles a solved cube and prints where
% the four cross edges ended up. (For trying things out.)
cross_edges_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    cross_edge_places(Cube, Places),
    forall(member(Name-Slot-Flip, Places),
           format("~w: at ~w, flip ~w~n", [Name, Slot, Flip])).

% test_where: the edge finder must give the right answers.
test_where :-
    solved_cube(S),
    forall(member(N, [dr, df, dl, db]),
           where_is_edge(S, N, N, 0)),            % solved cube: every edge is at home
    scramble_cube("F", C1),
    where_is_edge(C1, df, fl, 1),                 % an F move sends df to the fl spot
    scramble_cube("R", C2),
    where_is_edge(C2, dr, fr, 0),                 % an R move sends dr to the fr spot
    forall(between(1, 100, _),
           ( random_scramble(25, Ms),
             apply_moves(Ms, S, C),
             cross_edge_places(C, L),
             length(L, 4),                        % exactly one answer for each edge
             findall(Sl, member(_-Sl-_, L), Slots),
             sort(Slots, Distinct),
             length(Distinct, 4) )),              % the four edges sit in four different spots
    format("Edge locator correct: solved cube, F, R, and 100 random cubes~n").

% ---------- Following stickers through the moves ----------

% compute_move_position(+Move, +Pos, -NewPos)
% The sticker that is at spot Pos moves to spot NewPos when Move is done.
% This is the SLOW way (it searches the table), so we only use it once,
% to build the fast lookup table below.
compute_move_position(Move, Pos, NewPos) :-
    move_name(Move, Face, Times),         % for example rp = the r table, 3 times
    move_perm(Face, Perm),
    times_position(Times, Perm, Pos, NewPos).

% times_position(+Times, +Perm, +Pos, -NewPos)
% Follows one sticker through the table, as many times as asked.
times_position(0, _, Pos, Pos).                   % zero times: the sticker stays where it is
times_position(N, Perm, Pos, NewPos) :-
    N > 0,
    once(nth1(Mid, Perm, Pos)),   % the table says "new spot gets old spot", so we look
                                  % for the spot Mid whose entry is Pos
    N1 is N - 1,
    times_position(N1, Perm, Mid, NewPos).

% ----- The fast lookup table -----
% move_to(Move, Pos, NewPos) is one fact for every move and every spot
% (18 x 54 = 972 facts). "dynamic" means facts can be added while the
% program runs. build_move_table adds them with assertz.
:- dynamic move_to/3.

build_move_table :-
    retractall(move_to(_, _, _)),                 % start with an empty table
    forall(( move_name(M, _, _), between(1, 54, P) ),
           ( compute_move_position(M, P, N),
             assertz(move_to(M, P, N)) )).

:- build_move_table.      % runs once, when this file is loaded

% move_position(+Move, +Pos, -NewPos): the fast way, just a table lookup.
move_position(Move, Pos, NewPos) :-
    move_to(Move, Pos, NewPos).

% move_positions(+Move, +Positions, -NewPositions)
% The same thing for a whole list of spots at once.
move_positions(Move, Positions, NewPositions) :-
    maplist(move_position(Move), Positions, NewPositions).

% track_positions(+Moves, +Positions, -Final)
% Follows a list of spots through a whole list of moves.
track_positions([], Positions, Positions).
track_positions([Move|Rest], Positions, Final) :-
    move_positions(Move, Positions, Next),
    track_positions(Rest, Next, Final).

% edge_at_positions(+Positions, -SlotName, -Flip)
% Takes two sticker spots that sit in one edge spot. Tells us which edge spot
% it is, and whether they are in the spot's normal order (Flip 0) or reversed (Flip 1).
% Fails if the two spots are not one edge spot.
edge_at_positions([A, B], SlotName, Flip) :-
    (   edge(_, SlotName, [A, B]) -> Flip = 0
    ;   edge(_, SlotName, [B, A]) -> Flip = 1
    ).

% track_edge_report(+Scramble, +Name): follows edge Name from its home
% through the moves in the text and prints where it ends up.
track_edge_report(Scramble, Name) :-
    parse_moves(Scramble, Moves),
    edge(_, Name, Home),
    track_positions(Moves, Home, Now),
    edge_at_positions(Now, Slot, Flip),
    format("Edge ~w: positions ~w -> ~w, slot ~w, flip ~w~n",
           [Name, Home, Now, Slot, Flip]).

% ---------- Tests for the tracking ----------

% test_tracking_known: answers worked out by hand from the move tables.
test_tracking_known :-
    forall(member(t(Scramble, Name, Want),
                  [ t("R",   dr, [24, 13]),     % dr goes to the fr spot
                    t("R2",  dr, [6, 11]),      % dr goes to the ur spot
                    t("R'",  dr, [49, 15]),     % dr goes to the br spot
                    t("F",   df, [42, 22]),     % df goes to the fl spot (flipped)
                    t("R F", dr, [26, 29]) ]),  % dr goes to fr, then down to df
           ( parse_moves(Scramble, Moves),
             edge(_, Name, Home),
             track_positions(Moves, Home, Got),
             Got == Want )),
    format("Tracking matches 5 known moves (R, R2, R', F, R F)~n").

% test_tracking_vs_cube: follows ALL 54 spots and compares with really
% moving a cube whose stickers are numbered 1 to 54.
test_tracking_vs_cube :-
    numlist(1, 54, All),
    forall(between(1, 100, _),
           ( random_scramble(20, Ms),
             apply_moves(Ms, All, After),          % really move the numbered cube
             track_positions(Ms, All, Tracked),    % follow every spot
             forall(nth1(P, Tracked, NewP),        % sticker P is now at NewP...
                    nth1(NewP, After, P)) )),      % ...so the cube must show P there
    format("Tracking matches the full cube: 100 random move lists~n").

% test_tracking_edges: follows each cross edge from its home and compares
% with the edge finder from the top of this file.
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

test_tracking :-
    test_tracking_known,
    test_tracking_vs_cube,
    test_tracking_edges,
    format("Tracking tests passed~n").

% ---------- Searching for one edge ----------

% edge_goal(+Name, -Goal): the two spots the edge Name sits on when it is solved.
edge_goal(Name, Goal) :-
    edge(_, Name, Goal).

% edge_current_positions(+Cube, +Name, -Positions)
% The two spots where the two stickers of piece Name are right now,
% listed in the same order as in edge_goal (first sticker first).
edge_current_positions(Cube, Name, Positions) :-
    where_is_edge(Cube, Name, Slot, Flip),
    edge(_, Slot, SlotPositions),
    (   Flip =:= 0
    ->  Positions = SlotPositions
    ;   reverse(SlotPositions, Positions)
    ).

% edge_search(+Positions, +Goal, -Moves)
% Finds the SHORTEST list of moves that carries the edge from Positions to
% Goal. It tries 0 moves, then 1, then 2, ... up to 6 ("iterative deepening":
% go a little deeper each round until something works).
edge_search(Positions, Goal, Moves) :-
    once(( between(0, 6, Depth),
           edge_dfs(Depth, none, Positions, Goal, Moves) )).

% edge_dfs(+Depth, +PrevFace, +Positions, +Goal, -Moves)
% "Depth-first search": use exactly Depth more moves to get from Positions to Goal.
% PrevFace is the face we just turned, so we never turn it twice in a row.
edge_dfs(0, _, Goal, Goal, []).                  % no moves left: we must be at the goal
edge_dfs(Depth, PrevFace, Positions, Goal, [Move|Rest]) :-
    Depth > 0,
    move_name(Move, Face, _),                    % try each of the 18 moves one by one
    Face \== PrevFace,
    move_positions(Move, Positions, Next),       % where does the edge go?
    Depth1 is Depth - 1,
    edge_dfs(Depth1, Face, Next, Goal, Rest).

% solve_edge(+Cube, +Name, -Moves)
% Moves that bring the cross edge Name home. (Other edges may get moved.)
solve_edge(Cube, Name, Moves) :-
    edge_current_positions(Cube, Name, Positions),
    edge_goal(Name, Goal),
    edge_search(Positions, Goal, Moves).

% solve_edge_report(+Scramble, +Name): scrambles a solved cube, finds the
% moves for one cross edge, prints them, and checks them on the real cube.
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

% all_edge_states(-States): every way an edge can sit: 12 spots x 2 flips = 24.
all_edge_states(States) :-
    findall(Pos,
            ( edge(_, _, SlotPos),
              ( Pos = SlotPos ; reverse(SlotPos, Pos) ) ),
            States).

% ----- A second table: how far is each edge from home, on its own? -----
% edge_dist(Name, A, B, D): the edge Name, with its stickers at spots A and B,
% needs at least D moves to get home, even if we ignore every other edge.
% (It is the answer of the single-edge search above, saved for later.)
:- dynamic edge_dist/4.

build_edge_dist_table :-
    retractall(edge_dist(_, _, _, _)),
    all_edge_states(States),
    forall(( member(Name, [dr, df, dl, db]),
             member([A, B], States) ),
           ( edge_goal(Name, Goal),
             edge_search([A, B], Goal, Ms),
             length(Ms, D),
             assertz(edge_dist(Name, A, B, D)) )).

:- build_edge_dist_table.     % runs once, when this file is loaded

% ---------- Tests for the single-edge search ----------

% test_edge_search_exhaustive: solves EVERY possible position of each cross
% edge. Counted by hand: 1 position needs 0 moves, 6 need 1, 13 need 2,
% 4 need 3. The search must find exactly those shortest lengths.
test_edge_search_exhaustive :-
    all_edge_states(States),
    length(States, 24),
    forall(member(Name, [dr, df, dl, db]),
           ( edge_goal(Name, Goal),
             findall(D, ( member(S, States),
                          edge_search(S, Goal, Ms),
                          length(Ms, D) ),
                     Ds),
             length(Ds, 24),                      % every position got solved
             findall(K-N, ( between(0, 3, K),
                            include(==(K), Ds, Same),
                            length(Same, N) ),
                     Counts),
             Counts == [0-1, 1-6, 2-13, 3-4] )),
    format("All 24 states of all 4 cross edges solved: 1 at 0 moves, 6 at 1, 13 at 2, 4 at 3~n").

% test_solve_edge_random: random full cubes, each edge solved, then
% checked by really moving the whole cube.
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

test_edge_search :-
    test_edge_search_exhaustive,
    test_solve_edge_random,
    format("Edge search tests passed~n").

% ---------- Solving one edge while keeping the others ----------

% An "item" e(Name, A, B) says: the edge called Name has its first sticker
% at spot A and its second sticker at spot B.

% home_item(+Name, -Item): the item for edge Name when it is solved.
home_item(Name, e(Name, A, B)) :-
    edge(_, Name, [A, B]).

% now_item(+Cube, +Name, -Item): where edge Name is on this cube.
now_item(Cube, Name, e(Name, A, B)) :-
    edge_current_positions(Cube, Name, [A, B]).

% move_item(+Move, +Item, -NewItem): the item after one move.
move_item(Move, e(Name, A, B), e(Name, A1, B1)) :-
    move_position(Move, A, A1),
    move_position(Move, B, B1).

% close_enough(+R, +Item): this edge could still get home in R moves
% (looking at it alone). If not, no set of R moves can fix the cube.
close_enough(R, e(Name, A, B)) :-
    edge_dist(Name, A, B, D),
    D =< R.

% ok_order(+PrevFace, +Face): is it worth turning Face right after PrevFace?
% Never the same face twice. For opposite faces (they do not get in each
% other's way) we only try one order: U then D, L then R, F then B.
ok_order(Prev, Face) :-
    Face \== Prev,
    \+ member(Prev-Face, [d-u, l-r, b-f]).

% keep_dfs(+Depth, +PrevFace, +Items, +Goal, -Moves)
% Like edge_dfs, but for a LIST of edges at once. Items says where the edges
% are now, and Goal says where they must end up. Branches that cannot finish
% in the moves we have left are cut off early (this is called "pruning").
keep_dfs(0, _, Goal, Goal, []).
keep_dfs(Depth, Prev, Items, Goal, [Move|Rest]) :-
    Depth > 0,
    move_name(Move, Face, _),
    ok_order(Prev, Face),
    maplist(move_item(Move), Items, Next),
    Depth1 is Depth - 1,
    maplist(close_enough(Depth1), Next),         % the pruning rule
    keep_dfs(Depth1, Face, Next, Goal, Rest).

% keep_search(+Start, +Home, +KeptItems, -Moves)
% Finds the shortest moves that take the edge from Start to Home while every
% edge we want to keep ends up back where it is now. Tries 0 moves, 1, 2, ... up to 8.
keep_search(Start, Home, KeptItems, Moves) :-
    once(( between(0, 8, Depth),
           keep_dfs(Depth, none, [Start|KeptItems], [Home|KeptItems], Moves) )).

% solve_edge_keeping(+Cube, +Name, +Kept, -Moves)
% Moves that bring edge Name home, and also put the edges that were already
% solved (the names in Kept) back home at the end.
solve_edge_keeping(Cube, Name, Kept, Moves) :-
    now_item(Cube, Name, Start),
    home_item(Name, Home),
    maplist(home_item, Kept, KeptItems),
    keep_search(Start, Home, KeptItems, Moves).

% ---------- Naming the situation (the "case") ----------

% position_face(+Pos, -Face): which face a sticker spot belongs to.
position_face(Pos, Face) :-
    once(( face_start(Face, S),
           Pos > S,
           Pos =< S + 9 )).

% slot_layer(+Slot, -Layer): is an edge spot in the top, middle or bottom layer?
slot_layer(Slot, Layer) :-
    (   memberchk(Slot, [ur, uf, ul, ub]) -> Layer = top
    ;   memberchk(Slot, [dr, df, dl, db]) -> Layer = bottom
    ;   Layer = middle
    ).

% valid_case(?Case): the six situations a cross edge can be in.
valid_case(solved).             % already in place
valid_case(top_white_up).       % top layer, white sticker facing up
valid_case(top_white_side).     % top layer, white sticker on a side
valid_case(middle_layer).       % middle layer (either way round)
valid_case(bottom_wrong_slot).  % bottom layer, white down, but in the wrong spot
valid_case(bottom_flipped).     % bottom layer, white sticker on a side

% edge_case(+Cube, +Name, -Case)
% Tells which of the six situations edge Name is in right now.
% The first sticker of a cross edge is its white one (the bottom sticker),
% so spot A tells us which face the white sticker is on.
edge_case(Cube, Name, Case) :-
    edge_current_positions(Cube, Name, [A, B]),
    edge_at_positions([A, B], Slot, _),          % which spot is holding it
    position_face(A, WhiteFace),
    slot_layer(Slot, Layer),
    (   Slot == Name, WhiteFace == d -> Case = solved
    ;   Layer == bottom, WhiteFace == d -> Case = bottom_wrong_slot
    ;   Layer == bottom -> Case = bottom_flipped
    ;   Layer == middle -> Case = middle_layer
    ;   WhiteFace == u -> Case = top_white_up
    ;   Case = top_white_side
    ).

% ---------- The whole cross ----------

% cross_steps(+Cube, -Steps)
% Steps is a list of step(EdgeName, Case, Moves), one for each cross edge, in
% the order we solve them: df, dr, db, dl.
cross_steps(Cube, Steps) :-
    cross_steps_from(Cube, [df, dr, db, dl], [], Steps).

% cross_steps_from(+Cube, +ToDo, +Done, -Steps)
% ToDo = edges still to solve. Done = edges already solved (we must keep them).
cross_steps_from(_, [], _, []).                  % nothing left to solve
cross_steps_from(Cube, [Name|Rest], Done, [step(Name, Case, M1)|Steps]) :-
    edge_case(Cube, Name, Case),                 % first name the situation
    solve_edge_keeping(Cube, Name, Done, M1),    % solve this edge, keeping the finished ones
    apply_moves(M1, Cube, Cube1),                % do those moves on the cube
    cross_steps_from(Cube1, Rest, [Name|Done], Steps).

% steps_moves(+Steps, -Moves): all the moves of all the steps, in order.
steps_moves(Steps, Moves) :-
    findall(M, member(step(_, _, M), Steps), Lists),
    append(Lists, Moves).

% solve_cross(+Cube, -Moves): the moves that make the cross on the bottom face.
solve_cross(Cube, Moves) :-
    cross_steps(Cube, Steps),
    steps_moves(Steps, Moves).

% solve_cross_report(+Scramble): scrambles, solves the cross, shows the moves,
% and checks the result on the real cube.
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

% cross_steps_report(+Scramble): scrambles, then shows each step with its case.
cross_steps_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    cross_steps(Cube, Steps),
    length(Steps, Total),
    forall(nth1(I, Steps, step(Name, Case, Moves)),
           ( scramble_text(Moves, Text),
             length(Moves, N),
             format("Step ~w of ~w: edge ~w, case ~w, ~w moves: ~w~n",
                    [I, Total, Name, Case, N, Text]) )).

% ---------- Tests for the whole cross ----------

% test_cross_easy: scrambles where we already know the answer. One turn of
% a face that touches a cross edge is undone by one move.
test_cross_easy :-
    forall(member(Scramble-Want,
                  [ ""-0, "U"-0, "R"-1, "R2"-1, "F"-1,
                    "D"-1, "D2"-1, "L"-1, "B"-1 ]),
           ( scramble_cube(Scramble, C),
             solve_cross(C, Moves),
             length(Moves, Want),                 % exactly the length we expect
             apply_moves(Moves, C, After),
             cross_solved(After) )),
    format("Cross solver: 9 easy scrambles solved in the expected number of moves~n").

% test_cases: checks the case names on cubes where the situation of one
% edge is known (worked out by hand from the tracking tests).
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

% steps_ok(+Cube, +Steps, +Done): replays the steps on the full cube.
% After each step, that edge and every earlier edge must be home.
steps_ok(_, [], _).
steps_ok(Cube, [step(Name, Case, Moves)|Rest], Done) :-
    valid_case(Case),
    (   Case == solved -> Moves == [] ; Moves \== [] ),   % "solved" means no moves, and the other way round
    apply_moves(Moves, Cube, Cube1),
    forall(member(E, [Name|Done]), where_is_edge(Cube1, E, E, 0)),
    steps_ok(Cube1, Rest, [Name|Done]).

% test_cross_full(+N): the big test. N random scrambles; every step is
% replayed on the full cube and the final cross must be solved.
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
    length(AllSteps, N),                 % no scramble got lost on the way
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

test_cross :-
    test_cross_easy,
    test_cases,
    test_cross_full(500),
    format("Cross solver tests passed~n").

% test_last_edge: the hardest case. Three cross edges are done, and the fourth
% (dl) can be in any of the 18 places left. Solves all 18 and reports the
% lengths.
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
    length(Lens, 18),                    % 24 positions minus the 3 taken spots x 2
    msort(Lens, Sorted),
    max_list(Lens, Longest),
    Secs is T1 - T0,
    format("Last cross edge: all 18 possible states solved. Lengths: ~w~n", [Sorted]),
    format("Longest: ~w moves. Time: ~1f seconds~n", [Longest, Secs]).