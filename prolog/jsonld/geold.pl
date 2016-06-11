:- module(
  geold,
  [
    geold_flatten_geo/0,
    geold_flatten_geo/1,     % ?G
    geold_geojson/2,         % +Node, -GeoJson
    geold_interpret_array/0,
    geold_interpret_array/1, % ?G
    geold_print_feature/1,   % ?Feature
    geold_rm_feature_collections/0,
    geold_tuple/2,           % +Source,                            -Tuple
    geold_tuple/4,           % +Source, +ExtraContext, +ExtraData, -Tuple
    geold_tuples/2,          % +Source,                            -Tuples
    geold_tuples/4           % +Source, +ExtraContext, +ExtraData, -Tuples
  ]
).

/** <module> GeoJSON-LD

Because JSON-LD cannot deal with GeoJSON coordinate values, we have to
extend it ourselves.  We do this by adding array support.  This way
JSON-LD can be translated into triples while preserving the array
information.  Later RDF transformations can then be used to interpret
the array as e.g. Well-Known Text (WKT).

@author Wouter Beek
@version 2016/05-2016/06
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(cli/rc)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(dict_ext)).
:- use_module(library(geo/rdf_wkt), []).
:- use_module(library(json_ext)).
:- use_module(library(jsonld/jsonld_read)).
:- use_module(library(lists)).
:- use_module(library(print_ext)).
:- use_module(library(rdf/rdf_array)).
:- use_module(library(rdf/rdf_ext)).
:- use_module(library(rdf/rdf_term)).
:- use_module(library(rdf/rdf_update)).
:- use_module(library(rdfs/rdfs_ext)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(yall)).

:- rdf_register_prefix(geold, 'http://geojsonld.com/vocab#').

:- rdf_meta
   geold_interpret_array(r),
   geold_print_feature(r).





%! geold_context(-Context) is det.
%
% The default GeoJSON-LD context.

geold_context(_{
  coordinates: _{'@id': 'geold:coordinates', '@type': 'tcco:array'},
  crs: 'geold:crs',
  geo : 'http://www.opengis.net/ont/geosparql#',
  geold: 'http://geojsonld.com/vocab#',
  geometry: 'geold:geometry',
  'GeometryCollection': 'geold:GeometryCollection',
  'Feature': 'geold:Feature',
  'FeatureCollection': 'geold:FeatureCollection',
  features: 'geold:features',
  'LineString': 'geold:LineString',
  'MultiLineString': 'geold:MultiLineString',
  'MultiPoint': 'geold:MultiPoint',
  'MultiPolygon': 'geold:MultiPolygon',
  'Point': 'geold:Point',
  'Polygon': 'geold:Polygon',
  properties: 'geold:properties',
  tcco: 'http://triply.cc/ontology/',
  '@vocab': 'http://example.org/'
}).



%! geold_flatten_geo is det.
%! geold_flatten_geo(?G) is det.

geold_flatten_geo :-
  geold_flatten_geo(_).


geold_flatten_geo(G) :-
  rdf_call_update((
    % Find instance.
    rdf_has(S, geold:geometry, B, P, G),
    rdf_is_bnode(B),
    rdf_has(B, geold:coordinates, Lit, Q, G),
    % Transform instance.
    rdf_assert(S, P, Lit, G),
    rdf_retractall(S, P, B, G),
    rdf_retractall(B, Q, Lit, G),
    rdf_retractall(B, rdf:type, _, G)
  )).



%! geold_geojson(+Node, -GeoJson) is det.
%
% Emits a description of Node in GeoJSON.

geold_geojson(Node, _{}) :-
  rdfs_instance(Node, geold:'Feature').



%! geold_interpret_array is det.
%! geold_interpret_array(?G) is det.

geold_interpret_array :-
  geold_interpret_array(_).


geold_interpret_array(G) :-
  rdf_call_update((
    rdf_has(I, geold:geometry, Array^^tcco:array, _, G),
    rdfs_instance(I, C),
    rdf_global_id(_:Name, C),
    rdf_global_id(wkt:Name, D),
    Shape =.. [Name|_],
    rdf_change(I, geold:coordinates, Array^^tcco:array, object(Shape^^D))
  )).



%! geold_print_feature(?Feature) is nondet.

geold_print_feature(I) :-
  rdfs_instance(I, geold:'Feature'),
  rc_cbd(I).



%! geold_tuple(+Source, -Tuple) is det.
%! geold_tuple(+Source, +ExtraContext, +ExtraData, -Tuple) is det.

geold_tuple(Source, Tuple) :-
  geold_tuple(Source, _{}, _{}, Tuple).


geold_tuple(Source, ExtraContext, ExtraData, Tuple) :-
  geold_prepare(Source, ExtraContext, Context, ExtraData, Data),
  jsonld_tuple_with_context(Context, Data, Tuple).



%! geold_tuples(+Source, -Tuples) is det.
%! geold_tuples(+Source, +ExtraContext, +ExtraData, -Tuples) is det.

geold_tuples(Source, Tuples) :-
  geold_tuples(Source, _{}, _{}, Tuples).


geold_tuples(Source, ExtraContext, ExtraData, Tuples) :-
  geold_prepare(Source, ExtraContext, Context, ExtraData, Data),
  aggregate_all(
    set(Tuple),
    jsonld_tuple_with_context(Context, Data, Tuple),
    Tuples
  ).



%! geold_rm_feature_collections is det.
%
% Remove all GeoJSON FeatureCollections, since these are mere
% artifacts.

geold_rm_feature_collections :-
  rdf_rm_col(geold:features),
  rdf_rm(_, rdf:type, geold:'FeatureCollection').





% HELPERS %

%! geold_prepare(+Source, +ExtraContext, -Context, +ExtraData, -Data) is det.

geold_prepare(Source, ExtraContext, Context, ExtraData, Data) :-
  geold_prepare_context(ExtraContext, Context),
  geold_prepare_data(Source, ExtraData, Data).



%! geold_prepare_context(+ExtraContext, -Context) is det.

geold_prepare_context(ExtraContext, Context) :-
  geold_context(Context0),
  Context = Context0.put(ExtraContext).



%! geold_prepare_data(+Source, +ExtraData, -Data) is det.

geold_prepare_data(Source, ExtraData, Data2) :-
  json_read_any(Source, Data1),
  (   dict_has_key(features, Data1)
  ->  maplist(
        {ExtraData}/[Data1,Data2]>>dict_put(Data1, ExtraData, Data2),
        Data1.features,
        Data2
      )
  ;   Data2 = Data1.put(ExtraData)
  ).