:- module(
  rdf_ext,
  [
    quad_object/2,          % +Quad, -O
    rdf_aggregate_all/3,    % +Template, :Goal, -Result
    rdf_assert/1,           % +Tuple
    rdf_assert/2,           % +Triple, +G
    rdf_assert_action/4,    % +ActionClass, +Actor, -Action, +G
    rdf_assert_instance/2,  % +I, ?C
    rdf_assert_instance/3,  % +I, ?C, +G
    rdf_assert_instances/2, % +I, +Cs
    rdf_assert_instances/3, % +I, +Cs, +G
    rdf_assert_list/4,      % +S, +P, +L, +G
    rdf_assert_mode/4,      % +Mode, +S, +P, +O
    rdf_assert_mode/5,      % +Mode, +S, +P, +O, +Sink
    rdf_assert_now/2,       % +S, +P
    rdf_assert_now/3,       % +S, +P, +D
    rdf_assert_now/4,       % +S, +P, +D, +G
    rdf_assert_objects/3,   % +S, +P, +Os
    rdf_assert_objects/4,   % +S, +P, +Os, +G
    rdf_assert_rev/3,       % +O, +P, +S
    rdf_assert_rev/4,       % +O, +P, +S, +G
    rdf_create_iri/2,       % +Prefix, -Iri
    rdf_create_iri/3,       % +Prefix, +SubPaths, -Iri
    rdf_expect_graph/1,     % ?G
    rdf_global_iri/3,       % ?Alias, ?Local, ?Iri
    rdf_graph_to_triples/2, % ?G, -Triples
    rdf_has/5,              % ?S, ?P, ?O, ?Q, ?G
    rdf_image/2,            % +S, -Img
    rdf_is_ground_quad/1,   % @Term
    rdf_is_ground_triple/1, % @Term
    rdf_is_quad/1,          % @Term
    rdf_is_triple/1,        % @Term
    rdf_langstring/3,       % ?S, ?P, -Lit
    rdf_list/3,             % ?S, ?P, -L
    rdf_nextto_cl/2,        % ?X, ?Y
    rdf_pref_lex/3,         % ?S, ?P, ?Lex
    rdf_pref_string/3,      % ?S, ?P, ?Lit
    rdf_reification/3,      % ?S, ?P, ?O
    rdf_reification/4,      % ?S, ?P, ?O, ?G
    rdf_reification/5,      % ?S, ?P, ?O, ?G, -Stmt
    rdf_retractall/1,       % +Tuple
    rdf_root/1,             % ?Root
    rdf_root/2,             % ?Root, ?G
    rdf_snap/1,             % :Goal_0
    rdf_string/2,           % +Lit, -String
    rdf_tree/2,             % ?S, -Tree
    rdf_tree/3,             % ?S, ?G, -Tree
    rdf_triples/4,          % ?S, ?P. ?O, -Triples:ordset
    rdf_tuple/1,            % ?Tuple
    rdf_unload_db/0,
    triple_subject/2        % ?Triple, ?S
  ]
).

/** <module> RDF extensions

@author Wouter Beek
@compat RDF 1.1
@version 2015/12-2016/06
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(closure)).
:- use_module(library(error)).
:- use_module(library(gen/gen_ntuples)).
:- use_module(library(nlp/nlp_lang)).
:- use_module(library(ordsets)).
:- use_module(library(print_ext)).
:- use_module(library(rdf/rdf_default)).
:- use_module(library(rdf/rdf_prefix), []). % Load RDF prefixes.
:- use_module(library(rdf/rdf_term)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(uuid_ext)).
:- use_module(library(yall)).

:- rdf_register_prefix(dbo, 'http://dbpedia.org/ontology/').
:- rdf_register_prefix(dcmit, 'http://purl.org/dc/dcmitype/').
:- rdf_register_prefix(prov, 'http://www.w3.org/ns/prov#').

:- meta_predicate
    rdf_aggregate_all(+, 0, -),
    rdf_snap(0).

:- rdf_meta
   quad_object(t, o),
   rdf_aggregate_all(+, t, -),
   rdf_assert(t),
   rdf_assert(t, r),
   rdf_assert_action(r, r, -, r),
   rdf_assert_instance(r, r),
   rdf_assert_instance(r, r, r),
   rdf_assert_instances(r, t),
   rdf_assert_instances(r, t, r),
   rdf_assert_list(r, r, t, r),
   rdf_assert_mode(+, r, r, o),
   rdf_assert_mode(+, r, r, o, r),
   rdf_assert_now(o, r),
   rdf_assert_now(o, r, r),
   rdf_assert_now(o, r, r, r),
   rdf_assert_objects(r, r, t),
   rdf_assert_objects(r, r, t, r),
   rdf_assert_rev(o, r, r),
   rdf_assert_rev(o, r, r, r),
   rdf_expect_graph(r),
   rdf_graph_to_triples(r, -),
   rdf_has(r, r, o, r, r),
   rdf_image(r, -),
   rdf_langstring(r, r, o),
   rdf_list(r, r, -),
   rdf_nextto_cl(o, o),
   rdf_pref_lex(r, r, ?),
   rdf_pref_string(r, r, o),
   rdf_pref_string(r, r, -, o),
   rdf_pref_string(r, r, -, -, o),
   rdf_retractall(t),
   rdf_reification(r, r, o),
   rdf_reification(r, r, o, r),
   rdf_reification(r, r, o, r, -),
   rdf_root(r),
   rdf_root(r, r),
   rdf_string(r, -),
   rdf_tree(r, -),
   rdf_tree(r, r, -),
   rdf_triples(r, r, o, -).





%! quad_object(+Quad, -O) is det.

quad_object(rdf(_,_,O,_), O).



%! rdf_aggregate_all(+Template, :Goal, -Result) is det.

rdf_aggregate_all(Template, Goal, Result) :-
  aggregate_all(Template, Goal, Result).



%! rdf_assert(+Tuple) is det.

rdf_assert(rdf(S,P,O)) :- !,
  rdf_assert(S, P, O).
rdf_assert(rdf(S,P,O,G)) :-
  rdf_assert(S, P, O, G).


%! rdf_assert(+Triple, +G) is det.

rdf_assert(rdf(S,P,O), G) :-
  rdf_assert(S, P, O, G).



%! rdf_assert_action(+ActionC, +Actor, -Action, +G) is det.

rdf_assert_action(ActionC, Actor, Action, G):-
  rdf_create_iri(vzm, [action], Action),
  rdf_assert(Action, rdf:type, ActionC, G),
  rdf_assert_now(Action, prov:atTime, G),
  rdf_assert(Action, prov:wasAssociatedWith, Actor, G).



%! rdf_assert_instance(+I, ?C) is det.
%! rdf_assert_instance(+I, ?C, ?G) is det.

rdf_assert_instance(I, C) :-
  rdf_assert_instance(I, C, _).


rdf_assert_instance(I, C, G) :-
  rdf_defval(C, rdfs:'Resource'),
  rdf_assert(I, rdf:type, C, G).



%! rdf_assert_instances(+I, +Cs) is det.
%! rdf_assert_instances(+I, +Cs, ?G) is det.

rdf_assert_instances(I, Cs) :-
  rdf_assert_instances(I, Cs, _).

rdf_assert_instances(I, Cs, G) :-
  maplist({I,G}/[C]>>rdf_assert_instance(I, C, G), Cs).



%! rdf_assert_list(+S, +P, +L, +G) is det.

rdf_assert_list(S, P, L, G) :-
  rdf_assert_list(L, B, G),
  rdf_assert(S, P, B, G).



%! rdf_assert_mode(+Mode:oneof([hdt,mem]), +S, +P, +O) is det.
%! rdf_assert_mode(+Mode:oneof([hdt,mem]), +S, +P, +O, +Sink) is det.

rdf_assert_mode(hdt, S, P, O) :-
  gen_ntriple(S, P, O).
rdf_assert_mode(mem, S, P, O) :-
  rdf_assert(S, P, O).


rdf_assert_mode(hdt, S, P, O, Sink) :-
  call_to_stream(Sink, [Out,M,M]>>with_output_to(Out, gen_ntriple(S, P, O))).
rdf_assert_mode(mem, S, P, O, G) :-
  rdf_assert(S, P, O, G).



%! rdf_assert_now(+S, +P) is det.
%! rdf_assert_now(+S, +P, +D) is det.
%! rdf_assert_now(+S, +P, +D, +G) is det.

rdf_assert_now(S, P) :-
  rdf_assert_now(S, P, xsd:dateTime).

rdf_assert_now(S, P, D) :-
  rdf_assert_now(S, P, D, default).

rdf_assert_now(S, P, D, G) :-
  get_time(Now),
  rdf_assert(S, P, Now^^D, G).



%! rdf_assert_objects(+S, +P, +Os) is det.
%! rdf_assert_objects(+S, +P, +Os, +G) is det.

rdf_assert_objects(S, P, Os) :-
  rdf_default_graph(G),
  rdf_assert_objects(S, P, Os, G).


rdf_assert_objects(S, P, Os, G) :-
  forall(member(O, Os), rdf_assert(S, P, O, G)).



%! rdf_assert_rev(+O, +P, +S) is det.

rdf_assert_rev(O, P, S) :-
  rdf_assert_rev(S, P, O).


%! rdf_assert_rev(+O, +P, +S, +G) is det.

rdf_assert_rev(O, P, S, G) :-
  rdf_assert(S, P, O, G).



%! rdf_create_iri(+Prefix,            -Iri) is det.
%! rdf_create_iri(+Prefix, +SubPaths, -Iri) is det.
% Succeeds with a fresh IRI within the RDF namespace denoted by Prefix
% and the given SubPaths.
%
% IRI freshness is guaranteed by the UUID that is used as the path suffix.
%
% @arg Prefix   A registered RDF prefix name.
% @arg SubPaths A list of path names that prefix the UUID.
% @arg Iri      A fresh IRI.

rdf_create_iri(Prefix, Iri) :-
  rdf_create_iri(Prefix, [], Iri).


rdf_create_iri(Prefix, SubPaths0, Iri) :-
  uuid_no_hyphen(Id),
  append(SubPaths0, [Id], SubPaths),
  atomic_list_concat(SubPaths, /, LocalName),
  % Resolve the absolute IRI against the base IRI denoted by the RDF prefix.
  rdf_global_id(Prefix:LocalName, Iri).



%! rdf_expect_graph(+G) is semidet.
%! rdf_expect_graph(-G) is nondet.
% If Term is uninstantiated it is non-deterministically
% instantiated to existing RDF graphs.
% If Term is instantiated and does not denote an existing RDF graph
% this results in an exception.
%
% @throws existence_error

rdf_expect_graph(G) :-
  rdf_graph(G), !.
rdf_expect_graph(G) :-
  existence_error(rdf_graph, G).



%! rdf_global_iri(+Alias, +Local, -Iri) is det.
%! rdf_global_iri(-Alias, -Local, +Iri) is det.

rdf_global_iri(Alias, Local, Iri) :-
  rdf_global_id(Alias:Local, Iri).



% ! rdf_graph_to_triples(?G, -Triples) is det.

rdf_graph_to_triples(G, Triples) :-
  rdf_expect_graph(G),
  aggregate_all(set(rdf(S,P,O)), rdf(S, P, O, G), Triples).



%! rdf_has(?S, ?P, ?O, -Q, ?G) is nondet.

rdf_has(S, P, O, Q, G) :-
  rdf_has(S, P, O, Q),
  rdf(S, Q, O, G).



%! rdf_image(+S, -Image:iri) is nondet.

rdf_image(S, V) :-
  rdf_has(S, dbo:thumbnail, V^^xsd:anyURI).
rdf_image(S, V) :-
  rdf_has(S, foaf:depiction, V^^xsd:anyURI).
rdf_image(S, V) :-
  rdf(S, _, V),
  rdfs_instance(V, dcmit:'Image').



%! rdf_is_ground_quad(@Term) is semidet.
% Succeeds if the given triple is ground, i.e., contains no blank node.

rdf_is_ground_quad(rdf(S,P,O,_)) :-
  rdf_is_ground_triple(rdf(S,P,O)).



%! rdf_is_ground_triple(@Term) is semidet.
% Succeeds if the given triple is ground, i.e., contains no blank node.

rdf_is_ground_triple(rdf(S,_,O)) :-
  \+ rdf_is_bnode(S),
  \+ rdf_is_bnode(O).



%! rdf_is_quad(@Term) is semidet.

rdf_is_quad(rdf(_,_,_,_)).



%! rdf_is_triple(@Term) is semidet.

rdf_is_triple(rdf(_,_,_)).



%! rdf_langstring(?S, ?P, -Lit) is nondet.
% Matches RDF statements whose object term is a language-tagged string
% that mathes the given language priory list.
% Notice that results for each of the prioritized languages are given
% in arbitrary order.

rdf_langstring(S, P, Lit) :-
  current_lrange(LRange),
  rdf_langstring(S, P, LRange, Lit).

rdf_langstring(S, P, LRange, Lit) :-
  rdf_has(S, P, V@LTag),
  basic_filtering(LRange, LTag),
  Lit = V@LTag.



%! rdf_list(?S, ?P, -L) is nondet.

rdf_list(S, P, L) :-
  rdf_has(S, P, B),
  (rdf_list(B) -> rdf_list(B, L) ; L = [B]).



%! rdf_nextto_cl(?X, ?Y, ?RdfList) is nondet.

rdf_nextto_cl(X, Y) :-
  closure([X,Y]>>rdf_nextto(X, Y), X, Y).



%! rdf_pref_lex(?S, ?P, ?Lex) is nondet.
%
% Like rdf_pref_string, but returns only the lexical form.

rdf_pref_lex(S, P, Lex) :-
  rdf_pref_string(S, P, Lit),
  rdf_literal_lex(Lit, Lex).



%! rdf_pref_string(?S, ?P, ?Lit) is nondet.
%
% Returns, in this exact order:
%
%   1. The language-tagged strings that match the given language
%   priority list; returning results for higher priority language
%   earlier.
%
%   2. The language-tagged strings that do not match the given
%   language priority list.
%
%   3. XSD strings.

rdf_pref_string(S, P, Lit) :-
  current_lrange(LRange),
  rdf_pref_string(S, P, LRange, Lit).

% Matching language-tagged strings.
rdf_pref_string(S, P, LRange, Lit) :-
  rdf_langstring(S, P, LRange, Lit).
% Non-matching language-tagged strings.
rdf_pref_string(S, P, LRange, Lit) :-
  rdf_has(S, P, V@LTag),
  % Avoid duplicates.
  \+ basic_filtering(LRange, LTag),
  Lit = V@LTag.
% Plain XSD strings.
rdf_pref_string(S, P, _, V^^xsd:string) :-
  rdf_has(S, P, V^^xsd:string).



%! rdf_reification(?S, ?P, ?O) is nondet.
%! rdf_reification(?S, ?P, ?O, ?G) is nondet.
%! rdf_reification(?S, ?P, ?O, ?G, -Stmt) is nondet.

rdf_reification(S, P, O) :-
  rdf_reification(S, P, O, _).


rdf_reification(S, P, O, G) :-
  rdf_reification(S, P, O, G, _).


rdf_reification(S, P, O, G, Stmt) :-
  rdf_has(Stmt, rdf:subject, S, _, G),
  rdf_has(Stmt, rdf:predicate, P, _, G),
  rdf_has(Stmt, rdf:object, O, _, G).



%! rdf_retractall(+Tuple) is det.

rdf_retractall(rdf(S,P,O)) :- !,
  rdf_retractall(S, P, O).
rdf_retractall(rdf(S,P,O,G)) :-
  rdf_retractall(S, P, O, G).



%! rdf_root(?Root) is nondet.
%! rdf_root(?Root, ?G) is nondet.

rdf_root(Root) :-
  rdf_root(Root, _).


rdf_root(Root, G) :-
  rdf_subject(Root, G),
  \+ rdf(_, _, Root).



%! rdf_snap(:Goal_0) .

rdf_snap(Goal_0) :-
  rdf_transaction(Goal_0, _, [snapshot(true)]).



%! rdf_string(+Lit, -String) is det.

rdf_string(V^^xsd:string, V) :- !.
rdf_string(V@_, V).



%! rdf_tree(?S, -Tree) is det.
%! rdf_tree(?S, ?G, -Tree) is det.

rdf_tree(S, Tree) :-
  rdf_tree(S, _, Tree).


rdf_tree(S, G, Tree) :-
  rdf_subject(S, G),
  rdf_tree([S], G, [], [], Tree).

rdf_tree([], _, _, Tree, Tree) :- !.
rdf_tree([H|T], G, Hist, Tree, Sol) :-
  memberchk(H, Hist), !,
  rdf_tree(T, G, Hist, Tree, Sol).
rdf_tree([S|T1], G, Hist1, Tree1, Sol) :-
  aggregate_all(set(rdf(S,P,O)), rdf(S, P, O, G), Triples),
  aggregate_all(set(O), (rdf(S, _, O, G), \+ rdf_is_literal(O)), Os),
  ord_union(T1, Os, T2),
  ord_add_element(Hist1, S, Hist2),
  ord_union(Tree1, Triples, Tree2),
  rdf_tree(T2, G, Hist2, Tree2, Sol).



%! rdf_tuple(+Tuple) is semidet.
%! rdf_tuple(-Tuple) is nondet.

rdf_tuple(Tuple) :-
  var(Tuple), !,
  rdf(S, P, O, G),
  (G == default -> Tuple = rdf(S,P,O) ; Tuple = rdf(S,P,O,G)).
rdf_tuple(rdf(S,P,O)) :- !,
  rdf(S, P, O).
rdf_tuple(rdf(S,P,O,G)) :-
  rdf(S, P, O, G).
  


%! rdf_triples(?S, ?P, ?O, -Triples) is det.

rdf_triples(S, P, O, Triples):-
  aggregate_all(set(rdf(S,P,O)), rdf(S, P, O), Triples).



%! rdf_unload_db is det.

rdf_unload_db :-
  rdf_graph(G), !,
  rdf_unload_graph(G),
  rdf_unload_db.
rdf_unload_db.



%! triple_subject(+Triple, -S) is det.

triple_subject(rdf(S,_,_), S).





% HELPER %

%! basic_filtering(
%!   +LanguagePriorityList:list(atom),
%!   +LanguageTag:atom
%! ) is semidet.
% Succeeds if the LanguagePriorityList matches the LanguageTag according to
% the basic filtering algorithm described in RFC 4647,
% i.e., if the former is a case-insensitive prefix of the latter,
% while also treating the `*` sign as a wildcard.
%
% @compat RFC 4647

basic_filtering(Ranges, Tag):-
  % NONDET
  member(Range, Ranges),
  atomic_list_concat(Subtags1, -, Range),
  atomic_list_concat(Subtags2, -, Tag),
  basic_filtering0(Subtags1, Subtags2), !.

basic_filtering0(_, []).
basic_filtering0([H1|T1], [H2|T2]):-
  subtag_match(H1, H2),
  basic_filtering0(T1, T2).


%! subtag_match(+RangeSubtag:atom, +Subtag:atom) is semidet.
% Two subtags match if either they are the same when compared
% case-insensitively or the language range's subtag is the wildcard `*`

subtag_match(*, _):- !.
subtag_match(X1, X2):-
  downcase_atom(X1, X),
  downcase_atom(X2, X).
