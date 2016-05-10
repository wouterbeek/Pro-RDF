:- module(
  oaei,
  [
    oaei/2,                    % ?From, ?To
    oaei/4,                    % ?From, ?To, ?Rel, ?V
    oaei_assert/2,             % +Pair,           ?G
    oaei_assert/4,             % +Pair, +Rel, +V, ?G
    oaei_convert_rdf_to_tsv/2, % +Source, +Sink
    oaei_convert_tsv_to_rdf/2, % +Source, +Sink
    oaei_load_rdf/2,           % +Source, -Alignments
    oaei_load_rdf/3,           % +Source, -Alignments, +Opts
    oaei_load_tsv/2,           % +Source, -Alignments
    oaei_save_rdf/2,           % +Sink,   +Alignments
    oaei_save_tsv/2            % +Sink,   +Alignments
  ]
).

/** <module> Ontology Alignment Evaluation Initiative (OAEI)

During loading and saving alignments are represented as pairs.

@author Wouter Beek
@version 2015/10, 2015/12-2016/01, 2016/05
*/

:- use_module(library(csv_ext)).
:- use_module(library(lists)).
:- use_module(library(os/open_any2)).
:- use_module(library(pair_ext)).
:- use_module(library(rdf/rdf_load)).
:- use_module(library(rdf/rdf_save)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(yall)).

:- rdf_register_prefix(align, 'http://knowledgeweb.semanticweb.org/heterogeneity/alignment#').

:- rdf_meta
   oaei(o, o),
   oaei(o, o, ?, ?),
   oaei_assert(o, o, ?),
   oaei_assert(o, o, +, +, ?).





%! oaei(?From, ?To) is nondet.
%! oaei(?From, ?To, ?Rel, ?V) is nondet.

oaei(From, To) :-
  oaei(From, To, =, 1.0).


oaei(From, To, Rel, V) :-
  rdf_has(X, align:entity1, From),
  rdf_has(X, align:entity2, To),
  rdf_has(X, align:relation, Rel^^xsd:string),
  rdf_has(X, align:measure, V^^xsd:float).



%! oaei_assert(+Pair, ?G) is det.
%! oaei_assert(+Pair, +Rel, +V:between(0.0,1.0), ?G) is det.

oaei_assert(Pair, G) :-
  oaei_assert(Pair, =, 1.0, G).


oaei_assert(From-To, Rel, V, G) :-
  rdf_create_bnode(B),
  rdf_assert(B, align:entity1, From, G),
  rdf_assert(B, align:entity2, To, G),
  rdf_assert(B, align:relation, Rel, G),
  rdf_assert(B, align:measure, V, G).



%! oaei_convert_rdf_to_tsv(+Source, +Sink) is det.

oaei_convert_rdf_to_tsv(Source, Sink) :-
  oaei_load_rdf(Source, L),
  oaei_save_tsv(L, Sink).



%! oaei_convert_tsv_to_rdf(+Source, +Sink) is det.

oaei_convert_tsv_to_rdf(Source, Sink) :-
  oaei_load_tsv(Source, L),
  oaei_save_rdf(L, Sink).



%! oaei_load_rdf(+Source, -Alignments) is det.
%! oaei_load_rdf(+Source, -Alignments, +Opts) is det.

oaei_load_rdf(Source, L) :-
  oaei_load_rdf(Source, L, []).


oaei_load_rdf(Source, L, Opts) :-
  rdf_call_on_graph(Source, oaei_load_rdf0(L), Opts).

oaei_load_rdf0(L, _, _, _) :-
  findall(From-To, oaei(From, To), L).



%! oaei_load_tsv(+Source, -Alignments) is det.

oaei_load_tsv(Source, Pairs) :-
  tsv_read_file(Source, Rows, [arity(2)]),
  maplist(pair_row, Pairs, Rows).



%! oaei_save_rdf(+Sink, +Alignments) is det.

oaei_save_rdf(Sink, Pairs) :-
  rdf_call_to_graph(Sink, oaei_assert1(Pairs)).

oaei_assert1(Pairs, G) :-
  maplist({G}/[Pair]>>oaei_assert(Pair, G), Pairs).



%! oaei_save_tsv(+Sink, +Alignments) is det.

oaei_save_tsv(Sink, Pairs) :-
  call_to_stream(Sink, oaei_save_tsv1(Pairs)).

oaei_save_tsv1(Pairs, Out, _, _) :-
  maplist(oaei_save_tsv2(Out), Pairs).

oaei_save_tsv2(Out, Pair) :-
  pair_row(Pair, Row),
  tsv_write_stream(Out, [Row]).
