% main.pl
% The whole solve: cross, then F2L, then OLL, then PLL.

:- ensure_loaded(f2l).
:- ensure_loaded(pll).

% solve(Cube, Stages): solves a legal cube in four stages, each stage(Name, Steps).
solve(Cube, Stages) :-
    legal_cube(Cube),
    cross_steps(Cube, CrossSteps),
    steps_moves(CrossSteps, M1),
    apply_moves(M1, Cube, C1),
    f2l_steps(C1, F2lSteps),
    steps_moves(F2lSteps, M2),
    apply_moves(M2, C1, C2),
    oll_solve_steps(C2, OllSteps),
    steps_moves(OllSteps, M3),
    apply_moves(M3, C2, C3),
    pll_solve_steps(C3, PllSteps),
    Stages = [ stage(cross, CrossSteps),
               stage(f2l,   F2lSteps),
               stage(oll,   OllSteps),
               stage(pll,   PllSteps) ].

% stages_moves(Stages, Moves): every move of every stage, in one list.
stages_moves(Stages, Moves) :-
    findall(M,
            ( member(stage(_, Steps), Stages),
              member(step(_, _, M), Steps) ),
            Lists),
    append(Lists, Moves).

% stage_moves(Steps, Merged): the moves of one stage, with neighbouring turns joined.
stage_moves(Steps, Merged) :-
    steps_moves(Steps, Raw),
    merge_moves(Raw, Merged).

% solve_moves(Cube, Moves): the whole solution as one list of moves.
solve_moves(Cube, Moves) :-
    solve(Cube, Stages),
    stages_moves(Stages, Moves).

% solve_report(Scramble): scrambles, solves, prints each stage and checks it on the real
%   cube.
solve_report(Scramble) :-
    scramble_cube(Scramble, Cube),
    solve(Cube, Stages),
    forall(member(stage(Name, Steps), Stages),
           ( stage_moves(Steps, Moves),
             length(Moves, N),
             scramble_text(Moves, Text),
             format("~w (~w moves): ~w~n", [Name, N, Text]) )),
    findall(N, ( member(stage(_, Steps), Stages),
                 stage_moves(Steps, Moves),
                 length(Moves, N) ),
            Counts),
    sum_list(Counts, Total),
    format("Total: ~w moves~n", [Total]),
    stages_moves(Stages, All),
    apply_moves(All, Cube, After),
    solved_cube(Solved),
    (   After == Solved
    ->  format("Check on the real cube: solved~n")
    ;   format("Check on the real cube: FAILED~n")
    ).

% replay_ok/2: replays the stages on the real cube and checks each one did its job.
replay_ok(Cube, [ stage(cross, CrossSteps),
                  stage(f2l,   F2lSteps),
                  stage(oll,   OllSteps),
                  stage(pll,   PllSteps) ]) :-
    steps_moves(CrossSteps, M1),
    apply_moves(M1, Cube, C1),
    cross_solved(C1),
    steps_moves(F2lSteps, M2),
    apply_moves(M2, C1, C2),
    cross_solved(C2),
    f2l_pairs_solved(C2, 4),
    steps_moves(OllSteps, M3),
    apply_moves(M3, C2, C3),
    f2l_pairs_solved(C3, 4),
    oll_solved(C3),
    steps_moves(PllSteps, M4),
    apply_moves(M4, C3, C4),
    solved_cube(Solved),
    C4 == Solved.

% test_solve_solved: a solved cube gives four stages and no moves.
test_solve_solved :-
    solved_cube(Solved),
    solve(Solved, Stages),
    Stages = [_, _, _, _],
    stages_moves(Stages, []),
    format("Solved cube: 4 stages, 0 moves~n").

% test_solve_known: one fixed scramble, every stage checked.
test_solve_known :-
    scramble_cube("R U R' U' F2 D L' B2 U R", Cube),
    solve(Cube, Stages),
    replay_ok(Cube, Stages),
    format("Known scramble solved, every stage checked~n").

% test_solve(N): N random cubes solved from scratch, every stage checked.
test_solve(N) :-
    solved_cube(S),
    statistics(cputime, T0),
    findall(Total,
            ( between(1, N, _),
              random_scramble(25, Ms),
              apply_moves(Ms, S, Cube),
              solve(Cube, Stages),
              replay_ok(Cube, Stages),
              findall(L, ( member(stage(_, Steps), Stages),
                           stage_moves(Steps, M),
                           length(M, L) ),
                      Ls),
              sum_list(Ls, Total) ),
            Totals),
    length(Totals, N),
    statistics(cputime, T1),
    sum_list(Totals, Sum),
    max_list(Totals, Longest),
    Avg is Sum / N,
    Secs is T1 - T0,
    format("~w random cubes solved from scratch, every stage checked on the full cube. Moves: average ~1f, longest ~w. Time: ~1f seconds~n",
           [N, Avg, Longest, Secs]).

% test_main: runs the solve tests.
test_main :-
    test_solve_solved,
    test_solve_known,
    test_solve(10),
    format("Solve tests passed~n").