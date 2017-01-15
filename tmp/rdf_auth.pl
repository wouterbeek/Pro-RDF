:- module(
  rdf_auth,
  [
    rdf_user_transaction/4 % +User, :Auth_1, +Gs, :Goal_0
  ]
).

/** <module> RDF authenticated

Authenticated read/write access to the RDF DB.

@author Wouter Beek
@version 2015/07, 2015/10, 2015/12
*/

:- use_module(library(apply)).

:- meta_predicate
    authenticated_graph(2, +, +),
    rdf_user_transaction(+, 2, +, 0).

:- rdf_meta
   rdf_user_transaction(r, :, t, :).





%! rdf_user_transaction(+User, :Auth_1, +Gs, :Goal_0) is semidet.
%
% Performs `Goal_0` in an RDF transaction if the User is authenticated
% for all given graphs.

rdf_user_transaction(User, Auth_2, Gs, Goal_0) :-
  maplist(authenticated_graph(Auth_2, User), Gs),
  rdf_transaction(Goal_0).



%! authenticated_graph(:Auth_2, +User, +G) is semidet.
%
% Succeds if `call(Auth_2, User, Graph)` succeeds.

authenticated_graph(Auth_2, User, G) :-
  call(Auth_2, User, G).
