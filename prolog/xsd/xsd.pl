:- encoding(utf8).
:- module(
  xsd,
  [
    dt_to_xsd_date_time/3, % +Dt, +D, -DateTime
    xsd_date_time_to_dt/3, % +DateTime, +D, -DT
    xsd_date_time_type/1,  % ?D
    xsd_encode_string//0,  % +String, -EncodedString
    xsd_numeric_type/1,    % ?D
    xsd_strict_subtype/2,  % ?Sub, ?Super
    xsd_subtype/2          % ?Sub, ?Super
  ]
).

/** <module> XSD support

@author Wouter Beek
@compat XML Schema 1.1 Part 2: Datatypes
@version 2017-2018
*/

:- use_module(library(aggregate)).
:- use_module(library(dif)).
:- use_module(library(error)).
:- use_module(library(semweb/rdf11), []).
:- use_module(library(sgml)).
:- use_module(library(xsdp_types)).

:- use_module(library(dcg)).
:- use_module(library(dcg/dcg_abnf)).
:- use_module(library(list_ext)).
:- use_module(library(semweb/rdf_prefix)).
:- use_module(library(uri_ext)).
:- use_module(library(xml_ext)).
:- use_module(library(xsd/xsd_grammar)).

:- rdf_meta
   dt_to_xsd_date_time(+, r, -),
   xsd_date_time_to_dt(+, r, -),
   xsd_numeric_type(r),
   xsd_strict_subtype(r, r),
   xsd_subtype(r, r).





%! dt_to_xsd_date_time(+Dt:dt, +D:iri, -DateTime:compound) is det.

dt_to_xsd_date_time(dt(Y,Mo,D,_,_,_,_), xsd:date, date(Y,Mo,D)) :- !.
dt_to_xsd_date_time(dt(Y,Mo,D,H,Mi,S,_), xsd:dateTime, date_time(Y,Mo,D,H,Mi,S)) :- !.
dt_to_xsd_date_time(dt(_,_,D,_,_,_,_), xsd:gDay, D) :- !.
dt_to_xsd_date_time(dt(_,Mo,_,_,_,_,_), xsd:gMonth, Mo) :- !.
dt_to_xsd_date_time(dt(_,Mo,D,_,_,_,_), xsd:gMonthDay, month_day(Mo,D)) :- !.
dt_to_xsd_date_time(dt(Y,_,_,_,_,_,_), xsd:gYear, Y) :- !.
dt_to_xsd_date_time(dt(Y,Mo,_,_,_,_,_), xsd:gYearMonth, year_month(Y,Mo)) :- !.
dt_to_xsd_date_time(dt(_,_,_,H,Mi,S,_), xsd:time, time(H,Mi,S)).



%! xsd_date_time_to_dt(+DateTime:compound, +D:iri, -DT:compound) is det.

% xsd:date
xsd_date_time_to_dt(date(Y,Mo,D), xsd:date, dt(Y,Mo,D,_,_,_,0)).
% xsd:dateTime
xsd_date_time_to_dt(date_time(Y,Mo,D,H,Mi,S), xsd:dateTime, dt(Y,Mo,D,H,Mi,S,0)).
xsd_date_time_to_dt(date_time(Y,Mo,D,H,Mi,S,TZ), xsd:dateTime, dt(Y,Mo,D,H,Mi,S,TZ)).
% xsd:gDay
xsd_date_time_to_dt(D, xsd:gDay, dt(_,_,D,_,_,_,0)).
% xsd:gMonth
xsd_date_time_to_dt(Mo, xsd:gMonth, dt(_,Mo,_,_,_,_,0)).
% xsd:gMonthDay
xsd_date_time_to_dt(month_day(Mo,D), xsd:gMonthDay, dt(_,Mo,D,_,_,_,0)).
% xsd:gYear
xsd_date_time_to_dt(Y, xsd:gYear, dt(Y,_,_,_,_,_,0)).
% xsd:gYearMonth
xsd_date_time_to_dt(year_month(Y,Mo), xsd:gYearMonth, dt(Y,Mo,_,_,_,_,0)).
% xsd:time
xsd_date_time_to_dt(time(H,Mi,S), xsd:time, dt(_,_,_,H,Mi,S,0)).



%! xsd_date_time_type(+D:atom) is semidet.
%! xsd_date_time_type(-D:atom) is multi.

xsd_date_time_type(D) :-
  rdf11:xsd_date_time_type(D).



%! xsd_encode_string// .
%
% Turtle 1.1 ECHAR (backslash escape sequences) are handled by
% turtle:turtle_write_quoted_string/2.  This encoding predicate only
% takes care of restrictions that are specific to `xsd:string'.

% XML 1.1 Char
xsd_encode_string, [Code] --> 'Char'(version(1,1), Code), !, xsd_encode_string.
% Turtle 1.1 UCHAR
xsd_encode_string, uchar(Code) --> [Code], !, xsd_encode_string.
xsd_encode_string --> "".

uchar(N) -->
  {
    int_to_hex_weights(N, Weights),
    length(Weights, Length)
  },
  (   {Length > 4}
  ->  "\\u", zero_padded(4, Weights)
  ;   "\\U", zero_padded(8, Weights)
  ).

int_to_hex_weights(0, []) :- !.
int_to_hex_weights(N1, [H|T]) :-
  H is N1 mod 16,
  N2 is N1 // 16,
  int_to_hex_weights(N2, T).

zero_padded(N, []) --> !,
  #(N, digit_weight(0)).
zero_padded(N1, [H|T]) -->
  digit_weight(H),
  {N2 is N1 - 1},
  zero_padded(N2, T).



%! xsd_numeric_type(+D:iri) is semidet.
%! xsd_numeric_type(-D:iri) is multi.

xsd_numeric_type(xsd:byte).
xsd_numeric_type(xsd:double).
xsd_numeric_type(xsd:decimal).
xsd_numeric_type(xsd:float).
xsd_numeric_type(xsd:int).
xsd_numeric_type(xsd:integer).
xsd_numeric_type(xsd:long).
xsd_numeric_type(xsd:negativeInteger).
xsd_numeric_type(xsd:nonNegativeInteger).
xsd_numeric_type(xsd:nonPositiveInteger).
xsd_numeric_type(xsd:positiveInteger).
xsd_numeric_type(xsd:short).
xsd_numeric_type(xsd:unsignedByte).
xsd_numeric_type(xsd:unsignedInt).
xsd_numeric_type(xsd:unsignedLong).
xsd_numeric_type(xsd:unsignedShort).



%! xsd_strict_subtype(?Sub:atom, ?Super:atom) is nondet.

xsd_strict_subtype(X, Y) :-
  dif(X, Y),
  xsd_subtype(X, Y).



%! xsd_subtype(?Sub:atom, ?Super:atom) is nondet.

xsd_subtype(SubGlobal, SuperGlobal) :-
  xsd_global_local_(SubGlobal, SubLocal),
  xsd_global_local_(SuperGlobal, SuperLocal),
  xsdp_subtype_of(SubLocal, SuperLocal),
  xsd_global_local_(SubGlobal, SubLocal),
  xsd_global_local_(SuperGlobal, SuperLocal).

xsd_global_local_(Global, Local) :-
  var(Global),
  var(Local), !.
xsd_global_local_(Global, Local) :-
  rdf_prefix_iri(xsd:Local, Global).
