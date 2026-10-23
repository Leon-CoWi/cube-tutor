% cube.pl
% THE CUBE ITSELF: how we store it, print it, scramble it and check it.
%
% We store the cube as a list of 54 letters. Each letter is one little
% colored square (a "sticker"). The six faces come in this order, 9 stickers each:
%   spots  1- 9 : u (Up, the top face)
%   spots 10-18 : r (Right)
%   spots 19-27 : f (Front, the face toward you)
%   spots 28-36 : d (Down, the bottom face)
%   spots 37-45 : l (Left)
%   spots 46-54 : b (Back)
% On a solved cube, every sticker has the letter of the face it sits on.

% face_letters(-List): the six faces, in the order we store them.
face_letters([u, r, f, d, l, b]).

% solved_cube(-Cube): gives the solved cube (9 u's, then 9 r's, and so on).
solved_cube(Cube) :-
    face_letters(Faces),
    findall(F, (member(F, Faces), between(1, 9, _)), Cube).

% ---------- Printing the cube on screen ----------

% face_start(?Face, ?Offset): how many stickers come before this face in the list.
% (u has 0 before it, r has 9, f has 18, and so on.)
face_start(u, 0).
face_start(r, 9).
face_start(f, 18).
face_start(d, 27).
face_start(l, 36).
face_start(b, 45).

% face_row(+Cube, +Face, +Row, -Three)
% Gets the 3 stickers of one row (0 = top, 1 = middle, 2 = bottom) of a face.
face_row(Cube, Face, Row, [A, B, C]) :-
    face_start(Face, S),
    P is S + Row * 3,      % how many stickers come before this row
    P1 is P + 1,
    P2 is P + 2,
    P3 is P + 3,
    nth1(P1, Cube, A),     % nth1 = "give me the item at this spot" (counting from 1)
    nth1(P2, Cube, B),
    nth1(P3, Cube, C).

% print_face_row(+Cube, +Face, +Row): prints one row of a face, like "u u u "
print_face_row(Cube, Face, Row) :-
    face_row(Cube, Face, Row, [A, B, C]),
    format("~w ~w ~w ", [A, B, C]).

% print_single(+Cube, +Face): prints a whole face (3 rows), pushed to the right
% so it sits above or below the Front face.
print_single(Cube, Face) :-
    forall(between(0, 2, R),
           ( write('      '),
             print_face_row(Cube, Face, R),
             nl )).

% print_middle(+Cube): prints the middle strip: Left, Front, Right, Back side by side.
print_middle(Cube) :-
    forall(between(0, 2, R),
           ( print_face_row(Cube, l, R),
             print_face_row(Cube, f, R),
             print_face_row(Cube, r, R),
             print_face_row(Cube, b, R),
             nl )).

% print_cube(+Cube): prints the whole cube flattened out like a paper box
% (top on top, the four sides in the middle, bottom at the bottom).
print_cube(Cube) :-
    print_single(Cube, u),
    print_middle(Cube),
    print_single(Cube, d).

% ---------- Reading moves that you type ----------

% parse_moves(+String, -Moves)
% Turns text like "R U R' U'" into our list [r, u, rp, up].
% Moves are separated by spaces. Capital or small letters both work.
parse_moves(String, Moves) :-
    split_string(String, " ", " ", Parts0),   % cut the text at every space
    exclude(==(""), Parts0, Parts),           % throw away empty pieces
    maplist(token_move, Parts, Moves).        % change each piece into a move

% token_move(+Token, -Move)
% Changes one written move ("R'", "u2", "F") into our name for it (rp, u2, f).
token_move(Token, Move) :-
    downcase_atom(Token, Lower),              % "R'" becomes r'
    atomic_list_concat(Pieces, '\'', Lower),  % cut at the apostrophe: [r, '']
    atomic_list_concat(Pieces, p, Move).      % glue back with a p: rp

% ---------- Making a scrambled cube ----------
% These use apply_moves/3 from moves.pl, so moves.pl must be loaded too.

% scramble_cube(+String, -Cube)
% Starts with a solved cube, does the moves in the text, and gives the result.
scramble_cube(String, Cube) :-
    parse_moves(String, Moves),       % text into a list of moves
    solved_cube(Solved),              % a fresh solved cube
    apply_moves(Moves, Solved, Cube). % do the moves on it

% show_scramble(+String): scrambles a solved cube and prints it.
show_scramble(String) :-
    scramble_cube(String, Cube),
    print_cube(Cube).

% ---------- Turning moves back into text ----------

% suffix_text(+Times, -Suffix): what to write after the face letter.
% (1 turn = nothing, 2 turns = 2, 3 turns = the ' mark)
suffix_text(1, '').
suffix_text(2, '2').
suffix_text(3, '\'').

% move_text(+Move, -Text): rp becomes R'   u2 becomes U2   f becomes F
move_text(Move, Text) :-
    move_name(Move, Face, Times),
    upcase_atom(Face, Big),
    suffix_text(Times, Suffix),
    atom_concat(Big, Suffix, Text).

% scramble_text(+Moves, -Text): turns a move list like [r, up, f2] into R U' F2
scramble_text(Moves, Text) :-
    maplist(move_text, Moves, Texts),
    atomic_list_concat(Texts, ' ', Text).

% ---------- Random scrambles ----------

% random_scramble(+N, -Moves): makes N random moves,
% never turning the same face twice in a row.
random_scramble(N, Moves) :-
    findall(M, move_name(M, _, _), All),      % all 18 moves
    random_moves(N, none, All, Moves).

% random_moves(+N, +PrevFace, +All, -Moves)
% Picks the moves one by one, remembering which face was turned last.
random_moves(0, _, _, []).                    % no moves left to make, so stop
random_moves(N, PrevFace, All, [Move|Rest]) :-
    N > 0,
    include(different_face(PrevFace), All, Choices),   % remove moves on the last face
    random_member(Move, Choices),                      % pick one by chance
    move_name(Move, Face, _),
    N1 is N - 1,
    random_moves(N1, Face, All, Rest).

% different_face(+PrevFace, +Move): true if the move turns a different face.
different_face(PrevFace, Move) :-
    move_name(Move, Face, _),
    Face \== PrevFace.

% show_random(+N): makes a random scramble of N moves, then prints it and the cube.
show_random(N) :-
    random_scramble(N, Moves),
    scramble_text(Moves, Text),
    format("Scramble: ~w~n", [Text]),
    solved_cube(Solved),
    apply_moves(Moves, Solved, Cube),
    print_cube(Cube).

% ---------- Test for the random scrambler ----------

% no_repeat_faces(+Moves): true if no two moves in a row turn the same face.
no_repeat_faces([]).
no_repeat_faces([_]).
no_repeat_faces([A, B|Rest]) :-
    move_name(A, FA, _),
    move_name(B, FB, _),
    FA \== FB,
    no_repeat_faces([B|Rest]).

% test_random: makes 200 random scrambles and checks each one looks right.
test_random :-
    forall(between(1, 200, _),
           ( random_scramble(25, Moves),
             length(Moves, 25),
             no_repeat_faces(Moves),
             scramble_text(Moves, Text),
             parse_moves(Text, Back),
             Back == Moves )),
    format("200 random scrambles: right length, no repeated faces, text round-trips~n").

% ---------- Is the cube possible? Part 1: the stickers ----------

% face_center(?Face, ?Position): the middle sticker of each face.
% Centers never move on a real cube, so the middle of the u face is always u, and so on.
face_center(u,  5).
face_center(r, 14).
face_center(f, 23).
face_center(d, 32).
face_center(l, 41).
face_center(b, 50).

% sticker_problem(+Cube, -Problem): gives ONE thing that is wrong with the cube.
% Each rule below is one way a cube can be wrong. Prolog will try all of
% them and find every problem that applies.

% 1. The list does not have 54 stickers.
sticker_problem(Cube, wrong_length(N)) :-
    length(Cube, N),
    N =\= 54.

% 2. Some sticker is not one of the six face letters.
sticker_problem(Cube, unknown_letter(X)) :-
    member(X, Cube),
    face_letters(Faces),
    \+ memberchk(X, Faces).

% 3. Some letter does not show up exactly 9 times.
sticker_problem(Cube, bad_count(F, N)) :-
    face_letters(Faces),
    member(F, Faces),
    include(==(F), Cube, Same),
    length(Same, N),
    N =\= 9.

% 4. A middle sticker is not the letter of its own face.
sticker_problem(Cube, bad_center(F, Found)) :-
    face_center(F, Pos),
    nth1(Pos, Cube, Found),
    Found \== F.

% sticker_problems(+Cube, -Problems): the list of ALL problems found.
sticker_problems(Cube, Problems) :-
    findall(P, sticker_problem(Cube, P), Problems).

% legal_stickers(+Cube): true when no sticker problems were found.
legal_stickers(Cube) :-
    sticker_problems(Cube, []).

% set_sticker(+Position, +New, +Cube, -NewCube): a copy of the cube where the
% sticker at that spot is changed to New. (We use it to make broken cubes for tests.)
set_sticker(Pos, New, Cube, NewCube) :-
    nth1(Pos, Cube, _, Rest),        % take the old sticker out
    nth1(Pos, NewCube, New, Rest).   % put the new one in the same spot

% test_stickers: good cubes must pass, and four kinds of broken cube must be caught.
test_stickers :-
    solved_cube(S),
    legal_stickers(S),                              % the solved cube is fine
    scramble_cube("R U R' U' F2 D L'", C),
    legal_stickers(C),                              % a real scramble is fine
    set_sticker(1, r, S, Bad1),                     % one u sticker turned into r
    sticker_problems(Bad1, P1),
    P1 == [bad_count(u, 8), bad_count(r, 10)],
    set_sticker(5, r, S, T),                        % swap two centers: the counts
    set_sticker(14, u, T, Bad2),                    % are still 9 each!
    sticker_problems(Bad2, P2),
    P2 == [bad_center(u, r), bad_center(r, u)],
    set_sticker(1, x, S, Bad3),                     % a letter that is not a face
    sticker_problems(Bad3, P3),
    P3 == [unknown_letter(x), bad_count(u, 8)],
    append(Short, [_], S),                          % a cube missing one sticker
    sticker_problems(Short, P4),
    P4 == [wrong_length(53), bad_count(b, 8)],
    format("Sticker checks: good cubes accepted, 4 kinds of broken cube caught~n").

% ---------- Is the cube possible? Part 2: the pieces ----------

% corner(?Index, ?Name, ?Positions)
% The 8 corner spots of the cube. Positions are the 3 sticker spots that
% belong to that corner. The FIRST one is always on the top (u) or bottom (d)
% face, and the other two follow clockwise as you look at the corner from outside.
% Name: urf means the corner where Up, Right and Front meet, and so on.
corner(1, urf, [ 9, 10, 21]).
corner(2, ufl, [ 7, 19, 39]).
corner(3, ulb, [ 1, 37, 48]).
corner(4, ubr, [ 3, 46, 12]).
corner(5, dfr, [30, 27, 16]).
corner(6, dlf, [28, 45, 25]).
corner(7, dbl, [34, 54, 43]).
corner(8, drb, [36, 18, 52]).

% edge(?Index, ?Name, ?Positions)
% The 12 edge spots (the pieces between two corners), with 2 sticker spots each.
% For top and bottom edges the first spot is on the u or d face. For the four
% middle edges (fr, fl, bl, br) the first spot is on the f or b face.
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

% letters_at(+Cube, +Positions, -Letters)
% Gets the letters sitting at those spots, in the same order.
letters_at(Cube, Positions, Letters) :-
    findall(L, ( member(P, Positions), nth1(P, Cube, L) ), Letters).

% rotate_left(+Triple, ?Times, -Rotated)
% Spins a list of 3 items to the left by 0, 1 or 2 places.
rotate_left([A, B, C], 0, [A, B, C]).
rotate_left([A, B, C], 1, [B, C, A]).
rotate_left([A, B, C], 2, [C, A, B]).

% corner_state(+Cube, +Slot, -Home, -Twist)
% Looks at the corner piece sitting in spot Slot. It tells us which spot
% that piece belongs to when solved (Home), and how twisted it is (Twist is 0, 1 or 2).
% Fails if the 3 stickers do not make a real corner piece.
corner_state(Cube, Slot, Home, Twist) :-
    corner(Slot, _, Pos),
    letters_at(Cube, Pos, Read),             % the letters we see in this spot
    solved_cube(Solved),
    once(( rotate_left(Read, Twist, Canon),  % spin until the u or d letter is first
           Canon = [First|_],
           memberchk(First, [u, d]),
           corner(Home, _, HomePos),         % which solved corner has the same letters?
           letters_at(Solved, HomePos, Canon) )).

% edge_match(+Read, +Pair, ?Flip)
% Read is the letters we see. Pair is the letters of a solved edge.
% Same order means not flipped (0). Opposite order means flipped (1).
edge_match([A, B], [A, B], 0).
edge_match([A, B], [B, A], 1).

% edge_state(+Cube, +Slot, -Home, -Flip)
% The same idea for edges: where does this piece belong, and is it flipped?
% Fails if the 2 stickers do not make a real edge piece.
edge_state(Cube, Slot, Home, Flip) :-
    edge(Slot, _, Pos),
    letters_at(Cube, Pos, Read),
    solved_cube(Solved),
    once(( edge(Home, _, HomePos),
           letters_at(Solved, HomePos, Pair),
           edge_match(Read, Pair, Flip) )).

% ----- Step 2: does every spot hold a real piece? -----

% A corner spot is bad if its 3 stickers cannot be any real corner.
slot_problem(Cube, bad_corner(Name)) :-
    corner(Slot, Name, _),
    \+ corner_state(Cube, Slot, _, _).

% An edge spot is bad if its 2 stickers cannot be any real edge.
slot_problem(Cube, bad_edge(Name)) :-
    edge(Slot, Name, _),
    \+ edge_state(Cube, Slot, _, _).

slot_problems(Cube, Problems) :-
    findall(P, slot_problem(Cube, P), Problems).

% ----- Step 3: the three big rules of a real cube -----

% homes_ok(+N, +List): true if the list has every number from 1 to N exactly
% once (so no piece shows up twice).
homes_ok(N, List) :-
    numlist(1, N, All),
    msort(List, Sorted),
    Sorted == All.

% inversions(+List, -N): counts the pairs that are in the wrong order.
% An even N means an "even" shuffle, an odd N means an "odd" shuffle.
inversions(List, N) :-
    findall(x, ( nth1(I, List, A), nth1(J, List, B), I < J, A > B ), Xs),
    length(Xs, N).

% corner_homes(+Cube, -Homes): for the 8 corner spots, which piece sits in each.
corner_homes(Cube, Homes) :-
    findall(H, corner_state(Cube, _, H, _), Homes).

% edge_homes(+Cube, -Homes): the same for the 12 edge spots.
edge_homes(Cube, Homes) :-
    findall(H, edge_state(Cube, _, H, _), Homes).

piece_problem(Cube, duplicate_corner) :-          % the same corner piece shows up twice
    corner_homes(Cube, Homes),
    \+ homes_ok(8, Homes).

piece_problem(Cube, duplicate_edge) :-            % the same edge piece shows up twice
    edge_homes(Cube, Homes),
    \+ homes_ok(12, Homes).

piece_problem(Cube, corner_twist) :-              % all corner twists must add up to a multiple of 3
    findall(T, corner_state(Cube, _, _, T), Ts),
    sum_list(Ts, Sum),
    Sum mod 3 =\= 0.

piece_problem(Cube, edge_flip) :-                 % all edge flips must add up to an even number
    findall(F, edge_state(Cube, _, _, F), Fs),
    sum_list(Fs, Sum),
    Sum mod 2 =\= 0.

piece_problem(Cube, parity) :-                    % corners and edges must be shuffled in the same "even or odd" way
    corner_homes(Cube, CH),
    homes_ok(8, CH),
    edge_homes(Cube, EH),
    homes_ok(12, EH),
    inversions(CH, CI),
    inversions(EH, EI),
    (CI + EI) mod 2 =:= 1.

piece_problems(Cube, Problems) :-
    findall(P, piece_problem(Cube, P), Problems).

% ----- All the checks together -----

% cube_problems(+Cube, -Problems): an empty list [] means the cube is possible.
% Each step only runs if the step before found nothing wrong.
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

% legal_cube(+Cube): true if the cube could really exist.
legal_cube(Cube) :-
    cube_problems(Cube, []).

% check_cube(+Cube): prints in words whether the cube is possible.
check_cube(Cube) :-
    cube_problems(Cube, Problems),
    (   Problems == []
    ->  format("Cube is legal.~n")
    ;   format("Cube is NOT legal: ~w~n", [Problems])
    ).

% ---------- Tests for the piece checks ----------

% test_piece_tables: the corner, edge and center tables must use each of the
% 54 spots exactly once (this catches a typo in a number).
test_piece_tables :-
    findall(P, ( corner(_, _, L), member(P, L) ), CornerPos),
    findall(P, ( edge(_, _, L), member(P, L) ), EdgePos),
    findall(P, face_center(_, P), CenterPos),
    append([CornerPos, EdgePos, CenterPos], All),
    msort(All, Sorted),
    numlist(1, 54, Want),
    Sorted == Want,
    format("Piece tables: all 54 positions used exactly once~n").

% test_pieces: real cubes must pass, and five kinds of impossible cube must be caught.
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
    % one corner twisted in place
    set_sticker(9, r, S, T1),
    set_sticker(10, f, T1, T2),
    set_sticker(21, u, T2, Twisted),
    cube_problems(Twisted, P1), P1 == [corner_twist],
    % one edge flipped in place
    set_sticker(6, r, S, T3),
    set_sticker(11, u, T3, Flipped),
    cube_problems(Flipped, P2), P2 == [edge_flip],
    % two edges swapped (nothing else moved)
    set_sticker(11, f, S, T4),
    set_sticker(20, r, T4, Swapped),
    cube_problems(Swapped, P3), P3 == [parity],
    % a corner with two stickers swapped (a mirror-image corner)
    set_sticker(9, r, S, T5),
    set_sticker(10, u, T5, Mirrored),
    cube_problems(Mirrored, P4), P4 == [bad_corner(urf)],
    % an "edge" made of two u stickers
    set_sticker(6, f, S, T6),
    set_sticker(20, u, T6, Impossible),
    cube_problems(Impossible, P5), P5 == [bad_edge(uf)],
    format("Broken cubes caught: twisted corner, flipped edge, swapped edges, mirrored corner, impossible edge~n"),
    format("Piece checks passed~n").