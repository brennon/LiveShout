/*
 *      liveshout.h - command line ICEcast source client
 *
 *      Copyright (c) 2010 Jamie Bullock <jamie@postlude.co.uk>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#include <shout/shout.h>

#define LS_VERSION 0.6

/* general config */
#define LS_SAMPLE_RATE  (44100)
#define LS_FRAMES_PER_BUFFER (2048)
#define LS_NUM_CHANNELS    (1)
#define LS_RECONNECT_TIMEOUT (5000)   // milliseconds

/* ICECAST config */
#define LS_SHOUT_NAME "Ecliptic Streaming"
#define LS_ICECAST_IP "127.0.0.1"
#define LS_ICECAST_PORT 8000
#define LS_ICECAST_PASSWORD "eclipticlabs"
#define LS_ICECAST_MOUNTPOINT "/stream1"
#define LS_ICECAST_USER "source"

/* LAME config */
#define LS_MP3_BITRATE (256)
#define LS_MP3_MODE (1)
#define LS_MP3_QUALITY (5)
#define LS_MP3_BUFFER_SIZE 1.25 * LS_FRAMES_PER_BUFFER * 7200

/* Vorbis config */
#define LS_VORBIS_QUALITY (.9)

/* Portaudio config */
#define LS_SAMPLE_SIZE (4)
#define LS_PA_SAMPLE_TYPE  paFloat32


typedef enum ls_encoding_type_ {
    LS_ENCODING_MP3,
    LS_ENCODING_VORBIS
} ls_encoding_type;

/* send buffer of bufsize raw bytes to shoutcast server given by *shout */
void ls_shout_send(shout_t *shout, unsigned char *outbuf, int bufsize);


/* encode a buffer of PCM samples in 32-bit floating point format to 
 * compressed encoding of encoding_type 
 *
 * buffer *inbuf should be supplied as a 'flat' multidimensional array, 
 * i.e. float inbuf[frames_per_buffer * n_channels]
 *
 * */
int ls_encode_buffer(unsigned char *outbuf, short *inbuf,
        ls_encoding_type encoding_type, unsigned int n_channels);


/* initialise the encoder  */
void ls_init_encoder(ls_encoding_type encoding_type, unsigned int n_channels, float quality);

/* create a new source client */
int ls_init_shout(shout_t *shout, ls_encoding_type encoding_type, int port, 
				  const char *address, const char *mount_point);


/* close the encoder */
void ls_encoder_close(ls_encoding_type encoding_type);

/* reconnect the source client */
BOOL ls_shout_reconnect(shout_t *shout);

