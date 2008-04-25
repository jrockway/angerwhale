use strict;
use warnings;
use Test::More tests => 4;
use Test::MockObject;

use ok 'Angerwhale::Content::Filter::PGP';

my $msg = <<EOM;
-----BEGIN PGP MESSAGE-----
Version: GnuPG v1.4.6 (GNU/Linux)

owGbwMvMwCR4a49dafTntFzG09xJDB6C87RKUotLuDrsmVlBPG2YtCCTjSfDPOWV
O5S/pz7IX5dudGCq1PxDFcJn6xnm+z/z7JytoW6+ujyYxb6hVGgO47YFAA==
=3Tys
-----END PGP MESSAGE-----
EOM

my $item = Test::MockObject->new;
$item->{data} = $msg;
$item->mock( 
    data => 
      sub { 
          my ($a,$b) = @_;
          return $a->{data} unless $b;
          $a->{data} = $b;
      },
);
my $metadata = {};
$item->set_always( metadata => $metadata );

my $filter = 'Angerwhale::Content::Filter::PGP';
my $item2 = $filter->filter->(undef, undef, $item);

ok $item2;
is $item2->{data}, "test\n";
is $metadata->{raw_text}, $msg;
