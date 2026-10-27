% count.pl
% Counts predicates, facts, rules and queries in the project (for the report).
% Use: load session.pl, load this, then type count_all.

:- ensure_loaded(session).

% clause_info/3: one row for every clause written in a project file (fact or rule).
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

% test_name(Name): true if the name starts with test_.
test_name(Name) :- sub_atom(Name, 0, _, _, test_).

% user_query/1: the predicates a person types at the prompt.
user_query(start).
user_query(explain).
user_query(explain_why).
user_query(view_demo).
user_query(check_cube).
user_query(Name) :- sub_atom(Name, 0, _, _, solve_), \+ test_name(Name).
user_query(Name) :- sub_atom(Name, _, _, 0, '_report'), \+ test_name(Name).
user_query(Name) :- sub_atom(Name, _, _, 0, '_demo'), \+ test_name(Name).

% report_file(File, Rows): prints how many predicates, facts and rules one file has.
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

% count_all: prints each file, the totals, and the number of queries.
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