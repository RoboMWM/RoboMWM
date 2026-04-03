# Takes a "broken" video capture with 1 frame skips and splices them in from another capture that has different 1 frame skips.
# Then muxes the audio with the audio from a third capture that does not have 1 frame skips.
# Generated with AI after many turns of debugging, namely attempting to get the offset recalculated correctly after splicing in a frame.

param (
    [string]$BrokenVideo = "video_with_drops.avi",[string]$SecondVideo = "second_capture.avi",
    [string]$GoodAudio   = "complete_video.avi",
    [string]$FramesList  = "frames.txt",
    [string]$FramesList2 = "frames2.txt",
    [string]$OutputVideo = "fixed_output.mkv",
    [string]$FilterScript = "filtergraph.txt",
    [double]$Framerate = 0,

    # Trimming parameters (Format: "HH:MM:SS.mmm" or seconds)
    [string]$TrimStart = "00:00:00.901",
    [string]$TrimEnd = "",
    [string]$CutFromEnd = "00:00:53.653"     # Use this to chop time off the end (e.g., "53.653" or "00:00:53.653")
)

# Read the frames, ensure they are numbers, sort sequentially
$drops1 = Get-Content $FramesList -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Sort-Object
$drops2 = Get-Content $FramesList2 -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Sort-Object

if ($null -eq $drops1 -or $drops1.Count -eq 0) {
    Write-Host "No valid frame numbers found in $FramesList. Exiting."
    exit
}

if ($null -eq $drops2) { $drops2 = @() }

# Auto-detect Framerate using ffprobe to calculate exact timecodes
if ($Framerate -eq 0) {
    Write-Host "Auto-detecting framerate for timecode calculation..."
    $fpsStr = (ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 $BrokenVideo).Trim()
    if ($fpsStr -match "/") {
        $num, $den = $fpsStr -split '/'
        $Framerate = [double]$num / [double]$den
    } else {
        $Framerate = [double]$fpsStr
    }
    if ($Framerate -eq 0) { $Framerate = 29.97 }
}

Write-Host "Using Framerate: $Framerate fps" -ForegroundColor Cyan

$filter = ""
$concatStr = ""
$current_index1 = 0    # Tracks position STRICTLY in Video 1's timeline
$current_broadcast = 0 # Tracks position in the ABSOLUTE final output timeline
$i = 0

Write-Host "Generating FFmpeg filtergraph to splice $($drops1.Count) frames from $SecondVideo..."

foreach ($d in $drops1) {
    # 1. Segment before the drop from Video 1
    # $d is the frame number in Video 1, so the length is $d minus where we left off in Video 1
    $length = $d - $current_index1
    
    if ($length -gt 0) {
        $end_index1 = $current_index1 + $length
        $filter += "[0:v]trim=start_frame=${current_index1}:end_frame=${end_index1},setpts=PTS-STARTPTS[v$i];`n"
        $concatStr += "[v$i]"
        $i++
        
        # Advance the absolute broadcast timeline by the valid frames we just took
        $current_broadcast += $length
    }
    
    # 2. Grab the exact missing frame from Video 2
    # The frame we are missing sits perfectly at the absolute $current_broadcast position
    $target_broadcast_frame = $current_broadcast
    
    # Calculate where this target frame lives in Video 2's timeline.
    # We iteratively adjust downward for every frame Video 2 itself dropped prior to this point.
    $index2 = $target_broadcast_frame
    foreach ($d2 in $drops2) {
        if ($d2 -le $index2) {
            $index2--
        }
    }
    
    $end_index2 = $index2 + 1
    
    $filter += "[1:v]trim=start_frame=${index2}:end_frame=${end_index2},setpts=PTS-STARTPTS[v$i];`n"
    $concatStr += "[v$i]"
    $i++
    
    # 3. Timecode Calculation & Output
    $seconds = $target_broadcast_frame / $Framerate
    $ts = [TimeSpan]::FromSeconds($seconds)
    $timecode = $ts.ToString("hh\:mm\:ss\.fff")
    Write-Host "-> Spliced V2 frame $index2 to fill absolute broadcast frame $target_broadcast_frame (Timecode: $timecode)" -ForegroundColor Yellow
    
    # 4. Advance our trackers
    $current_broadcast++  # We added 1 replacement frame to the absolute timeline
    $current_index1 = $d  # Advance V1's tracker to the drop point
}

# Add the final segment from the last drop to the end of Video 1
$filter += "[0:v]trim=start_frame=${current_index1},setpts=PTS-STARTPTS[v$i];`n"
$concatStr += "[v$i]"

# Concat everything together.
$totalPieces = $i + 1
$filter += "${concatStr}concat=n=${totalPieces}:v=1:a=0,setfield=tff,setpts=N/FRAME_RATE/TB[vout]`n"

# SAVE FILTERGRAPH TO FILE
$filter | Out-File -FilePath $FilterScript -Encoding ASCII -Force

# ==========================================
# TRIMMING LOGIC
# ==========================================
$trimArgs = ""
if (![string]::IsNullOrWhiteSpace($TrimStart)) {
    $trimArgs += " -ss $TrimStart"
}

# Decide between an absolute End Time or a "Cut from End" math approach
if (![string]::IsNullOrWhiteSpace($TrimEnd)) {
    $trimArgs += " -to $TrimEnd"
} elseif (![string]::IsNullOrWhiteSpace($CutFromEnd)) {
    Write-Host "`nCalculating exact end time based on `$CutFromEnd..." -ForegroundColor Cyan

    # Get total duration of the master audio file
    $durStr = (ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $GoodAudio).Trim()

    if (![string]::IsNullOrWhiteSpace($durStr)) {
        $totalSeconds = [double]$durStr

        # Parse the amount to cut
        $cutSeconds = 0
        if ($CutFromEnd -match ':') {
            $cutSeconds = [TimeSpan]::Parse($CutFromEnd).TotalSeconds
        } else {
            $cutSeconds = [double]$CutFromEnd
        }

        # Calculate new target end time
        $targetEndSeconds = $totalSeconds - $cutSeconds
        if ($targetEndSeconds -lt 0) { $targetEndSeconds = 0 }

        $targetEndTime = [TimeSpan]::FromSeconds($targetEndSeconds)
        $calculatedTrimEnd = $targetEndTime.ToString("hh\:mm\:ss\.fff")

        Write-Host "-> Total Duration: $([TimeSpan]::FromSeconds($totalSeconds).ToString("hh\:mm\:ss\.fff"))"
        Write-Host "-> Cutting: $cutSeconds seconds"
        Write-Host "-> Auto-generated TrimEnd: $calculatedTrimEnd" -ForegroundColor Yellow

        $trimArgs += " -to $calculatedTrimEnd"
    } else {
        Write-Host "Warning: Could not extract duration from $GoodAudio. Skipping end trim." -ForegroundColor Red
    }
}

# ==========================================
# 2-PASS FFV1 ENCODING
# ==========================================

Write-Host "`nExecuting FFmpeg PASS 1 (Analyzing)..." -ForegroundColor Cyan
$pass1Cmd = "ffmpeg -hide_banner -y -i `"$BrokenVideo`" -i `"$SecondVideo`" -i `"$GoodAudio`" -/filter_complex `"$FilterScript`" -map `"[vout]`" -c:v ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 1 -aspect 4:3 -an $trimArgs -f null NUL"

Write-Host $pass1Cmd -ForegroundColor DarkGray
Invoke-Expression $pass1Cmd

Write-Host "`nExecuting FFmpeg PASS 2 (Encoding)..." -ForegroundColor Cyan
$pass2Cmd = "ffmpeg -hide_banner -y -i `"$BrokenVideo`" -i `"$SecondVideo`" -i `"$GoodAudio`" -/filter_complex `"$FilterScript`" -map `"[vout]`" -map 2:a -c:v ffv1 -level 3 -coder 1 -context 1 -g 1 -slicecrc 1 -pass 2 -aspect 4:3 -c:a flac -compression_level 12 $trimArgs `"$OutputVideo`""

Write-Host $pass2Cmd -ForegroundColor DarkGray
Invoke-Expression $pass2Cmd

# Check if FFmpeg succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDone! Successfully saved archival 2-pass FFV1/FLAC as $OutputVideo" -ForegroundColor Green
} else {
    Write-Host "`nFFmpeg encountered an error during Pass 2. Check the console output above." -ForegroundColor Red
}
