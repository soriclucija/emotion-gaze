import pandas as pd

file_path = r"C:\Users\lucij\Desktop\Leiden\Year 2\Internship\Data\Cleaned_data\Cleaned_behavior\behavior_task2_only.csv"
df = pd.read_csv(file_path)

# recoding map - because German labels are used in the original dataset
emotion_map = {
    "Furcht": "Fear",
    "Traurigkeit": "Sadness",
    "Ärger": "Anger",
    "Ã„rger": "Anger",  
    "Neutral": "Neutral",
    "Freude": "Happiness",
    "Fear": "Fear",
    "Sadness": "Sadness",
    "Anger": "Anger",
    "Happiness": "Happiness",
}

# reocde emotion labels (English version)
df["EmotionLabel_EN"] = df["EmotionLabel"].map(emotion_map)

# recode perceived emotion labels (English version)
df["PerceivedEmotion_EN"] = df["Rating.PerceivedEmotion.ValueLabel"].map(emotion_map)

# accuracy column: 1 if correct, 0 if incorrect
df["Labeling_Accuracy"] = (
    df["EmotionLabel_EN"] == df["PerceivedEmotion_EN"]
).astype(int)

df_clean = df[[
    "sub_id",
    "Subject",
    "Group",
    "Sex",
    "Age",
    "Stimuli",  # <-- added
    "EmotionLabel_EN",
    "Gender",
    "Rating.ConfidenceScore.Value",
    "Rating.IntensityScore.Value",
    "Rating.PerceivedEmotion.Value",      
    "PerceivedEmotion_EN",
    "Labeling_Accuracy"
]]

# rename for clarity
df_clean = df_clean.rename(columns={
    "Sex": "Participant_Gender",
    "EmotionLabel_EN": "EmotionLabel",
    "Gender": "Video_Gender",
    "Rating.ConfidenceScore.Value": "Confidence",
    "Rating.IntensityScore.Value": "Intensity",
    "Rating.PerceivedEmotion.Value": "PerceivedEmotion_Number",
    "PerceivedEmotion_EN": "PerceivedEmotion"
})

output_path = r"C:\Users\lucij\Desktop\Leiden\Year 2\Internship\Data\Cleaned_data\Cleaned_behavior\behavior_task2_final.csv"
df_clean.to_csv(output_path, index=False)

print("Done! File saved to:", output_path)