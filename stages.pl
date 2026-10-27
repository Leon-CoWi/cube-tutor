% stages.pl
% Which stage are we in? Tells if the cross, F2L, OLL or PLL is done.
% Uses cube.pl and moves.pl.

:- ensure_loaded(cube).
:- ensure_loaded(moves).

% positions_solved(Cube, Positions): true if the stickers at these positions match a
%   solved cube.
positions_solved(Cube, Positions) :-
    solved_cube(Solved),
    forall(member(P, Positions),
           ( nth1(P, Cube, X),
             nth1(P, Solved, X) )).

% cross_edge_solved(Cube, Name): true if one cross edge (dr, df, dl or db) is in place
%   and not flipped.
cross_edge_solved(Cube, Name) :-
    edge(_, Name, Positions),
    positions_solved(Cube, Positions).

% cross_solved(Cube): true if all four cross edges are solved.
cross_solved(Cube) :-
    forall(member(Name, [dr, df, dl, db]),
           cross_edge_solved(Cube, Name)).

% cross_report(Scramble): scrambles a solved cube and says if its cross is solved.
cross_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    (   cross_solved(Cube)
    ->  format("Cross solved: yes~n")
    ;   format("Cross solved: no~n")
    ).

% f2l_slot/3: the four pair slots: which corner and which edge make each pair.
f2l_slot(fr, dfr, fr).
f2l_slot(fl, dlf, fl).
f2l_slot(bl, dbl, bl).
f2l_slot(br, drb, br).

% f2l_pair_solved(Cube, Slot): true if both the corner and the edge of a pair are in
%   place.
f2l_pair_solved(Cube, Slot) :-
    f2l_slot(Slot, CornerName, EdgeName),
    corner(_, CornerName, CornerPos),
    edge(_, EdgeName, EdgePos),
    positions_solved(Cube, CornerPos),
    positions_solved(Cube, EdgePos).

% solved_f2l_slots(Cube, Slots): the list of pair slots that are solved.
solved_f2l_slots(Cube, Slots) :-
    findall(S, f2l_pair_solved(Cube, S), Slots).

% f2l_pairs_solved(Cube, N): how many of the 4 pairs are solved.
f2l_pairs_solved(Cube, N) :-
    solved_f2l_slots(Cube, Slots),
    length(Slots, N).

% f2l_report(Scramble): scrambles a cube and prints how many pairs are solved.
f2l_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    solved_f2l_slots(Cube, Slots),
    length(Slots, N),
    format("F2L pairs solved: ~w ~w~n", [N, Slots]).

% test_f2l_pairs: known scrambles must give the right number of solved pairs.
test_f2l_pairs :-
    forall(member(Scramble-Want,
                  [ ""-4, "U"-4, "R U R' U'"-3, "R"-2, "F"-2, "D"-0 ]),
           ( scramble_cube(Scramble, C),
             f2l_pairs_solved(C, Got),
             Got == Want )),
    format("F2L pair counts correct for 6 known scrambles~n").

% face_positions(Face, Positions): the 9 sticker positions of a face.
face_positions(Face, Positions) :-
    face_start(Face, S),
    S1 is S + 1,
    S9 is S + 9,
    numlist(S1, S9, Positions).

% oll_solved(Cube): true if all 9 top stickers are u.
oll_solved(Cube) :-
    face_positions(u, Positions),
    positions_solved(Cube, Positions).

% pll_solved(Cube): true if the whole cube is solved.
pll_solved(Cube) :-
    solved_cube(Solved),
    Cube == Solved.

% yes_no(Goal, Answer): answer is yes if the goal works, otherwise no.
yes_no(Goal, Answer) :-
    (   call(Goal)
    ->  Answer = yes
    ;   Answer = no
    ).

% last_layer_report(Scramble): scrambles a cube and says if OLL and PLL are solved.
last_layer_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    yes_no(oll_solved(Cube), O),
    yes_no(pll_solved(Cube), P),
    format("OLL solved: ~w, PLL solved: ~w~n", [O, P]).

% test_oll_pll: known scrambles must give the right OLL and PLL answers.
test_oll_pll :-
    forall(member(t(Scramble, WantO, WantP),
                  [ t("",          yes, yes),
                    t("U",         yes, no),
                    t("D",         yes, no),
                    t("R",         no,  no),
                    t("F",         no,  no),
                    t("R U R' U'", no,  no) ]),
           ( scramble_cube(Scramble, C),
             yes_no(oll_solved(C), GotO),
             yes_no(pll_solved(C), GotP),
             GotO == WantO,
             GotP == WantP )),
    format("OLL/PLL answers correct for 6 known scrambles~n").

% current_stage(Cube, Stage): the stage to work on next: cross, f2l(N), oll, pll or
%   solved.
current_stage(Cube, Stage) :-
    (   \+ cross_solved(Cube)
    ->  Stage = cross
    ;   f2l_pairs_solved(Cube, N), N < 4
    ->  Stage = f2l(N)
    ;   \+ oll_solved(Cube)
    ->  Stage = oll
    ;   \+ pll_solved(Cube)
    ->  Stage = pll
    ;   Stage = solved
    ).

% stage_report(Scramble): scrambles a solved cube and prints its stage.
stage_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    current_stage(Cube, Stage),
    format("Current stage: ~w~n", [Stage]).

% valid_stage/1: the only answers current_stage may give.
valid_stage(cross).
valid_stage(f2l(N)) :- between(0, 3, N).
valid_stage(oll).
valid_stage(pll).
valid_stage(solved).

% test_stages: known scrambles must give the expected stage.
test_stages :-
    forall(member(Scramble-Want,
                  [ ""-solved,
                    "U"-pll,
                    "R U R' U'"-f2l(3),
                    "R"-cross,
                    "F"-cross,
                    "D"-cross,
                    "F R U R' U' F'"-oll,
                    "R U R' U' R' F R2 U' R' U' R U R' F'"-pll ]),
           ( scramble_cube(Scramble, C),
             current_stage(C, Got),
             Got == Want )),
    format("Stage detection correct for 8 known scrambles~n").

% undo_moves(Moves, Undo): the moves that take a cube back to solved (reverse and undo
%   each).
undo_moves(Moves, Undo) :-
    reverse(Moves, Rev),
    maplist(inverse_move, Rev, Undo).

% test_random_stages: 100 random scrambles must each give one valid stage, and undoing
%   them gives solved.
test_random_stages :-
    forall(between(1, 100, _),
           ( random_scramble(25, Moves),
             solved_cube(Solved),
             apply_moves(Moves, Solved, Scrambled),
             findall(S, current_stage(Scrambled, S), [Stage]),
             valid_stage(Stage),
             undo_moves(Moves, Undo),
             apply_moves(Undo, Scrambled, Back),
             current_stage(Back, Final),
             Final == solved )),
    format("100 random scrambles: one valid stage each, and undoing them gives solved~n").

% random_stage(Stage): the stage of one random 25-move scramble.
random_stage(Stage) :-
    random_scramble(25, Moves),
    solved_cube(Solved),
    apply_moves(Moves, Solved, Cube),
    current_stage(Cube, Stage).

% stage_stats(N): scrambles N random cubes and counts how many land in each stage.
stage_stats(N) :-
    findall(S, ( between(1, N, _), random_stage(S) ), Stages),
    sort(Stages, Kinds),
    forall(member(K, Kinds),
           ( include(==(K), Stages, Same),
             length(Same, Count),
             format("~w: ~w~n", [K, Count]) )).