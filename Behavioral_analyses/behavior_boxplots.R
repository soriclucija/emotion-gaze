library(tidyverse)
library(lme4)
library(car)
library(emmeans)
library(dplyr)
library(ggplot2)
library(ggdist)

df <- read_csv("C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavior_task2_final.csv")

df %>%
  distinct(Subject, Group) %>%
  count(Group)

df <- df %>% 
  mutate(
    Group              = factor(Group, levels = c("A", "C", "S")),
    Participant_Gender = factor(Participant_Gender),
    Video_Gender       = factor(Video_Gender),
    EmotionLabel       = factor(EmotionLabel),
    PerceivedEmotion   = factor(PerceivedEmotion),
    Labeling_Accuracy  = as.numeric(Labeling_Accuracy)  # 0 = incorrect, 1 = correct
  )

df <- df %>%
  mutate(
    Actor = factor(str_extract(Stimuli, "^[0-9]+")) #to track different actors in videos
  )

View(df)

unique(df$Actor)


# accuracy per group x condition
accuracy_summary <- df %>%
  group_by(Group, EmotionLabel) %>%
  summarise(
    N        = n(),
    Correct  = sum(Labeling_Accuracy),
    Accuracy = mean(Labeling_Accuracy),
    SE       = sd(Labeling_Accuracy) / sqrt(N),
    .groups  = "drop"
  )

print(accuracy_summary)

df_subject <- df %>%
  group_by(Subject, Group, EmotionLabel) %>%
  summarise(acc = mean(Labeling_Accuracy), .groups = "drop")

df_subject <- df_subject %>%
  mutate(
    Group = dplyr::recode(Group,
                   "A" = "ASD",
                   "S" = "SAD",
                   "C" = "Control"),
    Group = factor(Group, levels = c("Control", "ASD", "SAD"))
  )
group_colors <- c(
  "ASD"     = "#09283c",
  "SAD"     = "#ffc857",
  "Control" = "#3CC8C0"
)

ggplot(df_subject, aes(x = EmotionLabel, y = acc)) +
  
  # scatter
  geom_jitter(
    aes(color = Group),
    position = position_jitterdodge(
      jitter.width = 0.08,
      dodge.width = 0.6
    ),
    size = 1.6,
    alpha = 0.6
  ) +
  
  # boxplots
  geom_boxplot(
    aes(fill = Group),
    position = position_dodge(width = 0.6),
    width = 0.5,
    outlier.shape = NA,
    color = "",
    alpha = 1
  ) +
  
  # colors
  scale_fill_manual(values = group_colors) +
  scale_color_manual(values = group_colors) +
  
  theme_classic(base_size = 16) +
  
  theme(
    text = element_text(family = "sans"),  
    
    axis.line = element_line(linewidth = 1.5, color = "black"),
    
    axis.text = element_text(size = 22),
    axis.title = element_text(size = 24),
    
    axis.title.y = element_text(margin = margin(r = 20)),
    
    legend.position = "none",
    strip.background = element_blank()
  ) +
  
  labs(
    x = "",
    y = "Accuracy"
  )

# confidence per condition x emotion
confidence_summary <- df %>%
  group_by(Group, EmotionLabel) %>%
  summarise(
    N        = n(),
    Correct  = sum(Confidence),
    Accuracy = mean(Confidence),
    SE       = sd(Confidence) / sqrt(N),
    .groups  = "drop"
  )

print(confidence_summary)

df_subject_conf <- df %>%
  group_by(Subject, Group, EmotionLabel) %>%
  summarise(conf = mean(Confidence), .groups = "drop")

df_subject_conf <- df_subject_conf %>%
  mutate(
    Group = dplyr::recode(Group,
                          "A" = "ASD",
                          "S" = "SAD",
                          "C" = "Control"),
    Group = factor(Group, levels = c("Control", "ASD", "SAD"))
  )

ggplot(df_subject_conf, aes(x = EmotionLabel, y = conf)) +
  
  # scatter
  geom_jitter(
    aes(color = Group),
    position = position_jitterdodge(
      jitter.width = 0.08,
      dodge.width = 0.6
    ),
    size = 1.6,
    alpha = 0.6
  ) +
  
  # boxplots
  geom_boxplot(
    aes(fill = Group),
    position = position_dodge(width = 0.6),
    width = 0.5,
    outlier.shape = NA,
    color = "black",
    alpha = 1
  ) +
  
  # colors
  scale_fill_manual(values = group_colors) +
  scale_color_manual(values = group_colors) +
  
  theme_classic(base_size = 16) +
  
  theme(
    text = element_text(family = "sans"),  
    
    axis.line = element_line(linewidth = 1.5, color = "black"),
    
    axis.text = element_text(size = 22),
    axis.title = element_text(size = 24),
    
    axis.title.y = element_text(margin = margin(r = 20)),
    
    legend.position = "none",
    strip.background = element_blank()
  ) +
  
  labs(
    x = "",
    y = "Confidence"
  )

# intensity per condition x emotion
intensity_summary <- df %>%
  group_by(Group, EmotionLabel) %>%
  summarise(
    N        = n(),
    Correct  = sum(Intensity),
    Accuracy = mean(Intensity),
    SE       = sd(Intensity) / sqrt(N),
    .groups  = "drop"
  )

print(intensity_summary)

df_subject_intense <- df %>%
  group_by(Subject, Group, EmotionLabel) %>%
  summarise(intense = mean(Intensity), .groups = "drop")

df_subject_intense <- df_subject_intense %>%
  mutate(
    Group = dplyr::recode(Group,
                          "A" = "ASD",
                          "S" = "SAD",
                          "C" = "Control"),
    Group = factor(Group, levels = c("Control", "ASD", "SAD"))
  )

ggplot(df_subject_intense, aes(x = EmotionLabel, y = intense)) +
  
  # scatter
  geom_jitter(
    aes(color = Group),
    position = position_jitterdodge(
      jitter.width = 0.08,
      dodge.width = 0.6
    ),
    size = 1.6,
    alpha = 0.6
  ) +
  
  # boxplots
  geom_boxplot(
    aes(fill = Group),
    position = position_dodge(width = 0.6),
    width = 0.5,
    outlier.shape = NA,
    color = "black",
    alpha = 1
  ) +
  
  # colors
  scale_fill_manual(values = group_colors) +
  scale_color_manual(values = group_colors) +
  
  theme_classic(base_size = 16) +
  
  theme(
    text = element_text(family = "sans"),  
    
    axis.line = element_line(linewidth = 1.5, color = "black"),
    
    axis.text = element_text(size = 22),
    axis.title = element_text(size = 24),
    
    axis.title.y = element_text(margin = margin(r = 20)),
    
    legend.position = "none",
    strip.background = element_blank()
  ) +
  
  labs(
    x = "",
    y = "Intensity"
  )

# matrices

confusion_theme <- theme_classic(base_size = 16) +
  theme(
    text          = element_text(family = "sans"),
    axis.line     = element_blank(),
    axis.ticks    = element_blank(),
    axis.text     = element_text(size = 18),
    axis.text.x   = element_text(angle = 45, hjust = 1),
    axis.title    = element_text(size = 24),
    axis.title.y  = element_text(margin = margin(r = 20)),
    legend.position  = "right",
    legend.title  = element_text(size = 16),
    legend.text   = element_text(size = 14),
    plot.title    = element_text(size = 22, face = "bold", hjust = 0.5),
    panel.grid    = element_blank()
  )

confusion_data <- df %>%
  mutate(
    Group = dplyr::recode(as.character(Group),
                          "A" = "ASD", "C" = "Control", "S" = "SAD"),
    Group = factor(Group, levels = c("Control", "ASD", "SAD"))
  ) %>%
  filter(!is.na(PerceivedEmotion)) %>%
  group_by(Group, EmotionLabel, PerceivedEmotion) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(Group, EmotionLabel) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup() %>%
  complete(Group, EmotionLabel, PerceivedEmotion,
           fill = list(n = 0, prop = 0)) %>%
  mutate(
    is_correct = EmotionLabel == PerceivedEmotion,
    text_color = case_when(
      Group == "ASD"  & is_correct > 0.55     ~ "white",  # ASD is dark coloured
      Group == "SAD"  & prop > 0.55     ~ "black",  # SAD is dark coloured
      Group == "Control" & prop > 0.80  ~ "black",  # Control is light beige — always black
      TRUE                              ~ "black"   # catch-all
    )
  )

make_confusion <- function(group_name) {
  dat        <- confusion_data %>% filter(Group == group_name)
  group_col  <- group_colors[[group_name]]   # pick this group's color
  
  ggplot(dat, aes(x = PerceivedEmotion, y = EmotionLabel, fill = prop)) +
    
    geom_tile(color = "white", linewidth = 0.8) +
    
    geom_text(
      aes(label = sprintf("%.2f", prop), color = text_color),
      size = 6
    ) +
    
    geom_tile(
      data  = dat %>% filter(is_correct),
      color = "black", linewidth = 1.8, fill = NA
    ) +
    
    scale_fill_gradient(
      low    = "white",
      high   = group_col,
      name   = "Proportion",
      limits = c(0, 1),
      breaks = c(0, 0.25, 0.5, 0.75, 1)
    ) +
    scale_color_identity() +
    scale_y_discrete(limits = rev) +
    
    labs(
      x     = "Perceived Emotion",
      y     = "Actual Emotion",
    ) +
    confusion_theme
}

make_confusion("Control")
make_confusion("ASD")
make_confusion("SAD")