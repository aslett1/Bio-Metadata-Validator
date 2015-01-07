#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Bio::Metadata::Validator;

# "if" relationships

my $v = Bio::Metadata::Validator->new( config_file => 't/data/broken_relationships.conf' );
throws_ok { $v->validate('t/data/relationships.csv') }
  qr/fields with an 'if' dependency/, 'exception when validating against bad config ("if" field is not boolean)';

$v = Bio::Metadata::Validator->new( config_file => 't/data/relationships.conf' );
is( $v->validate('t/data/relationships.csv'), 0, 'broken relationship input file marked as invalid' );

like  ( $v->all_rows->[1],  qr/\[field 'one' .*?]$/, 'error with missing value for "if" true' );

unlike( $v->all_rows->[2],  qr/\[field /, 'no error on valid row; "if" column true' );
like  ( $v->all_rows->[3],  qr/\[field 'two' .*? \[field 'three' .*?]$/, 'two errors with two missing "if" dependencies' );
like  ( $v->all_rows->[4],  qr/\[field 'three' .*?]$/, 'error with one missing dependency' );
like  ( $v->all_rows->[5],  qr/\[field 'two' .*?]$/, 'error with other missing dependency' );

unlike( $v->all_rows->[6],  qr/\[field /, 'no error on valid row; "if" column false' );
like  ( $v->all_rows->[7],  qr/\[field 'four' .*? \[field 'five'.*?]$/, 'two errors with two missing "if" dependencies' );
like  ( $v->all_rows->[8],  qr/\[field 'five' .*?]$/, 'error with "false" dependency value supplied when "if" is true' );
like  ( $v->all_rows->[9],  qr/\[field 'four' .*?]$/, 'error with other missing dependency' );

like  ( $v->all_rows->[10], qr/\[field 'four' should not be completed .*?]$/, 'one error with "false" dependency value supplied when "if" is true' );
like  ( $v->all_rows->[11], qr/\[field 'two' should not be completed .*?]$/, 'one error with "true" dependency value supplied when "if" is false' );

unlike( $v->all_rows->[12], qr/\[field /, 'no error with valid second "if"; "if" column true' );
unlike( $v->all_rows->[13], qr/\[field /, 'no error with valid second "if"; "if" column false' );
like  ( $v->all_rows->[14], qr/\[field 'seven' .*| \[field 'eight'.*?]$/, 'two errors with second "if" when dependency columns not correct' );

# "one_of" relationships

unlike( $v->all_rows->[15], qr/\[exactly one field out of 'ten', 'eleven' should.*?]$/, 'no error when one column of "one-of" group is present' );
like  ( $v->all_rows->[16], qr/\[exactly one field out of 'ten', 'eleven' should.*?]$/, 'error when two columns of a "one-of" group is present' );
like  ( $v->all_rows->[17], qr/\[exactly one field out of 'twelve'.*?found 2.*?]$/, 'error when two columns of a three-column "one-of" group are present' );
like  ( $v->all_rows->[18], qr/\[exactly one field out of 'twelve'.*?found 3.*?]$/, 'error when three columns of a three-column "one-of" group are present' );

# "some_of" relationships

like  ( $v->all_rows->[19], qr/\[at least one field out of 'eighteen'.*?]$/, 'error when no columns in a three-column "some-of" group are found' );

# make sure that we're checking for the presence of a value in a field, rather than
# always a *valid* value
like  ( $v->all_rows->[20], qr/\[value in field 'twelve' is not valid] \[exactly one field out of 'twelve'.*?found 2/, 'error when two columns in a three-column "one-of" group are found, one valid, one invalid' );

done_testing();

