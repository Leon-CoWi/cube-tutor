% moves.pl
% THE MOVES: what each turn of the cube does to the 54 stickers.
%
% A move is stored as a table of 54 numbers. Think of it as instructions:
% "for spot number i, copy the sticker from spot number P of the old cube".
% Doing a move just means building a new cube by following the table.

% apply_perm(+Perm, +Cube, -NewCube)
% Builds the new cube by looking up, for every spot, which old spot to copy from.
apply_perm(Perm, Cube, NewCube) :-
    findall(X,
            ( member(P, Perm),
              nth1(P, Cube, X) ),
            NewCube).

% A tiny practice table, only for learning (works on lists of 4 items).
rotate_demo([2, 3, 4, 1]).

% ---------- The six basic move tables (one clockwise quarter turn each) ----------
% move_perm(+Name, -Table). One table per face, in the order U, R, F, D, L, B.
% The notes on the right of each line say which part of the cube that line is.

% U: turn the top layer clockwise, as seen from above.
move_perm(u, [ 7,  4,  1,  8,  5,  2,  9,  6,  3,     % top face spins
              46, 47, 48, 13, 14, 15, 16, 17, 18,     % right face's top row gets the back's top row
              10, 11, 12, 22, 23, 24, 25, 26, 27,     % front face's top row gets the right's top row
              28, 29, 30, 31, 32, 33, 34, 35, 36,     % bottom face stays the same
              19, 20, 21, 40, 41, 42, 43, 44, 45,     % left face's top row gets the front's top row
              37, 38, 39, 49, 50, 51, 52, 53, 54 ]).  % back face's top row gets the left's top row

% R: turn the right layer clockwise, as seen from the right.
move_perm(r, [  1,  2, 21,  4,  5, 24,  7,  8, 27,    % top face's right column gets the front's right column
               16, 13, 10, 17, 14, 11, 18, 15, 12,     % right face spins
               19, 20, 30, 22, 23, 33, 25, 26, 36,     % front face's right column gets the bottom's right column
               28, 29, 52, 31, 32, 49, 34, 35, 46,     % bottom face's right column gets the back's left column (upside down)
               37, 38, 39, 40, 41, 42, 43, 44, 45,     % left face stays the same
                9, 47, 48,  6, 50, 51,  3, 53, 54 ]).  % back face's left column gets the top's right column (upside down)

% L: turn the left layer clockwise, as seen from the left.
move_perm(l, [ 54,  2,  3, 51,  5,  6, 48,  8,  9,    % top face's left column gets the back's right column (upside down)
               10, 11, 12, 13, 14, 15, 16, 17, 18,     % right face stays the same
                1, 20, 21,  4, 23, 24,  7, 26, 27,     % front face's left column gets the top's left column
               19, 29, 30, 22, 32, 33, 25, 35, 36,     % bottom face's left column gets the front's left column
               43, 40, 37, 44, 41, 38, 45, 42, 39,     % left face spins
               46, 47, 34, 49, 50, 31, 52, 53, 28 ]).  % back face's right column gets the bottom's left column (upside down)

% F: turn the front layer clockwise, as seen from the front.
move_perm(f, [  1,  2,  3,  4,  5,  6, 45, 42, 39,    % top face's bottom row gets the left's right column (upside down)
                7, 11, 12,  8, 14, 15,  9, 17, 18,     % right face's left column gets the top's bottom row
               25, 22, 19, 26, 23, 20, 27, 24, 21,     % front face spins
               16, 13, 10, 31, 32, 33, 34, 35, 36,     % bottom face's top row gets the right's left column (upside down)
               37, 38, 28, 40, 41, 29, 43, 44, 30,     % left face's right column gets the bottom's top row
               46, 47, 48, 49, 50, 51, 52, 53, 54 ]).  % back face stays the same

% D: turn the bottom layer clockwise, as seen from below.
move_perm(d, [  1,  2,  3,  4,  5,  6,  7,  8,  9,    % top face stays the same
               10, 11, 12, 13, 14, 15, 25, 26, 27,     % right face's bottom row gets the front's bottom row
               19, 20, 21, 22, 23, 24, 43, 44, 45,     % front face's bottom row gets the left's bottom row
               34, 31, 28, 35, 32, 29, 36, 33, 30,     % bottom face spins
               37, 38, 39, 40, 41, 42, 52, 53, 54,     % left face's bottom row gets the back's bottom row
               46, 47, 48, 49, 50, 51, 16, 17, 18 ]).  % back face's bottom row gets the right's bottom row

% B: turn the back layer clockwise, as seen from behind.
move_perm(b, [ 12, 15, 18,  4,  5,  6,  7,  8,  9,    % top face's top row gets the right's right column
               10, 11, 36, 13, 14, 35, 16, 17, 34,     % right face's right column gets the bottom's bottom row (upside down)
               19, 20, 21, 22, 23, 24, 25, 26, 27,     % front face stays the same
               28, 29, 30, 31, 32, 33, 37, 40, 43,     % bottom face's bottom row gets the left's left column
                3, 38, 39,  2, 41, 42,  1, 44, 45,     % left face's left column gets the top's top row (upside down)
               52, 49, 46, 53, 50, 47, 54, 51, 48 ]).  % back face spins

% ---------- All 18 move names ----------
% move_name(?Move, ?BaseFace, ?Times)
% Each move is "turn this face clockwise this many times".
%   plain letter = 1 turn,  2 at the end = 2 turns (a half turn),
%   p at the end = 3 turns (same as one turn the other way, written R' on paper)
move_name(u,  u, 1).   move_name(u2, u, 2).   move_name(up, u, 3).
move_name(r,  r, 1).   move_name(r2, r, 2).   move_name(rp, r, 3).
move_name(f,  f, 1).   move_name(f2, f, 2).   move_name(fp, f, 3).
move_name(d,  d, 1).   move_name(d2, d, 2).   move_name(dp, d, 3).
move_name(l,  l, 1).   move_name(l2, l, 2).   move_name(lp, l, 3).
move_name(b,  b, 1).   move_name(b2, b, 2).   move_name(bp, b, 3).

% repeat_perm(+Times, +Perm, +Cube, -NewCube)
% Does the same table again and again, as many times as asked.
repeat_perm(0, _, Cube, Cube).              % zero times: the cube stays the same
repeat_perm(N, Perm, Cube, NewCube) :-
    N > 0,
    apply_perm(Perm, Cube, Mid),            % do it once...
    N1 is N - 1,
    repeat_perm(N1, Perm, Mid, NewCube).    % ...then do it the remaining times

% apply_move(+Move, +Cube, -NewCube)
% Does any one of the 18 moves (u, up, u2, r, rp, r2, ...) on a cube.
apply_move(Move, Cube, NewCube) :-
    move_name(Move, Face, Times),
    move_perm(Face, Perm),
    repeat_perm(Times, Perm, Cube, NewCube).

% apply_moves(+Moves, +Cube, -NewCube)
% Does a whole LIST of moves one after another, like [r, u, rp, up].
apply_moves([], Cube, Cube).                % no moves left: the cube stays the same
apply_moves([Move|Rest], Cube, NewCube) :-
    apply_move(Move, Cube, Mid),            % do the first move...
    apply_moves(Rest, Mid, NewCube).        % ...then the rest of the list

% inverse_move(+Move, -Inverse): the move that undoes Move.
% A face turned 4 times is back where it started, so the undo is the
% remaining turns (4 minus what we did).
inverse_move(Move, Inverse) :-
    move_name(Move, Face, Times),
    T2 is 4 - Times,
    move_name(Inverse, Face, T2).

% ---------- Tests ----------
% test_move(+Name): checks that one basic table makes sense, then prints a message.
test_move(Name) :-
    move_perm(Name, P),
    msort(P, Sorted),
    numlist(1, 54, All),
    Sorted == All,              % every number from 1 to 54 shows up exactly once
    apply_perm(P, All, C1),     % turn the move four times on a cube where
    apply_perm(P, C1, C2),      % every sticker is different...
    apply_perm(P, C2, C3),
    apply_perm(P, C3, C4),
    C4 == All,                  % ...and we must end up back where we started
    format("~w passes: valid permutation, and ~w x4 = identity~n", [Name, Name]).

% test_inverses: every move followed by its undo must leave the cube unchanged.
test_inverses :-
    numlist(1, 54, All),
    forall(move_name(M, _, _),
           ( inverse_move(M, Inv),
             apply_move(M, All, C1),
             apply_move(Inv, C1, C2),
             C2 == All )),
    format("All 18 moves: move then inverse = identity~n").

% test_doubles: for every face, a half turn must equal two single turns.
test_doubles :-
    numlist(1, 54, All),
    forall(( move_name(Single, Face, 1), move_name(Double, Face, 2) ),
           ( apply_move(Single, All, C1),
             apply_move(Single, C1, C2),
             apply_move(Double, All, D),
             C2 == D )),
    format("All 6 doubles = two single turns~n").

% test_sexy: on a real cube, doing R U R' U' six times brings it back.
% Doing it once must change the cube. Doing it six times must restore it.
test_sexy :-
    numlist(1, 54, All),
    Trigger = [r, u, rp, up],
    apply_moves(Trigger, All, Once),
    Once \== All,                           % one time: the cube HAS changed
    findall(M, ( between(1, 6, _), member(M, Trigger) ), Six),
    apply_moves(Six, All, After),
    After == All,                           % six times: back to the start
    format("R U R' U' x6 = identity (and x1 is not)~n").

% test_ru105: on a real cube, doing R U 105 times brings it back.
test_ru105 :-
    numlist(1, 54, All),
    findall(M, ( between(1, 105, _), member(M, [r, u]) ), Seq),
    apply_moves(Seq, All, After),
    After == All,
    format("(R U) x105 = identity~n").

% test_all: runs every test in this file.
test_all :-
    forall(member(M, [u, r, f, d, l, b]), test_move(M)),
    test_inverses,
    test_doubles,
    test_sexy,
    test_ru105,
    format("ALL MOVE TESTS PASSED~n").

% ---------- Look at a move ----------
% show_move(+Move): prints a solved cube after doing one move
% (cube.pl must be loaded too, because we use solved_cube and print_cube).
show_move(Move) :-
    solved_cube(C),
    apply_move(Move, C, C1),
    print_cube(C1).