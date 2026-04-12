# Extracts and trims audio from all inputs, recalculating the "CutFromEnd" 
# relative to each specific file's duration.

param (
    [string]$BrokenVideo = "video_with_drops.avi",
    [string]$SecondVideo = "second_capture.avi",
    [string]$GoodAudio   = "complete_video.avi",
    [string]$LinearAudio = "linear_audio_capture.avi",

    # Trimming parameters
    [string]$TrimStart = "00:00:00.901",
    [string]$TrimEnd = "",
    [string]$CutFromEnd = "00:00:53.394"
)

function Convert-ToSeconds {
    param ([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return 0 }
    if ($Value -match ':') { return [TimeSpan]::Parse($Value).TotalSeconds }
    return [double]$Value
}

function Format-Timecode {
    param ([double]$Seconds)
    return ([TimeSpan]::FromSeconds([Math]::Max($Seconds, 0))).ToString("hh\:mm\:ss\.fff")
}

$filesToProcess = @($BrokenVideo, $SecondVideo, $GoodAudio, $LinearAudio)

Write-Host "Starting individualized audio extraction..." -ForegroundColor Cyan

foreach ($file in $filesToProcess) {
    if (-not (Test-Path $file)) {
        Write-Host "Skipping $file (File not found)" -ForegroundColor DarkYellow
        continue
    }

    $basename = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $outputFile = "$basename.flac"
    
    # 1. Start building trim arguments with the fixed Start time
    $thisTrimArgs = ""
    if (![string]::IsNullOrWhiteSpace($TrimStart)) {
        $thisTrimArgs += " -ss $TrimStart"
    }

    # 2. Handle the End Trim logic specifically for THIS file
    if (![string]::IsNullOrWhiteSpace($TrimEnd)) {
        # If an absolute end time was provided, use it directly
        $thisTrimArgs += " -to $TrimEnd"
    } elseif (![string]::IsNullOrWhiteSpace($CutFromEnd)) {
        # Recalculate based on this specific file's duration
        $durStr = (ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file).Trim()
        
        if (![string]::IsNullOrWhiteSpace($durStr)) {
            $totalSeconds = [double]$durStr
            $cutSeconds = Convert-ToSeconds $CutFromEnd
            $targetEndSeconds = $totalSeconds - $cutSeconds
            
            if ($targetEndSeconds -lt 0) { $targetEndSeconds = 0 }
            
            $calculatedTo = Format-Timecode $targetEndSeconds
            $thisTrimArgs += " -to $calculatedTo"
            
            Write-Host "`nProcessing: $file" -ForegroundColor Yellow
            Write-Host "-> Duration: $(Format-Timecode $totalSeconds) | End Cut: $calculatedTo" -ForegroundColor Gray
        }
    }

    # 3. Execute the extraction
    $cmd = "ffmpeg -hide_banner -y -i `"$file`" -vn -map 0:a -c:a flac -compression_level 12 $thisTrimArgs `"$outputFile`""
    Write-Host $cmd -ForegroundColor DarkGray
    Invoke-Expression $cmd

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully saved $outputFile" -ForegroundColor Green
    } else {
        Write-Host "Error processing $file" -ForegroundColor Red
    }
}

Write-Host "`nAll audio stems extracted." -ForegroundColor Cyan