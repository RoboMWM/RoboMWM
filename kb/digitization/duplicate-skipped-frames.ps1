# Takes a "broken" video capture with 1 frame skips and duplicates the preceding frame to "fill" the skipped frame.
# Then muxes the audio with the audio from a different capture that does not have 1 frame skips.
# Generated with AI after several turns of debugging

param ([string]$BrokenVideo = "video_with_drops.avi",
    [string]$GoodAudio = "complete_video.avi",
    [string]$FramesList = "frames.txt",
    [string]$OutputVideo = "fixed_output.mkv", # Changed to MKV for FFV1/FLAC compatibility
    [string]$FilterScript = "filtergraph.txt"
)

# Read the frames, ensure they are numbers, and sort them sequentially
$drops = Get-Content $FramesList | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Sort-Object

if ($drops.Count -eq 0) {
    Write-Host "No valid frame numbers found in $FramesList. Exiting."
    exit
}

$filter = ""
$concatStr = ""
$prev = 0
$i = 0

Write-Host "Generating FFmpeg filtergraph for $($drops.Count) dropped frames..."

foreach ($d in $drops) {
    # Subtract 1 to duplicate the frame BEFORE the gap (and account for 0-indexing)
    $dupFrame = $d - 1
    
    # The start of the next segment
    $end = $d 
    
    # 1. Segment before the drop (up to and including the duplicated frame)
    $filter += "[0:v]trim=start_frame=${prev}:end_frame=${end},setpts=PTS-STARTPTS[v$i];`n"
    
    # 2. Duplicate the frame BEFORE the gap
    $filter += "[0:v]trim=start_frame=${dupFrame}:end_frame=${end},setpts=PTS-STARTPTS[interp$i];`n"
    
    $concatStr += "[v$i][interp$i]"
    
    # Next segment should resume at the frame immediately following the drop
    $prev = $end
    $i++
}

# Add the final segment from the last drop to the end of the video
$filter += "[0:v]trim=start_frame=${prev},setpts=PTS-STARTPTS[v$i];`n"
$concatStr += "[v$i]"

# Concat everything together. 
$totalPieces = ($drops.Count * 2) + 1

# Note: We apply your 'setfield=tff' right after concat so it applies to the whole new stream
$filter += "${concatStr}concat=n=${totalPieces}:v=1:a=0,setfield=tff,setpts=N/FRAME_RATE/TB,setpts=N/FRAME_RATE/TB[vout]`n"

# SAVE FILTERGRAPH TO FILE
$filter | Out-File -FilePath $FilterScript -Encoding ASCII -Force

# ==========================================
# 2-PASS FFV1 ENCODING
# ==========================================

Write-Host "Executing FFmpeg PASS 1 (Analyzing)..." -ForegroundColor Cyan

# PASS 1 COMMAND
# -an removes audio for pass 1 to speed it up
# -f null NUL discards the video output, it just creates the ffmpeg2pass-0.log file
# -y forces overwrite so the script doesn't pause and ask for confirmation
$pass1Cmd = "ffmpeg -hide_banner -y -i `"$BrokenVideo`" -i `"$GoodAudio`" -/filter_complex `"$FilterScript`" -map `"[vout]`" -c:v ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 1 -an -f null NUL"

Write-Host $pass1Cmd
Invoke-Expression $pass1Cmd

Write-Host "Executing FFmpeg PASS 2 (Encoding)..." -ForegroundColor Cyan

# PASS 2 COMMAND
# -map 1:a grabs the audio from GoodAudio.avi
# -c:a flac compresses the audio losslessly to save space
$pass2Cmd = "ffmpeg -hide_banner -y -i `"$BrokenVideo`" -i `"$GoodAudio`" -/filter_complex `"$FilterScript`" -map `"[vout]`" -map 1:a -c:v ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 2 -c:a flac `"$OutputVideo`""

Write-Host $pass2Cmd
Invoke-Expression $pass2Cmd

# Check if FFmpeg succeeded before claiming we are done
if ($LASTEXITCODE -eq 0) {
    Write-Host "Done! Successfully saved archival 2-pass FFV1/FLAC as $OutputVideo" -ForegroundColor Green
} else {
    Write-Host "FFmpeg encountered an error during Pass 2. Check the console output above." -ForegroundColor Red
}