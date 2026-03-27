import cv2
import numpy as np
import os
import pandas as pd
from collections import deque
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input #using mobilenetv2 pretrained on imagenet for feature extraction


INPUT_FOLDER = r"C:\Users\lucij\Desktop\Leiden\Year 2\Internship\Stimuli"
OUTPUT_CSV = "transitions.csv"
IMG_SIZE = (160, 160)
BASELINE_SEC = 0.5       # neutral frames at start
STD_MULTIPLIER = 3.0     # threshold = baseline_mean + k * baseline_std
SMOOTH_WINDOW = 5        # frames to average before thresholding
PERSISTENCE = 3          # consecutive smoothed frames above threshold
BATCH_SIZE = 32

model = MobileNetV2(weights="imagenet", include_top=False, pooling="avg")

# help functions
def cosine_dist(a, b):
    return 1 - np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-8)

def extract_feats_batch(frames):
    imgs = [cv2.resize(cv2.cvtColor(f, cv2.COLOR_BGR2RGB), IMG_SIZE) for f in frames]
    arr = preprocess_input(np.array(imgs, dtype=np.float32))
    return model.predict(arr, verbose=0)

# transition detection
def detect_transition(video_path):
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    baseline_frames_needed = int(BASELINE_SEC * fps)

    all_frames = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        all_frames.append(frame)
    cap.release()

    if len(all_frames) < baseline_frames_needed + PERSISTENCE:
        return None, None

    all_feats = []
    for i in range(0, len(all_frames), BATCH_SIZE):
        batch = all_frames[i:i + BATCH_SIZE]
        feats = extract_feats_batch(batch)
        all_feats.extend(feats)
    all_feats = np.array(all_feats)

    baseline = np.mean(all_feats[:baseline_frames_needed], axis=0)

    baseline_dists = [cosine_dist(f, baseline) for f in all_feats[:baseline_frames_needed]]
    threshold = np.mean(baseline_dists) + STD_MULTIPLIER * np.std(baseline_dists) # 3 SDs above baseline mean

    distances = [cosine_dist(f, baseline) for f in all_feats[baseline_frames_needed:]]

    smooth_buf = deque(maxlen=SMOOTH_WINDOW) #rolling window
    smoothed = []
    for d in distances:
        smooth_buf.append(d)
        smoothed.append(np.mean(smooth_buf))

    # detect first persistent switch above threshold
    change_count = 0
    transition_frame = None
    for i, d in enumerate(smoothed):
        if d > threshold:
            change_count += 1
        else:
            change_count = 0
        if change_count >= PERSISTENCE: #if we have enough (3 in a row) consecutive frames above threshold, we mark the transition
            onset = i - PERSISTENCE + 1
            transition_frame = baseline_frames_needed + onset
            break

    transition_time = transition_frame / fps if transition_frame is not None else None
    return transition_time, threshold

def main():
    videos = sorted([f for f in os.listdir(INPUT_FOLDER) if f.endswith(".avi")])
    print(f"Found {len(videos)} videos\n")

    results = []
    for v in videos:
        path = os.path.join(INPUT_FOLDER, v)
        print(f"▶ {v}")
        t, thresh = detect_transition(path)
        results.append({
            "video_name": v,
            "transition_timestamp": round(t, 3) if t is not None else "none",
            "adaptive_threshold": round(thresh, 4) if thresh is not None else "none"
        })
        print(f"   → {t:.3f}s  (threshold used: {thresh:.4f})" if t else "   → no transition found")

    df = pd.DataFrame(results)
    print("\nRESULTS:\n", df)
    df.to_csv(OUTPUT_CSV, index=False)
    print(f"\nSaved → {OUTPUT_CSV}")

if __name__ == "__main__":
    main()