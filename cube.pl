% cube.pl
% The cube itself: how it is stored, printed, scrambled and checked.
% The cube is a list of 54 letters (stickers), 9 per face, in this order:
% u (1-9), r (10-18), f (19-27), d (28-36), l (37-45), b (46-54).

% face_letters/1: the six faces, in storage order.
face_letters([u, r, f, d, l, b]).

% solved_cube(Cube): the solved cube: 9 u, then 9 r, and so on.
solved_cube(Cube) :-
    face_letters(Faces),
    findall(F, (member(F, Faces), between(1, 9, _)), Cube).

% face_start/2: how many stickers come before each face (u 0, r 9, f 18, d 27, l 36, b
%   45).
face_start(u, 0).
face_start(r, 9).
face_start(f, 18).
face_start(d, 27).
face_start(l, 36).
face_start(b, 45).

% face_row/4: the 3 stickers of one row of a face (0 top, 1 middle, 2 bottom).
face_row(Cube, Face, Row, [A, B, C]) :-
    face_start(Face, S),
    P is S + Row * 3,
    P1 is P + 1,
    P2 is P + 2,
    P3 is P + 3,
    nth1(P1, Cube, A),
    nth1(P2, Cube, B),
    nth1(P3, Cube, C).

% print_face_row(Cube, Face, Row): prints one row of a face.
print_face_row(Cube, Face, Row) :-
    face_row(Cube, Face, Row, [A, B, C]),
    format("~w ~w ~w ", [A, B, C]).

% print_single(Cube, Face): prints one whole face (used for the top and bottom).
print_single(Cube, Face) :-
    forall(between(0, 2, R),
           ( write('      '),
             print_face_row(Cube, Face, R),
             nl )).

% print_middle(Cube): prints the left, front, right and back faces side by side.
print_middle(Cube) :-
    forall(between(0, 2, R),
           ( print_face_row(Cube, l, R),
             print_face_row(Cube, f, R),
             print_face_row(Cube, r, R),
             print_face_row(Cube, b, R),
             nl )).

% print_cube(Cube): prints the whole cube flattened out.
print_cube(Cube) :-
    print_single(Cube, u),
    print_middle(Cube),
    print_single(Cube, d).

% parse_moves(String, Moves): turns text like "R U R' U'" into a move list like [r, u,
%   rp, up].
parse_moves(String, Moves) :-
    split_string(String, " ", " ", Parts0),
    exclude(==(""), Parts0, Parts),
    maplist(token_move, Parts, Moves).

% token_move(Token, Move): turns one written move ("R'", "u2", "F") into our move name
%   (rp, u2, f).
token_move(Token, Move) :-
    downcase_atom(Token, Lower),
    atomic_list_concat(Pieces, '\'', Lower),
    atomic_list_concat(Pieces, p, Move).

% scramble_cube(String, Cube): makes a solved cube, does the moves in the text, gives
%   the result.
scramble_cube(String, Cube) :-
    parse_moves(String, Moves),
    solved_cube(Solved),
    apply_moves(Moves, Solved, Cube).

% show_scramble(String): scrambles a solved cube and prints it.
show_scramble(String) :-
    scramble_cube(String, Cube),
    print_cube(Cube).

% suffix_text/2: what to write after the face letter (1 turn nothing, 2 turns "2", 3
%   turns "'").
suffix_text(1, '').
suffix_text(2, '2').
suffix_text(3, '\'').

% move_text(Move, Text): a move written the usual way (rp becomes R').
move_text(Move, Text) :-
    move_name(Move, Face, Times),
    upcase_atom(Face, Big),
    suffix_text(Times, Suffix),
    atom_concat(Big, Suffix, Text).

% scramble_text(Moves, Text): a move list written as text, like [r, up, f2] becomes "R
%   U' F2".
scramble_text(Moves, Text) :-
    maplist(move_text, Moves, Texts),
    atomic_list_concat(Texts, ' ', Text).

% random_scramble(N, Moves): N random moves, never the same face twice in a row.
random_scramble(N, Moves) :-
    findall(M, move_name(M, _, _), All),
    random_moves(N, none, All, Moves).

% random_moves/4: picks the random moves one by one, remembering the last face.
random_moves(0, _, _, []).

random_moves(N, PrevFace, All, [Move|Rest]) :-
    N > 0,
    include(different_face(PrevFace), All, Choices),
    random_member(Move, Choices),
    move_name(Move, Face, _),
    N1 is N - 1,
    random_moves(N1, Face, All, Rest).

% different_face(PrevFace, Move): true if the move turns a different face than the last
%   one.
different_face(PrevFace, Move) :-
    move_name(Move, Face, _),
    Face \== PrevFace.

% show_random(N): makes a random scramble of N moves, prints it and the cube.
show_random(N) :-
    random_scramble(N, Moves),
    scramble_text(Moves, Text),
    format("Scramble: ~w~n", [Text]),
    solved_cube(Solved),
    apply_moves(Moves, Solved, Cube),
    print_cube(Cube).

% no_repeat_faces/1: true if no two moves in a row turn the same face.
no_repeat_faces([]).

no_repeat_faces([_]).

no_repeat_faces([A, B|Rest]) :-
    move_name(A, FA, _),
    move_name(B, FB, _),
    FA \== FB,
    no_repeat_faces([B|Rest]).

% test_random: checks 200 random scrambles look right.
test_random :-
    forall(between(1, 200, _),
           ( random_scramble(25, Moves),
             length(Moves, 25),
             no_repeat_faces(Moves),
             scramble_text(Moves, Text),
             parse_moves(Text, Back),
             Back == Moves )),
    format("200 random scrambles: right length, no repeated faces, text round-trips~n").

% face_center/2: the middle sticker spot of each face (centres never move).
face_center(u,  5).
face_center(r, 14).
face_center(f, 23).
face_center(d, 32).
face_center(l, 41).
face_center(b, 50).

% sticker_problem/2: the ways stickers can be wrong: not 54, unknown letter, not 9 of a
%   colour, wrong centre.
sticker_problem(Cube, wrong_length(N)) :-
    length(Cube, N),
    N =\= 54.

sticker_problem(Cube, unknown_letter(X)) :-
    member(X, Cube),
    face_letters(Faces),
    \+ memberchk(X, Faces).

sticker_problem(Cube, bad_count(F, N)) :-
    face_letters(Faces),
    member(F, Faces),
    include(==(F), Cube, Same),
    length(Same, N),
    N =\= 9.

sticker_problem(Cube, bad_center(F, Found)) :-
    face_center(F, Pos),
    nth1(Pos, Cube, Found),
    Found \== F.

% sticker_problems(Cube, Problems): all sticker problems found in a cube.
sticker_problems(Cube, Problems) :-
    findall(P, sticker_problem(Cube, P), Problems).

% legal_stickers(Cube): true when no sticker problems are found.
legal_stickers(Cube) :-
    sticker_problems(Cube, []).

% set_sticker(Pos, New, Cube, NewCube): a copy of the cube with one sticker changed
%   (used to make broken cubes for tests).
set_sticker(Pos, New, Cube, NewCube) :-
    nth1(Pos, Cube, _, Rest),
    nth1(Pos, NewCube, New, Rest).

% test_stickers: good cubes must pass and 4 kinds of broken cube must be caught.
test_stickers :-
    solved_cube(S),
    legal_stickers(S),
    scramble_cube("R U R' U' F2 D L'", C),
    legal_stickers(C),
    set_sticker(1, r, S, Bad1),
    sticker_problems(Bad1, P1),
    P1 == [bad_count(u, 8), bad_count(r, 10)],
    set_sticker(5, r, S, T),
    set_sticker(14, u, T, Bad2),
    sticker_problems(Bad2, P2),
    P2 == [bad_center(u, r), bad_center(r, u)],
    set_sticker(1, x, S, Bad3),
    sticker_problems(Bad3, P3),
    P3 == [unknown_letter(x), bad_count(u, 8)],
    append(Short, [_], S),
    sticker_problems(Short, P4),
    P4 == [wrong_length(53), bad_count(b, 8)],
    format("Sticker checks: good cubes accepted, 4 kinds of broken cube caught~n").

% corner/3: the 8 corner spots: index, name, and its 3 sticker positions (first is on u
%   or d).
corner(1, urf, [ 9, 10, 21]).
corner(2, ufl, [ 7, 19, 39]).
corner(3, ulb, [ 1, 37, 48]).
corner(4, ubr, [ 3, 46, 12]).
corner(5, dfr, [30, 27, 16]).
corner(6, dlf, [28, 45, 25]).
corner(7, dbl, [34, 54, 43]).
corner(8, drb, [36, 18, 52]).

% edge/3: the 12 edge spots: index, name, and its 2 sticker positions.
edge( 1, ur, [ 6, 11]).
edge( 2, uf, [ 8, 20]).
edge( 3, ul, [ 4, 38]).
edge( 4, ub, [ 2, 47]).
edge( 5, dr, [33, 17]).
edge( 6, df, [29, 26]).
edge( 7, dl, [31, 44]).
edge( 8, db, [35, 53]).
edge( 9, fr, [24, 13]).
edge(10, fl, [22, 42]).
edge(11, bl, [51, 40]).
edge(12, br, [49, 15]).

% letters_at(Cube, Positions, Letters): the letters sitting at a list of positions.
letters_at(Cube, Positions, Letters) :-
    findall(L, ( member(P, Positions), nth1(P, Cube, L) ), Letters).

% rotate_left/3: spins a list of 3 items left by 0, 1 or 2 places.
rotate_left([A, B, C], 0, [A, B, C]).
rotate_left([A, B, C], 1, [B, C, A]).
rotate_left([A, B, C], 2, [C, A, B]).

% corner_state(Cube, Slot, Home, Twist): which corner piece sits in a slot (Home) and
%   how twisted it is (0, 1 or 2).
corner_state(Cube, Slot, Home, Twist) :-
    corner(Slot, _, Pos),
    letters_at(Cube, Pos, Read),
    solved_cube(Solved),
    once(( rotate_left(Read, Twist, Canon),
           Canon = [First|_],
           memberchk(First, [u, d]),
           corner(Home, _, HomePos),
           letters_at(Solved, HomePos, Canon) )).

% edge_match/3: compares seen letters with a solved edge: same order flip 0, opposite
%   flip 1.
edge_match([A, B], [A, B], 0).
edge_match([A, B], [B, A], 1).

% edge_state(Cube, Slot, Home, Flip): which edge piece sits in a slot (Home) and whether
%   it is flipped.
edge_state(Cube, Slot, Home, Flip) :-
    edge(Slot, _, Pos),
    letters_at(Cube, Pos, Read),
    solved_cube(Solved),
    once(( edge(Home, _, HomePos),
           letters_at(Solved, HomePos, Pair),
           edge_match(Read, Pair, Flip) )).

% slot_problem/2: a slot is bad if its stickers cannot be any real piece.
slot_problem(Cube, bad_corner(Name)) :-
    corner(Slot, Name, _),
    \+ corner_state(Cube, Slot, _, _).

slot_problem(Cube, bad_edge(Name)) :-
    edge(Slot, Name, _),
    \+ edge_state(Cube, Slot, _, _).

% slot_problems(Cube, Problems): all bad slots of one kind (corner or edge).
slot_problems(Cube, Problems) :-
    findall(P, slot_problem(Cube, P), Problems).

% homes_ok(N, List): true if the list has every number 1 to N exactly once.
homes_ok(N, List) :-
    numlist(1, N, All),
    msort(List, Sorted),
    Sorted == All.

% inversions(List, N): counts pairs in the wrong order (even or odd shuffle).
inversions(List, N) :-
    findall(x, ( nth1(I, List, A), nth1(J, List, B), I < J, A > B ), Xs),
    length(Xs, N).

% corner_homes(Cube, Homes): which piece sits in each of the 8 corner slots.
corner_homes(Cube, Homes) :-
    findall(H, corner_state(Cube, _, H, _), Homes).

% edge_homes(Cube, Homes): which piece sits in each of the 12 edge slots.
edge_homes(Cube, Homes) :-
    findall(H, edge_state(Cube, _, H, _), Homes).

% piece_problem/2: the ways pieces can be wrong: a piece twice, corner twist, edge flip,
%   parity.
piece_problem(Cube, duplicate_corner) :-
    corner_homes(Cube, Homes),
    \+ homes_ok(8, Homes).

piece_problem(Cube, duplicate_edge) :-
    edge_homes(Cube, Homes),
    \+ homes_ok(12, Homes).

piece_problem(Cube, corner_twist) :-
    findall(T, corner_state(Cube, _, _, T), Ts),
    sum_list(Ts, Sum),
    Sum mod 3 =\= 0.

piece_problem(Cube, edge_flip) :-
    findall(F, edge_state(Cube, _, _, F), Fs),
    sum_list(Fs, Sum),
    Sum mod 2 =\= 0.

piece_problem(Cube, parity) :-
    corner_homes(Cube, CH),
    homes_ok(8, CH),
    edge_homes(Cube, EH),
    homes_ok(12, EH),
    inversions(CH, CI),
    inversions(EH, EI),
    (CI + EI) mod 2 =:= 1.

% piece_problems(Cube, Problems): all piece problems found in a cube.
piece_problems(Cube, Problems) :-
    findall(P, piece_problem(Cube, P), Problems).

% cube_problems(Cube, Problems): all problems of a cube; [] means it is possible. Each
%   check runs only if the one before found nothing.
cube_problems(Cube, Problems) :-
    sticker_problems(Cube, P1),
    (   P1 \== []
    ->  Problems = P1
    ;   slot_problems(Cube, P2),
        (   P2 \== []
        ->  Problems = P2
        ;   piece_problems(Cube, Problems)
        )
    ).

% legal_cube(Cube): true if the cube could really exist.
legal_cube(Cube) :-
    cube_problems(Cube, []).

% check_cube(Cube): prints in words whether the cube is possible.
check_cube(Cube) :-
    cube_problems(Cube, Problems),
    (   Problems == []
    ->  format("Cube is legal.~n")
    ;   format("Cube is NOT legal: ~w~n", [Problems])
    ).

% test_piece_tables: the corner, edge and centre tables must use each of the 54
%   positions once.
test_piece_tables :-
    findall(P, ( corner(_, _, L), member(P, L) ), CornerPos),
    findall(P, ( edge(_, _, L), member(P, L) ), EdgePos),
    findall(P, face_center(_, P), CenterPos),
    append([CornerPos, EdgePos, CenterPos], All),
    msort(All, Sorted),
    numlist(1, 54, Want),
    Sorted == Want,
    format("Piece tables: all 54 positions used exactly once~n").

% test_pieces: real cubes must pass and 5 kinds of impossible cube must be caught.
test_pieces :-
    test_piece_tables,
    solved_cube(S),
    legal_cube(S),
    forall(move_name(M, _, _),
           ( apply_move(M, S, C1), legal_cube(C1) )),
    format("Solved cube and all 18 single moves: legal~n"),
    forall(between(1, 100, _),
           ( random_scramble(25, Ms),
             apply_moves(Ms, S, C2),
             legal_cube(C2) )),
    format("100 random scrambles: legal~n"),
    set_sticker(9, r, S, T1),
    set_sticker(10, f, T1, T2),
    set_sticker(21, u, T2, Twisted),
    cube_problems(Twisted, P1), P1 == [corner_twist],
    set_sticker(6, r, S, T3),
    set_sticker(11, u, T3, Flipped),
    cube_problems(Flipped, P2), P2 == [edge_flip],
    set_sticker(11, f, S, T4),
    set_sticker(20, r, T4, Swapped),
    cube_problems(Swapped, P3), P3 == [parity],
    set_sticker(9, r, S, T5),
    set_sticker(10, u, T5, Mirrored),
    cube_problems(Mirrored, P4), P4 == [bad_corner(urf)],
    set_sticker(6, f, S, T6),
    set_sticker(20, u, T6, Impossible),
    cube_problems(Impossible, P5), P5 == [bad_edge(uf)],
    format("Broken cubes caught: twisted corner, flipped edge, swapped edges, mirrored corner, impossible edge~n"),
    format("Piece checks passed~n").