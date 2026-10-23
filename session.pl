% session.pl
% The interactive lesson. It teaches one step at a time, and shows the
% moves for the way the learner should hold the cube.
% This is the file you load to use the tutor. Then type: start.
% It loads explain.pl and view.pl (and with them everything else).
:- ensure_loaded(explain).
:- ensure_loaded(view).

% Remember which folder this file is in, so we can find cube.txt next to it.
:- dynamic project_dir/1.
:- prolog_load_context(directory, Dir), assertz(project_dir(Dir)).

% cube_file(-File): the full path of cube.txt.
cube_file(File) :-
    project_dir(Dir),
    atomic_list_concat([Dir, '/cube.txt'], File).

% ---------- Showing one step ----------

% show_session_step(+Cube, +Item, +Ctx, +Why, +PrevView, +View)
% Prints one step. Cube is the cube BEFORE the step.
% Same as explain_step, but the moves are shown for the way the learner
% holds the cube (View). PrevView is the view of the step before; we only
% print the "HOLD" line when the view changes.
show_session_step(Cube, item(Stage, K, M, Step), ctx(I, N, Done, Total), Why, Prev, View) :-
    Step = step(Name, Case, Moves0),
    merge_moves(Moves0, Moves),
    view_moves(View, Moves, Shown),
    stage_title(Stage, Title),
    step_target(Stage, Name, Target),
    situation_text(Cube, Stage, Step, Situation),
    length(Moves, L),
    show_moves(Shown, Text),
    DoneAfter is Done + L,
    nl,
    format("=== ~w: step ~w of ~w ===~n", [Title, K, M]),
    (   K =:= 1
    ->  stage_goal(Stage, Goal),
        format("Goal of this stage: ~w~n", [Goal])
    ;   true
    ),
    (   View \== Prev
    ->  view_text(View, Hold),
        format("HOLD: ~w~n", [Hold])
    ;   true
    ),
    format("Working on: ~w~n", [Target]),
    (   Stage == f2l
    ->  format("In this view the pair is at the front right.~n")
    ;   true
    ),
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

% ---------- Asking what to do next ----------

% ask_next(+Why0, -Why, -Action)
% Asks the learner what to do. Action is next, all or quit.
% Why0 is the current "why lines on or off", Why is the new one.
ask_next(Why0, Why, Action) :-
    format("~n[Enter] next   [w] why on/off   [a] show all the rest   [q] quit > "),
    flush_output,
    read_line_to_string(user_input, Line0),
    (   Line0 == end_of_file -> Line = "q" ; Line = Line0 ),
    string_lower(Line, Lower),
    normalize_space(string(Answer), Lower),
    handle_answer(Answer, Why0, Why, Action).

% handle_answer(+Answer, +Why0, -Why, -Action)
% What each answer does. An unknown answer asks again.
handle_answer("", Why, Why, next) :- !.
handle_answer("a", Why, Why, all) :- !.
handle_answer("q", Why, Why, quit) :- !.
handle_answer("w", Why0, Why, Action) :- !,
    (   Why0 == true -> Why1 = false ; Why1 = true ),
    format("Why lines are now ~w (from the next step on).~n", [Why1]),
    ask_next(Why1, Why, Action).
handle_answer(_, Why0, Why, Action) :-
    format("Please press Enter, w, a or q.~n"),
    ask_next(Why0, Why, Action).

% ---------- Walking through the solution ----------

% session_items(+Items, +I, +N, +Done, +Total, +Cube, +Why, +Mode, +PrevView)
% Goes through the steps one by one. Mode is step (ask after every step)
% or all (stop asking and show the rest).
session_items([], _, _, _, _, _, _, _, _).
session_items([Item|Items], I, N, Done, Total, Cube, Why, Mode, Prev) :-
    Item = item(Stage, _, _, Step),
    step_view(Stage, Step, View),
    show_session_step(Cube, Item, ctx(I, N, Done, Total), Why, Prev, View),
    Step = step(_, _, Moves),
    apply_moves(Moves, Cube, Cube1),
    item_length(Item, L),
    Done1 is Done + L,
    I1 is I + 1,
    (   Items == []
    ->  session_items([], I1, N, Done1, Total, Cube1, Why, Mode, View)
    ;   Mode == all
    ->  session_items(Items, I1, N, Done1, Total, Cube1, Why, Mode, View)
    ;   ask_next(Why, Why1, Action),
        (   Action == quit
        ->  format("Stopped after step ~w of ~w. Run start. to begin again.~n", [I, N])
        ;   (   Action == all -> Mode1 = all ; Mode1 = Mode ),
            session_items(Items, I1, N, Done1, Total, Cube1, Why1, Mode1, View)
        )
    ).

% lesson(+Cube)
% Solves a legal cube and teaches it, step by step.
lesson(Cube) :-
    solve(Cube, Stages),
    flat_steps(Stages, Items),
    length(Items, N),
    (   N =:= 0
    ->  format("The cube is already solved. Nothing to do.~n")
    ;   maplist(item_length, Items, Lens),
        sum_list(Lens, Total),
        format("~nThe solution has ~w steps and ~w moves.~n", [N, Total]),
        session_items(Items, 1, N, 0, Total, Cube, false, step, none),
        format("~nFinished.~n")
    ).

% ---------- Reading cube.txt ----------

% cube_from_string(+String, -Cube)
% Turns text into a cube. It must be exactly 54 letters from u r f d l b.
cube_from_string(String, Cube) :-
    string_lower(String, Lower),
    normalize_space(string(Clean), Lower),
    string_chars(Clean, Cube),
    length(Cube, 54),
    forall(member(C, Cube), memberchk(C, [u, r, f, d, l, b])).

% load_cube_file(-Cube)
% Reads cube.txt (the file next to this one) and gives the cube.
% If the file is missing or wrong, it says so and fails.
load_cube_file(Cube) :-
    cube_file(File),
    (   exists_file(File)
    ->  read_file_to_string(File, String, []),
        (   cube_from_string(String, Cube)
        ->  true
        ;   format("cube.txt is not 54 letters from u r f d l b.~n"),
            fail
        )
    ;   format("There is no cube.txt yet. Run: python vision.py capture, then python vision.py read~n"),
        fail
    ).

% ---------- Starting ----------

% start
% The main entry. Asks for a scramble, 'scan', or 'random', then runs the lesson.
start :-
    format("CubeTutor~n"),
    format("Hold the cube with white on the bottom and green toward you.~n"),
    format("Type the scramble you applied to a solved cube (like R U R' U'),~n"),
    format("or 'scan' to use cube.txt from the camera, or 'random', or 'q' to quit.~n> "),
    flush_output,
    read_line_to_string(user_input, Line0),
    (   Line0 == end_of_file -> Line = "q" ; Line = Line0 ),
    normalize_space(string(Text), Line),
    start_with(Text).

% start_with(+Text)
% Does what the learner typed: q, random, scan, or a scramble.
start_with("q") :- !.
start_with("random") :- !,
    solved_cube(S),
    random_scramble(25, Ms),
    apply_moves(Ms, S, Cube),
    scramble_text(Ms, ScrambleText),
    format("Scramble: ~w~n", [ScrambleText]),
    lesson(Cube).
start_with("scan") :- !,
    (   load_cube_file(Cube)
    ->  check_and_teach(Cube, scan)
    ;   start
    ).
start_with(Text) :-
    (   catch(scramble_cube(Text, Cube), _, fail)
    ->  check_and_teach(Cube, typed)
    ;   format("I could not read that scramble. Use letters U D R L F B, with ' or 2.~n"),
        start
    ).

% check_and_teach(+Cube, +Source)
% If the cube is possible, teach it. If not (for example a sticker was
% misread by the camera), say what is wrong. Source is scan or typed.
check_and_teach(Cube, Source) :-
    (   cube_problems(Cube, [])
    ->  lesson(Cube)
    ;   format("This cube cannot be solved as it is:~n"),
        check_cube(Cube),
        (   Source == scan
        ->  format("A sticker was probably misread. Retake the photos with better light:~n"),
            format("  python vision.py capture   then   python vision.py read~n"),
            format("then run start. and type scan again.~n")
        ;   format("Check the scramble and try again.~n"),
            start
        )
    ).

% ---------- Tests ----------

% test_session
% Runs a whole lesson with the questions skipped (mode all). Checks that
% every step is printed, and that the HOLD and Why lines are there.
test_session :-
    scramble_cube("R U R' U' F2 D L' B2 U R", Cube),
    solve(Cube, Stages),
    flat_steps(Stages, Items),
    length(Items, N),
    maplist(item_length, Items, Lens),
    sum_list(Lens, Total),
    with_output_to(string(Out),
                   session_items(Items, 1, N, 0, Total, Cube, true, all, none)),
    split_string(Out, "\n", "", Lines),
    include(is_moves_line, Lines, MovesLines),
    length(MovesLines, N),
    sub_string(Out, _, _, _, "HOLD: Turn the cube over"),
    sub_string(Out, _, _, _, "Why: "),
    format("Session test passed (~w steps)~n", [N]).

% test_scan_parse
% A solved cube written as letters must read back correctly,
% and texts that are wrong must be refused.
test_scan_parse :-
    solved_cube(Solved),
    atomic_list_concat(Solved, Text),
    cube_from_string(Text, Back),
    Back == Solved,
    \+ cube_from_string("uuuu", _),
    \+ cube_from_string("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", _),
    format("cube.txt parsing test passed~n").