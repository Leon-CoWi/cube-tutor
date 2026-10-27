% view.pl
% Which way to hold the cube, and the moves renamed for that view.
% The solver thinks "white bottom, green front". Here we turn the cube
% and rename the moves so the learner can follow.

:- ensure_loaded(main).
:- use_module(library(random)).
:- use_module(library(lists)).

% view_faces/2: for each view: which real face you see at which place.
view_faces(green_front,  [u-u, d-d, f-f, b-b, l-l, r-r]).
view_faces(white_top,    [u-d, d-u, f-f, b-b, l-r, r-l]).
view_faces(red_front,    [l-f, f-r, r-b, b-l, u-u, d-d]).
view_faces(orange_front, [r-f, f-l, l-b, b-r, u-u, d-d]).
view_faces(blue_front,   [b-f, f-b, l-r, r-l, u-u, d-d]).

% view_perm/2: for each view: the table that turns the cube that way.
view_perm(green_front,
  [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54]).

view_perm(white_top,
  [36,35,34,33,32,31,30,29,28,45,44,43,42,41,40,39,38,37,27,26,25,24,23,22,21,20,19,9,8,7,6,5,4,3,2,1,18,17,16,15,14,13,12,11,10,54,53,52,51,50,49,48,47,46]).

view_perm(red_front,
  [3,6,9,2,5,8,1,4,7,19,20,21,22,23,24,25,26,27,37,38,39,40,41,42,43,44,45,34,31,28,35,32,29,36,33,30,46,47,48,49,50,51,52,53,54,10,11,12,13,14,15,16,17,18]).

view_perm(orange_front,
  [7,4,1,8,5,2,9,6,3,46,47,48,49,50,51,52,53,54,10,11,12,13,14,15,16,17,18,30,33,36,29,32,35,28,31,34,19,20,21,22,23,24,25,26,27,37,38,39,40,41,42,43,44,45]).

view_perm(blue_front,
  [9,8,7,6,5,4,3,2,1,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,36,35,34,33,32,31,30,29,28,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27]).

% view_text/2: the sentence shown for each view.
view_text(green_front,  'Hold the cube with white on the bottom and green toward you.').
view_text(white_top,    'Turn the cube over: white on top, green still toward you.').
view_text(red_front,    'Hold the cube with white on the bottom and red toward you.').
view_text(orange_front, 'Hold the cube with white on the bottom and orange toward you.').
view_text(blue_front,   'Hold the cube with white on the bottom and blue toward you.').

% stage_view/2: the view each stage uses.
stage_view(cross, white_top).
stage_view(oll,   green_front).
stage_view(pll,   green_front).

% slot_view/2: the view each F2L slot uses (the pair is brought to the front right).
slot_view(fr, green_front).
slot_view(fl, red_front).
slot_view(br, orange_front).
slot_view(bl, blue_front).

% step_view/3: the view to use for one step.
step_view(f2l, step(Slot, _, _), View) :- !, slot_view(Slot, View).
step_view(Stage, _, View) :- stage_view(Stage, View).

% view_move(View, Move, Shown): a real move shown for a view (same turn, different
%   face).
view_move(View, Move, Shown) :-
    atom_chars(Move, [Face|Rest]),
    view_faces(View, Pairs),
    memberchk(Face-Other, Pairs),
    atom_chars(Shown, [Other|Rest]).

% view_moves(View, Moves, Shown): the same for a list of moves.
view_moves(View, Moves, Shown) :-
    maplist(view_move(View), Moves, Shown).

% rotate_cube(View, Cube, Turned): the same cube held another way.
rotate_cube(View, Cube, Turned) :-
    view_perm(View, Perm),
    maplist(sticker_of(Cube), Perm, Turned).

% sticker_of(Cube, I, X): the sticker at a position.
sticker_of(Cube, I, X) :- nth1(I, Cube, X).

% show_move(Move, Text): a move written the usual way (rp becomes R').
show_move(Move, Text) :-
    atom_chars(Move, [F|Rest]),
    upcase_atom(F, Big),
    ( Rest == [p] -> atom_concat(Big, '''', Text)
    ; Rest == ['2'] -> atom_concat(Big, '2', Text)
    ; Text = Big ).

% show_moves(Moves, Text): a list of moves written as text.
show_moves(Moves, Text) :-
    maplist(show_move, Moves, Parts),
    atomic_list_concat(Parts, ' ', Text).

% view_demo: prints the demo for a built-in scramble.
view_demo :-
    view_demo("R U R' U' F2 D L' B2 U R").

% view_demo(Scramble): solves a scramble and prints, for each step, how to hold the cube
%   and the moves.
view_demo(Scramble) :-
    scramble_cube(Scramble, Cube),
    solve(Cube, Stages),
    forall(( member(stage(Stage, Steps), Stages), member(Step, Steps) ),
           ( Step = step(_, _, Moves),
             step_view(Stage, Step, View),
             view_moves(View, Moves, Shown),
             view_text(View, Hold),
             show_moves(Shown, Text),
             format("~w: ~w~n   ~w~n", [Stage, Hold, Text]) )).

% centre_index/2: the position of each face centre.
centre_index(u, 5).
  centre_index(r, 14).
 centre_index(f, 23).
centre_index(d, 32).
 centre_index(l, 41).
 centre_index(b, 50).

% all_moves/1: the 18 moves.
all_moves([u,u2,up, d,d2,dp, r,r2,rp, l,l2,lp, f,f2,fp, b,b2,bp]).

% random_moves(N, Moves): a list of N random moves.
random_moves(N, Moves) :-
    all_moves(All),
    length(Moves, N),
    maplist(pick_from(All), Moves).

% pick_from(All, M): picks one random move.
pick_from(All, M) :- random_member(M, All).

% test_view_tables: each table uses 1 to 54 once and puts the right centre in place.
test_view_tables :-
    numlist(1, 54, All),
    solved_cube(Solved),
    forall(view_perm(V, P),
           ( msort(P, Sorted),
             ( Sorted == All -> true
             ; format("~w: not a permutation of 1..54~n", [V]), fail ),
             rotate_cube(V, Solved, R),
             view_faces(V, Pairs),
             forall(member(Real-Seen, Pairs),
                    ( centre_index(Seen, I),
                      nth1(I, R, Letter),
                      ( Letter == Real -> true
                      ; format("~w: wrong centre at ~w~n", [V, Seen]), fail ) )) )),
    writeln('View tables are permutations with the right centres').

% test_view_moves(N): turning the cube then moving equals moving then turning (renamed
%   moves).
test_view_moves(N) :-
    solved_cube(Solved),
    forall(( view_perm(V, _), between(1, N, _) ),
           ( random_moves(15, Scr),
             apply_moves(Scr, Solved, C),
             random_moves(12, Ms),
             apply_moves(Ms, C, After),
             rotate_cube(V, After, A1),
             rotate_cube(V, C, RC),
             view_moves(V, Ms, Ss),
             apply_moves(Ss, RC, A2),
             ( A1 == A2 -> true
             ; format("~w: mismatch for ~w~n", [V, Ms]), fail ) )),
    format("Rewritten moves agree in all 5 views (~w random tests each)~n", [N]).

% test_view: runs the view tests.
test_view :-
    test_view_tables,
    test_view_moves(200),
    writeln('View tests passed').