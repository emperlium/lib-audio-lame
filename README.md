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

## Methods

### new()

Instantiates a new Nick::Audio::LAME object.

Arguments are interpreted as a hash.

There are two mandatory keys.

- sample\_rate

    Sample rate of PCM data.

- channels

    Number of audio channels.

The rest are optional.

- buffer\_in

    Scalar that'll be used to pull PCM data from.

- buffer\_out

    Scalar that'll be used to push encoded MP3 frames to.

- no\_xing\_header

    Whether data will be collected to be written to a XING header at the end.

    If you dont call **make\_xing()** or **make\_xing()** this is a waste of effort.

    Defaults to false (i.e. collect the data).

- cbr

    Indicates the file should be encoded constant bitrate

    The value should be the target bitrate.

    Valid: 8, 16, 24, 32, 40, 48, 64, 80, 96, 112, 128, 160, 192, 224, 256, or 320.

- vbr

    Indicates the file should be encoded variable bitrate

    The value should be the quality between 0 and 9 (0 being highest quality).

- quality

    Internal algorithm selection.

    Effects quality by selecting expensive or cheap algorithms.

    The value should be between 0 and 9 (0 being highest quality).

### compress()

Compresses PCM audio data from **buffer\_in**, possibly writing encoded MP3 frames to **buffer\_out**.

Returns the number of bytes of MP3 data written to buffer\_out.

### flush()

Flushes any remaining data LAME has buffered internally, possibly writing encoded MP3 frames to **buffer\_out**.

Returns the number of bytes of data written to buffer\_out.

### update\_xing()

Given a filehandle as an argument, updates the XING header at the beginning of the file.

### make\_xing()

Builds a XING header and places it in **buffer\_out**.

Returns the number of bytes of data written to buffer\_out.

### get\_frame\_num()

Returns the number of frames encoded so far.

### get\_samples\_to\_encode()

Returns the number of PCM samples buffered, but not yet encoded to MP3 data.
