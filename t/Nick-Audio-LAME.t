use strict;
use warnings;

use Nick::MP3::Frame qw(
    find_frame header find_bitrate_type $FRAME_LENGTH
);

use Test::More tests => 5;

use_ok( 'Nick::Audio::LAME' );

my( $buff_in, $buff_out );
my $lame = Nick::Audio::LAME -> new(
    'sample_rate'       => 22050,
    'channels'          => 1,
    'no_xing_header'    => 0,
    'cbr'               => 64,
    'buffer_in'         => \$buff_in,
    'buffer_out'        => \$buff_out
);

ok( defined( $lame ), 'new()' );

my $mp3 = '';
my $i = -32767;
my $to;
while ( $i < 32767 ) {
    $to = $i + 8192;
    $to > 32767 and $to = 32767;
    $buff_in = '';
    for ( ; $i <= $to; $i += 8 ) {
        $buff_in .= pack 's', $i;
    }
    $i++;
    $lame -> compress()
        and $mp3 .= $buff_out;
}
$lame -> flush()
    and $mp3 .= $buff_out;
my @frames;
while (
    defined(
        $i = find_frame( $mp3 )
    )
) {
    if (
        $i >= 0 && $i + $FRAME_LENGTH <= length( $mp3 )
    ) {
        push @frames => join( '-',
            @{ header() }{ qw( sample_rate bitrate stereo layer ) }
        );
        substr( $mp3, 0, $i + $FRAME_LENGTH ) = '';
    } else {
        substr( $mp3, 0, $i ) = '';
    }
}

my $want_frames = 18;
is( scalar @frames, $want_frames, 'mp3 frames' );
is_deeply(
    \@frames,
    [ ( '22050-64-0-3' ) x $want_frames ],
    'valid frames'
);

$lame -> make_xing();
is( find_bitrate_type( $buff_out ) -> type(), 'Info', 'xing header' );
