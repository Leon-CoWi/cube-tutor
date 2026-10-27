% oll.pl
% OLL: make the whole top face one colour (pieces may still be in the wrong spots).
% Uses a list of known recipes (algorithms) and a table that tells which one to use.

:- ensure_loaded(stages).

% oll_alg/2: the 10 known OLL recipes. Each keeps the cross and the 4 pairs safe.
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

% oll_names(Names): all the recipe names.
oll_names(Names) :-
    findall(Name, oll_alg(Name, _), Names).

% oll_moves(Name, Moves): a recipe as a list of moves.
oll_moves(Name, Moves) :-
    oll_alg(Name, Text),
    parse_moves(Text, Moves).

% oll_list: prints the recipes, one per line.
oll_list :-
    forall(oll_alg(Name, Text),
           ( oll_moves(Name, Moves),
             length(Moves, N),
             format("~w: ~w (~w moves)~n", [Name, Text, N]) )).

% good_alg(Text): a recipe must keep the cross and pairs, and must not finish the top by
%   itself.
good_alg(Text) :-
    scramble_cube(Text, Cube),
    cross_solved(Cube),
    f2l_pairs_solved(Cube, 4),
    \+ oll_solved(Cube).

% test_oll_algs: checks every recipe, and that no two share a name.
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

% ll_positions/1: the 21 stickers that matter for OLL: the 9 top ones and the top row of
%   the 4 sides.
ll_positions([ 1, 2, 3, 4, 5, 6, 7, 8, 9,
              19,20,21,
              10,11,12,
              46,47,48,
              37,38,39 ]).

% sticker_mark(Cube, Pos, Mark): u if the sticker is the top colour, x if not.
sticker_mark(Cube, Pos, Mark) :-
    nth1(Pos, Cube, Letter),
    (   Letter == u
    ->  Mark = u
    ;   Mark = x
    ).

% oll_pattern_of(Cube, Pattern): the 21 marks (u or x) of a cube, called its pattern.
oll_pattern_of(Cube, Pattern) :-
    ll_positions(Positions),
    maplist(sticker_mark(Cube), Positions, Pattern).

% inverse_moves(Moves, Inverse): the moves that undo a list of moves.
inverse_moves(Moves, Inverse) :-
    reverse(Moves, Reversed),
    maplist(inverse_move, Reversed, Inverse).

% derive_pattern(Name, Pattern): the pattern a recipe fixes: do the recipe backwards on
%   a solved cube.
derive_pattern(Name, Pattern) :-
    solved_cube(Solved),
    oll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Inverse, Solved, Cube),
    oll_pattern_of(Cube, Pattern).

% oll_case/2: one fact per recipe: its name and the pattern it fixes.
:- dynamic oll_case/2.

% build_oll_cases: fills oll_case when the file loads.
build_oll_cases :-
    retractall(oll_case(_, _)),
    forall(oll_alg(Name, _),
           ( derive_pattern(Name, Pattern),
             assertz(oll_case(Name, Pattern)) )).
:- build_oll_cases.

% top_count(Pattern, N): how many of the 9 top stickers are the top colour.
top_count(Pattern, N) :-
    length(Top, 9),
    append(Top, _, Pattern),
    include(==(u), Top, Us),
    length(Us, N).

% total_count(Pattern, N): how many of all 21 stickers are the top colour.
total_count(Pattern, N) :-
    include(==(u), Pattern, Us),
    length(Us, N).

% oll_show(Pattern): draws a pattern as seen from above (front at the bottom).
oll_show(Pattern) :-
    forall(member(Row, [ [ 0,18,17,16, 0],
                         [19, 1, 2, 3,15],
                         [20, 4, 5, 6,14],
                         [21, 7, 8, 9,13],
                         [ 0,10,11,12, 0] ]),
           ( forall(member(I, Row), show_cell(Pattern, I)),
             nl )).

% show_cell/2: prints one square of the drawing.
show_cell(_, 0) :- !,
    write('  ').

show_cell(Pattern, I) :-
    nth1(I, Pattern, Mark),
    (   Mark == u
    ->  Char = '#'
    ;   Char = '.'
    ),
    format("~w ", [Char]).

% oll_show_case(Name): draws the pattern a recipe fixes.
oll_show_case(Name) :-
    oll_case(Name, Pattern),
    top_count(Pattern, T),
    format("~w: ~w of 9 top stickers have the top colour~n", [Name, T]),
    oll_show(Pattern).

% test_oll_patterns: every recipe has its own pattern, and fixes it.
test_oll_patterns :-
    solved_cube(Solved),
    oll_pattern_of(Solved, Done),
    top_count(Done, 9),
    total_count(Done, 9),
    oll_names(Names),
    length(Names, Count),
    findall(N, oll_case(N, _), CaseNames),
    length(CaseNames, Count),
    forall(oll_case(Name, Pattern),
           ( Pattern \== Done,
             oll_moves(Name, Moves),
             inverse_moves(Moves, Inverse),
             apply_moves(Inverse, Solved, Cube1),
             apply_moves(Moves, Cube1, Cube2),
             oll_pattern_of(Cube2, After),
             After == Done )),
    findall(P, oll_case(_, P), Patterns),
    sort(Patterns, Distinct),
    length(Distinct, D),
    format("~w case patterns derived: none is already finished, each algorithm turns its own pattern into the finished top~n", [Count]),
    format("Distinct patterns: ~w of ~w~n", [D, Count]).

% test_oll_known: Sune and Antisune patterns worked out by hand.
test_oll_known :-
    forall(member(Name, [sune, antisune]),
           ( oll_case(Name, Pattern),
             top_count(Pattern, 6),
             total_count(Pattern, 9) )),
    format("Sune and Antisune: 6 top stickers, 9 in total~n").

% test_oll_cases: runs the pattern tests.
test_oll_cases :-
    test_oll_patterns,
    test_oll_known,
    format("OLL pattern tests passed~n").

% pre_turn/1: the 4 top turns to try first: none, quarter, half, other quarter.
pre_turn([]).
pre_turn([u]).
pre_turn([u2]).
pre_turn([up]).

% oll_match(Cube, Name, Turn): finds a recipe that fits after one of the top turns.
oll_match(Cube, Name, Turn) :-
    pre_turn(Turn),
    apply_moves(Turn, Cube, Turned),
    oll_pattern_of(Turned, Pattern),
    oll_case(Name, Pattern).

% oll_one_alg(Cube, Name, Moves): the first match as one list of moves (top turn, then
%   recipe).
oll_one_alg(Cube, Name, Moves) :-
    once(( oll_match(Cube, Name, Turn),
           oll_moves(Name, Alg),
           append(Turn, Alg, Moves) )).

% fixed_ok(Cube, Moves): after the moves the top is one colour, and the cross and pairs
%   are still solved.
fixed_ok(Cube, Moves) :-
    apply_moves(Moves, Cube, After),
    oll_solved(After),
    cross_solved(After),
    f2l_pairs_solved(After, 4).

% oll_match_report(Scramble): scrambles a cube and says which recipe fixes the top.
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

% case_cube(Name, Cube): the cube a recipe fixes (a solved cube with the recipe done
%   backwards).
case_cube(Name, Cube) :-
    solved_cube(Solved),
    oll_moves(Name, Moves),
    inverse_moves(Moves, Inverse),
    apply_moves(Inverse, Solved, Cube).

% test_oll_match_cases: every case with every top turn must be matched and fixed.
test_oll_match_cases :-
    findall(Name-Turn, ( oll_case(Name, _), pre_turn(Turn) ), Combos),
    length(Combos, Count),
    forall(member(Name-Turn, Combos),
           ( case_cube(Name, Case),
             inverse_moves(Turn, Back),
             apply_moves(Back, Case, Cube),
             oll_one_alg(Cube, _, Moves),
             fixed_ok(Cube, Moves) )),
    format("10 cases x 4 U turns = ~w cubes: each one matched and fixed by a table algorithm~n", [Count]).

% random_ll_cube(Cube): a random last layer: a solved cube mixed with 3 random recipes.
random_ll_cube(Cube) :-
    solved_cube(Solved),
    ll_scramble(3, Solved, Cube).

% ll_scramble/3: does N random recipes, each after a random top turn.
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

% test_oll_match_random(N): N random last layers: finished, no match (allowed), or
%   matched and fixed.
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

% test_oll_matching: runs the matching tests.
test_oll_matching :-
    test_oll_match_cases,
    test_oll_match_random(200),
    format("OLL matching tests passed~n").

% oll_option/3: one way to use a recipe: its moves, and how they shuffle the 21
%   stickers.
:- dynamic oll_option/3.

% ll_map(Moves, Map): finds where each of the 21 stickers moves to for a list of moves.
ll_map(Moves, Map) :-
    ll_positions(Positions),
    numlist(1, 54, Labels),
    apply_moves(Moves, Labels, Moved),
    maplist(map_index(Positions, Moved), Positions, Map).

% map_index(Positions, Moved, Pos, Index): helper for ll_map: where one sticker came
%   from.
map_index(Positions, Moved, Pos, Index) :-
    nth1(Pos, Moved, Source),
    once(nth1(Index, Positions, Source)).

% build_oll_options: fills oll_option when the file loads.
build_oll_options :-
    retractall(oll_option(_, _, _)),
    forall(( oll_alg(Name, _), pre_turn(Turn) ),
           ( oll_moves(Name, Alg),
             append(Turn, Alg, Moves),
             ll_map(Moves, Map),
             assertz(oll_option(Name, Moves, Map)) )).
:- build_oll_options.

% pattern_step(Pattern, Map, New): the pattern after using one option.
pattern_step(Pattern, Map, New) :-
    maplist(pattern_at(Pattern), Map, New).

% pattern_at(Pattern, I, Mark): the mark at one place of a pattern.
pattern_at(Pattern, I, Mark) :-
    nth1(I, Pattern, Mark).

% put_at(List, Pos, Item, New): a list with one item swapped for a new one.
put_at(List, Pos, Item, New) :-
    nth1(Pos, List, _, Rest),
    nth1(Pos, New, Item, Rest).

% put_all/4: swaps several items of a list.
put_all([], [], Cube, Cube).

put_all([P|Ps], [V|Vs], Cube0, Cube) :-
    put_at(Cube0, P, V, Cube1),
    put_all(Ps, Vs, Cube1, Cube).

% sticker_at(Cube, Pos, Item): the sticker at a position.
sticker_at(Cube, Pos, Item) :-
    nth1(Pos, Cube, Item).

% rotate_by/3: moves the first item to the end, N times.
rotate_by(0, List, List) :- !.

rotate_by(N, [H|T], Rotated) :-
    N > 0,
    append(T, [H], List1),
    N1 is N - 1,
    rotate_by(N1, List1, Rotated).

% twist_slot(Cube, Positions, N, New): turns the stickers of one piece around (twists a
%   corner or flips an edge).
twist_slot(Cube, Positions, N, New) :-
    maplist(sticker_at(Cube), Positions, Vals),
    rotate_by(N, Vals, Rotated),
    put_all(Positions, Rotated, Cube, New).

% twist_corners/4: twists the 4 top corners.
twist_corners([], [], Cube, Cube).

twist_corners([T|Ts], [S|Ss], Cube0, Cube) :-
    corner(S, _, Positions),
    twist_slot(Cube0, Positions, T, Cube1),
    twist_corners(Ts, Ss, Cube1, Cube).

% flip_edges/4: flips the 4 top edges.
flip_edges([], [], Cube, Cube).

flip_edges([F|Fs], [S|Ss], Cube0, Cube) :-
    edge(S, _, Positions),
    twist_slot(Cube0, Positions, F, Cube1),
    flip_edges(Fs, Ss, Cube1, Cube).

% all_ll_cubes(Cubes): one cube for every legal way to orient the last layer (216).
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

% oll_dist/2, oll_next/3: tables: how many recipes a pattern needs (oll_dist), and the
%   best recipe to use next (oll_next).
:- dynamic oll_dist/2, oll_next/3.

% build_oll_table: fills the table, starting from the finished top and going outward.
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

% fill_levels(Patterns, D): gives distance D+1 to patterns that reach a distance D
%   pattern with one recipe.
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
    msort(Found0, Found1),
    pick_first(Found1, [], Found),
    (   Found == []
    ->  true
    ;   forall(member(P-opt(Name, Moves), Found),
               ( assertz(oll_dist(P, D1)),
                 assertz(oll_next(P, Name, Moves)) )),
        fill_levels(Patterns, D1)
    ).

% pick_first/3: keeps only the first (shortest) option for each pattern.
pick_first([], _, []).

pick_first([_-P-Opt|T], Seen, Out) :-
    (   memberchk(P, Seen)
    ->  pick_first(T, Seen, Out)
    ;   Out = [P-Opt|Rest],
        pick_first(T, [P|Seen], Rest)
    ).
:- build_oll_table.

% oll_solve_steps(Cube, Steps): the recipes needed to finish the top (first two layers
%   must be solved).
oll_solve_steps(Cube, Steps) :-
    oll_pattern_of(Cube, Pattern),
    oll_walk(Pattern, Cube, Steps).

% oll_walk(Pattern, Cube, Steps): follows the table one recipe at a time, checking on
%   the real cube.
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

% oll_steps_moves/2: all the moves of all the steps, in order.
oll_steps_moves([], []).

oll_steps_moves([step(_, _, M)|Steps], Moves) :-
    oll_steps_moves(Steps, Rest),
    append(M, Rest, Moves).

% solve_oll(Cube, Moves): all the OLL moves in one list.
solve_oll(Cube, Moves) :-
    oll_solve_steps(Cube, Steps),
    oll_steps_moves(Steps, Moves).

% solve_oll_report(Scramble): scrambles, solves the top and checks it on the real cube.
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

% oll_count_kinds(List, Counts): counts how many times each item shows up in a list.
oll_count_kinds(List, Counts) :-
    msort(List, Sorted),
    sort(List, Kinds),
    findall(K-N, ( member(K, Kinds),
                   include(==(K), Sorted, Same),
                   length(Same, N) ),
            Counts).

% test_oll_table: there are exactly 216 patterns and each has a way to the finished top.
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

% test_oll_all_cubes: solves all 216 cubes and checks each on the real cube.
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

% test_oll_random(N): N random last layers must all be solved.
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

% test_oll_solver: runs the solver tests.
test_oll_solver :-
    test_oll_table,
    test_oll_all_cubes,
    test_oll_random(200),
    format("OLL solver tests passed~n").