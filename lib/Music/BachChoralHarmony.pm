package Music::BachChoralHarmony;

# ABSTRACT: Parse the UCI Bach choral harmony data set

our $VERSION = '0.0203';

use Moo;
use strictures 2;
use namespace::clean;

use Text::CSV;
use File::ShareDir 'dist_dir';
use List::Util qw/ any /;

=head1 SYNOPSIS

  use Music::BachChoralHarmony;

  my $bach = Music::BachChoralHarmony->new;
  my $songs = $bach->parse;

  # show all the song ids:
  print Dumper [ keys %$songs ];

  # show all the song titles:
  print Dumper [ map { $songs->{$_}{title} } keys %$songs ];

  $songs = $bach->search( id => '000106b_' );
  $songs = $bach->search( id => '000106b_ 000206b_' );
  $songs = $bach->search( key => 'C_M' );         # In C major
  $songs = $bach->search( key => 'C_M C_m' );     # In C major or C minor
  $songs = $bach->search( bass => 'C' );          # With a C note in the bass
  $songs = $bach->search( bass => 'C D' );        # With C or D in the bass
  $songs = $bach->search( bass => 'C & D' );      # With C and D in the bass
  $songs = $bach->search( chord => 'C_M' );       # With a C major chord
  $songs = $bach->search( chord => 'C_M D_m' );   # With a C major or a D minor chord
  $songs = $bach->search( chord => 'C_M & D_m' ); # With a C major and a D minor chord
  $songs = $bach->search( notes => 'C E G' );     # With the notes C or E or G
  $songs = $bach->search( notes => 'C & E & G' ); # With C and E and G

=head1 DESCRIPTION

C<Music::BachChoralHarmony> parses the UCI Bach choral harmony data set of 60
chorales.

This module does a few simple things:

1. It turns the UCI CSV data into a perl data structure.

2. It converts the UCI YES/NO note specification into a bit string.

3. It combines the Bach BWV number, song title and key with the data.

4. It allows searching by ids, keys, notes, and chords.

The BWV and titles were collected from an old Internet Archive of
C<jsbchorales.net> and filled-in from C<bach-chorales.com>.  The keys were
computed with a C<music21> python program and again filled-in from
C<bach-chorales.com>.  Check out the links in the L</SEE ALSO> section
for more information.

See the distribution C<eg/> programs for usage examples.

=head1 ATTRIBUTES

=head2 data_file

  $file = $bach->data_file;

The local file where the Bach choral harmony data set resides.

Default: C<dist_dir()>/jsbach_chorals_harmony.data

=cut

has data_file => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' .  'jsbach_chorals_harmony.data' },
);

=head2 key_title

  $file = $bach->key_title;

The local file where the key signatures and titles for each song are listed by
BWV number.

Default: C<dist_dir()>/jsbach_BWV_keys_titles.txt

=cut

has key_title => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' . 'jsbach_BWV_keys_titles.txt' },
);

=head2 data

  $songs = $bach->data;

The data resulting from the L</parse> method.

=cut

has data => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { {} },
);

=head1 METHODS

=head2 new

  $bach = Music::BachChoralHarmony->new();

Create a new C<Music::BachChoralHarmony> object.

=head2 parse

  $songs = $bach->parse();

Parse the B<data_file> and B<key_title> files into a B<data> hash
reference of each song keyed by the song id.  Each song includes a BWV
identifier, title, key and list of events.  The event list is made of
hash references with keys for the notes bit string, bass note, the
accent value and the resonating chord.

=cut

sub parse {
    my ($self) = @_;

    # Collect the key signatures and titles
    my %data;

    open my $fh, '<', $self->key_title
        or die "Can't read ", $self->key_title, ": $!";

    while ( my $line = readline($fh) ) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^#/;
        my @parts = split /\s+/, $line, 4;
        $data{ $parts[0] } = {
            bwv   => $parts[1],
            key   => $parts[2],
            title => $parts[3],
        };
    }

    close $fh;

    # Collect the events
    my $csv = Text::CSV->new( { binary => 1 } )
        or die "Can't use CSV: ", Text::CSV->error_diag();

    open $fh, '<', $self->data_file
        or die "Can't read ", $self->data_file, ": $!";

    my $progression;

    # 000106b_ 2 YES  NO  NO  NO YES  NO  NO YES  NO  NO  NO  NO E 5  C_M
    while ( my $row = $csv->getline($fh) ) {

        ( my $id = $row->[0] ) =~ s/\s*//g;

        my $notes = '';

        for my $note ( 2 .. 13 ) {
            $notes .= $row->[$note] eq 'YES' ? 1 : 0;
        }

        ( my $bass   = $row->[14] ) =~ s/\s*//g;
        ( my $accent = $row->[15] ) =~ s/\s*//g;
        ( my $chord  = $row->[16] ) =~ s/\s*//g;

        $progression->{$id}{key}   ||= $data{$id}{key};
        $progression->{$id}{bwv}   ||= $data{$id}{bwv};
        $progression->{$id}{title} ||= $data{$id}{title};

        my $struct = {
            notes  => $notes,
            bass   => $bass,
            accent => $accent,
            chord  => $chord,
        };

        push @{ $progression->{$id}{events} }, $struct;
    }

    $csv->eof or die $csv->error_diag();
    close $fh;

    $self->data($progression);

    return $self->data;
}

=head2 search

  $songs = $bach->search( id => '000106b_' ); # Single song
  $songs = $bach->search( id => '000106b_ 000206b_' ); # Two songs
  $songs = $bach->search( key => 'C_M' );         # All C major key songs
  $songs = $bach->search( key => 'C_M C_m' );     # All in C major and C minor keys
  $songs = $bach->search( bass => 'C' );          # All with a C in the bass
  $songs = $bach->search( bass => 'C D' );        # With a C or a D in the bass
  $songs = $bach->search( bass => 'C & D' );      # With a C and a D in the bass
  $songs = $bach->search( chord => 'C_M' );       # With a C major chord
  $songs = $bach->search( chord => 'C_M D_m' );   # With C major or D minor chords
  $songs = $bach->search( chord => 'C_M & D_m' ); # With both C major and D minor chords
  $songs = $bach->search( notes => 'C E G' );     # With the notes C or E or G
  $songs = $bach->search( notes => 'C & E & G' ); # With the notes C and E and G

Search the parsed result B<data> by song B<id>s, B<key>s, B<bass>
notes, B<chord>s, or individual B<notes> and return an array reference
of hash references:

  [ { $song_id => $song_data }, ... ],

The B<id>, and B<key> can be searched by single or multiple values
returning all songs that match.  Separate note names with a space
character.

The B<bass>, B<chord>, and B<notes> can be searched either as C<or>
(separating note names with a space character), or as inclusive C<and>
(separating note names with an C<&> character).

=cut

sub search {
    my ( $self, %args ) = @_;

    my @results = ();

    if ( $args{id} ) {
        my @ids = split /\s+/, $args{id};
        for my $id ( @ids ) {
            push @results, { $id => $self->data->{$id} };
        }
    }
    elsif ( $args{key} ) {
        my @keys = split /\s+/, $args{key};
        for my $id ( keys %{ $self->data } ) {
            push @results, { $id => $self->data->{$id} }
                if any { $_ eq $self->data->{$id}{key} } @keys;
        }
    }
    elsif ( $args{bass} ) {
        @results = $self->_search_param( bass => $args{bass} );
    }
    elsif ( $args{chord} ) {
        @results = $self->_search_param( chord => $args{chord} );
    }
    elsif ( $args{notes} ) {
        my $and = $args{notes} =~ /&/ ? 1 : 0;
        my $re  = $and ? qr/\s*&\s*/ : qr/\s+/;
        my @notes = split $re, $args{notes};
        my %index = (
            'C'  => 0,
            'C#' => 1,
            'Db' => 1,
            'D'  => 2,
            'D#' => 3,
            'Eb' => 3,
            'E'  => 4,
            'F'  => 5,
            'F#' => 6,
            'Gb' => 6,
            'G'  => 7,
            'G#' => 8,
            'Ab' => 8,
            'A'  => 9,
            'A#' => 10,
            'Bb' => 10,
            'B'  => 11,
        );
        ID: for my $id ( keys %{ $self->data } ) {
            my %and_notes = ();
            for my $event ( @{ $self->data->{$id}{events} } ) {
                my @bitstring = split //, $event->{notes};
                my $i = 0;
                for my $bit ( @bitstring ) {
                    if ( $bit ) {
                        if ( $and ) {
                            for my $note ( sort @notes ) {
                                if ( defined $index{$note} && $i == $index{$note} ) {
                                    $and_notes{$note}++;
                                }
                            }
                        }
                        else {
                            if ( any { defined $index{$_} && $i == $index{$_} } @notes ) {
                                push @results, { $id => $self->data->{$id} };
                                next ID;
                            }
                        }
                    }
                    $i++;
                }
            }
            if ( keys %and_notes ) {
                my %notes;
                @notes{@notes} = undef;
                my $i = 0;
                for my $n ( keys %and_notes ) {
                    $i++
                        if exists $notes{$n};
                }
                push @results, { $id => $self->data->{$id} }
                    if $i == scalar keys %notes;
            }
        }
    }

    return \@results;
}

sub _search_param {
    my ( $self, $name, $param ) = @_;

    my @results = ();

    my $and = $param =~ /&/ ? 1 : 0;
    my $re  = $and ? qr/\s*&\s*/ : qr/\s+/;
    my %notes = ();
    @notes{ split $re, $param } = undef;

    ID: for my $id ( keys %{ $self->data } ) {
        my %and_notes = ();
        for my $event ( @{ $self->data->{$id}{events} } ) {
            if ( $and ) {
                for my $note ( keys %notes ) {
                    if ( $note eq $event->{$name} ) {
                        $and_notes{$note}++;
                    }
                }
            }
            else {
                if ( any { $_ eq $event->{$name} } keys %notes ) {
                    push @results, { $id => $self->data->{$id} };
                    next ID;
                }
            }
        }
        if ( keys %and_notes ) {
            my $i = 0;
            for my $n ( keys %and_notes ) {
                $i++
                    if exists $notes{$n};
            }
            push @results, { $id => $self->data->{$id} }
                if $i == scalar keys %notes;
        }
    }

    return @results;
}


1;
__END__

=head1 SEE ALSO

L<Moo>

L<Text::CSV>

L<File::ShareDir>

L<List::Util>

L<https://archive.ics.uci.edu/ml/datasets/Bach+Choral+Harmony>

L<https://web.archive.org/web/20140515065053/http://www.jsbchorales.net/bwv.shtml>

L<http://www.bach-chorales.com/BachChorales.htm>

L<http://web.mit.edu/music21/>

L<https://github.com/ology/Bach-Chorales/blob/master/bin/key.py>

=head1 THANK YOU

Dan Book (L<DBOOK|https://metacpan.org/author/DBOOK>) for the ShareDir clues.

=cut
