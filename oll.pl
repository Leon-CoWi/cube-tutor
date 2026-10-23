% oll.pl
% OLL = Orient the Last Layer.
% Goal: make the whole top face one colour (the top colour).
% We don't care yet if the pieces are in the right spot, only the colour.
% This file loads stages.pl (which loads cube.pl and moves.pl).
:- ensure_loaded(stages).

% ---------- The list of algorithms ----------
% oll_alg(Name, Text): a named algorithm, written the usual way.
% Every one of them keeps the cross and the 4 F2L pairs safe.
% They only change the last layer.
oll_alg(sune,       "R U R' U R U2 R'").
oll_alg(antisune,   "R U2 R' U' R U' R'").
oll_alg(t_shape,    "F R U R' U' F'").
oll_alg(p_right,    "F U R U' R' F'").
oll_alg(p_left,     "F' U' L' U L F").
oll_alg(fish_right, "F R' F' R U R U' R'").
oll_alg(cross_h,    "R U2 R' U' R U R' U' R U' R'").
oll_alg(cross_pi,   "R U2 R2 U' R2 U' R2 U2 R").
oll_alg(c_shape,    "R U R2 U' R' F R U R U' F'").
oll_alg(headlights, "R2 D R' U2 R D' R' U2 R'").

% oll_names(-Names): all the algorithm names, in the same order as above.
oll_names(Names) :-
    findall(Name, oll_alg(Name, _), Names).

% oll_moves(+Name, -Moves): the algorithm turned into a list of moves.
oll_moves(Name, Moves) :-
    oll_alg(Name, Text),
    parse_moves(Text, Moves).

% oll_list: prints the list, one line per algorithm.
oll_list :-
    forall(oll_alg(Name, Text),
           ( oll_moves(Name, Moves),
             length(Moves, N),
             format("~w: ~w (~w moves)~n", [Name, Text, N]) )).

% ---------- Test: the list of algorithms ----------

% good_alg(+Text)
% On a solved cube, the algorithm must keep the cross and all 4 pairs.
% It must also NOT leave the top face finished
% (if it did, it would be an algorithm that does nothing useful).
good_alg(Text) :-
    scramble_cube(Text, Cube),
    cross_solved(Cube),
    f2l_pairs_solved(Cube, 4),
    \+ oll_solved(Cube).

% test_oll_algs
% Checks every algorithm in the list, and that no two share a name.
test_oll_algs :-
    oll_names(Names),
    length(Names, Count),
    sort(Names, Unique),
    length(Unique, Count),
    findall(Name, ( oll_alg(Name, Text), \+ good_alg(Text) ), Bad),
    (   Bad == []
    ->  format("~w OLL algorithms: names unique, each keeps the cross and all 4 pairs, none solves the last layer by itself~n", [Count])
    ;   format("Problem with: ~w~n", [Bad]),
        fail
    ).

% ---------- Last-layer patterns ----------

% ll_positions(-Positions)
% The 21 stickers that matter for OLL, always in this order:
% the 9 top stickers, then the top row of the F, R, B and L faces.
ll_positions([ 1, 2, 3, 4, 5, 6, 7, 8, 9,      % U face
              19,20,21,                        % F face, top row
              10,11,12,                        % R face, top row
              46,47,48,                        % B face, top row
              37,38,39 ]).                     % L face, top row

% sticker_mark(+Cube, +Pos, -Mark)
% Mark is u if the sticker at Pos has the top colour, x if it is any other colour.
sticker_mark(Cube, Pos, Mark) :-
    nth1(Pos, Cube, Letter),
    (   Letter == u
    ->  Mark = u
    ;   Mark = x
    ).

% oll_pattern_of(+Cube, -Pattern)
% The 21 marks (u or x) of a cube. This is the "pattern" of its last layer.
oll_pattern_of(Cube, Pattern) :-
    ll_positions(Positions),
    maplist(sticker_mark(Cube), Positions, Pattern).

% inverse_moves(+Moves, -Inverse)
% The moves that undo Moves: flip each move, and go in reverse order.
inverse_moves(Moves, Inverse) :-
    reverse(Moves, Reversed),
    maplist(inverse_move, Reversed, Inverse).      % inverse_move is in moves.pl

% derive_pattern(+Name, -Pattern)
% Start from a solved cube, do the algorithm BACKWARDS, and record the pattern.
% That pattern is exactly the mess the algorithm is made to fix.
derive_pattern(Name, Pattern) :-
    solved_cube(Solved),
    oll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Inverse, Solved, Cube),
    oll_pattern_of(Cube, Pattern).

% oll_case(Name, Pattern)
% One fact per algorithm. They are built when this file loads.
:- dynamic oll_case/2.

build_oll_cases :-
    retractall(oll_case(_, _)),
    forall(oll_alg(Name, _),
           ( derive_pattern(Name, Pattern),
             assertz(oll_case(Name, Pattern)) )).

:- build_oll_cases.

% ---------- Looking at a pattern ----------

% top_count(+Pattern, -N)
% How many of the 9 top stickers have the top colour.
top_count(Pattern, N) :-
    length(Top, 9),
    append(Top, _, Pattern),
    include(==(u), Top, Us),
    length(Us, N).

% total_count(+Pattern, -N)
% How many of all 21 stickers have the top colour.
total_count(Pattern, N) :-
    include(==(u), Pattern, Us),
    length(Us, N).

% oll_show(+Pattern)
% Draws it as if you look down on the cube, with the F face at the bottom.
% The middle 3x3 is the top face. The edge around it is the other 12 stickers.
% The numbers are places in the pattern list (0 = empty corner of the drawing).
oll_show(Pattern) :-
    forall(member(Row, [ [ 0,18,17,16, 0],
                         [19, 1, 2, 3,15],
                         [20, 4, 5, 6,14],
                         [21, 7, 8, 9,13],
                         [ 0,10,11,12, 0] ]),
           ( forall(member(I, Row), show_cell(Pattern, I)),
             nl )).

show_cell(_, 0) :- !,
    write('  ').
show_cell(Pattern, I) :-
    nth1(I, Pattern, Mark),
    (   Mark == u
    ->  Char = '#'
    ;   Char = '.'
    ),
    format("~w ", [Char]).

% oll_show_case(+Name)
% Draws the pattern that algorithm Name fixes.
oll_show_case(Name) :-
    oll_case(Name, Pattern),
    top_count(Pattern, T),
    format("~w: ~w of 9 top stickers have the top colour~n", [Name, T]),
    oll_show(Pattern).

% ---------- Tests: the patterns ----------

% test_oll_patterns
% Checks that:
%   - every algorithm has its pattern
%   - no pattern is already finished
%   - each algorithm turns its own pattern into the finished top
test_oll_patterns :-
    solved_cube(Solved),
    oll_pattern_of(Solved, Done),                  % the finished pattern
    top_count(Done, 9),                            % all 9 top stickers are right...
    total_count(Done, 9),                          % ...and none of the side stickers are
    oll_names(Names),
    length(Names, Count),
    findall(N, oll_case(N, _), CaseNames),
    length(CaseNames, Count),                      % one pattern per algorithm
    forall(oll_case(Name, Pattern),
           ( Pattern \== Done,                     % the case is not already solved
             oll_moves(Name, Moves),
             inverse_moves(Moves, Inverse),
             apply_moves(Inverse, Solved, Cube1),   % make the mess...
             apply_moves(Moves, Cube1, Cube2),      % ...then fix it
             oll_pattern_of(Cube2, After),
             After == Done )),
    findall(P, oll_case(_, P), Patterns),
    sort(Patterns, Distinct),
    length(Distinct, D),
    format("~w case patterns derived: none is already finished, each algorithm turns its own pattern into the finished top~n", [Count]),
    format("Distinct patterns: ~w of ~w~n", [D, Count]).

% test_oll_known
% Patterns I worked out by hand.
% Sune and Antisune both fix "a cross plus one correct corner".
% The top face shows 6 top-colour stickers (5 from the cross, 1 from the
% corner). The other 3 corners each have their top-colour sticker on a
% side, so there are 9 top-colour stickers in total.
test_oll_known :-
    forall(member(Name, [sune, antisune]),
           ( oll_case(Name, Pattern),
             top_count(Pattern, 6),
             total_count(Pattern, 9) )),
    format("Sune and Antisune: 6 top stickers, 9 in total~n").

test_oll_cases :-
    test_oll_patterns,
    test_oll_known,
    format("OLL pattern tests passed~n").

% ---------- Matching a cube to a case ----------

% pre_turn(-Moves)
% The 4 ways to turn the top layer before an algorithm:
% not at all, a quarter turn, a half turn, a quarter turn the other way.
pre_turn([]).
pre_turn([u]).
pre_turn([u2]).
pre_turn([up]).

% oll_match(+Cube, -Name, -Turn)
% After turning the top layer by Turn, the cube's pattern is the pattern
% of case Name. (Prolog tries the 4 turns one by one, and for each one
% looks the pattern up in the oll_case facts.)
oll_match(Cube, Name, Turn) :-
    pre_turn(Turn),
    apply_moves(Turn, Cube, Turned),
    oll_pattern_of(Turned, Pattern),
    oll_case(Name, Pattern).

% oll_one_alg(+Cube, -Name, -Moves)
% Takes the first match and gives it as one list of moves:
% the top-layer turn first, then the algorithm.
% Fails if no algorithm in the list fits.
oll_one_alg(Cube, Name, Moves) :-
    once(( oll_match(Cube, Name, Turn),
           oll_moves(Name, Alg),
           append(Turn, Alg, Moves) )).

% fixed_ok(+Cube, +Moves)
% After doing Moves: the top is finished, and the cross and
% all 4 pairs are still solved.
fixed_ok(Cube, Moves) :-
    apply_moves(Moves, Cube, After),
    oll_solved(After),
    cross_solved(After),
    f2l_pairs_solved(After, 4).

% oll_match_report(+Scramble)
% Scrambles a solved cube, then tells which algorithm (and which U turn)
% fixes the top. (Just for trying things out.)
oll_match_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    (   oll_solved(Cube)
    ->  format("The top is already oriented~n")
    ;   oll_one_alg(Cube, Name, Moves)
    ->  length(Moves, N),
        scramble_text(Moves, Text),
        format("Case: ~w. Moves (~w): ~w~n", [Name, N, Text]),
        (   fixed_ok(Cube, Moves)
        ->  format("Check on the real cube: top oriented, cross and 4 pairs kept~n")
        ;   format("Check on the real cube: FAILED~n")
        )
    ;   format("No single table algorithm fixes this top~n")
    ).

% ---------- Tests: the matching ----------

% case_cube(+Name, -Cube)
% The cube that algorithm Name fixes:
% a solved cube with the algorithm done backwards.
case_cube(Name, Cube) :-
    solved_cube(Solved),
    oll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Inverse, Solved, Cube).

% test_oll_match_cases
% For every case and every U turn, make a cube that needs that turn.
% Then check that an algorithm is found and that it works.
test_oll_match_cases :-
    findall(Name-Turn, ( oll_case(Name, _), pre_turn(Turn) ), Combos),
    length(Combos, Count),
    forall(member(Name-Turn, Combos),
           ( case_cube(Name, Case),
             inverse_moves(Turn, Back),
             apply_moves(Back, Case, Cube),         % the case, turned out of place
             oll_one_alg(Cube, _, Moves),
             fixed_ok(Cube, Moves) )),
    format("10 cases x 4 U turns = ~w cubes: each one matched and fixed by a table algorithm~n", [Count]).

% random_ll_cube(-Cube)
% A random last layer. Start from a solved cube and do 3 random algorithms
% from the list, each after a random U turn. The first two layers stay
% solved, but the last layer gets mixed up.
random_ll_cube(Cube) :-
    solved_cube(Solved),
    ll_scramble(3, Solved, Cube).

ll_scramble(0, Cube, Cube).
ll_scramble(N, Cube0, Cube) :-
    N > 0,
    oll_names(Names),
    random_member(Name, Names),
    findall(T, pre_turn(T), Turns),
    random_member(Turn, Turns),
    oll_moves(Name, Moves),
    apply_moves(Turn, Cube0, Cube1),
    apply_moves(Moves, Cube1, Cube2),
    N1 is N - 1,
    ll_scramble(N1, Cube2, Cube).

% test_oll_match_random(+N)
% N random last layers. Each one must be one of these:
%   - already finished
%   - no single algorithm fits (this is allowed)
%   - a match is found, and it really fixes the top
% A match that does NOT fix the top makes the test fail.
test_oll_match_random(N) :-
    findall(R,
            ( between(1, N, _),
              random_ll_cube(Cube),
              (   oll_solved(Cube)
              ->  R = solved
              ;   oll_one_alg(Cube, _, Moves)
              ->  (   fixed_ok(Cube, Moves)
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

test_oll_matching :-
    test_oll_match_cases,
    test_oll_match_random(200),
    format("OLL matching tests passed~n").

% ---------- The OLL solver ----------

% oll_option(Name, Moves, Map)
% One way to use the list: a U turn followed by algorithm Name, as one
% list of Moves.
% Map tells how those moves shuffle the 21 pattern stickers:
% the new mark at place I is the old mark at place Map[I].
% Built when the file loads.
:- dynamic oll_option/3.

% ll_map(+Moves, -Map)
% Do Moves on a cube whose stickers are numbered 1 to 54, and see where each
% of the 21 last-layer stickers came from. If one came from outside the
% last layer this fails (it should never happen).
ll_map(Moves, Map) :-
    ll_positions(Positions),
    numlist(1, 54, Labels),
    apply_moves(Moves, Labels, Moved),
    maplist(map_index(Positions, Moved), Positions, Map).

map_index(Positions, Moved, Pos, Index) :-
    nth1(Pos, Moved, Source),                      % which sticker is at Pos now
    once(nth1(Index, Positions, Source)).          % its place in the pattern

build_oll_options :-
    retractall(oll_option(_, _, _)),
    forall(( oll_alg(Name, _), pre_turn(Turn) ),
           ( oll_moves(Name, Alg),
             append(Turn, Alg, Moves),
             ll_map(Moves, Map),
             assertz(oll_option(Name, Moves, Map)) )).

:- build_oll_options.

% pattern_step(+Pattern, +Map, -New)
% The pattern after using one option.
pattern_step(Pattern, Map, New) :-
    maplist(pattern_at(Pattern), Map, New).

pattern_at(Pattern, I, Mark) :-
    nth1(I, Pattern, Mark).

% ---- All 216 possible last-layer orientations ----

% put_at(+List, +Pos, +Item, -New)
% The list with the item at Pos swapped for a new one.
put_at(List, Pos, Item, New) :-
    nth1(Pos, List, _, Rest),                      % take the old item out...
    nth1(Pos, New, Item, Rest).                    % ...and put the new one in

put_all([], [], Cube, Cube).
put_all([P|Ps], [V|Vs], Cube0, Cube) :-
    put_at(Cube0, P, V, Cube1),
    put_all(Ps, Vs, Cube1, Cube).

sticker_at(Cube, Pos, Item) :-
    nth1(Pos, Cube, Item).

% rotate_by(+N, +List, -Rotated)
% Moves the first item to the end, N times.
% Works on a list of any length (rotate_left in cube.pl is only for corners).
rotate_by(0, List, List) :- !.
rotate_by(N, [H|T], Rotated) :-
    N > 0,
    append(T, [H], List1),
    N1 is N - 1,
    rotate_by(N1, List1, Rotated).

% twist_slot(+Cube, +Positions, +N, -New)
% Turns the stickers of one piece N places round
% (twists a corner, or flips an edge).
twist_slot(Cube, Positions, N, New) :-
    maplist(sticker_at(Cube), Positions, Vals),
    rotate_by(N, Vals, Rotated),
    put_all(Positions, Rotated, Cube, New).

% twist_corners(+Twists, +Slots, +Cube, -New)
% Corner slots 1 to 4 are the top ones (urf, ufl, ulb, ubr).
% Each one gets its twist: 0, 1 or 2.
twist_corners([], [], Cube, Cube).
twist_corners([T|Ts], [S|Ss], Cube0, Cube) :-
    corner(S, _, Positions),
    twist_slot(Cube0, Positions, T, Cube1),
    twist_corners(Ts, Ss, Cube1, Cube).

% flip_edges(+Flips, +Slots, +Cube, -New)
% Edge slots 1 to 4 are the top ones (ur, uf, ul, ub).
% Each one gets its flip: 0 or 1.
flip_edges([], [], Cube, Cube).
flip_edges([F|Fs], [S|Ss], Cube0, Cube) :-
    edge(S, _, Positions),
    twist_slot(Cube0, Positions, F, Cube1),
    flip_edges(Fs, Ss, Cube1, Cube).

% all_ll_cubes(-Cubes)
% One cube for every legal way the last layer can be oriented.
% On a real cube, the corner twists must add up to a multiple of 3 and
% the edge flips must add up to an even number. That gives 27 x 8 = 216 cubes.
all_ll_cubes(Cubes) :-
    solved_cube(Solved),
    findall(Cube,
            ( length(Ts, 4), maplist(between(0, 2), Ts),
              sum_list(Ts, SumT), 0 =:= SumT mod 3,
              length(Fs, 4), maplist(between(0, 1), Fs),
              sum_list(Fs, SumF), 0 =:= SumF mod 2,
              twist_corners(Ts, [1,2,3,4], Solved, Cube1),
              flip_edges(Fs, [1,2,3,4], Cube1, Cube) ),
            Cubes).

% ---- The table: the best option for every pattern ----

% oll_dist(Pattern, D): this pattern needs D algorithms (with U turns).
% oll_next(Pattern, Name, Moves): the best next step for this pattern.
:- dynamic oll_dist/2, oll_next/3.

build_oll_table :-
    retractall(oll_dist(_, _)),
    retractall(oll_next(_, _, _)),
    all_ll_cubes(Cubes),
    maplist(oll_pattern_of, Cubes, Patterns0),
    sort(Patterns0, Patterns),
    solved_cube(Solved),
    oll_pattern_of(Solved, Done),
    assertz(oll_dist(Done, 0)),
    fill_levels(Patterns, 0).

% fill_levels(+Patterns, +D)
% Look at every pattern that has no distance yet. If one option takes it to
% a pattern that is D away, it is D+1 away (and we save that option).
% Repeat until nothing new shows up.
fill_levels(Patterns, D) :-
    D1 is D + 1,
    findall(Len-P-opt(Name, Moves),
            ( member(P, Patterns),
              \+ oll_dist(P, _),
              oll_option(Name, Moves, Map),
              pattern_step(P, Map, Q),
              oll_dist(Q, D),
              length(Moves, Len) ),
            Found0),
    msort(Found0, Found1),                         % shortest options first
    pick_first(Found1, [], Found),                 % only one option per pattern
    (   Found == []
    ->  true
    ;   forall(member(P-opt(Name, Moves), Found),
               ( assertz(oll_dist(P, D1)),
                 assertz(oll_next(P, Name, Moves)) )),
        fill_levels(Patterns, D1)
    ).

% pick_first(+Sorted, +Seen, -Picked)
% Keeps only the first entry for each pattern.
pick_first([], _, []).
pick_first([_-P-Opt|T], Seen, Out) :-
    (   memberchk(P, Seen)
    ->  pick_first(T, Seen, Out)
    ;   Out = [P-Opt|Rest],
        pick_first(T, [P|Seen], Rest)
    ).

:- build_oll_table.

% ---- Solving ----

% oll_solve_steps(+Cube, -Steps)
% The cube must have its first two layers solved.
% Each step is step(oll, Name, Moves): the algorithm used and its moves
% (with the U turn in front).
% Fails if the cube is not covered by the table.
oll_solve_steps(Cube, Steps) :-
    oll_pattern_of(Cube, Pattern),
    oll_walk(Pattern, Cube, Steps).

% oll_walk(+Pattern, +Cube, -Steps)
% Follows the table. Every move is done on the real cube, and the new
% pattern must be exactly one step closer.
oll_walk(Pattern, Cube, Steps) :-
    oll_dist(Pattern, D),
    (   D =:= 0
    ->  Steps = []
    ;   oll_next(Pattern, Name, Moves),
        apply_moves(Moves, Cube, Cube1),
        oll_pattern_of(Cube1, Pattern1),
        oll_dist(Pattern1, D1),
        D1 =:= D - 1,
        Steps = [step(oll, Name, Moves)|Rest],
        oll_walk(Pattern1, Cube1, Rest)
    ).

% oll_steps_moves(+Steps, -Moves)
% Puts all the moves of all the steps into one list, in order.
oll_steps_moves([], []).
oll_steps_moves([step(_, _, M)|Steps], Moves) :-
    oll_steps_moves(Steps, Rest),
    append(M, Rest, Moves).

% solve_oll(+Cube, -Moves)
% All the OLL moves in one list.
solve_oll(Cube, Moves) :-
    oll_solve_steps(Cube, Steps),
    oll_steps_moves(Steps, Moves).

% solve_oll_report(+Scramble)
% Scrambles a solved cube, solves the top face, and checks it on the real cube.
solve_oll_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    (   oll_solve_steps(Cube, Steps)
    ->  (   Steps == []
        ->  format("The top is already oriented~n")
        ;   forall(nth1(I, Steps, step(_, Case, Moves)),
                   ( length(Moves, N),
                     scramble_text(Moves, Text),
                     format("Step ~w (~w): ~w moves: ~w~n", [I, Case, N, Text]) )),
            oll_steps_moves(Steps, All),
            (   fixed_ok(Cube, All)
            ->  format("Check on the real cube: top oriented, cross and 4 pairs kept~n")
            ;   format("Check on the real cube: FAILED~n")
            )
        )
    ;   format("This cube is not covered (are the first two layers solved?)~n")
    ).

% ---------- Tests: the solver ----------

% oll_count_kinds(+List, -Counts)
% Counts how many times each different item shows up in the list.
oll_count_kinds(List, Counts) :-
    msort(List, Sorted),
    sort(List, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Sorted, Same),
                   length(Same, N) ),
            Counts).

% test_oll_table
% There must be exactly 216 patterns, each one from a real legal cube,
% and each one must have a way to the finished top.
test_oll_table :-
    all_ll_cubes(Cubes),
    length(Cubes, 216),
    forall(member(C, Cubes), legal_cube(C)),
    maplist(oll_pattern_of, Cubes, Patterns0),
    sort(Patterns0, Patterns),
    length(Patterns, 216),
    findall(P, ( member(P, Patterns), \+ oll_dist(P, _) ), Missing),
    length(Missing, NotCovered),
    (   NotCovered =:= 0
    ->  findall(D, oll_dist(_, D), Ds),
        oll_count_kinds(Ds, Counts),
        format("216 last-layer orientations, all covered. Algorithms needed (number-of-patterns): ~w~n", [Counts])
    ;   format("Not covered: ~w of 216 patterns~n", [NotCovered]),
        fail
    ).

% test_oll_all_cubes
% Solves all 216 cubes and checks each answer on the real 54-sticker cube.
test_oll_all_cubes :-
    all_ll_cubes(Cubes),
    findall(N,
            ( member(Cube, Cubes),
              oll_solve_steps(Cube, Steps),
              oll_steps_moves(Steps, Moves),
              fixed_ok(Cube, Moves),
              length(Steps, N) ),
            Ns),
    length(Ns, 216),
    max_list(Ns, Most),
    sum_list(Ns, Total),
    Avg is Total / 216,
    format("All 216 cubes solved and checked on the full cube. Most steps: ~w, average: ~2f~n", [Most, Avg]).

% test_oll_random(+N)
% N random last layers (same kind as in the matching test). All must be solved.
test_oll_random(N) :-
    findall(Steps,
            ( between(1, N, _),
              random_ll_cube(Cube),
              oll_solve_steps(Cube, Steps),
              oll_steps_moves(Steps, Moves),
              fixed_ok(Cube, Moves) ),
            All),
    length(All, N),
    format("~w random last layers: all solved and checked on the full cube~n", [N]).

test_oll_solver :-
    test_oll_table,
    test_oll_all_cubes,
    test_oll_random(200),
    format("OLL solver tests passed~n").