#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <lame/lame.h>

struct nickaudiolame {
    lame_global_flags *lame_flags;
    int channels;
    unsigned char *mp3_out;
    SV *scalar_in;
    SV *scalar_out;
};

typedef struct nickaudiolame NICKAUDIOLAME;

#define MAX_SIZE 8 * 1024

MODULE = Nick::Audio::LAME  PACKAGE = Nick::Audio::LAME

static NICKAUDIOLAME *
NICKAUDIOLAME::new_xs( sample_rate, channels, cbr, vbr, quality, no_xing_header, scalar_in, scalar_out )
        int sample_rate;
        int channels;
        int cbr;
        float vbr;
        int quality;
        bool no_xing_header;
        SV *scalar_in;
        SV *scalar_out;
    CODE:
        Newxz( RETVAL, 1, NICKAUDIOLAME );
        RETVAL -> lame_flags = lame_init();
        RETVAL -> channels = channels;
        lame_set_num_channels( RETVAL -> lame_flags, channels );
        lame_set_in_samplerate( RETVAL -> lame_flags, sample_rate );
        lame_set_write_id3tag_automatic( RETVAL -> lame_flags, 0 );
        if (no_xing_header) {
            lame_set_bWriteVbrTag( RETVAL -> lame_flags, 0 );
        }
        if ( cbr > 0 ) {
            lame_set_VBR( RETVAL -> lame_flags, vbr_off );
            lame_set_brate( RETVAL -> lame_flags, cbr );
        } else {
            lame_set_VBR( RETVAL -> lame_flags, vbr_default );
            lame_set_VBR_quality( RETVAL -> lame_flags, vbr );
        }
        lame_set_quality( RETVAL -> lame_flags, quality );
        if (
            lame_init_params( RETVAL -> lame_flags ) < 0
        ) {
            croak( "Failed to initialize LAME." );
        }
        Newx( RETVAL -> mp3_out, MAX_SIZE, unsigned char );
        RETVAL -> scalar_in = SvREFCNT_inc(
            SvROK( scalar_in )
            ? SvRV( scalar_in )
            : scalar_in
        );
        RETVAL -> scalar_out = SvREFCNT_inc(
            SvROK( scalar_out )
            ? SvRV( scalar_out )
            : scalar_out
        );
    OUTPUT:
        RETVAL

void
NICKAUDIOLAME::DESTROY()
    CODE:
        lame_close( THIS -> lame_flags );
        SvREFCNT_dec( THIS -> scalar_in );
        SvREFCNT_dec( THIS -> scalar_out );
        Safefree( THIS -> mp3_out );
        Safefree( THIS );

int
NICKAUDIOLAME::compress()
    CODE:
        STRLEN len_in;
        if (
            ! SvOK( THIS -> scalar_in )
        ) {
            sv_setpvn( THIS -> scalar_out, NULL, 0 );
            XSRETURN_UNDEF;
        }
        short int *in_buff = (short int*)SvPV( THIS -> scalar_in, len_in );
        if ( THIS -> channels == 1 ) {
            RETVAL = lame_encode_buffer(
                THIS -> lame_flags,
                in_buff,
                in_buff,
                len_in / 2,
                THIS -> mp3_out,
                0
            );
        } else {
            RETVAL = lame_encode_buffer_interleaved(
                THIS -> lame_flags,
                in_buff,
                len_in / 4,
                THIS -> mp3_out,
                0
            );
        }
        if ( RETVAL == -1 ) {
            croak( "LAME buffer not big enough" );
        }
        if ( RETVAL < 0 ) {
            croak( "LAME internal error: %d", RETVAL );
        }
        sv_setpvn( THIS -> scalar_out, THIS -> mp3_out, RETVAL );
    OUTPUT:
        RETVAL

int
NICKAUDIOLAME::flush()
    CODE:
        RETVAL = lame_encode_flush(
            THIS -> lame_flags,
            THIS -> mp3_out,
            MAX_SIZE
        );
        if ( RETVAL == -1 ) {
            croak( "LAME buffer not big enough" );
        }
        if ( RETVAL < 0 ) {
            croak( "LAME internal error: %d", RETVAL );
        }
        sv_setpvn( THIS -> scalar_out, THIS -> mp3_out, RETVAL );
    OUTPUT:
        RETVAL

void
NICKAUDIOLAME::update_xing( fh )
        FILE *fh
    CODE:
        lame_mp3_tags_fid(
            THIS -> lame_flags, fh
        );

int
NICKAUDIOLAME::make_xing()
    CODE:
        RETVAL = lame_get_lametag_frame(
            THIS -> lame_flags,
            THIS -> mp3_out,
            MAX_SIZE
        );
        sv_setpvn( THIS -> scalar_out, THIS -> mp3_out, RETVAL );
    OUTPUT:
        RETVAL

int
NICKAUDIOLAME::get_frame_num()
    CODE:
        RETVAL = lame_get_frameNum( THIS -> lame_flags );
    OUTPUT:
        RETVAL

int
NICKAUDIOLAME::get_samples_to_encode()
    CODE:
        RETVAL = lame_get_mf_samples_to_encode( THIS -> lame_flags );
    OUTPUT:
        RETVAL
