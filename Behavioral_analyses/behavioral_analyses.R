library(tidyverse)
library(lme4)
library(lmerTest) 
library(car)
library(emmeans)
library(ggplot2)
library(ggdist)
library(scales)

df <- read_csv("C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavior_task2_final.csv")

df <- df %>%
  mutate(
    Group = dplyr::recode(Group, "A" = "ASD", "C" = "Control", "S" = "SAD"),
    Group = factor(Group, levels = c("Control", "ASD", "SAD")),
    
    Participant_Gender = factor(Participant_Gender),
    Video_Gender       = factor(Video_Gender),
    EmotionLabel       = factor(EmotionLabel,
                                levels = c("Anger","Fear","Happiness","Neutral","Sadness")),
    PerceivedEmotion   = factor(PerceivedEmotion,
                                levels = c("Anger","Fear","Happiness","Neutral","Sadness")),
    Labeling_Accuracy  = as.numeric(Labeling_Accuracy),
    
    Actor = factor(str_extract(Stimuli, "^[0-9]+"))
  )

cat("── Participants per group ──\n")
df %>% distinct(Subject, Group) %>% count(Group) %>% print() 

cat("\n── Emotions ──\n")
print(levels(df$EmotionLabel))

cat("\n── Actors ──\n")
print(levels(df$Actor))

cat("\n── Missing values ──\n")
print(colSums(is.na(df)))

# descriptives
df_subj <- df %>%
  group_by(Subject, Group, EmotionLabel) %>%
  summarise(
    acc     = mean(Labeling_Accuracy),
    conf    = mean(Confidence),
    intense = mean(Intensity),
    .groups = "drop"
  )

summary_table <- df_subj %>%
  group_by(Group, EmotionLabel) %>%
  summarise(
    N           = n(),
    Acc_mean    = round(mean(acc), 3),
    Acc_SD      = round(sd(acc), 3),
    Conf_mean   = round(mean(conf), 1),
    Conf_SD     = round(sd(conf), 1),
    Int_mean    = round(mean(intense), 1),
    Int_SD      = round(sd(intense), 1),
    .groups     = "drop"
  )

cat("\n── Summary table ──\n")
print(summary_table, n = Inf)


# MIXED MODELS
df_no_happy <- df %>%
  filter(EmotionLabel != "Happiness") %>%
  mutate(
    EmotionLabel = droplevels(EmotionLabel), # excl happiness bc of ceiling effect
    # center confidence and intensity to fix convergence and aid interpretation
    Confidence_c = scale(Confidence, center = TRUE, scale = FALSE),
    Intensity_c  = scale(Intensity,  center = TRUE, scale = FALSE)
  )

# 1
m_acc <- glmer(
  Labeling_Accuracy ~ Group * EmotionLabel + (1|Subject) + (1|Actor),
  data    = df_no_happy,
  family  = binomial,
  control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
)

print(summary(m_acc))
print(Anova(m_acc, type = 3))

emm_acc <- emmeans(m_acc, ~ Group | EmotionLabel, type = "response")
print(emm_acc)

pairs_acc <- pairs(emm_acc, adjust = "fdr")
print(pairs_acc)

# odds ratio for accuracy per group x emotion interaction
or_table <- as.data.frame(coef(summary(m_acc)))
or_table$OR     <- exp(or_table$Estimate)
or_table$OR_low <- exp(or_table$Estimate - 1.96 * or_table$`Std. Error`)
or_table$OR_hi  <- exp(or_table$Estimate + 1.96 * or_table$`Std. Error`)
print(round(or_table[, c("OR","OR_low","OR_hi","Pr(>|z|)")], 3))


# 2 - accuracy controlling for confidence and intensity (centered)
m_ca_group <- glmer(
  Labeling_Accuracy ~ Group * EmotionLabel + Confidence_c + Intensity_c + (1|Subject) + (1|Actor),
  data    = df_no_happy,
  family  = binomial,
  control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
)

print(summary(m_ca_group))
print(Anova(m_ca_group, type = 3))

emm_acc_ci <- emmeans(m_ca_group, ~ Group | EmotionLabel, type = "response")
print(emm_acc_ci)

pairs_acc_ci <- pairs(emm_acc_ci, adjust = "fdr")
print(pairs_acc_ci)

# model comparison - does adding confidence and intensity improve fit?
anova(m_acc, m_ca_group)

# odds ratio for accuracy per group x emotion interaction while controlling for confidence and intensity
or_ca <- as.data.frame(coef(summary(m_ca_group)))
or_ca$OR     <- exp(or_ca$Estimate)
or_ca$OR_low <- exp(or_ca$Estimate - 1.96 * or_ca$`Std. Error`)
or_ca$OR_hi  <- exp(or_ca$Estimate + 1.96 * or_ca$`Std. Error`)
print(round(or_ca[, c("OR","OR_low","OR_hi","Pr(>|z|)")], 3))


# 3 - confidence per group x emotion
m_conf <- lmer(
  Confidence ~ Group * EmotionLabel + (1|Subject) + (1|Actor),
  data = df_no_happy
)

print(summary(m_conf))
print(Anova(m_conf, type = 3))

emm_conf <- emmeans(m_conf, ~ Group | EmotionLabel)
print(emm_conf)

pairs_conf <- pairs(emm_conf, adjust = "fdr")
print(pairs_conf)


# 4 - intensity per group x emotion
m_int <- lmer(
  Intensity ~ Group * EmotionLabel + (1|Subject) + (1|Actor),
  data = df_no_happy
)

print(summary(m_int))
print(Anova(m_int, type = 3))

emm_int <- emmeans(m_int, ~ Group | EmotionLabel)
print(emm_int)

pairs_int <- pairs(emm_int, adjust = "fdr")
print(pairs_int)
