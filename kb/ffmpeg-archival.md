# Archival ffmpeg commands

Commands for **archiving videos with no loss of quality.** (Or no perceptual loss of quality.) For publishing/distributing videos (where file size matters more) are published at https://github.com/RoboMWM/ffmpeg_drag-and-drop_batch_scripts

## Lossless

For re-encoding uncompressed or another lossless codec to FFV1 (e.g. captures of VHS/Video8 analog tape source, often interlaced).

### 2 pass convert to FFV1 version 3

- first pass to null muxer
- archival settings (error correction, compression, etc.)
- set interlace flag top-field-first (ignore if not interlaced source)
- `ffmpeg.exe -hide_banner -i .\sharpcam6-eh55-2001-01.avi -an -vcodec ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 1 -vf setfield=tff -f null NUL`
- second pass to mkv:
- `ffmpeg.exe -hide_banner -i .\sharpcam6-eh55-2001-01.avi -acodec copy -vcodec ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 2 -vf setfield=tff sharpcam6-eh55-2001-01.mkv`

one liner:
`D:\programs\ffmpeg\ffmpeg.exe -hide_banner -i D:\fultonsheenstopworld.avi -an -vcodec ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 1 -vf setfield=tff -f null NUL; if($?) {D:\programs\ffmpeg\ffmpeg.exe -hide_banner -i D:\fultonsheenstopworld.avi -acodec copy -vcodec ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 1 -vf setfield=tff fultonsheenstopworld.mkv}`

Optional flags:
- Add `-passlogfile K:\ffmpeg2pass` to change where the passlogfield is created
- Replace `-acodec copy` with `-acodec pcm_s16le -af "pan=mono|FC=FL"` to "delete" the right audio channel and convert to mono(i.e. inadvertant stereo recording resulting in a silent right channel).
    - Output should include `[Parsed_pan_0 @ 0000020ce0053ec0] Pure channel mapping detected: 0`
    - Front Center (FC) = Front Left (FL)

Sources:
- https://superuser.com/questions/1491785/ffmpeg-two-pass-video-encoding-on-windows
- https://trac.ffmpeg.org/wiki/Encode/FFV1#Examples1
- http://ffv1.org/
- https://video.stackexchange.com/a/32964 - range coder
- https://forum.videohelp.com/threads/400415-FFMPEG-Not-Flagging-Interlaced-Video-Properly
- https://ffmpeg.org/ffmpeg-filters.html#toc-setfield-1
- https://superuser.com/questions/601972/ffmpeg-isolate-one-audio-channel
- vf setfield https://gist.github.com/tayvano/6e2d456a9897f55025e25035478a3a50#file-gistfile1-txt-L3835

## Perceptually lossless

Idea with these are to store videos more efficiently than lossless without sacrificing any perceptable visual quality.

### Interlaced content

H264 appears to be the last codec that includes interlaced content in its spec. H265/HEVC apparently does not; it does have some implementations for storing interlaced fields but I haven't bothered to test these.

use `-flags +ilme+ildct` to inform libx264 to store the interlaced fields and use compression appropriate for interlaced fields.

Set the tune to assist the compession if necessary via `-x264-params "tune=film"`. Using the `grain` film will result in less compression efficiency so you'll likely use either `film`, `animation`, or no tune at all.

If the source doesn't include whether it's tff or bff interlacing, you can specify it in `-x264-params "tff=1:tune=film"` (which I believe will also help with compression).

## Fixing videos

### 25 to 30fps (fixes winphoneprojection client recording)

`ffmpeg.exe -hide_banner -itsscale 0.83333333 -i input.mp4 -map_metadata 0 -movflags use_metadata_tags -c copy -map 0 output.mp4`

## Notes

Using 10-bit encoding of an 8-bit source can improve compression efficiency and thus reduce file size. I compressed a 1.29GB MPEG2 source to 466MB instead of 474MB. If you wish to try 10-bit encoding for 8-bit sources, add `-pix_fmt yuv420p10le`

Sources:
- https://www.dr-lex.be/info-stuff/videotips.html
- https://yukisubs.wordpress.com/wp-content/uploads/2016/10/why_does_10bit_save_bandwidth_-_ateme.pdf
- https://x266.nl/x264/10bit_03-422_10_bit_pristine_video_quality.pdf