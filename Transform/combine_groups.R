library(dplyr)
library(readxl)


files <- c(
  "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavioral_GroupS_combined.csv",
  "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavioral_GroupC_combined.csv",
  "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavioral_GroupA_combined.csv"
)

combined <- bind_rows(lapply(files, read.csv))

write.csv(combined, 
          "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_behavior/behavior_combined.csv",
          row.names = FALSE,na = "")


files2 <- c(
  "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/GroupA_warped.xlsx",
  "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/GroupC_warped.xlsx",
  "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/GroupS_warped.xlsx"
)

combined2 <- bind_rows(lapply(files2, read_xlsx))

write.csv(combined2, 
          "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_gaze/gaze_combined_warped.csv",
          row.names = FALSE,na = "")

write.table(combined2, 
            "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Cleaned_data/Cleaned_gaze/gaze_combined_warped.txt",
            row.names = FALSE, na = "", sep = ",", col.names = FALSE)