# FFmpeg audio commands

Primarily for converting music to the most efficient quality to size ratio for my Zune.

## Convert wav files to MP3 V0

V0 is the highest quality variable bitrate setting for MP3

Using PowerShell to convert all wav files in a directory to mp3 v0:
`ls | Where { $_.Extension -eq ".wav" } | ForEach { ffmpeg.exe -i $_.FullName -codec:a libmp3lame -qscale:a 0 $_.Name.Replace(".wav", ".mp3") }`

https://stackoverflow.com/a/61012921/4025452

## Convert flac files to AAC vbr 5

`-vbr 5` is a fdk_aac encoder option. fdk_aac is known for being much better than the ffmpeg aac encoder. vbr 5 is its highest quality variable bitrate setting.

fdk_aac encoder is not "free" in that it can't be included with compiled ffmpeg distributions, forcing you to compile your own ffmpeg to have this encoder. AAC is more efficient on quality to size ratio and is probably the most efficient codec the Zune supports.

Powershell: `ls | Where { $_.Extension -eq ".flac" } | ForEach { ffmpeg.exe -i $_.FullName -codec:a libfdk_aac -vbr 5 -afterburner 1 $_.Name.Replace(".flac", ".m4a") }`

## Convert flac files to MP3 V0

Convert flac files in a different directory to mp3 v0 in current directory:
`ls "Overwatch Collectors Edition Soundtrack" | Where { $_.Extension -eq ".flac" } | ForEach { ffmpeg.exe -i $_.FullName -codec:a libmp3lame -qscale:a 0 $_.Name.Replace(".flac", ".mp3") }`