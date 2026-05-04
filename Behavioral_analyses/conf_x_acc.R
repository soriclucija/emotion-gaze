# ============================================================================
#  Confidence x Accuracy calibration plots
#  Plot 1: overall | Plot 2: 2x2 per emotion
# ============================================================================

library(tidyverse)
library(ggplot2)
library(patchwork)

df <- read_csv("C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavior_task2_final.csv")

df <- df %>%
  mutate(
    Group = dplyr::recode(Group, "A" = "ASD", "C" = "Control", "S" = "SAD"),
    Group = factor(Group, levels = c("Control", "ASD", "SAD")),
    EmotionLabel = factor(EmotionLabel,
                          levels = c("Anger", "Fear", "Happiness",
                                     "Neutral", "Sadness")),
    Labeling_Accuracy = as.numeric(Labeling_Accuracy)
  )

group_colors <- c(
  "ASD"     = "#4f6d7a",
  "SAD"     = "#ffc857",
  "Control" = "#3CC8C0"
)

cal_theme <- theme_classic(base_size = 16) +
  theme(
    text             = element_text(family = "sans"),
    axis.line        = element_line(linewidth = 1.5, color = "black"),
    axis.text        = element_text(size = 16),
    axis.title       = element_text(size = 20),
    axis.title.y     = element_text(margin = margin(r = 20)),
    legend.position  = "right",
    legend.title     = element_blank(),          # removed legend title
    legend.text      = element_text(size = 18),
    strip.background = element_blank(),
    strip.text       = element_text(size = 16, face = "bold")
  )


# ── PLOT 1 — overall (all emotions combined) ──────────────────────────────────

cal_data <- df %>%
  group_by(Subject, Group) %>%
  summarise(
    mean_conf = mean(Confidence),
    mean_acc  = mean(Labeling_Accuracy),
    .groups   = "drop"
  )

ggplot(cal_data, aes(x = mean_conf, y = mean_acc, color = Group)) +
  
  geom_point(size = 2.5, alpha = 0.6) +
  
  geom_smooth(
    aes(fill = Group),
    method    = "lm",
    se        = TRUE,
    linewidth = 1.2,
    alpha     = 0.2
  ) +
  
  scale_color_manual(values = group_colors) +
  scale_fill_manual(values  = group_colors) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  
  labs(x = "Mean Confidence", y = "Mean Accuracy") +
  cal_theme


# ── PLOT 2 — 2x2 grid, one plot per emotion ───────────────────────────────────

cal_data_emo <- df %>%
  filter(EmotionLabel != "Happiness") %>%
  group_by(Subject, Group, EmotionLabel) %>%
  summarise(
    mean_conf = mean(Confidence),
    mean_acc  = mean(Labeling_Accuracy),
    .groups   = "drop"
  )

emotions <- c("Anger", "Fear", "Neutral", "Sadness")

# build one plot per emotion, suppress legend on all but the last
plots <- map(emotions, function(emo) {
  
  is_last <- emo == emotions[length(emotions)]
  
  cal_data_emo %>%
    filter(EmotionLabel == emo) %>%
    ggplot(aes(x = mean_conf, y = mean_acc, color = Group)) +
    
    geom_point(size = 2, alpha = 0.5) +
    
    geom_smooth(
      aes(fill = Group),
      method    = "lm",
      se        = TRUE,
      linewidth = 1.2,
      alpha     = 0.2
    ) +
    
    scale_color_manual(values = group_colors) +
    scale_fill_manual(values  = group_colors) +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    
    labs(
      x     = "",
      y     = "",
      title = emo,
    ) +
    cal_theme +
    # only show legend on last panel, hide on others to avoid repetition
    theme(legend.position = if (is_last) "right" else "none")
})

# combine into 2x2
(plots[[1]] | plots[[2]]) / (plots[[3]] | plots[[4]])