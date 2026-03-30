This is the output of the couple of AI chat turns to generate a script that could identify skipped frames from one capture that were not missing in another.

The frame is literally skipped, as in, not duplicated or 'detected as dropped,' but actually skipped with no way to tell other than comparing with another capture from another VCR that doesn't have skipped frames (i.e. the capture is slightly longer).

It identifies the skipped frame with what appears to be 100% accuracy, especially in low motion scenes that I cannot detect with my human eyes.

Because the script crops the outer edges, it appears to avoid any OSD overlays as a bonus.

I installed python 3.12 with the standalone MSI installer in Sandboxie (with `MsiInstallerExemptions=y` in sandbox configuration and checking the box to install `py` as admin) and used `pip install opencv-python numpy tqdm` to install dependencies. I had to run the script with the `py` command instead of `python`.

`py find_drops.py video_with_skips.avi complete_video.avi`

There is a non-critical bug with the script I saved where it will print out the last frame as being skipped multiple times corresponding to multiple frames of the complete video. I did ask AI about it and saved its response here, but since the issue is non-critical I decided to not bother implementing and testing the fix. It also helps me see if something went wrong, as it will terminate early if there was a decoding issue (e.g. if PC went to sleep and on wakeup it didn't wake the drive fast enough and got a decoding error)

---

This is a classic and notoriously frustrating problem in VHS capture restoration. The reason previous scripts failed to find the exact frame during low-motion scenes is because they likely use a **greedy, threshold-based approach**. They look at frames sequentially, wait for the difference (PSNR or SSIM) to cross a certain threshold, and then flag a desync. In a static scene, adjacent frames are nearly identical, so the threshold isn't broken until motion occurs, making the script log the drop exactly when the scene changes rather than when it actually happened. 

To find the *mathematically exact* frame where the skip occurred, we need to abandon greedy forward-checking and use **Global Optimization via Dynamic Programming (specifically, Viterbi alignment)**. 

### How this script works
Instead of making a decision frame-by-frame, this script calculates the similarity score of *every possible alignment* and carries those potential timelines forward. When motion finally occurs, the algorithm looks backward through the timeline to find the optimal path. 

To account for the fact that these are from two different VCRs (which means slightly different head-switching noise, tracking shifts, and color variations), the script will:
1. Grayscale and slightly blur the frames to ignore tape grain.
2. Crop the outer 8% to eliminate VCR edge/head-switching garbage.
3. Downscale slightly to forgive sub-pixel VCR tracking alignment differences.
4. Use Normalized Cross-Correlation (NCC) to match structural picture data, ignoring brightness/contrast shifts.

### The Python Script

You will need Python installed, along with OpenCV and NumPy. You can install the dependencies via:
`pip install opencv-python numpy tqdm`

Save the following code as `find_drops.py`:

```python
import cv2
import numpy as np
import sys
from collections import deque

try:
    from tqdm import tqdm
except ImportError:
    print("Install tqdm for a progress bar: pip install tqdm")
    tqdm = lambda x, **kwargs: x

def process_frame(frame):
    # Grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    # Crop borders (8%) to avoid VCR head switching and tracking noise
    h, w = gray.shape
    cy, cx = int(h * 0.08), int(w * 0.08)
    cropped = gray[cy:h-cy, cx:w-cx]
    # Downscale to forgive sub-pixel tracking differences
    resized = cv2.resize(cropped, (160, 120))
    # Blur to remove high-frequency tape noise, keeping structure
    blurred = cv2.GaussianBlur(resized, (5, 5), 0)
    return blurred

def compare_frames(f1, f2):
    # Normalized Cross Correlation (robust to brightness/contrast shifts between VCRs)
    res = cv2.matchTemplate(f1, f2, cv2.TM_CCOEFF_NORMED)
    return res[0][0]

def main():
    if len(sys.argv) != 3:
        print("Usage: python find_drops.py <skipped_video.avi> <complete_video.avi>")
        sys.exit(1)

    v1_path = sys.argv[1] # Shorter capture (missing 9 frames)
    v2_path = sys.argv[2] # Longer capture (good video source)

    cap1 = cv2.VideoCapture(v1_path)
    cap2 = cv2.VideoCapture(v2_path)

    # N is the length of the shorter, broken video
    N = int(cap1.get(cv2.CAP_PROP_FRAME_COUNT))
    if N == 0:
        print("Error: Could not read video 1. Check file path and codecs.")
        sys.exit(1)

    # We expect 9 skips, but allow the algorithm room to breathe (e.g., if initial sync is off by a few frames)
    MAX_SKIPS = 30 
    
    # A tiny penalty for increasing the offset. 
    # This forces the algorithm to place the skip EXACTLY at the motion boundary 
    # during still scenes, rather than arbitrarily placing it in the middle of a dead scene.
    PENALTY = 0.001 

    v2_deque = deque()

    # Pre-fill V2 buffer with frames to allow lookahead
    for _ in range(MAX_SKIPS + 1):
        ret, f = cap2.read()
        if ret:
            v2_deque.append(process_frame(f))
        else:
            v2_deque.append(np.zeros((120, 160), dtype=np.uint8))

    # dp[k] represents the max cumulative score if current offset is k
    dp = np.full(MAX_SKIPS + 1, -np.inf)
    
    # Store backpointers to trace the exact path of drops later. 
    # Memory footprint: extremely low (int8)
    backpointers = np.zeros((N, MAX_SKIPS + 1), dtype=np.int8)

    print(f"Analyzing {N} frames using Viterbi sequence alignment...")
    for i in tqdm(range(N)):
        ret, f1 = cap1.read()
        if not ret:
            N = i # Adjust if actual frame count is slightly less than header
            break
            
        f1_proc = process_frame(f1)
        new_dp = np.full(MAX_SKIPS + 1, -np.inf)

        if i == 0:
            for k in range(MAX_SKIPS + 1):
                new_dp[k] = compare_frames(f1_proc, v2_deque[k])
                backpointers[i, k] = k
        else:
            for k in range(MAX_SKIPS + 1):
                best_prev_score = -np.inf
                best_m = -1
                
                # Offset cannot decrease (frames are only lost, not gained)
                for m in range(k + 1):
                    score = dp[m] - PENALTY * (k - m)
                    if score > best_prev_score:
                        best_prev_score = score
                        best_m = m

                sim = compare_frames(f1_proc, v2_deque[k])
                new_dp[k] = best_prev_score + sim
                backpointers[i, k] = best_m

        dp = new_dp

        # Advance V2 deque dynamically to keep memory usage flat
        v2_deque.popleft()
        ret, f2 = cap2.read()
        if ret:
            v2_deque.append(process_frame(f2))
        else:
            v2_deque.append(np.zeros((120, 160), dtype=np.uint8))

    # --- TRACEBACK ---
    # Start from the best ending offset and trace backward to find exactly where it shifted
    current_k = np.argmax(dp)
    skipped_frames = []

    for i in range(N - 1, 0, -1):
        prev_k = backpointers[i, current_k]
        if prev_k < current_k:
            # Offset increased, meaning frame(s) were dropped between i-1 and i
            drop_count = current_k - prev_k
            for d in range(drop_count):
                v1_idx = i
                v2_missing_idx = i + prev_k + d
                skipped_frames.append((v1_idx, v2_missing_idx))
        current_k = prev_k

    skipped_frames.reverse()

    print("\n--- Alignment Results ---")
    if not skipped_frames:
        print("No skipped frames detected.")
    else:
        print(f"Total dropped frames found: {len(skipped_frames)}")
        print("\nList of drops:")
        for v1_idx, v2_idx in skipped_frames:
            print(f"-> Continuity break at Video 1 Frame {v1_idx} (Corresponds to dropped Video 2 Frame {v2_idx})")

    cap1.release()
    cap2.release()

if __name__ == "__main__":
    main()
```

### Usage
Run the script from your terminal/command prompt, providing the shorter video first:

```bash
python find_drops.py video_with_drops.avi complete_video.avi
```

### Important Notes for Execution
* **Initial Sync:** This algorithm assumes that `complete_video.avi` starts at the exact same frame as `video_with_drops.avi`, or slightly *before* it. If the broken capture starts several seconds before the complete capture, trim them to roughly the same starting visual frame first.
* **Lagarith Support:** `cv2.VideoCapture` uses FFmpeg under the hood, so it will natively decode Lagarith AVIs without any extra configuration. The uncompressed PCM audio won't interfere because OpenCV entirely ignores audio streams. 

---

Ouch. Waiting 40 minutes for a script to process nearly **94,000** frames only for it to crash on the literal last step of the traceback is incredibly frustrating. I understand why that's annoying.

You are completely right on both fronts. Let's break down exactly what happened with that error and how we can fix your accuracy concerns.

### 1. The `OverflowError`
The crash happened because of this line in the original script: 
`backpointers = np.zeros((N, MAX_SKIPS + 1), dtype=np.int8)`

To save memory, I set the array to `int8` (which has a maximum value of **127**). When the traceback tried to add your current frame index (`i`, which was **93546**) to the `int8` value, NumPy's strict type-casting panicked and threw an overflow error. 

**The Fix:** We will change the array to `np.int32`. The memory footprint for **94,000** frames will still be practically nothing (about 11 MB), but it will safely handle integers up to 2 billion.

### 2. The Accuracy Issue
Your intuition about the downscaling and blurring is 100% correct. While blurring removes VCR tracking noise, it also destroys the high-frequency micro-details (like a tiny sharp edge shifting a single pixel) that define the *exact* moment a skip happens in a low-motion scene. 

**The Fix:** We need to drop the blur entirely and increase the resolution. 
* **The Trade-off:** Normalized Cross-Correlation (NCC) is computationally heavy. Processing raw 720x480 frames without any downscaling will likely take several hours instead of 40 minutes. 
* **The Compromise:** I have updated the script to remove the blur entirely and added a `SCALE_FACTOR` variable. It defaults to `0.5` (half resolution), which preserves much sharper edges than before while keeping the execution time somewhat reasonable. If you want maximum, pixel-perfect accuracy and don't mind letting your PC run overnight, you can set `SCALE_FACTOR = 1.0`.

---

### The Updated Script

Save this as your new `find_drops.py`. 

```python
import cv2
import numpy as np
import sys
from collections import deque

try:
    from tqdm import tqdm
except ImportError:
    print("Install tqdm for a progress bar: pip install tqdm")
    tqdm = lambda x, **kwargs: x

# ADJUST THIS: 1.0 = Full Resolution (Slowest, Most Accurate)
# 0.5 = Half Resolution (Good balance of speed and sharp detail)
SCALE_FACTOR = 0.5 

def process_frame(frame):
    # Grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # Crop borders (8%) to avoid VCR head switching and tracking noise at the edges
    # We still want this crop so the algorithm doesn't track tape garbage
    h, w = gray.shape
    cy, cx = int(h * 0.08), int(w * 0.08)
    cropped = gray[cy:h-cy, cx:w-cx]
    
    # Optional Downscale: We removed the heavy 160x120 squeeze and the blur
    if SCALE_FACTOR < 1.0:
        new_w = int(cropped.shape[1] * SCALE_FACTOR)
        new_h = int(cropped.shape[0] * SCALE_FACTOR)
        return cv2.resize(cropped, (new_w, new_h), interpolation=cv2.INTER_AREA)
        
    return cropped

def compare_frames(f1, f2):
    # Normalized Cross Correlation
    res = cv2.matchTemplate(f1, f2, cv2.TM_CCOEFF_NORMED)
    return res[0][0]

def main():
    if len(sys.argv) != 3:
        print("Usage: python find_drops.py <skipped_video.avi> <complete_video.avi>")
        sys.exit(1)

    v1_path = sys.argv[1] 
    v2_path = sys.argv[2] 

    cap1 = cv2.VideoCapture(v1_path)
    cap2 = cv2.VideoCapture(v2_path)

    N = int(cap1.get(cv2.CAP_PROP_FRAME_COUNT))
    if N == 0:
        print("Error: Could not read video 1.")
        sys.exit(1)

    MAX_SKIPS = 30 
    PENALTY = 0.001 

    v2_deque = deque()

    # Pre-fill V2 buffer
    ret, sample_frame = cap2.read()
    if not ret:
        print("Error reading video 2.")
        sys.exit(1)
        
    sample_proc = process_frame(sample_frame)
    v2_deque.append(sample_proc)
    
    for _ in range(MAX_SKIPS):
        ret, f = cap2.read()
        if ret:
            v2_deque.append(process_frame(f))
        else:
            v2_deque.append(np.zeros_like(sample_proc))

    cap1.set(cv2.CAP_PROP_POS_FRAMES, 0) # Reset just in case

    dp = np.full(MAX_SKIPS + 1, -np.inf)
    
    # FIXED: Changed from int8 to int32 to prevent OverflowError on large frame counts
    backpointers = np.zeros((N, MAX_SKIPS + 1), dtype=np.int32)

    print(f"Analyzing {N} frames with scale factor {SCALE_FACTOR}...")
    for i in tqdm(range(N)):
        ret, f1 = cap1.read()
        if not ret:
            N = i 
            break
            
        f1_proc = process_frame(f1)
        new_dp = np.full(MAX_SKIPS + 1, -np.inf)

        if i == 0:
            for k in range(MAX_SKIPS + 1):
                new_dp[k] = compare_frames(f1_proc, v2_deque[k])
                backpointers[i, k] = k
        else:
            for k in range(MAX_SKIPS + 1):
                best_prev_score = -np.inf
                best_m = -1
                
                for m in range(k + 1):
                    score = dp[m] - PENALTY * (k - m)
                    if score > best_prev_score:
                        best_prev_score = score
                        best_m = m

                sim = compare_frames(f1_proc, v2_deque[k])
                new_dp[k] = best_prev_score + sim
                backpointers[i, k] = best_m

        dp = new_dp

        v2_deque.popleft()
        ret, f2 = cap2.read()
        if ret:
            v2_deque.append(process_frame(f2))
        else:
            v2_deque.append(np.zeros_like(sample_proc))

    # --- TRACEBACK ---
    current_k = int(np.argmax(dp))
    skipped_frames = []

    for i in range(N - 1, 0, -1):
        # FIXED: Explicitly cast to Python int to guarantee no weird numpy scalar math issues
        prev_k = int(backpointers[i, current_k])
        if prev_k < current_k:
            drop_count = current_k - prev_k
            for d in range(drop_count):
                v1_idx = i
                v2_missing_idx = i + prev_k + d
                skipped_frames.append((v1_idx, v2_missing_idx))
        current_k = prev_k

    skipped_frames.reverse()

    print("\n--- Alignment Results ---")
    if not skipped_frames:
        print("No skipped frames detected.")
    else:
        print(f"Total dropped frames found: {len(skipped_frames)}")
        print("\nList of drops:")
        for v1_idx, v2_idx in skipped_frames:
            print(f"-> Continuity break at Video 1 Frame {v1_idx} (Corresponds to dropped Video 2 Frame {v2_idx})")

    cap1.release()
    cap2.release()

if __name__ == "__main__":
    main()
```

That is awesome to hear! I'm glad it managed to nail those exact frames. Finding 9 missing frames hidden inside 90,000+ is exactly the kind of needle-in-a-haystack problem that sequence alignment is built for. 

As for that cascade of drops at the very end, what you are seeing is an **end-of-file artifact**. 

### Why this happens
Because Video 1 (the skipped capture) is physically shorter than Video 2 (the complete capture), Video 1 abruptly ends while the algorithm is still holding onto a buffer of upcoming frames from Video 2. 

When the sequence alignment reaches the final frame of Video 1 (Frame 93546), it "closes the books." To make the math balance out, it categorizes the entire remaining length of Video 2 as a massive cluster of dropped frames occurring at the precise millisecond Video 1 stops existing. 

### The Fix
Since we know any "skips" clustered identically at the absolute last frame of the video are just the algorithm dumping the rest of its buffer, we can just add a quick filter to slice them off before it prints the final list.

You can replace the bottom **Traceback** section of your script with this updated version. It simply filters out any drops that occur in the last 10 frames of the video:

```python
    # --- TRACEBACK ---
    current_k = int(np.argmax(dp))
    skipped_frames = []

    for i in range(N - 1, 0, -1):
        prev_k = int(backpointers[i, current_k])
        if prev_k < current_k:
            drop_count = current_k - prev_k
            for d in range(drop_count):
                v1_idx = i
                v2_missing_idx = i + prev_k + d
                skipped_frames.append((v1_idx, v2_missing_idx))
        current_k = prev_k

    skipped_frames.reverse()

    # --- NEW: Clean up end-of-file artifacts ---
    # Filter out the remaining V2 buffer dumping at the end of V1
    if skipped_frames:
        eof_threshold = N - 10 
        skipped_frames = [(v1, v2) for v1, v2 in skipped_frames if v1 < eof_threshold]

    print("\n--- Alignment Results ---")
    if not skipped_frames:
        print("No skipped frames detected.")
    else:
        print(f"Total dropped frames found: {len(skipped_frames)}")
        print("\nList of drops:")
        for v1_idx, v2_idx in skipped_frames:
            print(f"-> Continuity break at Video 1 Frame {v1_idx} (Corresponds to dropped Video 2 Frame {v2_idx})")

    cap1.release()
    cap2.release()

if __name__ == "__main__":
    main()
```

Now that you have the exact frame numbers (7800, 16903, 26009, etc.), what is your preferred tool for the final repair? Would you like me to write an **Avisynth** script that automatically splices those specific 9 frames from Video 2 into Video 1, or would you prefer an **FFmpeg** command list?