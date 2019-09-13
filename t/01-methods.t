#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::BachChoralHarmony';

my $data_file = 'share/jsbach_chorals_harmony.data';
my $key_title = 'share/jsbach_BWV_keys_titles.txt';

ok -e $data_file, 'data_file exists';
ok -e $key_title, 'key_title exists';

my $bach = Music::BachChoralHarmony->new(
    data_file => $data_file,
    key_title => $key_title,
);
isa_ok $bach, 'Music::BachChoralHarmony';

my $songs;
lives_ok {
    $songs = $bach->parse;
} 'lives through parse';

is keys %$songs, 60, 'parse progression';

my $x = '000106b_';
my $y = '000206b_';
ok exists $songs->{$x}, $x;
my $song = $songs->{$x};

is $song->{key}, 'F_M', 'key';
is $song->{bwv}, '1.6', 'bwv';
ok $song->{title}, 'title';
is scalar( @{ $song->{events} } ), 162, 'events';
is $song->{events}[0]{notes}, '100001000100', 'notes';
is $song->{events}[0]{bass}, 'F', 'bass';
is $song->{events}[0]{chord}, 'F_M', 'chord';
is $song->{events}[0]{accent}, 3, 'accent';

is_deeply $bach->data->{$x}, $song, 'data';
is_deeply $bach->search( id => $x ), [ { $x => $song } ], 'id search';

is scalar( @{ $bach->search( id => $x . ' ' .$y ) } ), 2, 'multiple id search';
is scalar( @{ $bach->search( key => 'X_M' ) } ), 0, 'X_M key search';
is scalar( @{ $bach->search( key => 'C_M' ) } ), 6, 'C key search';
is scalar( @{ $bach->search( key => 'C_m' ) } ), 1, 'C_m key search';
is scalar( @{ $bach->search( key => 'X_M C_M' ) } ), 6, 'X_M or C_M key search';
is scalar( @{ $bach->search( key => 'C_M C#M DbM D_M D#M EbM E_M F_M F#M GbM G_M G#M AbM A_M A#M BbM B_M' ) } ), 35, 'major keys search';
is scalar( @{ $bach->search( key => 'C_m C#m Dbm D_m D#m Ebm E_m F_m F#m Gbm G_m G#m Abm A_m A#m Bbm B_m' ) } ), 25, 'minor keys search';
is scalar( @{ $bach->search( key => 'C_M C_m' ) } ), 7, 'C_M or C_m key search';
is scalar( @{ $bach->search( bass => 'X' ) } ), 0, 'X bass search';
is scalar( @{ $bach->search( bass => 'C' ) } ), 47, 'C bass search';
is scalar( @{ $bach->search( bass => 'X C' ) } ), 47, 'X or C bass search';
is scalar( @{ $bach->search( bass => 'X & C' ) } ), 0, 'X and C bass search';
is scalar( @{ $bach->search( chord => 'X' ) } ), 0, 'X chord search';
is scalar( @{ $bach->search( chord => 'C_M' ) } ), 37, 'C chord search';
is scalar( @{ $bach->search( chord => 'X C_M' ) } ), 37, 'X or C_M chord search';
is scalar( @{ $bach->search( chord => 'X & C_M' ) } ), 0, 'X and C_M chord search';
is scalar( @{ $bach->search( notes => 'X' ) } ), 0, 'X notes search';
is scalar( @{ $bach->search( notes => 'C#' ) } ), 46, 'C# notes search';
is scalar( @{ $bach->search( notes => 'Db' ) } ), 46, 'Db notes search';
is scalar( @{ $bach->search( notes => 'C' ) } ), 50, 'C notes search';
is scalar( @{ $bach->search( notes => 'E' ) } ), 58, 'E notes search';
is scalar( @{ $bach->search( notes => 'G' ) } ), 55, 'G notes search';
is scalar( @{ $bach->search( notes => 'X C' ) } ), 50, 'X or C notes search';
is scalar( @{ $bach->search( notes => 'C E' ) } ), 60, 'C or E notes search';
is scalar( @{ $bach->search( notes => 'C G' ) } ), 57, 'C or G notes search';
is scalar( @{ $bach->search( notes => 'E G' ) } ), 60, 'E or G notes search';
is scalar( @{ $bach->search( notes => 'C E G' ) } ), 60, 'C or E or G notes search';
is scalar( @{ $bach->search( notes => 'X & C' ) } ), 0, 'X and C notes search';
is scalar( @{ $bach->search( notes => 'C & E' ) } ), 48, 'C and E notes search';
is scalar( @{ $bach->search( notes => 'C & G' ) } ), 48, 'C and G notes search';
is scalar( @{ $bach->search( notes => 'E & G' ) } ), 53, 'E and G notes search';
is scalar( @{ $bach->search( notes => 'C & E & G' ) } ), 46, 'C and E and G notes search';

done_testing();
