% explain.pl
% The teaching words: turns the steps of a solution into a lesson.

:- ensure_loaded(main).

% face_colour/2: the colour of each face (white bottom, green front).
face_colour(u, yellow).
face_colour(d, white).
face_colour(f, green).
face_colour(b, blue).
face_colour(r, orange).
face_colour(l, red).

% stage_title/2: the title of each stage.
stage_title(cross, "Cross").
stage_title(f2l,   "First two layers (F2L)").
stage_title(oll,   "OLL: orient the last layer").
stage_title(pll,   "PLL: permute the last layer").

% stage_goal/2: the goal of each stage, in words.
stage_goal(cross, "put the four white edges on the bottom face, each matching its side centre colour.").
stage_goal(f2l,   "pair each white corner with its edge and place the pairs in the first two layers.").
stage_goal(oll,   "make the whole top face one colour.").
stage_goal(pll,   "move the last-layer pieces to their places so the cube is solved.").

% stage_why/2: why each stage is done.
stage_why(cross, "A solid cross gives every later step a fixed base. Each white edge must also match its side centre, so the rest of the first layer can be built around it.").
stage_why(f2l,   "Joining a corner with its edge lets both slide into the first two layers together, without breaking the cross.").
stage_why(oll,   "Before the last-layer pieces can be moved to their places they must all face the right way. OLL makes the top face one colour without touching the first two layers.").
stage_why(pll,   "Now the top is one colour but pieces may still be in the wrong places. PLL moves them to their places without changing which way they face.").

% colour_pair(Slot, Text): the two side colours of a slot (fr becomes green-orange).
colour_pair(Slot, Text) :-
    atom_chars(Slot, [A, B]),
    face_colour(A, CA),
    face_colour(B, CB),
    format(atom(Text), "~w-~w", [CA, CB]).

% step_target/3: what a step is working on, in words.
step_target(cross, Edge, Text) :- !,
    colour_pair(Edge, Pair),
    upcase_atom(Edge, Up),
    format(string(Text), "the ~w edge (~w)", [Pair, Up]).

step_target(f2l, Slot, Text) :- !,
    colour_pair(Slot, Pair),
    upcase_atom(Slot, Up),
    format(string(Text), "the white-~w corner and the ~w edge (slot ~w)", [Pair, Pair, Up]).

step_target(oll, _, "the top face") :- !.

step_target(pll, _, "the top layer pieces").

% cross_case_text/2: the words for each cross situation.
cross_case_text(solved,            "it is already in place").
cross_case_text(top_white_up,      "it is on the top layer with its white sticker facing up").
cross_case_text(top_white_side,    "it is on the top layer with its white sticker facing sideways").
cross_case_text(middle_layer,      "it is in the middle layer").
cross_case_text(bottom_wrong_slot, "it is on the bottom layer but in the wrong place").
cross_case_text(bottom_flipped,    "it is in the right place on the bottom layer but flipped").

% f2l_case_text/2: the words for each F2L situation.
f2l_case_text(solved,                    "the pair is already together in its slot").
f2l_case_text(both_in_top,               "the corner and the edge are both on the top layer").
f2l_case_text(corner_top_edge_middle,    "the corner is on the top layer and the edge is in the middle layer").
f2l_case_text(corner_bottom_edge_top,    "the corner is in the bottom layer and the edge is on the top layer").
f2l_case_text(corner_bottom_edge_middle, "the corner is in the bottom layer and the edge is in the middle layer").
f2l_case_text(edge_in_bottom,            "the edge is down in the bottom layer").

% count_u(Pattern, Places, N): how many of some pattern places are the top colour.
count_u(Pattern, Places, N) :-
    findall(I, ( member(I, Places), nth1(I, Pattern, u) ), Found),
    length(Found, N).

% situation_text/4: describes the cube before a step.
situation_text(_, cross, step(_, Case, _), Text) :- !,
    cross_case_text(Case, Text).

situation_text(_, f2l, step(_, Case, _), Text) :- !,
    f2l_case_text(Case, Text).

situation_text(Cube, oll, _, Text) :- !,
    oll_pattern_of(Cube, Pattern),
    count_u(Pattern, [2,4,6,8], Edges),
    count_u(Pattern, [1,3,7,9], Corners),
    face_colour(u, Colour),
    format(string(Text), "~w of the 4 top edges and ~w of the 4 top corners show ~w on top",
           [Edges, Corners, Colour]).

situation_text(_, pll, step(_, auf, _), Text) :- !,
    Text = "every piece is in the right place, but the top layer is turned".

situation_text(Cube, pll, _, Text) :-
    moved_counts(Cube, Corners, Edges),
    format(string(Text), "~w of the 4 top corners and ~w of the 4 top edges are out of place",
           [Corners, Edges]).

% show_configuration/2: draws the last layer for OLL and PLL.
show_configuration(Cube, oll) :- !,
    oll_pattern_of(Cube, Pattern),
    oll_show(Pattern),
    format("(# = shows the top colour, seen from above with the front at the bottom)~n").

show_configuration(Cube, pll) :- !,
    pll_pattern_of(Cube, Pattern),
    pll_show(Pattern),
    format("(# = top face; letters say which side each rim sticker belongs to: f front, r right, b back, l left)~n").

show_configuration(_, _).

% algorithm_line/3: prints the recipe name for OLL and PLL.
algorithm_line(oll, Name, Moves) :- !,
    oll_alg(Name, Text),
    oll_moves(Name, Alg),
    format("Algorithm: ~w (~w)~n", [Name, Text]),
    ( Moves == Alg -> true ; format("(a U turn is added to line the layer up)~n") ).

algorithm_line(pll, auf, _) :- !,
    format("Just a turn of the top layer (AUF)~n").

algorithm_line(pll, Name, Moves) :- !,
    pll_alg(Name, Text),
    pll_moves(Name, Alg),
    format("Algorithm: ~w (~w)~n", [Name, Text]),
    ( Moves == Alg -> true ; format("(a U turn is added to line the layer up)~n") ).

algorithm_line(_, _, _).

% progress_line(I, N, DoneAfter, Total): prints the progress bar.
progress_line(I, N, DoneAfter, Total) :-
    Filled is round(20 * DoneAfter / Total),
    Empty is 20 - Filled,
    format("Progress: [~*c~*c] step ~w of ~w, ~w of ~w moves~n",
           [Filled, 35, Empty, 46, I, N, DoneAfter, Total]).

% explain_step/4: prints one step of the lesson.
explain_step(Cube, item(Stage, K, M, Step), ctx(I, N, Done, Total), Why) :-
    Step = step(Name, Case, Moves0),
    merge_moves(Moves0, Moves),
    stage_title(Stage, Title),
    step_target(Stage, Name, Target),
    situation_text(Cube, Stage, Step, Situation),
    length(Moves, L),
    scramble_text(Moves, Text),
    DoneAfter is Done + L,
    nl,
    format("=== ~w: step ~w of ~w ===~n", [Title, K, M]),
    (   K =:= 1
    ->  stage_goal(Stage, Goal),
        format("Goal of this stage: ~w~n", [Goal])
    ;   true
    ),
    format("Working on: ~w~n", [Target]),
    format("Situation: ~w~n", [Situation]),
    show_configuration(Cube, Stage),
    algorithm_line(Stage, Case, Moves),
    format("Moves (~w): ~w~n", [L, Text]),
    (   Why == true
    ->  stage_why(Stage, WhyText),
        format("Why: ~w~n", [WhyText])
    ;   true
    ),
    progress_line(I, N, DoneAfter, Total).

% has_moves/1: true if the step has any moves.
has_moves(step(_, _, Moves)) :- Moves \== [].

% flat_steps(Stages, Items): all the steps that have moves, in order.
flat_steps(Stages, Items) :-
    findall(item(Stage, K, M, Step),
            ( member(stage(Stage, Steps), Stages),
              include(has_moves, Steps, Real),
              length(Real, M),
              nth1(K, Real, Step) ),
            Items).

% item_length/2: how many moves a step has, as shown.
item_length(item(_, _, _, step(_, _, Moves0)), L) :-
    merge_moves(Moves0, Moves),
    length(Moves, L).

% explain_solution(Cube, Stages, Why): prints every step, following the cube through the
%   solution.
explain_solution(Cube, Stages, Why) :-
    flat_steps(Stages, Items),
    length(Items, N),
    (   N =:= 0
    ->  format("The cube is already solved. Nothing to do.~n")
    ;   maplist(item_length, Items, Lens),
        sum_list(Lens, Total),
        explain_items(Items, 1, N, 0, Total, Cube, Why),
        nl,
        format("Done: the cube is solved in ~w moves.~n", [Total])
    ).

% explain_items/7: prints the steps one by one.
explain_items([], _, _, _, _, _, _).

explain_items([Item|Items], I, N, Done, Total, Cube, Why) :-
    explain_step(Cube, Item, ctx(I, N, Done, Total), Why),
    Item = item(_, _, _, step(_, _, Moves)),
    apply_moves(Moves, Cube, Cube1),
    item_length(Item, L),
    Done1 is Done + L,
    I1 is I + 1,
    explain_items(Items, I1, N, Done1, Total, Cube1, Why).

% explain(Scramble): scrambles a solved cube, solves it and prints the lesson.
explain(Scramble) :-
    scramble_cube(Scramble, Cube),
    solve(Cube, Stages),
    explain_solution(Cube, Stages, false).

% explain_why(Scramble): the same, with the "why" lines.
explain_why(Scramble) :-
    scramble_cube(Scramble, Cube),
    solve(Cube, Stages),
    explain_solution(Cube, Stages, true).

% explain_demo: shows one fixed F2L step to see the layout.
explain_demo :-
    solved_cube(Cube),
    explain_step(Cube,
                 item(f2l, 1, 4, step(fr, corner_top_edge_middle, [u, f2, r2, f2, r2])),
                 ctx(1, 14, 0, 73),
                 true).

% test_explain_texts: every case, recipe, stage and target has its text (it also prints
%   recipe lines, that is normal).
test_explain_texts :-
    forall(valid_case(C), cross_case_text(C, _)),
    forall(valid_pair_case(C), f2l_case_text(C, _)),
    forall(oll_alg(N, _), algorithm_line(oll, N, [])),
    forall(pll_alg(N, _), algorithm_line(pll, N, [])),
    forall(member(S, [cross, f2l, oll, pll]),
           ( stage_title(S, _), stage_goal(S, _), stage_why(S, _) )),
    forall(member(E, [df, dr, db, dl]), step_target(cross, E, _)),
    forall(member(S, [fr, fl, bl, br]), step_target(f2l, S, _)),
    format("Every case, algorithm, stage and target has its text~n").

% test_explain_random(N): N random cubes explained; the number of "Moves" lines must
%   match the steps.
test_explain_random(N) :-
    solved_cube(S),
    findall(x,
            ( between(1, N, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, Cube),
              solve(Cube, Stages),
              with_output_to(string(Out), explain_solution(Cube, Stages, true)),
              split_string(Out, "\n", "", Lines),
              include(is_moves_line, Lines, MovesLines),
              length(MovesLines, Count),
              flat_steps(Stages, Items),
              length(Items, Count) ),
            Ok),
    length(Ok, N),
    format("~w random cubes: every step explained, the number of steps matches~n", [N]).

% is_moves_line(Line): true if a line starts with "Moves (".
is_moves_line(Line) :-
    sub_string(Line, 0, 7, _, "Moves (").

% test_explain: runs the explain tests.
test_explain :-
    test_explain_texts,
    test_explain_random(10),
    format("Explain tests passed~n").