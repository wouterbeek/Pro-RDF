:- module(
  rdf_read,
  [
    rdf/3, % ?Subject, ?Predicate, ?Object
    rdf/4, % ?Subject, ?Predicate, ?Object, ?Graph
    rdf/6, % ?Subject, ?Predicate, ?Object, -Sid, -Pid, -Oid
    rdf/7, % ?Subject:gid
           % ?Predicate:gid
           % ?Object:gid
           % ?Graph:rdf_graph
           % -Sid:uid
           % -Pid:uid
           % -Oid:uid
    rdf_date/3, % ?Subject, ?Predicate, ?Date
    rdf_date/4, % ?Subject:rdf_term
                % ?Predicate:iri
                % ?Date:compound
                % ?Graph:rdf_graph
    rdf_instance/2, % ?Instance, ?Class
    rdf_instance/3, % ?Instance:rdf_term
                    % ?Class:rdf_term
                    % ?Graph:rdf_graph
    rdf_langstring/4, % ?Subject, ?Predicate, +LanguagePriorityList, ?Value
    rdf_langstring/5, % ?Subject:rdf_term
                      % ?Predicate:iri
                      % +LanguagePriorityList:list(atom)
                      % ?Value:pair(atom)
                      % ?Graph:rdf_graph
    rdf_langstring_pref/4, % ?Subject, ?Predicate, +LanguagePriorityList, ?Value
    rdf_langstring_pref/5, % ?Subject:rdf_term
                           % ?Predicate:iri
                           % +LanguagePriorityList:list(atom)
                           % ?Value:pair(atom)
                           % ?Graph:rdf_graph
    rdf_literal/3, % ?Subject, ?Predicate, ?Value
    rdf_literal/4, % ?Subject, ?Predicate, ?Datatype, ?Value
    rdf_literal/5, % ?Subject:rdf_term
                   % ?Predicate:iri
                   % ?Datatype:iri
                   % ?Value
                   % ?Graph:rdf_graph
    rdf_literal_pl/3, % ?Subject, ?Predicate, ?Value
    rdf_literal_pl/4, % ?Subject, ?Predicate, ?Datatype, ?Value
    rdf_literal_pl/5 % ?Subject:rdf_term
                     % ?Predicate:iri
                     % ?Datatype:iri
                     % ?Value
                     % ?Graph:rdf_graph
  ]
).

/** <module> Generalized RDF reading

@author Wouter Beek
@compat RDF 1.1 Concepts and Abstract Syntax
@license MIT License
@see http://www.w3.org/TR/rdf11-concepts/
@version 2015/07-2015/12
*/

:- use_module(library(datetime/datetime)).
:- use_module(library(error)).
:- use_module(library(list_ext)).
:- use_module(library(ltag/ltag_match)).
:- use_module(library(rdf/id_store)).
:- use_module(library(rdf/rdf_build)).
:- use_module(library(rdf/rdf_datatype)).
:- use_module(library(rdf/rdf_prefix)).
:- use_module(library(rdf/rdf_term)).
:- use_module(library(semweb/rdf_db), [rdf/4 as rdf_id]).
:- use_module(library(xsd/xsd)).

:- rdf_meta(rdf(o,r,o)).
:- rdf_meta(rdf(o,r,o,r)).
:- rdf_meta(rdf(o,r,o,-,-,-)).
:- rdf_meta(rdf(o,r,o,r,-,-,-)).
:- rdf_meta(rdf_date(o,r,?)).
:- rdf_meta(rdf_date(o,r,?,r)).
:- rdf_meta(rdf_instance(o,r)).
:- rdf_meta(rdf_instance(o,r,r)).
:- rdf_meta(rdf_langstring(o,r,+,?)).
:- rdf_meta(rdf_langstring(o,r,+,?,r)).
:- rdf_meta(rdf_langstring_pref(o,r,+,?)).
:- rdf_meta(rdf_langstring_pref(o,r,+,?,r)).
:- rdf_meta(rdf_literal(o,r,?)).
:- rdf_meta(rdf_literal(o,r,r,?)).
:- rdf_meta(rdf_literal(o,r,r,?,r)).
:- rdf_meta(rdf_literal_pl(o,r,?)).
:- rdf_meta(rdf_literal_pl(o,r,r,?)).
:- rdf_meta(rdf_literal_pl(o,r,r,?,r)).





%! rdf(?Subject:rdf_term, ?Predicate:iri, ?Object:rdf_term) is nondet.
% Wrapper around rdf/4 reading from the default graph.

rdf(S, P, O):-
  rdf(S, P, O, _).


%! rdf(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   ?Graph:rdf_graph
%! ) is nondet.

% 1. Identity statement.
rdf(S, P, O, _):-
  ground(P),
  rdf_is_id(P, owl:sameAs), !,
  (   nonvar(S)
  ->  term_to_term(S, O)
  ;   nonvar(O)
  ->  term_to_term(O, S)
  ;   % Enumerate identical terms.
      % NONDET
      id_terms(Ts),
      member(S, O, Ts)
  ).
% 2. Statements other than identity statements.
rdf(S, P, O, G):-
  rdf(S, P, O, G, Sid, Pid, Oid),
  % Variable subject terms may be blank nodes that need to be
  % related to literals.
  (ground(S) -> true ; literal_id(S, Sid) -> true ; id_to_term(Sid, S)),
  (ground(P) -> true ; id_to_term(Pid, P)),
  (ground(O) -> true ; id_to_term(Oid, O)).


%! rdf(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   -Sid:uid,
%!   -Pid:uid,
%!   -Oid:uid
%! ) is nondet.


rdf(S, P, O, Sid, Pid, Oid):-
  rdf(S, P, O, _, Sid, Pid, Oid).


%! rdf(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   ?Graph:rdf_graph,
%!   -Sid:uid,
%!   -Pid:uid,
%!   -Oid:uid
%! ) is nondet.

rdf(S, P, O, G, Sid, Pid, Oid):-
  % (Only) in the subject position, literals may be represented by blank nodes.
  (rdf_is_literal(S) -> literal_id(S, Sid) ; nonvar(S) -> term_to_id(S, Sid) ; true),
  (nonvar(P) -> term_to_id(P, Pid) ; true),
  (nonvar(O) -> term_to_id(O, Oid) ; true),
  rdf_id(Sid, Pid, Oid, G).



%! rdf_date(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Date:compound
%! ) is nondet.
% Wrapper around rdf_date/4 with uninstantiated graph.

rdf_date(S, P, V):-
  rdf_date(S, P, V, _).


%! rdf_date(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Date:compound,
%!   ?Graph:rdf_graph
%! ) is nondet.
% Read some date-time value.
%
% Supports the following RDF datatypes:
%   * xsd:date
%   * xsd:dateTime
%   * xsd:gDay
%   * xsd:gMonth
%   * xsd:gMonthDay
%   * xsd:gYear
%   * xsd:gYearMonth
%   * xsd:time

rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:date, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:dateTime, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:gDay, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:gMonth, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:gMonthDay, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:gYear, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:gYearMonth, V, G).
rdf_date(S, P, V, G):-
  rdf_literal(S, P, xsd:time, V, G).



%! rdf_instance(?Instance:rdf_term, ?Class:iri) is nondet.
% Wrapper around rdf_instance/3 with uninstantiated graph.

rdf_instance(I, C):-
  rdf_instance(I, C, _).


%! rdf_instance(?Instance:rdf_term, ?Class:iri, ?Graph:rdf_graph) is nondet.

rdf_instance(I, C, G):-
  rdf_expand_ct(rdf:type, P),
  rdf(I, P, C, G).



%! rdf_langstring(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   +LanguagePriorityList:list(atom),
%!   ?Value:pair(atom)
%! ) is nondet.
% Wrapper around rdf_langstring/5 with uninstantiated graph.

rdf_langstring(S, P, LRanges, V):-
  rdf_langstring(S, P, LRanges, V, _).


%! rdf_langstring(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   +LanguagePriorityList:list(atom),
%!   ?Value:pair(atom),
%!   ?Graph:rdf_graph
%! ) is nondet.

rdf_langstring(S, P, LRanges, V, G):-
  rdf_literal(S, P, rdf:langString, V, G),
  V = _-LTag,
  atom(LTag),
  basic_filtering(LRanges, LTag).



%! rdf_langstring_pref(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   +LanguagePriorityList:list(atom),
%!   ?Value:pair(atom)
%! ) is nondet.
% Wrapper around rdf_langstring_pref/5 with uninstantiated graph.

rdf_langstring_pref(S, P, LRanges, V):-
  rdf_langstring_pref(S, P, LRanges, V, _).


%! rdf_langstring_pref(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   +LanguagePriorityList:list(atom),
%!   ?Value:pair(atom),
%!   ?Graph:rdf_graph
%! ) is nondet.
% Returns, in this exact order:
%   1. The language-tagged strings that match the given
%      language priority list.
%   2. The language-tagged strings that do not match the given
%      language priority list.
%   3. XSD strings.

rdf_langstring_pref(S, P, LRanges, V, G):-
  rdf_langstring(S, P, LRanges, V, G).
rdf_langstring_pref(S, P, LRanges, V, G):-
  rdf_literal(S, P, rdf:langString, V, G),
  \+ rdf_langstring(S, P, LRanges, V, G).
rdf_langstring_pref(S, P, _, V, G):-
  rdf_literal(S, P, xsd:string, V, G).



%! rdf_literal(?Subject:rdf_term, ?Predicate:iri, ?Value) is nondet.
% Wrapper around rdf_literal/4 with uninstantiated datatype.

rdf_literal(S, P, V):-
  rdf_literal(S, P, _, V).


%! rdf_literal(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?Value
%! ) is nondet.
% Wrapper around rdf_literal/5 with uninstantiated graph.

rdf_literal(S, P, D, V):-
  rdf_literal(S, P, D, V, _).


%! rdf_literal(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?Value,
%!   ?Graph:rdf_graph
%! ) is nondet.

rdf_literal(S, P, D, V, G):-
  rdf_literal(S, P, D, V, G, _).


%! rdf_literal(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?Value,
%!   ?Graph:rdf_graph,
%!   -Quadruple:rdf_quadruple
%! ) is nondet.
% This predicate is only used internally, by other predicates in rdf_read,
% since it makes available the RDF statement in Quadruple.

% Language-tagged strings.
rdf_literal(S, P, D, Val, G, rdf(S,P,O,G)):-
  rdf_expand_ct(rdf:langString, D),
  Val = Lex-LTag,
  O = literal(lang(LTag,Lex)),
  rdf(S, P, O, G),
  atom(LTag).
% Ground datatype and value.
rdf_literal(S, P, D, Val, G, rdf(S,P,O,G)):-
  ground(D),
  \+ rdf_expand_ct(rdf:langString, D),
  ground(Val), !,
  % Map to lexical form.
  rdf_canonical_map(D, Val, literal(type(D,Lex))),
  (   rdf_expand_ct(xsd:string, D),
      O = literal(Lex)
  ;   O = literal(type(D,Lex))
  ),
  rdf(S, P, O, G).
% Typed literal (as per RDF 1.0 specification).
rdf_literal(S, P, D, Val, G, rdf(S,P,Lit,G)):-
  (ground(D) -> \+ rdf_expand_ct(rdf:langString, D) ; true),
  Lit = literal(type(D,_)),
  rdf(S, P, Lit, G),
  rdf_lexical_map(Lit, Val).
% Simple literal (as per RDF 1.0 specification).
rdf_literal(S, P, xsd:string, Val, G, rdf(S,P,O,G)):-
  O = literal(Lex),
  rdf(S, P, O, G),
  atom(Lex),
  rdf_lexical_map(xsd:string, Lex, Val).



%! rdf_literal_pl(?Subject:rdf_term, ?Predicate:iri, ?Value) is nondet.
% Wrapper around rdf_literal_pl/4 with uninstantiated datatype.

rdf_literal_pl(S, P, V):-
  rdf_literal_pl(S, P, _, V).


%! rdf_literal_pl(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?Value
%! ) is nondet.
% Wrapper around rdf_literal_pl/5 with uninstantiated graph.

rdf_literal_pl(S, P, D, V):-
  rdf_literal_pl(S, P, D, V, _).


%! rdf_literal_pl(
%!   ?Subject:rdf_term,
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?Value,
%!   ?Graph:rdf_graph
%! ) is nondet.
% rdf_literal/[3-5] seeks to interpret the lexical form of an RDF datatype
% according to an RDF datatype.
%
% Sometimes this interpretation cannot be represented in a native Prolog term.
% It may then, for certain use cases, still be useful to return
% the native Prolog term which most closely matches the correct interpretation.
%
% For example, in XSD's dateTime/7 seconds are represented by a decimal,
% but in Prolog's date/9 and time/6 seconds are represented by a float.
% The latter comes quite close to the former, but will generally
% be a tiny bit less precise.
%
% In short: for correctness use rdf_literal/[3-5];
% for convencience at the cost of a little bit of correctness
% use rdf_literal_pl/[3-5].

rdf_literal_pl(S, P, D, V1, G):-
  is_of_type(date, V1), !,
  date_to_datetime(V1, V2),
  rdf_literal(S, P, D, V2, G).
rdf_literal_pl(S, P, D, V1, G):-
  rdf_literal(S, P, D, V2, G),
  (xsd_datatype(D, datetime) -> datetime_to_date(V2, V1) ; V1 = V2).
