% moves.pl
% The moves: what each turn does to the 54 stickers.
% A move is a table of 54 numbers: spot i of the new cube copies spot Table[i] of the old cube.

% apply_perm(Perm, Cube, NewCube): builds the new cube by following a table.
apply_perm(Perm, Cube, NewCube) :-
    findall(X,
            ( member(P, Perm),
              nth1(P, Cube, X) ),
            NewCube).

% rotate_demo/1: a tiny practice table for learning.
rotate_demo([2, 3, 4, 1]).

% move_perm/2: the six basic move tables (u, r, f, d, l, b), one clockwise quarter turn
%   each. Each has 54 numbers, 9 per face in the order u r f d l b.
move_perm(u, [ 7,  4,  1,  8,  5,  2,  9,  6,  3,
              46, 47, 48, 13, 14, 15, 16, 17, 18,
              10, 11, 12, 22, 23, 24, 25, 26, 27,
              28, 29, 30, 31, 32, 33, 34, 35, 36,
              19, 20, 21, 40, 41, 42, 43, 44, 45,
              37, 38, 39, 49, 50, 51, 52, 53, 54 ]).

move_perm(r, [  1,  2, 21,  4,  5, 24,  7,  8, 27,
               16, 13, 10, 17, 14, 11, 18, 15, 12,
               19, 20, 30, 22, 23, 33, 25, 26, 36,
               28, 29, 52, 31, 32, 49, 34, 35, 46,
               37, 38, 39, 40, 41, 42, 43, 44, 45,
                9, 47, 48,  6, 50, 51,  3, 53, 54 ]).

move_perm(l, [ 54,  2,  3, 51,  5,  6, 48,  8,  9,
               10, 11, 12, 13, 14, 15, 16, 17, 18,
                1, 20, 21,  4, 23, 24,  7, 26, 27,
               19, 29, 30, 22, 32, 33, 25, 35, 36,
               43, 40, 37, 44, 41, 38, 45, 42, 39,
               46, 47, 34, 49, 50, 31, 52, 53, 28 ]).

move_perm(f, [  1,  2,  3,  4,  5,  6, 45, 42, 39,
                7, 11, 12,  8, 14, 15,  9, 17, 18,
               25, 22, 19, 26, 23, 20, 27, 24, 21,
               16, 13, 10, 31, 32, 33, 34, 35, 36,
               37, 38, 28, 40, 41, 29, 43, 44, 30,
               46, 47, 48, 49, 50, 51, 52, 53, 54 ]).

move_perm(d, [  1,  2,  3,  4,  5,  6,  7,  8,  9,
               10, 11, 12, 13, 14, 15, 25, 26, 27,
               19, 20, 21, 22, 23, 24, 43, 44, 45,
               34, 31, 28, 35, 32, 29, 36, 33, 30,
               37, 38, 39, 40, 41, 42, 52, 53, 54,
               46, 47, 48, 49, 50, 51, 16, 17, 18 ]).

move_perm(b, [ 12, 15, 18,  4,  5,  6,  7,  8,  9,
               10, 11, 36, 13, 14, 35, 16, 17, 34,
               19, 20, 21, 22, 23, 24, 25, 26, 27,
               28, 29, 30, 31, 32, 33, 37, 40, 43,
                3, 38, 39,  2, 41, 42,  1, 44, 45,
               52, 49, 46, 53, 50, 47, 54, 51, 48 ]).

% move_name/3: the 18 moves: name, face, and how many quarter turns.
move_name(u,  u, 1).
   move_name(u2, u, 2).
   move_name(up, u, 3).
move_name(r,  r, 1).
   move_name(r2, r, 2).
   move_name(rp, r, 3).
move_name(f,  f, 1).
   move_name(f2, f, 2).
   move_name(fp, f, 3).
move_name(d,  d, 1).
   move_name(d2, d, 2).
   move_name(dp, d, 3).
move_name(l,  l, 1).
   move_name(l2, l, 2).
   move_name(lp, l, 3).
move_name(b,  b, 1).
   move_name(b2, b, 2).
   move_name(bp, b, 3).

% repeat_perm/4: does the same table again and again, N times.
repeat_perm(0, _, Cube, Cube).

repeat_perm(N, Perm, Cube, NewCube) :-
    N > 0,
    apply_perm(Perm, Cube, Mid),
    N1 is N - 1,
    repeat_perm(N1, Perm, Mid, NewCube).

% apply_move(Move, Cube, NewCube): does any one of the 18 moves on a cube.
apply_move(Move, Cube, NewCube) :-
    move_name(Move, Face, Times),
    move_perm(Face, Perm),
    repeat_perm(Times, Perm, Cube, NewCube).

% apply_moves/3: does a list of moves one after another.
apply_moves([], Cube, Cube).

apply_moves([Move|Rest], Cube, NewCube) :-
    apply_move(Move, Cube, Mid),
    apply_moves(Rest, Mid, NewCube).

% inverse_move(Move, Inverse): the move that undoes a move.
inverse_move(Move, Inverse) :-
    move_name(Move, Face, Times),
    T2 is 4 - Times,
    move_name(Inverse, Face, T2).

% test_move(Name): a table must use 1 to 54 once, and four turns must give back the
%   start.
test_move(Name) :-
    move_perm(Name, P),
    msort(P, Sorted),
    numlist(1, 54, All),
    Sorted == All,
    apply_perm(P, All, C1),
    apply_perm(P, C1, C2),
    apply_perm(P, C2, C3),
    apply_perm(P, C3, C4),
    C4 == All,
    format("~w passes: valid permutation, and ~w x4 = identity~n", [Name, Name]).

% test_inverses: every move followed by its undo changes nothing.
test_inverses :-
    numlist(1, 54, All),
    forall(move_name(M, _, _),
           ( inverse_move(M, Inv),
             apply_move(M, All, C1),
             apply_move(Inv, C1, C2),
             C2 == All )),
    format("All 18 moves: move then inverse = identity~n").

% test_doubles: a half turn equals two quarter turns.
test_doubles :-
    numlist(1, 54, All),
    forall(( move_name(Single, Face, 1), move_name(Double, Face, 2) ),
           ( apply_move(Single, All, C1),
             apply_move(Single, C1, C2),
             apply_move(Double, All, D),
             C2 == D )),
    format("All 6 doubles = two single turns~n").

% test_sexy: R U R' U' six times gives back the start (once does not).
test_sexy :-
    numlist(1, 54, All),
    Trigger = [r, u, rp, up],
    apply_moves(Trigger, All, Once),
    Once \== All,
    findall(M, ( between(1, 6, _), member(M, Trigger) ), Six),
    apply_moves(Six, All, After),
    After == All,
    format("R U R' U' x6 = identity (and x1 is not)~n").

% test_ru105: (R U) 105 times gives back the start.
test_ru105 :-
    numlist(1, 54, All),
    findall(M, ( between(1, 105, _), member(M, [r, u]) ), Seq),
    apply_moves(Seq, All, After),
    After == All,
    format("(R U) x105 = identity~n").

% test_all: runs all the move tests.
test_all :-
    forall(member(M, [u, r, f, d, l, b]), test_move(M)),
    test_inverses,
    test_doubles,
    test_sexy,
    test_ru105,
    format("ALL MOVE TESTS PASSED~n").

% show_move(Move): prints a solved cube after one move.
show_move(Move) :-
    solved_cube(C),
    apply_move(Move, C, C1),
    print_cube(C1).