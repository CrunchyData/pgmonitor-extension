1.0.1
=====

BUGFIXES
--------
 - The first three number version of pgBackRest (2.52.1) was not being handled properly. Fix handling of version number so that it now returns a padded integer similar to PostgreSQL's server_version_num.
