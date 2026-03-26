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