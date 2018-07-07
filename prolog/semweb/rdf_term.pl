:- module(
  rdf_term,
  [
    rdf_atom_term/2,              % +Atom, -Term
    rdf_bnode_iri/1,              % -Iri
    rdf_bnode_iri/2,              % ?Local, -Iri
    rdf_bnode_iri/3,              % +Document, ?Local, -Iri
    rdf_bnode_prefix/1,           % -Iri
    rdf_bnode_prefix/2,           % +Document, -Iri
    rdf_bool_false/1,             % ?Literal
    rdf_bool_true/1,              % ?Literal
   %rdf_create_bnode/1,           % --BNode
    rdf_create_iri/3,             % +Alias, +Segments, -Iri
   %rdf_equal/2,                  % ?Term1, ?Term2
   %rdf_default_graph/1,          % ?G
   %rdf_graph/1,                  % ?G
    rdf_iri//1,                   % ?Iri
   %rdf_is_bnode/1,               % @Term
    rdf_is_bnode_iri/1,           % @Term
    rdf_is_container_membership_property/1, % @Term
   %rdf_is_iri/1,                 % @Term
   %rdf_is_literal/1,             % @Term
    rdf_is_name/1,                % @Term
    rdf_is_numeric_literal/1,     % @Term
    rdf_is_object/1,              % @Term
   %rdf_is_predicate/1,           % @Term
    rdf_is_skip_node/1,           % @Term
   %rdf_is_subject/1,             % @Term
    rdf_is_term/1,                % @Term
    rdf_language_tagged_string/3, % ?LTag, ?Lex, ?Literal
    rdf_lexical_value/3,          % +D, ?Lex, ?Val
    rdf_literal//1,               % ?Literal
    rdf_literal/4,                % ?D, ?LTag, ?Lex, ?Literal
    rdf_literal_datatype_iri/2,   % +Literal, ?D
    rdf_literal_lexical_form/2,   % +Literal, ?Lex
    rdf_literal_value/2,          % +Literal, -Value
    rdf_literal_value/3,          % -Literal, +D, +Value
    rdf_term//1,                  % ?Term
    rdf_term_to_atom/2,           % +Term, -Atom
    rdf_typed_literal/3           % ?D, ?Lex, ?Literal
  ]
).

/** <module> RDF term support

@author Wouter Beek
@version 2018
*/

:- use_module(library(error)).
:- use_module(library(lists)).
:- reexport(library(semweb/rdf11), [
     rdf_create_bnode/1,
     rdf_equal/2,
     rdf_default_graph/1,
     rdf_graph/1,
     rdf_is_bnode/1,
     rdf_is_iri/1,
     rdf_is_literal/1,
     rdf_is_predicate/1,
     rdf_is_subject/1,
     op(110, xfx, @),
     op(650, xfx, ^^)
   ]).
:- use_module(library(settings)).
:- use_module(library(uuid)).

:- use_module(library(atom_ext)).
:- use_module(library(dcg)).
:- use_module(library(hash_ext)).
:- use_module(library(semweb/rdf_prefix)).
:- use_module(library(uri_ext)).
:- use_module(library(xsd/xsd)).

:- discontiguous
    rdf_lexical_to_value/3,
    rdf_value_to_lexical/3.

:- dynamic
    rdf_lexical_to_value_hook/3,
    rdf_value_to_lexical_hook/3.

:- multifile
    rdf_lexical_to_value_hook/3,
    rdf_value_to_lexical_hook/3.

:- rdf_meta
   rdf_bool_false(o),
   rdf_bool_true(o),
   rdf_is_bnode_iri(r),
   rdf_is_name(o),
   rdf_is_numeric_literal(o),
   rdf_is_object(o),
   rdf_is_skip_node(r),
   rdf_is_term(o),
   rdf_language_tagged_string(?, ?, o),
   rdf_lexical_value(r, ?, ?),
   rdf_lexical_to_value(r, +, -),
   rdf_lexical_to_value_error(r, +),
   rdf_value_to_lexical(r, +, -),
   rdf_literal(r, ?, ?, o),
   rdf_literal_datatype_iri(o, r),
   rdf_literal_lexical_form(o, ?),
   rdf_literal_value(o, -),
   rdf_literal_value(o, r, +),
   rdf_term_to_atom(t, -),
   rdf_typed_literal(r, ?, o),
   rdf_value_to_lexical(r, +, -),
   rdf_value_to_lexical_error(r, +).

:- setting(base_uri, atom, 'https://example.org/base-uri/',
           "The default base URI for RDF IRIs.").
:- setting(bnode_prefix_authority, atom, 'example.org', "").
:- setting(bnode_prefix_scheme, atom, https, "").





%! rdf_atom_term(+Atom:atom, -Term:rdf_term) is semidet.
%
% Parses the given atom (`Atom') in order to extract the encoded RDF
% term.  The following syntactic forms are supported:
%
%  1. RDF terms defined by the N-Triples 1.1 grammar (blank nodes,
%     IRIs, and literals).
%
%  2. Turtle 1.1 prefix notation for IRIs.
%
% @throws syntax_error if Atom cannot be parsed as a term in
%         Turtle-family notation.
%
% @throws type_error if the Turtle-family notation for Term cannot be
%         generated.

rdf_atom_term(Atom, Term) :-
  atom_phrase(rdf_term(Term), Atom), !.
rdf_term_to_atom(Atom, _) :-
  atom(Atom), !,
  syntax_error(rdf_term(Atom)).
rdf_term_to_atom(_, Term) :-
  type_error(rdf_term, Term).



%! rdf_bnode(+BNode:rdf_bnode)// .
%! rdf_bnode(-BNode:rdf_bnode)// .
%
% Generates or parses a blank node in Turtle-family notation.

% Parses a blank node.
rdf_bnode(BNode) -->
  {rdf_is_bnode(BNode)}, !,
  "_:",
  atom(BNode).
% Generates a blank node.
rdf_bnode(BNode) -->
  "_:", !,
  remainder(T),
  {atom_codes(BNode, [0'_,0':|T])}.



%! rdf_bnode_iri(-Iri:atom) is det.
%! rdf_bnode_iri(+Local:atom, -Iri:atom) is det.
%! rdf_bnode_iri(+Document:atom, +Local:atom, -Iri:atom) is det.

rdf_bnode_iri(Iri) :-
  uuid(Local),
  rdf_bnode_iri(Local, Iri).


rdf_bnode_iri(Local, Iri) :-
  rdf_bnode_iri_([Local], Iri).


rdf_bnode_iri(Doc, Local, Iri) :-
  md5_text(Doc, DocId),
  rdf_bnode_iri_([DocId,Local], Iri).

rdf_bnode_iri_(Segments, Iri) :-
  setting(bnode_prefix_scheme, Scheme),
  setting(bnode_prefix_authority, Auth),
  uri_comps(Iri, uri(Scheme,Auth,['.well-known',genid|Segments],_,_)).



%! rdf_bnode_prefix(-Iri:atom) is det.
%! rdf_bnode_prefix(+Document:atom, -Iri:atom) is det.

rdf_bnode_prefix(Iri) :-
  rdf_bnode_prefix_([], Iri).


rdf_bnode_prefix(Doc, Iri) :-
  md5_text(Doc, DocId),
  rdf_bnode_prefix_([DocId], Iri).

rdf_bnode_prefix_(Segments, Iri) :-
  rdf_bnode_iri_(Segments, Iri0),
  atom_terminator(Iri0, 0'/, Iri).



%! rdf_bool_false(+Term:rdf_term) is semidet.
%! rdf_bool_false(-Literal:rdf_literal) is det.

rdf_bool_false(false^^xsd:boolean).



%! rdf_bool_true(+Term:rdf_term) is semidet.
%! rdf_bool_true(-Literal:rdf_literal) is det.

rdf_bool_true(true^^xsd:boolean).



%! rdf_create_iri(+Alias, +Segments:list(atom), -Iri:atom) is det.

rdf_create_iri(Alias, Segments2, Iri) :-
  rdf_prefix(Alias, Prefix),
  uri_comps(Prefix, uri(Scheme,Auth,Segments1,_,_)),
  append_segments(Segments1, Segments2, Segments3),
  uri_comps(Iri, uri(Scheme,Auth,Segments3,_,_)).



%! rdf_iri(+Iri:atom)// .
%! rdf_iri(-Iri:atom)// .
%
% Generates or parses an IRI in Turtle-family notation.

% Generate a full or abbreviated IRI.
rdf_iri(Iri) -->
  {rdf_is_iri(Iri)}, !,
  (   {
        rdf_prefix(Alias, Prefix),
        atom_concat(Prefix, Local, Iri)
      }
  ->  atom(Alias),
      ":",
      atom(Local)
  ;   "<",
      atom(Iri),
      ">"
  ).
% Parse a full IRI.
rdf_iri(Iri) -->
  "<",
  ...(Codes),
  ">", !,
  {atom_codes(Iri, Codes)}.
% Parse an abbreviated IRI.
rdf_iri(Iri) -->
  ...(Codes),
  ":",
  {
    atom_codes(Alias, Codes),
    (rdf_prefix(Alias) -> true ; existence_error(rdf_alias,Alias))
  },
  remainder_as_atom(Local),
  {rdf_global_id(Alias:Local, Iri)}.



%! rdf_is_container_membership_property(@Term) is semidet.

rdf_is_container_membership_property(P) :-
  rdf_is_iri(P),
  rdf_equal(rdf:'_', Prefix),
  atom_concat(Prefix, Atom, P),
  atom_number(Atom, N),
  integer(N),
  N >= 0.



%! rdf_is_bnode_iri(@Term) is semidet.

rdf_is_bnode_iri(Iri) :-
  rdf_is_iri(Iri),
  uri_comps(Iri, uri(Scheme,Auth,Segments,_,_)),
  ground([Scheme,Auth]),
  prefix(['.well-known',genid], Segments).



%! rdf_is_name(@Term) is semidet.

rdf_is_name(Iri) :-
  rdf_is_iri(Iri), !.
rdf_is_name(Literal) :-
  rdf_is_literal(Literal).



%! rdf_is_numeric_literal(@Term) is semidet.

rdf_is_numeric_literal(literal(type(D,_))) :-
  xsd_is_numeric_datatype_iri(D).



%! rdf_is_object(@Term) is semidet.

rdf_is_object(S) :-
  rdf_is_subject(S), !.
rdf_is_object(Literal) :-
  rdf_is_literal(Literal).



%! rdf_is_skip_node(@Term) is semidet.

rdf_is_skip_node(Term) :-
  rdf_is_bnode(Term), !.
rdf_is_skip_node(Term) :-
  rdf_is_bnode_iri(Term).



%! rdf_is_term(@Term) is semidet.

rdf_is_term(O) :-
  rdf_is_object(O).



%! rdf_language_tagged_string(+LTag:atom, +Lex:atom, -Literal:rdf_literal) is det.
%! rdf_language_tagged_string(-LTag:atom, -Lex:atom, +Literal:rdf_literal) is det.

rdf_language_tagged_string(LTag, Lex, Lex@LTag).



%! rdf_lexical_value(+D:atom, +Lex:atom, -Value:term) is det.
%! rdf_lexical_value(+D:atom, -Lex:atom, +Value:term) is det.
%
% Translate between a value (`Value') and its serialization, according
% to a given datatype IRI (`D'), into a lexical form (`Lex').
%
% @error syntax_error(+Literal:compound)
% @error type_error(+D:atom,+Value:term)
% @error unimplemented_datatype_iri(+D:atom)

rdf_lexical_value(D, Lex, Value) :-
  (   nonvar(Lex)
  ->  rdf_lexical_to_value(D, Lex, Value)
  ;   rdf_value_to_lexical(D, Value, Lex)
  ), !.
rdf_lexical_value(D, _, _) :-
  throw(error(unimplemented_datatype_iri(D))).


% hooks
rdf_lexical_to_value(D, Lex, Value) :-
  rdf_lexical_to_value_hook(D, Lex, Value), !.
rdf_value_to_lexical(D, Value, Lex) :-
  rdf_value_to_lexical_hook(D, Value, Lex), !.
% rdf:HTML
rdf_lexical_to_value(rdf:'HTML', Lex, Value) :- !,
  (   rdf11:parse_partial_xml(load_html, Lex, Value)
  ->  true
  ;   rdf_lexical_to_value_error(rdf:'HTML', Lex)
  ).
rdf_value_to_lexical(rdf:'HTML', Value, Lex) :-
  (   rdf11:write_xml_literal(html, Value, Lex)
  ->  true
  ;   rdf_value_to_lexical_error(rdf:'HTML', Value)
  ).

% rdf:XMLLiteral
rdf_lexical_to_value(rdf:'XMLLiteral', Lex, Value) :-
  (   rdf11:parse_partial_xml(load_xml, Lex, Value)
  ->  true
  ;   rdf_lexical_to_value_error(rdf:'XMLLiteral', Lex)
  ).
rdf_value_to_lexical(rdf:'XMLLiteral', Value, Lex) :-
  (   rdf11:write_xml_literal(xml, Value, Lex)
  ->  true
  ;   rdf_value_to_lexical_error(rdf:'XMLLiteral', Value)
  ).

% XSD datatype IRIs
rdf_lexical_to_value(D, Lex, Value) :-
  xsd:xsd_lexical_to_value(D, Lex, Value).
rdf_value_to_lexical(D, Value, Lex) :-
  xsd:xsd_value_to_lexical(D, Value, Lex).

rdf_lexical_to_value_error(D, Lex) :-
  syntax_error(literal(type(D,Lex))).

rdf_value_to_lexical_error(D, Value) :-
  type_error(D, Value).



%! rdf_literal(+Literal:rdf_literal)// .
%! rdf_literal(-Literal:rdf_literal)// .
%
% Generates or parses a literal in Turtle-family notation.

% Generate a language-tagged string.
rdf_literal(Lex@LTag) -->
  {atom(LTag)}, !,
  "\"",
  atom(Lex),
  "\"@",
  atom(LTag).
% Generate a typed literal.
rdf_literal(Lex^^D) -->
  {atom(D)}, !,
  "\"",
  atom(Lex),
  "\"^^",
  rdf_iri(D).
% Parse a literal.
rdf_literal(Literal) -->
  "\"",
  ...(Codes),
  "\"", !,
  ("^^" -> rdf_iri(D) ; "@" -> remainder_as_atom(LTag) ; ""),
  {
    atom_codes(Lex, Codes),
    rdf_literal(D, LTag, Lex, Literal)
  }.



%! rdf_literal(+D:atom, +LTag:atom, +Lex:atom, -Literal:rdf_literal) is det.
%! rdf_literal(-D:atom, -LTag:atom, -Lex:atom, +Literal:rdf_literal) is det.
%
% Compose/decompose literals.

rdf_literal(D, LTag, Lex, Lex^^D) :-
  var(LTag).
rdf_literal(rdf:langString, LTag, Lex, Lex@LTag).



%! rdf_literal_datatype_iri(+Literal:rdf_literal, +D:atom) is semidet.
%! rdf_literal_datatype_iri(+Literal:rdf_literal, -D:atom) is det.

rdf_literal_datatype_iri(_^^D, D).
rdf_literal_datatype_iri(_@_, rdf:langString).



%! rdf_literal_lexical_form(+Literal:rdf_literal, +Lex:atom) is semidet.
%! rdf_literal_lexical_form(+Literal:rdf_literal, -Lex:atom) is det.

rdf_literal_lexical_form(Lex^^_, Lex).
rdf_literal_lexical_form(Lex@_, Lex).



%! rdf_literal_value(+Literal:rdf_literal, -Value:term) is det.
%! rdf_literal_value(+Literal:rdf_literal, -D:atom, -Value:term) is det.
%! rdf_literal_value(-Literal:rdf_literal, +D:atom, +Value:term) is det.
%
% Notice that languages-tagged strings do not have a value.

rdf_literal_value(Literal, Value) :-
  rdf_literal_value(Literal, _, Value).


% Language-tagged strings do not have a value space.
rdf_literal_value(Lex@LTag, rdf:langString, Lex-LTag) :- !.
rdf_literal_value(Lex^^D, D, Value) :-
  rdf_lexical_value(D, Lex, Value).



%! rdf_term(+Term:rdf_term)// .
%! rdf_term(-Term:rdf_term)// .
%
% Generates or parses a term in Turtle-family notation.

rdf_term(Literal) -->
  rdf_literal(Literal), !.
rdf_term(BNode) -->
  rdf_bnode(BNode), !.
rdf_term(Iri) -->
  rdf_iri(Iri).



%! rdf_typed_literal(+D:atom, +Lex:atom, -Literal:rdf_literal) is det.
%! rdf_typed_literal(-D:atom, -Lex:atom, +Literal:rdf_literal) is det.

rdf_typed_literal(D, Lex, Lex^^D).