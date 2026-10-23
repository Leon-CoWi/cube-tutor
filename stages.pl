% stages.pl
% WHICH STAGE ARE WE IN? Looks at a cube and tells which part of the
% solve (Cross, F2L, OLL, PLL) the learner is up to.
% Uses cube.pl (corner/3, edge/3, solved_cube/1, ...) and moves.pl.

% These two lines load the other files automatically (only if they are
% not loaded already), so you can just type [stages]. after a restart.
:- ensure_loaded(cube).
:- ensure_loaded(moves).

% positions_solved(+Cube, +Positions)
% True when the stickers at all these spots are exactly what a solved cube
% has at those spots.
positions_solved(Cube, Positions) :-
    solved_cube(Solved),
    forall(member(P, Positions),
           ( nth1(P, Cube, X),          % what our cube has at spot P
             nth1(P, Solved, X) )).     % the solved cube must have the same thing there

% ---------- Cross ----------
% The cross = the four white edges sitting correctly on the bottom face.

% cross_edge_solved(+Cube, +Name)
% True if the edge called Name (dr, df, dl or db) is in its place and not flipped.
cross_edge_solved(Cube, Name) :-
    edge(_, Name, Positions),           % look up the two sticker spots of this edge
    positions_solved(Cube, Positions).

% cross_solved(+Cube)
% True if all four cross edges (the white edges on the bottom) are solved.
cross_solved(Cube) :-
    forall(member(Name, [dr, df, dl, db]),
           cross_edge_solved(Cube, Name)).

% cross_report(+Scramble): scrambles a solved cube with the moves in the text,
% then says whether its cross is solved. (For trying things out.)
cross_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    (   cross_solved(Cube)
    ->  format("Cross solved: yes~n")
    ;   format("Cross solved: no~n")
    ).

% ---------- F2L (the first two layers) ----------
% F2L = the four "pairs", each one a white corner joined with its matching edge.

% f2l_slot(?Slot, ?CornerName, ?EdgeName)
% The four pair spots: which corner and which edge make up each pair.
f2l_slot(fr, dfr, fr).
f2l_slot(fl, dlf, fl).
f2l_slot(bl, dbl, bl).
f2l_slot(br, drb, br).

% f2l_pair_solved(+Cube, ?Slot)
% True if both the corner AND the edge of this pair spot are in place.
f2l_pair_solved(Cube, Slot) :-
    f2l_slot(Slot, CornerName, EdgeName),
    corner(_, CornerName, CornerPos),
    edge(_, EdgeName, EdgePos),
    positions_solved(Cube, CornerPos),
    positions_solved(Cube, EdgePos).

% solved_f2l_slots(+Cube, -Slots): the list of pair spots that are solved.
solved_f2l_slots(Cube, Slots) :-
    findall(S, f2l_pair_solved(Cube, S), Slots).

% f2l_pairs_solved(+Cube, -N): how many of the 4 pairs are solved.
f2l_pairs_solved(Cube, N) :-
    solved_f2l_slots(Cube, Slots),
    length(Slots, N).

% f2l_report(+Scramble): scrambles a cube, then prints how many pairs are solved.
f2l_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    solved_f2l_slots(Cube, Slots),
    length(Slots, N),
    format("F2L pairs solved: ~w ~w~n", [N, Slots]).

% test_f2l_pairs: some known scrambles must give the right number of solved pairs.
test_f2l_pairs :-
    forall(member(Scramble-Want,
                  [ ""-4, "U"-4, "R U R' U'"-3, "R"-2, "F"-2, "D"-0 ]),
           ( scramble_cube(Scramble, C),
             f2l_pairs_solved(C, Got),
             Got == Want )),
    format("F2L pair counts correct for 6 known scrambles~n").

% ---------- OLL and PLL (the last layer) ----------
% OLL = the whole top face is one color. PLL = the last layer pieces are in the right places.

% face_positions(+Face, -Positions): the 9 sticker spots of a face.
face_positions(Face, Positions) :-
    face_start(Face, S),
    S1 is S + 1,
    S9 is S + 9,
    numlist(S1, S9, Positions).

% oll_solved(+Cube): true if all nine stickers on the top face are u.
oll_solved(Cube) :-
    face_positions(u, Positions),
    positions_solved(Cube, Positions).

% pll_solved(+Cube): true if the whole cube is solved.
pll_solved(Cube) :-
    solved_cube(Solved),
    Cube == Solved.

% yes_no(+Goal, -Answer): Answer is yes if Goal works, otherwise no.
yes_no(Goal, Answer) :-
    (   call(Goal)
    ->  Answer = yes
    ;   Answer = no
    ).

% last_layer_report(+Scramble): scrambles a cube, then says if OLL and PLL are solved.
last_layer_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    yes_no(oll_solved(Cube), O),
    yes_no(pll_solved(Cube), P),
    format("OLL solved: ~w, PLL solved: ~w~n", [O, P]).

% test_oll_pll: some known scrambles must give the right answers.
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

% ---------- Which stage are we in? ----------

% current_stage(+Cube, -Stage)
% Stage is what the learner should work on next:
%   cross     the cross is not solved yet
%   f2l(N)    cross done, N of the 4 pairs done (N is 0 to 3)
%   oll       cross and F2L done, but the top face is not all one color yet
%   pll       top face done, but the last layer pieces are not in place yet
%   solved    the whole cube is solved
% Each check only runs if the one before it did not fit.
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

% stage_report(+Scramble): scrambles a solved cube, then prints its stage.
stage_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    current_stage(Cube, Stage),
    format("Current stage: ~w~n", [Stage]).

% valid_stage(+Stage): the only kinds of answer current_stage is allowed to give.
valid_stage(cross).
valid_stage(f2l(N)) :- between(0, 3, N).
valid_stage(oll).
valid_stage(pll).
valid_stage(solved).

% test_stages: known scrambles must give the expected stage.
% The last two are real algorithms (an OLL and the T-perm): on a solved cube
% they leave the first two layers alone, so we expect oll and pll.
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

% ---------- Tests on random cubes ----------

% undo_moves(+Moves, -Undo): the moves that take the cube back to solved.
% (Reverse the order, and undo each move.)
undo_moves(Moves, Undo) :-
    reverse(Moves, Rev),
    maplist(inverse_move, Rev, Undo).

% test_random_stages: 100 random scrambles. We do not know the "right"
% stage ahead of time, so we test things that must be true for ANY cube.
test_random_stages :-
    forall(between(1, 100, _),
           ( random_scramble(25, Moves),
             solved_cube(Solved),
             apply_moves(Moves, Solved, Scrambled),
             findall(S, current_stage(Scrambled, S), [Stage]),   % exactly one answer
             valid_stage(Stage),                                 % and it is a known kind
             undo_moves(Moves, Undo),
             apply_moves(Undo, Scrambled, Back),                 % undo the scramble
             current_stage(Back, Final),
             Final == solved )),
    format("100 random scrambles: one valid stage each, and undoing them gives solved~n").

% random_stage(-Stage): the stage of one random 25-move scramble.
random_stage(Stage) :-
    random_scramble(25, Moves),
    solved_cube(Solved),
    apply_moves(Moves, Solved, Cube),
    current_stage(Cube, Stage).

% stage_stats(+N): scrambles N random cubes and counts how many land in each stage.
stage_stats(N) :-
    findall(S, ( between(1, N, _), random_stage(S) ), Stages),
    sort(Stages, Kinds),                           % the different stages we saw
    forall(member(K, Kinds),
           ( include(==(K), Stages, Same),
             length(Same, Count),
             format("~w: ~w~n", [K, Count]) )).