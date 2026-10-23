% count.pl
% Counts how much is in the project: predicates, facts, rules and queries.
% Handy for the report. To use it: load session.pl, load this, then type: count_all.
:- ensure_loaded(session).

% clause_info(-File, -Name/Arity, -Kind)
% One row for every clause that is written in one of our project files.
% Kind is fact or rule.
% (Facts built while the file loads, like the distance tables, do not
% belong to a file, so they are not counted.)
clause_info(File, Name/Arity, Kind) :-
    project_dir(Dir),
    current_predicate(Name/Arity),
    functor(Head, Name, Arity),
    \+ predicate_property(user:Head, imported_from(_)),
    \+ predicate_property(user:Head, built_in),
    catch(clause(user:Head, Body, Ref), _, fail),
    clause_property(Ref, file(File)),
    sub_atom(File, 0, _, _, Dir),
    \+ sub_atom(File, _, _, 0, 'count.pl'),
    (   Body == true -> Kind = fact ; Kind = rule ).

% test_name(+Name)
% True if the predicate is a test (its name starts with test_).
test_name(Name) :- sub_atom(Name, 0, _, _, test_).

% user_query(+Name)
% The predicates a person types at the prompt (not tests).
user_query(start).
user_query(explain).
user_query(explain_why).
user_query(view_demo).
user_query(check_cube).
user_query(Name) :- sub_atom(Name, 0, _, _, solve_), \+ test_name(Name).
user_query(Name) :- sub_atom(Name, _, _, 0, '_report'), \+ test_name(Name).
user_query(Name) :- sub_atom(Name, _, _, 0, '_demo'), \+ test_name(Name).

% report_file(+File, +Rows)
% Prints one line for one file: how many predicates, facts and rules.
report_file(File, Rows) :-
    findall(P, member(File-P-_, Rows), Ps0),
    sort(Ps0, Ps),
    length(Ps, NP),
    findall(x, member(File-_-fact, Rows), Fs),
    length(Fs, NF),
    findall(x, member(File-_-rule, Rows), Rs),
    length(Rs, NR),
    file_base_name(File, Base),
    format("~w: ~d predicates, ~d facts, ~d rules~n", [Base, NP, NF, NR]).

% count_all
% Prints one line per file, then the totals, then how many queries there are:
% queries a user types, and test queries.
count_all :-
    findall(File-Pred-Kind, clause_info(File, Pred, Kind), Rows),
    findall(File, member(File-_-_, Rows), Fs0),
    sort(Fs0, Files),
    forall(member(File, Files), report_file(File, Rows)),
    findall(P, member(_-P-_, Rows), Ps0),
    sort(Ps0, Ps),
    length(Ps, NP),
    findall(x, member(_-_-fact, Rows), Fs),
    length(Fs, NF),
    findall(x, member(_-_-rule, Rows), Rs),
    length(Rs, NR),
    findall(N/A, ( member(N/A, Ps), test_name(N) ), Tests),
    length(Tests, NT),
    findall(N/A, ( member(N/A, Ps), user_query(N) ), Queries0),
    sort(Queries0, Queries),
    length(Queries, NQ),
    nl,
    format("TOTAL: ~d predicates, ~d facts, ~d rules~n", [NP, NF, NR]),
    format("Queries a user types: ~d~n", [NQ]),
    format("Test queries: ~d~n", [NT]),
    nl,
    format("User queries: ~w~n", [Queries]).