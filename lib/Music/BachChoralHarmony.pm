package Music::BachChoralHarmony;

# ABSTRACT: Parse the UCI Bach choral harmony data set

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use namespace::clean;

use Text::CSV;
use File::ShareDir 'dist_dir';

=head1 SYNOPSIS

  use Music::BachChoralHarmony;
  my $bach = Music::BachChoralHarmony->new;
  my $progression = $bach->parse;   # HoLoH
  print Dump [keys %$progression];  # show all the ids
  my $id = '001707b_';
  $progression = $bach->parse($id); # LoH

=head1 DESCRIPTION

C<Music::BachChoralHarmony> parses the UCI Bach choral harmony data set.

This module does two simple things: 1. It turns the CSV data into a perl data
strutcure.  2. It converts the YES/NO note specification into a bit string.

=head1 ATTRIBUTES

=head2 data_file

The local file where the Bach choral harmony data set resides.

Default: B<dist_dir()>/jsbach_chorals_harmony.data

=cut

has data_file => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' .  'jsbach_chorals_harmony.data' },
);

=head2 key_file

The local file where the key signatures for each song are listed by BWV number
(with a few unfortunate gaps).

Default: B<dist_dir()>/BWV-keys.txt

=cut

has key_file => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' .  'BWV-keys.txt' },
);

=head2 title_file

The local file where the titles for each song are listed by BWV number
(with a few unfortunate gaps).

Default: B<dist_dir()>/BWV-titles.txt

=cut

has title_file => (
    is      => 'ro',
    default => sub { dist_dir('Music-BachChoralHarmony') . '/' .  'BWV-titles.txt' },
);

=head2 all

Boolean flag to indicate that we want to collect into a single population, as
opposed to collecting each song by id.

Default: 0

=cut

has all => (
    is      => 'ro',
    default => sub { 0 },
);

=head1 METHODS

=head2 new()

  $bach = Music::BachChoralHarmony->new(%arguments);

Create a new C<Music::BachChoralHarmony> object.

=head2 parse()

  $progression = $bach->parse();

Parse the B<data_file>, B<key_file> and B<title_file> into the song progression
including the note bit string, bass note, the accent value and the resonating
chord.

If the B<all> flag is set or a song id is given, this function returns the
progression as a list.  Otherwise, the progression is returned as hash
references keyed by song id.

=cut

sub parse {
    my ($self) = @_;

    # Collect the key signatures
    my %keys;

    open my $fh, '<', $self->key_file
        or die "Can't read ", $self->key_file, ": $!";

    while ( my $line = readline($fh) ) {
        chomp $line;
        my @parts = split /\s+/, $line;
        $keys{ $parts[0] } = $parts[1];
    }

    close $fh;

    # Collect the titles
    my %titles;

    open $fh, '<', $self->title_file
        or die "Can't read ", $self->title_file, ": $!";

    while ( my $line = readline($fh) ) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^#/;
        my @parts = split /\s+/, $line, 3;
        $titles{ $parts[0] } = {
            bwv   => $parts[1],
            title => $parts[2],
        };
    }

    close $fh;

    my $csv = Text::CSV->new( { binary => 1 } )
        or die "Can't use CSV: ", Text::CSV->error_diag();

    open $fh, '<', $self->data_file
        or die "Can't read ", $self->data_file, ": $!";

    my $progression;

    # 000106b_ 2 YES  NO  NO  NO YES  NO  NO YES  NO  NO  NO  NO E 5  C_M
    while ( my $row = $csv->getline($fh) ) {

        ( my $id = $row->[0] ) =~ s/\s*//g;

        $progression->{$id}{key}   ||= $keys{$id};
        $progression->{$id}{bwv}   ||= $titles{$id}{bwv};
        $progression->{$id}{title} ||= $titles{$id}{title};

        my $notes = '';

        for my $note ( 2 .. 13 ) {
            $notes .= $row->[$note] eq 'YES' ? 1 : 0;
        }

        ( my $bass   = $row->[14] ) =~ s/\s*//g;
        ( my $accent = $row->[15] ) =~ s/\s*//g;
        ( my $chord  = $row->[16] ) =~ s/\s*//g;

        my $struct = {
            notes  => $notes,
            bass   => $bass,
            accent => $accent,
            chord  => $chord,
        };

        if ( $self->all ) {
            push @{ $progression->{events} }, $struct;
        }
        else {
            push @{ $progression->{$id}{events} }, $struct;
        }
    }

    $csv->eof or die $csv->error_diag();
    close $fh;

    return $progression;
}

1;
__END__

=head1 SEE ALSO

L<Moo>

L<Text::CSV>

L<File::ShareDir>

L<https://archive.ics.uci.edu/ml/datasets/Bach+Choral+Harmony>

=head1 THANK YOU

Dan Book (DBOOK) for the ShareDir clues

=cut
