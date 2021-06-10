-- python ~/src/cassandra-toolbox/cassandra-toolbox/cassandra-tracing 
-- may need older cassandra-driver in order to work with older version of cassandra.
-- pipenv --python 3
-- pipenv install cassandra-driver==3.9.0

DESCRIBE keyspaces ;
USE system_traces ;
DESCRIBE tables ;

SELECT * FROM events WHERE session_id=13456ad0-524c-11ea-a9fb-f3cda247d3db ;

SELECT dateOf(event_id), activity FROM events WHERE session_id=21dcc4d0-524c-11ea-a9fb-f3cda247d3db ;
