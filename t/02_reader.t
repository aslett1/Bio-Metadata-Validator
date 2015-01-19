#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Bio::Metadata::Config;

use_ok('Bio::Metadata::Reader');

my $r;
throws_ok { $r = Bio::Metadata::Reader->new }
  qr/Attribute \(config\) is required/, 'exception when instantiating without a config';

throws_ok { $r = Bio::Metadata::Reader->new( config => {} ) }
  qr/Attribute \(config\) does not pass the type constraint/,
  'exception when passing in an invalid config object';

my $config = Bio::Metadata::Config->new( config_file => 't/data/01_single.conf' );

lives_ok { $r = Bio::Metadata::Reader->new( config => $config ) }
  'no exception with a valid B::M::Config object';

throws_ok { $r->read_csv }
  qr/no input file given/, 'exception when no input file';

throws_ok { $r->read_csv('non-existent file') }
  qr/no such input file/, 'exception with non-existent input file';

my $manifest;
ok( $manifest = $r->read_csv('t/data/01_working_manifest.csv'), '"read" works with a valid manifest' );

isa_ok( $manifest, 'Bio::Metadata::Manifest' );

is( $manifest->row_count, 2, 'got expected number of rows in manifest' );

done_testing();
