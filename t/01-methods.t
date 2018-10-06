#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::BachChoralHarmony';

my $bach = Music::BachChoralHarmony->new( data_file => 'share/jsbach_chorals_harmony.data' );
isa_ok $bach, 'Music::BachChoralHarmony';

ok -e $bach->data_file, 'data_file exists';

my $progression;
lives_ok {
    $progression = $bach->parse;
} 'lives through parse';

is keys %$progression, 60, 'parse progression';

$progression = $bach->parse('000106b_');

is @$progression, 162, 'parse id progression';

done_testing();
