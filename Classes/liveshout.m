/*
 *      liveshout.c - command line ICEcast source client
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
 *
 *  usage:
 *      $ ./liveshout for default system input
 *      $ ./liveshout <file path> for LS_MP3 file input
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#ifdef LS_USE_PORTAUDIO
#include <portaudio.h>
#endif

#ifdef LS_HAVE_LAME
#include <lame/lame.h>
#endif
#include <vorbis/vorbisenc.h>

#include "liveshout.h"

/* Set buffer to zero */
#define LS_CLEAR(a) bzero((a),  LS_FRAMES_PER_BUFFER * LS_NUM_CHANNELS * LS_SAMPLE_SIZE)

//===================================


struct vorbis_globals {
    ogg_stream_state os;
    ogg_page         og;
    ogg_packet       op;
    vorbis_info      vi;
    vorbis_comment   vc;
    vorbis_dsp_state vd;
    vorbis_block     vb;
};

struct vorbis_globals vorbis;

#ifdef LS_USE_LAME
lame_global_flags *global_flags;
#endif

//===================================

int ls_vorbis_encode_buffer(unsigned char *outbuf, short *inbuf, 
        unsigned int n_channels)
{
    int eos = 0;
    int w = 0;
    unsigned int j;
    int result;
    long i;
    float **buffer;
	
    while(!eos)
    {
        result = ogg_stream_flush(&(vorbis.os), &(vorbis.og));
        if(result == 0)
            break;
        memcpy(outbuf+w, vorbis.og.header, vorbis.og.header_len);
        w += vorbis.og.header_len;
        memcpy(outbuf+w, vorbis.og.body, vorbis.og.body_len);
        w += vorbis.og.body_len;
    }

    buffer = vorbis_analysis_buffer(&vorbis.vd, LS_FRAMES_PER_BUFFER);

#ifdef LS_USE_PORTAUDIO
    /* rotate the matrix */
    for(i = 0; i < LS_FRAMES_PER_BUFFER; i++){
        for(j = 0; j < n_channels; j++){
            buffer[j][i] = (inbuf[n_channels * j + i]);
        }
    }
#else
	for(i = 0 ; i < LS_FRAMES_PER_BUFFER; i++){
		for(j = 0; j < n_channels; j++){
			buffer[j][i] = inbuf[n_channels * i + j] / 32768.f;
		}
	}

#endif
	
    vorbis_analysis_wrote(&vorbis.vd, LS_FRAMES_PER_BUFFER);

    while(vorbis_analysis_blockout(&vorbis.vd, &vorbis.vb) == 1){

        vorbis_analysis(&vorbis.vb, &vorbis.op);
        vorbis_bitrate_addblock(&vorbis.vb);

        while(vorbis_bitrate_flushpacket(&vorbis.vd, &vorbis.op)){

            ogg_stream_packetin(&vorbis.os, &vorbis.op);

            while(!eos){

                int result=ogg_stream_pageout(&vorbis.os,&vorbis.og);
                if(!result){
                    break;
                }

                memcpy(outbuf+w, vorbis.og.header, vorbis.og.header_len);
                w += vorbis.og.header_len;
                memcpy(outbuf+w, vorbis.og.body, vorbis.og.body_len);
                w += vorbis.og.body_len;

                if(ogg_page_eos(&vorbis.og)){
                    eos=1;
                }
            }
        }
    }

    return w;
}

void ls_vorbis_close(void)
{
    ogg_stream_clear(&vorbis.os);
    vorbis_block_clear(&vorbis.vb);
    vorbis_dsp_clear(&vorbis.vd);
    vorbis_comment_clear(&vorbis.vc);
    vorbis_info_clear(&vorbis.vi);
}


void ls_encoder_close(ls_encoding_type encoding_type)
{
		switch (encoding_type) {
			case LS_ENCODING_MP3:
#ifdef LS_USE_LAME
				lame_close(global_flags);
#else			
				NSLog(@"LiveShout not compiled with LAME support, invalid command");
#endif
				break;
			default:
				ls_vorbis_close();
				break;
		}
}


int ls_encode_buffer(unsigned char *outbuf, short *inbuf, 
        ls_encoding_type encoding_type, unsigned int n_channels)
{
#ifdef LS_HAVE_LAME
    float left[LS_FRAMES_PER_BUFFER];
    float right[LS_FRAMES_PER_BUFFER];
#endif
    int bufsize;

    switch(encoding_type){
        case LS_ENCODING_MP3:
#ifdef LS_HAVE_LAME
            /* normalize samples to 32767 and de-interleave */
            for(int n = 0; n < LS_FRAMES_PER_BUFFER; n++){
                /* FIX: arbitrary n_channels */
                left[n] = (inbuf[n_channels * 0 + n] * 32767.);
                right[n] = (inbuf[n_channels * 1 + n] * 32767.);
            }
            bufsize = lame_encode_buffer_float(global_flags, left, right,
                    LS_FRAMES_PER_BUFFER, outbuf, LS_MP3_BUFFER_SIZE);
            if(bufsize < 0){
                lame_close(global_flags);
                NSLog (@"%s: %s(): failed with error code: %d\n",
                        __FILE__, __FUNCTION__, bufsize);
                exit(0);
            }
#else
			NSLog (@"%s: %s(): LAME encoder not available",
					__FILE__, __FUNCTION__);
			bufsize = 0;
#endif
            break;
        case LS_ENCODING_VORBIS:
            bufsize = ls_vorbis_encode_buffer(outbuf, inbuf, n_channels);
            break;
        default:
            break;
    }
    return bufsize;
}

#ifdef LS_USE_PORTAUDIO
static void ls_portaudio_assert(PaError err, const char* command_name)
{

    if (err != paNoError){
        const char* eText=Pa_GetErrorText(err);
        if (!eText){
            eText = "???";
        }
        NSLog (@"portaudio error in %s: %s\nExiting\n", command_name, 
                eText);

        Pa_Terminate();
        exit(EXIT_FAILURE);
    }
}

PaStream *ls_portaudio_init(unsigned int n_channels)
{

    PaStreamParameters input_parameters;
    PaStream *stream = NULL;
    PaError err;

    err = Pa_Initialize();
    ls_portaudio_assert(err, "Pa_Initialize()");

    input_parameters.device = Pa_GetDefaultInputDevice(); 
    input_parameters.channelCount = n_channels;
    input_parameters.sampleFormat = LS_PA_SAMPLE_TYPE;
    input_parameters.suggestedLatency =
        Pa_GetDeviceInfo(input_parameters.device)->defaultLowInputLatency;
    input_parameters.hostApiSpecificStreamInfo = NULL;

    err = Pa_OpenStream(&stream, &input_parameters, NULL, LS_SAMPLE_RATE,
            LS_FRAMES_PER_BUFFER, paClipOff, NULL, NULL);
    ls_portaudio_assert(err, "Pa_OpenStream()");

    err = Pa_StartStream(stream);
    ls_portaudio_assert(err, "Pa_StartStream()");

    return stream;

}

int ls_buffer_from_stream(unsigned char *outbuf, PaStream *stream,
        ls_encoding_type encoding_type, unsigned int n_channels)
{

    PaError err;
    float *inbuf;
    unsigned int bufsize;

    inbuf = calloc(LS_FRAMES_PER_BUFFER * n_channels, sizeof(float));

    err = Pa_ReadStream(stream, inbuf, LS_FRAMES_PER_BUFFER);

    if(err & paInputOverflow){
        NSLog (@"xrun: input overflow.\n");
    }
    if(err & paOutputUnderflow){
        NSLog (@"xrun: output underflow.\n");
    }

    bufsize = ls_encode_buffer(outbuf, inbuf, encoding_type, n_channels);

    if(!bufsize){
        NSLog (@"%s: %s(): buffer has size 0!\n",
                __FILE__, __FUNCTION__);
    }

    free(inbuf);

    return bufsize;

}

int ls_do_stream(shout_t *shout, const char *filepath, 
        ls_encoding_type encoding_type, unsigned int n_channels)
{

    unsigned char *outbuf;
    unsigned int bufsize;
    FILE *infile = NULL;
    PaStream  *stream = NULL;
    PaError err;

    NSLog (@"%s: %s(): Using ", __FILE__, __FUNCTION__);
    if(filepath){
        infile = ls_init_file(filepath);
        outbuf = malloc(LS_FRAMES_PER_BUFFER);
        NSLog (@"%s ", filepath);
    }
    else {
        stream = ls_portaudio_init(n_channels);
        outbuf = malloc(LS_MP3_BUFFER_SIZE);
        NSLog (@"system default ");
    }
    NSLog (@"as input\n");
    NSLog (@"Buffering stream...\n"); 

    while(1)
    {
        if(infile){
            bufsize = ls_buffer_from_file(outbuf, infile, LS_FRAMES_PER_BUFFER);
        }
        else{
            bufsize = ls_buffer_from_stream(outbuf, stream, encoding_type,
                    n_channels);
        }

        ls_shout_send(shout, outbuf, bufsize);

    }

    if(stream){
        err = Pa_StopStream(stream);
        ls_portaudio_assert(err, "Pa_StopStream()");

        Pa_CloseStream(stream);
        Pa_Terminate();
    }

    free(outbuf);

    return 0;

}
#endif

FILE *ls_init_file(const char *infile)
{

    return fopen(infile, "r");

}

unsigned int ls_buffer_from_file(unsigned char *outbuf, FILE *infile, 
        unsigned int bytes)
{

    return fread(outbuf, 1, bytes, infile);

}

void ls_shout_send(shout_t *shout, unsigned char *outbuf, int bufsize)
{

    int rv;

    if (bufsize > 0) {
        /* send to server */
        rv = shout_send(shout, outbuf, bufsize);
        if (rv != SHOUTERR_SUCCESS) {
            NSLog (@"%s(): %s(): Send error: %s\n", __FILE__, __FUNCTION__,
                    shout_get_error(shout));
            return;
        }
    } else {
        return;
    }

	//NSLog(@"%d bytes sent to server", bufsize);
	
    shout_sync(shout);

}

BOOL ls_shout_reconnect(shout_t *shout)
{
	int n;
	
	while (shout_open(shout) != SHOUTERR_SUCCESS) {
		usleep(50000); // sleep for 50 ms
		if (++n * 50 >= LS_RECONNECT_TIMEOUT) {
			return FALSE;
		}
	}
	
	return TRUE;
	
}


void ls_lame_init_globals(unsigned int n_channels)
{

#ifdef LS_HAVE_LAME
    global_flags = lame_init();

    lame_set_num_channels(global_flags, n_channels);
    lame_set_in_samplerate(global_flags, LS_SAMPLE_RATE);
    lame_set_out_samplerate(global_flags, LS_SAMPLE_RATE);
    lame_set_brate(global_flags, LS_MP3_BITRATE);
    lame_set_mode(global_flags, LS_MP3_MODE);
    lame_set_quality(global_flags, LS_MP3_QUALITY);

    lame_init_params(global_flags);

#else
	NSLog (@"%s: %s(): LAME not available",
			__FILE__, __FUNCTION__);
#endif
	
}

void ls_vorbis_init_globals(unsigned int n_channels, float quality)
{
    unsigned int rv;
    ogg_packet header;
    ogg_packet header_comm;
    ogg_packet header_code;
    int eos;

    eos = 0;

    vorbis_info_init(&vorbis.vi);
    rv = vorbis_encode_init_vbr(&vorbis.vi, n_channels, 
            LS_SAMPLE_RATE, quality);

    if(rv){
        exit(1);
    }

    vorbis_comment_init(&vorbis.vc);
    vorbis_comment_add_tag(&vorbis.vc, "ENCODER", LS_SHOUT_NAME);
    vorbis_analysis_init(&vorbis.vd, &vorbis.vi);
    vorbis_block_init(&vorbis.vd, &vorbis.vb);

    srand(time(NULL));
    ogg_stream_init(&vorbis.os, rand());

    vorbis_analysis_headerout(&vorbis.vd, &vorbis.vc, &header, &header_comm,
            &header_code);
    ogg_stream_packetin(&vorbis.os, &header); 
    ogg_stream_packetin(&vorbis.os, &header_comm);
    ogg_stream_packetin(&vorbis.os, &header_code);

}


void ls_init_encoder(ls_encoding_type encoding_type, unsigned int n_channels, float quality)
{

    switch(encoding_type){
        case LS_ENCODING_MP3:
            ls_lame_init_globals(n_channels);
            break;
        case LS_ENCODING_VORBIS:
            ls_vorbis_init_globals(n_channels, quality);
            break;
    }
}

int ls_init_shout(shout_t *shout, ls_encoding_type encoding_type, int port, 
        const char *address, const char *mount_point)
{

	int shout_format;
	
    if (shout_set_name(shout, LS_SHOUT_NAME) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting stream name: %s\n", shout_get_error(shout));
        return 1;
    }

    if (shout_set_host(shout, address) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting hostname: %s\n", shout_get_error(shout));
        return 1;
    }

    if (shout_set_protocol(shout, SHOUT_PROTOCOL_HTTP) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting protocol: %s\n", shout_get_error(shout));
        return 1;
    }

    if (shout_set_port(shout, port) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting port: %s\n", shout_get_error(shout));
        return 1;
    }

    if (shout_set_password(shout, LS_ICECAST_PASSWORD) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting password: %s\n", shout_get_error(shout));
        return 1;
    }
    if (shout_set_mount(shout, mount_point) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting mount: %s\n", shout_get_error(shout));
        return 1;
    }

    if (shout_set_user(shout, LS_ICECAST_USER) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting user: %s\n", shout_get_error(shout));
        return 1;
    }

	switch (encoding_type) {
		case LS_ENCODING_MP3:
			shout_format = SHOUT_FORMAT_MP3;
		default:
			shout_format = SHOUT_FORMAT_VORBIS;
			break;
	}
    if (shout_set_format(shout, shout_format) != SHOUTERR_SUCCESS) {
        NSLog (@"Error setting user: %s\n", shout_get_error(shout));
        return 1;
    }

    return 0;

}

#ifdef LS_USE_MAIN
int main(int argc, char *argv[])
{

    shout_t *shout;
    ls_encoding_type encoding_type = LS_ENCODING_VORBIS;
    unsigned int n_channels = LS_NUM_CHANNELS;
    int shout_format = SHOUT_FORMAT_VORBIS;
    int rv;
    char *filepath = NULL;

    /* get filename if there is one */
    if(argc){
        filepath = argv[1];
        /* FIX: for now we don't do any checking e.g. that the file exists */
    }

    ls_init_encoder(encoding_type, n_channels, LS_VORBIS_QUALITY);

    shout_init();

    if (!(shout = shout_new())) {
        NSLog (@"Could not allocate shout_t\n");
        return 1;
    }

    rv = ls_init_shout(shout, shout_format);

    if(rv){
        return rv;
    }

    if (shout_open(shout) == SHOUTERR_SUCCESS) {
        NSLog (@"Connected to server...\n");
        ls_do_stream(shout, filepath, encoding_type, n_channels);
    } else {
        NSLog (@"Error connecting: %s\n", shout_get_error(shout));
    }

    shout_close(shout);
    shout_shutdown();

    return 0;
}
#endif
