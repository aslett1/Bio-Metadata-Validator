#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Slurp;
use Test::Output;
use Test::CacheFile;
use File::Temp;

use_ok('Bio::Metadata::Validator');

my $v;
lives_ok { $v = Bio::Metadata::Validator->new }
  'no exception when creating a B::M::Validator';

throws_ok { $v->validate } qr/must supply a Bio::Metadata::Manifest/,
  'exception when calling "validate" without a manifest';

# check an input file
my $config = Bio::Metadata::Config->new( config_file => 't/data/04_manifest.conf' );
my $reader = Bio::Metadata::Reader->new( config => $config );
my $manifest = $reader->read_csv('t/data/04_broken_manifest.csv');

is( $v->validate($manifest), 0, 'broken manifest is invalid' );

is( $v->_config->get('field')->[0]->{type}, 'Bool', 'config sets correct type (Bool) for field' );

is( scalar @{$manifest->rows},    2, 'found expected number of rows in "all_rows" (2)' );
is( $manifest->invalid_row_count, 1, 'found expected number of invalid rows in manifest (1)' );

is  ( $manifest->row_errors->[0], undef, 'found no error on valid row' );
like( $manifest->row_errors->[1], qr/errors found on row 2/, 'found error on invalid row' );

stdout_like( sub { $v->print_validation_report($manifest) }, qr/invalid/, 'report shows broken manifest as invalid' );
stdout_like( sub { $v->print_validation_report($manifest) }, qr/Found 1 invalid row\./, 'report shows expected number of invalid rows' );

# check that we see column descriptions when "verbose_errors" is true
is( $v->verbose_errors, 0, '"verbose_errors" starts false' );
lives_ok { $v->verbose_errors(1) } 'no exception when setting "verbose_errors" true';
is( $v->verbose_errors, 1, '"verbose_errors" set true' );

is( $manifest->is_invalid, 1, 'manifest "is_invalid" flag correctly shows 1' );

lives_ok { $v->validate($manifest) } 'validates file with verbose error flag set true';

like( $manifest->row_errors->[1], qr/^\[errors found on row 2\]/, 'flags errors on row 2' );
like( $manifest->row_errors->[1], qr/\[value in field 'one' is not valid; field description: 'Testing description'\]/, 'invalid column flagged without description' );

# check everything works with a working config and manifest
$manifest = $reader->read_csv('t/data/04_working_manifest.csv');
ok( $v->validate($manifest), 'valid input file marked as valid' );

is( $manifest->is_invalid, 0, 'manifest "is_invalid" flag correctly shows 0' );

stdout_like( sub { $v->print_validation_report($manifest) }, qr/(?<!in)valid/, 'report shows valid manifest as valid' );

done_testing();

