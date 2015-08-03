:- module(
  rdf_print,
  [
    rdf_print_graph/1, % +Graph
    rdf_print_graph/2, % +Graph:atom
                       % +Options:list(compound)
    rdf_print_quadruple/4, % ?Subject, ?Predicate, ?Object, ?Graph
    rdf_print_quadruple/5, % ?Subject:or([bnode,iri])
                           % ?Predicate:iri
                           % ?Object:rdf_term
                           % ?Graph:atom
                           % +Options:list(compound)
    rdf_print_term/1, % +Term
    rdf_print_term/2, % +Term:rdf_term
                      % +Options:list(compound)
    rdf_print_term//1, % +Term
    rdf_print_term//2, % +Term:rdf_term
                       % +Options:list(compound)
    rdf_print_triple/4, % ?Subject, ?Predicate:iri, ?Object, ?Graph
    rdf_print_triple/5 % ?Subject:or([bnode,iri])
                       % ?Predicate:iri
                       % ?Object:rdf_term
                       % ?Graph:atom
                       % +Options:list(compound)
  ]
).

/** <module> RDF print

Easy printing of RDF data to the terminal.

---

@author Wouter Beek
@version 2015/07-2015/08
*/

:- use_module(library(atom_ext)).
:- use_module(library(dcg/basics)).
:- use_module(library(dcg/dcg_bracketed)).
:- use_module(library(dcg/dcg_logic)).
:- use_module(library(dcg/dcg_phrase)).
:- use_module(library(dcg/dcg_quoted)).
:- use_module(library(option)).
:- use_module(library(rdf/rdf_bnode_name)).
:- use_module(library(semweb/rdf_db)).

:- set_prolog_flag(toplevel_print_anon, false).

:- predicate_options(rdf_print_graph/2, 2, [
     pass_to(rdf_print_triple/5, 5)
   ]).
:- predicate_options(rdf_print_iri//2, 2, [
     abbr_iri(+boolean),
     elip_ln(+or([nonneg,oneof([inf])])),
     logic_sym(+boolean)
   ]).
:- predicate_options(rdf_print_lexical//2, 2, [
     elip_lit(+or([nonneg,oneof([inf])]))
   ]).
:- predicate_options(rdf_print_literal//2, 2, [
     pass_to(rdf_print_lexical//2, 2)
   ]).
:- predicate_options(rdf_print_object//2, 2, [
     pass_to(rdf_print_term//2, 2)
   ]).
:- predicate_options(rdf_print_predicate//2, 2, [
     pass_to(rdf_print_term//2, 2)
   ]).
:- predicate_options(rdf_print_quadruple/5, 5, [
     pass_to(rdf_print_statement/5, 5)
   ]).
:- predicate_options(rdf_print_statement/5, 5, [
     indent(+nonneg),
     pass_to(rdf_print_statement//5, 5)
   ]).
:- predicate_options(rdf_print_statement//5, 5, [
     style(+oneof([triple,turtle]),
     pass_to(rdf_print_object//2, 2),
     pass_to(rdf_print_predicate//2, 2),
     pass_to(rdf_print_subject//2, 2)
   ]).
:- predicate_options(rdf_print_subject//2, 2, [
     pass_to(rdf_print_iri//2, 2)
   ]).
:- predicate_options(rdf_print_term/2, 2, [
     pass_to(rdf_print_term//2, 2)
   ]).
:- predicate_options(rdf_print_term//2, 2, [
     pass_to(rdf_print_literal//2, 2)
   ]).
:- predicate_options(rdf_print_triple/5, 5, [
     pass_to(rdf_print_statement/5, 5)
   ]).

:- rdf_meta(rdf_print_quadruple(r,r,o,?)).
:- rdf_meta(rdf_print_quadruple(r,r,o,?,+)).
:- rdf_meta(rdf_print_term(r)).
:- rdf_meta(rdf_print_term(r,+)).
:- rdf_meta(rdf_print_term(r,?,?)).
:- rdf_meta(rdf_print_term(r,+,?,?)).
:- rdf_meta(rdf_print_triple(r,r,o,?)).
:- rdf_meta(rdf_print_triple(r,r,o,?,+)).





%! rdf_print_graph(+Graph:atom) is det.

rdf_print_graph(G):-
  rdf_print_graph(G, []).


%! rdf_print_graph(+Graph:atom, +Options:list(compound)) is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * indent(+nonneg)
%   * logic_sym(+boolean)
%   * style(+oneof([triple,turtle])

rdf_print_graph(G, Opts):-
  rdf_print_triple(_, _, _, G, Opts),
  fail.
rdf_print_graph(_, _).



%! rdf_print_quadruple(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   ?Graph:atom
%! ) is det.

rdf_print_quadruple(S, P, O, G):-
  rdf_print_quadruple(S, P, O, G, []).


%! rdf_print_quadruple(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   ?Graph:atom,
%!   +Options:list(compound)
%! ) is nondet.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * indent(+nonneg)
%   * logic_sym(+boolean)
%   * style(+oneof([triple,turtle])

rdf_print_quadruple(S, P, O, G, Opts):-
  rdf(S, P, O, G),
  rdf_print_statement(S, P, O, G, Opts).



%! rdf_print_term(+Term:rdf_term) is det.

rdf_print_term(T):-
  rdf_print_term(T, []).


%! rdf_print_term(+Term:rdf_term, +Options:list(compound)) is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * logic_sym(+boolean)

rdf_print_term(T, Opts):-
  string_phrase(rdf_print_term(T, Opts), X),
  writeln(X).



%! rdf_print_triple(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   ?Graph:atom
%! ) is nondet.

rdf_print_triple(S, P, O, G):-
  rdf_print_triple(S, P, O, G, []).


%! rdf_print_triple(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   ?Graph:atom,
%!   +Options:list(compound)
%! ) is nondet.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * indent(+nonneg)
%   * logic_sym(+boolean)
%   * style(+oneof([triple,turtle])

rdf_print_triple(S, P, O, G, Opts):-
  rdf(S, P, O, G),
  rdf_print_statement(S, P, O, _, Opts).



%! rdf_print_statement(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   +Object:rdf_term,
%!   +Graph:atom,
%!   +Options:list(compound)
%! ) is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * indent(+nonneg)
%   * style(+oneof([triple,turtle])

rdf_print_statement(S, P, O, G, Opts):-
  option(indent(I), Opts, 0),
  string_phrase(rdf_print_statement(S, P, O, G, Opts), X),
  tab(I),
  writeln(X).



% GRAMMAR %

%! rdf_print_bnode(+BNode:bnode)// is det.

rdf_print_bnode(B) -->
  {rdf_bnode_name(B, Name)},
  atom(Name).



%! rdf_print_graph(+Graph:atom)// is det.

rdf_print_graph(G) -->
  atom(G).



%! rdf_print_iri(+Iri:atom, +Options:list(compound))// is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%     Whether IRIs should be abbreviated w.r.t.
%     the currently registered RDF prefixes.
%     Default is `true`.
%   * elip_ln(+or([nonneg,oneof([inf])]))
%     Elipses IRI local names so that they are assued to be at most
%     the given number of characters in length.
%     This is only used when `abbr_iri=true`.
%     Default is `inf` for no elipsis.
%   * logic_sym(+boolean)
%     Whether logic symbols should be used i.o. IRIs.
%     Default is `false`.

rdf_print_iri(Global, Opts) -->
  {option(logic_sym(true), Opts)},
  rdf_print_iri_sym(Global), !.
rdf_print_iri(Global, Opts) -->
  {
    option(abbr_iri(true), Opts, true),
    rdf_global_id(Prefix:Local, Global), !,
    option(elip_ln(N), Opts, inf),
    atom_truncate(Local, N, Local0)
  },
  atom(Prefix),
  ":",
  atom(Local0).
rdf_print_iri(Global, _) -->
  bracketed(angular, atom(Global)).

rdf_print_iri_sym(Iri) -->
  {rdf_global_id(owl:equivalentClass, Iri)}, !,
  equivalence.
rdf_print_iri_sym(Iri) -->
  {rdf_global_id(rdfs:subClassOf, Iri)}, !,
  subclass.
rdf_print_iri_sym(Iri) -->
  {rdf_global_id(rdf:type, Iri)}, !,
  set_membership.



%! rdf_print_lexical(+LexicalForm:atom, +Options:list(compound))// is det.
% The following options are supported:
% The following options are supported:
%   * elip_lit(+or([nonneg,oneof([inf])]))
%     Elipses lexical forms so that they are assured to be at most
%     the given number of characters in length.
%     Default is `inf` for no elipsis.

rdf_print_lexical(Lex, Opts) -->
  {
    option(elip_lit(N), Opts, inf),
    atom_truncate(Lex, N, Lex0)
  },
  quoted(atom(Lex0)).



%! rdf_print_literal(+Literal:comound, +Options:list(compound))// is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * elip_ln(+or([nonneg,oneof([inf])]))
%   * logic_sym(+boolean)

rdf_print_literal(literal(type(D,Lex)), Opts) --> !,
  rdf_print_lexical(Lex, Opts),
  "^^",
  rdf_print_iri(D, Opts).
rdf_print_literal(literal(lang(LangTag,Lex)), Opts) --> !,
  rdf_print_lexical(Lex, Opts),
  "@",
  atom(LangTag).
rdf_print_literal(literal(Lex), Opts) -->
  rdf_print_lexical(Lex, Opts).



%! rdf_print_object(+Object:rdf_term, +Options:list(compound))// is det.

rdf_print_object(O, Opts) -->
  rdf_print_term(O, Opts).



%! rdf_print_predicate(+Predicate:iri, +Options:list(compound))// is det.

rdf_print_predicate(P, Opts) -->
  rdf_print_iri(P, Opts).



%! rdf_print_statement(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   +Object:rdf_term,
%!   ?Graph:atom,
%!   +Options:list(compound)
%! )// is det.
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * elip_ln(+or([nonneg,oneof([inf])]))
%   * logic_sym(+boolean)
%   * style(+oneof([triple,turtle])
%     The style that is used for printing the statement.
%     Style `turtle` is appropriate for enumerating multiple triples.
%     Style `triple` is appropriate for singular triples.
%     Default is `turtle`.

rdf_print_statement(S, P, O, G, Opts) -->
  {option(style(triple), Opts)}, !,
  bracketed(langular, rdf_print_statement0(S, P, O, Opts)),
  ({ground(G)} -> "@", rdf_print_graph(G) ; "").
rdf_print_statement(S, P, O, G, Opts) -->
  rdf_print_subject(S, Opts),
  " ",
  rdf_print_predicate(P, Opts),
  " ",
  rdf_print_object(O, Opts),
  ({ground(G)} -> rdf_print_graph(G) ; ""),
  " .".

rdf_print_statement0(S, P, O, Opts) -->
  rdf_print_subject(S, Opts),
  ", ",
  rdf_print_predicate(P, Opts),
  ", ",
  rdf_print_object(O, Opts).



%! rdf_print_subject(
%!   +Subject:or([bnode,iri]),
%!   +Options:list(compound)
%! )// is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_ln(+or([nonneg,oneof([inf])]))

rdf_print_subject(S, _) -->
  {rdf_is_bnode(S)}, !,
  rdf_print_bnode(S).
rdf_print_subject(S, Opts) -->
  rdf_print_iri(S, Opts).



%! rdf_print_term(+Term:rdf_term)// is det.

rdf_print_term(T) -->
  rdf_print_term(T, []).


%! rdf_print_term(+Term:rdf_term, +Options:list(compound))// is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * elip_lit(+or([nonneg,oneof([inf])]))
%   * elip_ln(+or([nonneg,oneof([inf])]))
%   * logic_sym(+boolean)

rdf_print_term(T, Opts) -->
  {rdf_is_literal(T)}, !,
  rdf_print_literal(T, Opts).
rdf_print_term(T, _) -->
  {rdf_is_bnode(T)}, !,
  rdf_print_bnode(T).
rdf_print_term(T, Opts) -->
  rdf_print_iri(T, Opts).
