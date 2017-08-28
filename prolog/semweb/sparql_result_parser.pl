:- module(
  sparql_result_parser,
  [
    sparql_result/2 % +UriSpec, -Result
  ]
).

/** <module> SPARQL result parser

@author Wouter Beek
@compat SPARQL Query Results XML Format (Second Edition)
@see https://www.w3.org/TR/rdf-sparql-XMLres/
@version 2017/08
*/

:- use_module(library(apply)).
:- use_module(library(error)).
:- use_module(library(semweb/rdf_ext)).
:- use_module(library(xml/xml_ext)).

:- thread_local
   result/1.





%! sparql_result(+UriSpec:term, -Result:list(compound)) is nondet.

sparql_result(UriSpec, Result) :-
  retractall(result(_)),
  call_on_xml(UriSpec, result, sparql_result_),
  retract(result(Result)).

sparql_result_([element(result,_,Bindings)]) :-
  maplist(sparql_binding_, Bindings, Result),
  assert(result(Result)).

sparql_binding_(element(binding,_,Term1), Term2) :-
  sparql_term_(Term1, Term2).

sparql_term_([element(bnode,_,[BNode])], BNode) :- !.
sparql_term_([element(uri,_,[Uri])], Uri) :- !.
sparql_term_([element(literal,['xml:lang'=LTag],[Lex])], Lit) :- !,
  rdf_literal(Lit, rdf:langString, Lex, LTag).
sparql_term_([element(literal,[datatype=D],[Lex])], Lit) :- !,
  rdf_literal(Lit, D, Lex, _).
sparql_term_([element(literal,[],[Lex])], Lit) :- !,
  rdf_literal(Lit, xsd:string, Lex, _).
sparql_term_(Dom, _) :-
  domain_error(sparql_term, Dom).