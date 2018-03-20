package Nick::Audio::LAME;

use strict;
use warnings;

use XSLoader;
use Carp;

our $VERSION;

BEGIN {
    $VERSION = '0.01';
    XSLoader::load 'Nick::Audio::LAME' => $VERSION;
}

=pod

=head1 NAME

Nick::Audio::LAME - Interface to the libmp3lame (MP3 encoding) library.

=head1 SYNOPSIS

    use Nick::Audio::LAME;
    use Fcntl;

    my $sample_rate = 22050;
    my $hz = 441;
    my $duration = 7;

    my( $buff_in, $buff_out );
    my $lame = Nick::Audio::LAME -> new(
        'sample_rate'       => $sample_rate,
        'channels'          => 1,
        'no_xing_header'    => 0,
        'cbr'               => 64,
        'buffer_in'         => \$buff_in,
        'buffer_out'        => \$buff_out
    );

    sysopen( OUT, 'test.mp3', O_RDWR | O_TRUNC | O_CREAT | O_BINARY )
        or die;

    # make a sine wave block of data
    my $pi2 = 8 * atan2 1, 1;
    my $steps = $sample_rate / $hz;
    my( $audio_block, $i );
    for ( $i = 0; $i < $steps; $i++ ) {
        $audio_block .= pack 's', 32767 * sin(
            ( $i / $sample_rate ) * $pi2 * $hz
        );
    }
    $steps = ( $duration * $sample_rate * 2 ) / length( $audio_block );

    for ( $i = 0; $i < $steps; $i++ ) {
        $buff_in = $audio_block;
        $lame -> compress()
            and print OUT $buff_out;
    }
    $lame -> flush()
        and print OUT $buff_out;
    $lame -> update_xing( \*OUT );
    close OUT;

=head1 METHODS

=head2 new()

Instantiates a new Nick::Audio::LAME object.

Arguments are interpreted as a hash.

There are two mandatory keys.

=over 2

=item sample_rate

Sample rate of PCM data.

=item channels

Number of audio channels.

=back

The rest are optional.

=over 2

=item buffer_in

Scalar that'll be used to pull PCM data from.

=item buffer_out

Scalar that'll be used to push encoded MP3 frames to.

=item no_xing_header

Whether data will be collected to be written to a XING header at the end.

If you dont call B<make_xing()> or B<make_xing()> this is a waste of effort.

Defaults to false (i.e. collect the data).

=item cbr

Indicates the file should be encoded constant bitrate

The value should be the target bitrate.

Valid: 8, 16, 24, 32, 40, 48, 64, 80, 96, 112, 128, 160, 192, 224, 256, or 320.

=item vbr

Indicates the file should be encoded variable bitrate

The value should be the quality between 0 and 9 (0 being highest quality).

=item quality

Internal algorithm selection.

Effects quality by selecting expensive or cheap algorithms.

The value should be between 0 and 9 (0 being highest quality).

=back

=head2 compress()

Compresses PCM audio data from B<buffer_in>, possibly writing encoded MP3 frames to B<buffer_out>.

Returns the number of bytes of MP3 data written to buffer_out.

=head2 flush()

Flushes any remaining data LAME has buffered internally, possibly writing encoded MP3 frames to B<buffer_out>.

Returns the number of bytes of data written to buffer_out.

=head2 update_xing()

Given a filehandle as an argument, updates the XING header at the beginning of the file.

=head2 make_xing()

Builds a XING header and places it in B<buffer_out>.

Returns the number of bytes of data written to buffer_out.

=head2 get_frame_num()

Returns the number of frames encoded so far.

=head2 get_samples_to_encode()

Returns the number of PCM samples buffered, but not yet encoded to MP3 data.

=cut

sub new {
    my( $class, %settings ) = @_;
    my @missing;
    @missing = grep(
        ! exists $settings{$_},
        qw( sample_rate channels )
    ) and croak(
        'Missing parameters: ' . join ', ', @missing
    );
    for ( qw( in out ) ) {
        exists( $settings{ 'buffer_' . $_ } )
            or $settings{ 'buffer_' . $_ } = do{ my $x = '' };
    }
    $settings{'no_xing_header'} ||= 0;
    if (
        exists( $settings{'cbr'} ) && $settings{'cbr'}
    ) {
        $settings{'vbr'} = 0;
    } elsif (
        exists( $settings{'vbr'} )
    ) {
        $settings{'cbr'} = 0;
    } else {
        $settings{'cbr'} = 0;
        $settings{'vbr'} = 2;
    }
    exists( $settings{'quality'} )
        or $settings{'quality'} = 2;
    return Nick::Audio::LAME -> new_xs(
        @settings{ qw(
            sample_rate channels cbr vbr quality no_xing_header
            buffer_in buffer_out
        ) }
    );
}

1;
