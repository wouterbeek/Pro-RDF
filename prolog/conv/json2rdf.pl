:- module(
  json2rdf,
  [
    json2rdf/2,        % +Source, +Sink
    json2rdf/3,        % +Source, +Sink, +Opts
    json2rdf_stream/3, % +Source,        +State, +Out
    json2rdf_stream/4  % +Source, +Opts, +State, +Out
  ]
).

/** <module> JSON-2-RDF

@author Wouter Beek
@see http://ndjson.org/
@version 2016/06-2016/07
*/

:- use_module(library(atom_ext)).
:- use_module(library(debug)).
:- use_module(library(dict_ext)).
:- use_module(library(gen/gen_ntuples)).
:- use_module(library(json_ext)).
:- use_module(library(jsonld/jsonld_read)).
:- use_module(library(os/io)).
:- use_module(library(q/q_term)).
:- use_module(library(q/qb)).
:- use_module(library(readutil)).
:- use_module(library(semweb/rdf11)).





%! json2rdf(+Source, +Sink) is nondet.
%! json2rdf(+Source, +Sink, +Opts) is nondet.
%
% Convert JSON coming from Source into RDF that is stored in graph G
% using backend M.
%
% Options are passed to:
%
%   * call_on_stream/3
%
%   * call_to_ntriples/3

json2rdf(Source, Sink) :-
  json2rdf(Source, Sink, []).


json2rdf(Source, Sink, Opts) :-
  call_to_ntriples(Sink, json2rdf_stream(Source, Opts), Opts).



%! json2rdf_stream(+Source, +State, +Out) is nondet.
%! json2rdf_stream(+Source, +Opts, +State, +Out) is nondet.

json2rdf_stream(Source, State, Out) :-
  json2rdf_stream(Source, [], State, Out).


json2rdf_stream(Source, Opts1, State, Out) :-
  list_alias_options(Opts1, Opts2),
  call_on_stream(Source, json2rdf_stream0(Opts2, State, Out), Opts1).


json2rdf_stream0(Opts, State, Out, In, Meta, Meta) :-
  json2rdf_stmt0(In, Opts.tbox_alias, Triple),
  gen_ntuple(Triple, State, Out),
  fail.
json2rdf_stream0(_, _, _, _, Meta, Meta) :-
  debug(conv(jsond2rdf), "[DONE] JSON → RDF", []).


json2rdf_stmt0(In, Alias, Triple) :-
  repeat,
  read_line_to_string(In, Str),
  (   Str == end_of_file
  ->  !, fail
  ;   string_json_dict(Str, Dict),
      qb_iri(Alias, S),
      get_dict_path(Keys1, Dict, Val),

      % P
      atomic_list_concat(Keys1, '_', Local1),
      atomic_list_concat(Keys2, ' ', Local1),
      atomic_list_concat(Keys2, '_', Local2),
      rdf_global_id(Alias:Local2, P),

      % O
      (is_list(Val) -> O = Val^^tcco:array ; O = Val^^xsd:string),
      
      rdf_global_term(rdf(S,P,O), Triple)
  ).





% HELPERS %

list_alias_options(Opts1, Opts4) :-
  merge_options(Opts1, [alias(ex)], Opts2),
  select_option(alias(Alias), Opts2, Opts3),
  merge_options(Opts3, [abox_alias(Alias),tbox_alias(Alias)], Opts4).
