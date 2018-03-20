# lib-audio-lame

Interface to the libmp3lame (MP3 encoding) library.

## Dependencies

You'll need the [mp3lame library](http://lame.sourceforge.net/).

On Ubuntu distributions;

    sudo apt install libmp3lame-dev

## Installation

You'll also need to install the lib-audio-mp3 repository from this account for testing.

    perl Makefile.PL
    make test
    sudo make install

## Example

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
