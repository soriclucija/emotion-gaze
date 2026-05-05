library(readxl)
library(writexl)
library(stringr)
library(dplyr)


gaze_path  <- "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Updated_data/fixationCoordDataAllPs_image_GroupS_combinedEye.xlsx"
behav_dir  <- "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Complete_data/Proto_behavior/Behavior - S/S_csv" #change name when needed
out_path   <- "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/GroupS_warped.xlsx"


extract_group <- function(filename) {
  match <- str_match(basename(filename), regex("Group([A-Za-z0-9]+)", ignore_case = TRUE))
  if (is.na(match[1, 2])) {
    stop(paste(
      "Could not find a 'GroupX' pattern in gaze filename:", filename,
      "\nExpected something like 'fixmat_AllPs_Table_GroupA_combinedEye.xlsx'"
    ))
  }
  match[1, 2]
}


extract_sub_id <- function(filename) {
  basename_no_ext <- tools::file_path_sans_ext(basename(filename))
  match <- str_match(basename_no_ext, regex("(P\\d+)", ignore_case = TRUE))
  if (is.na(match[1, 2])) {
    stop(paste(
      "Could not extract sub_id (e.g. P033) from filename:", filename,
      "\nCheck the regex in extract_sub_id() and adjust if needed."
    ))
  }
  toupper(match[1, 2])
}


build_participant_map <- function(behav_dir) {
  files <- sort(list.files(
    behav_dir,
    pattern     = "\\.(xlsx|xls|csv)$",
    full.names  = FALSE,
    ignore.case = TRUE
  ))
  
  if (length(files) == 0) {
    stop(paste("No Excel/CSV files found in behavioral folder:", behav_dir))
  }
  
  sub_ids <- sapply(files, extract_sub_id)
  
  map_df <- data.frame(
    participant = seq_along(files),
    sub_id      = unname(sub_ids),
    source_file = files,
    stringsAsFactors = FALSE
  )
  
  cat("\nParticipant mapping:\n")
  for (i in seq_len(nrow(map_df))) {
    cat(sprintf("  Participant %3d  →  %s  (%s)\n",
                map_df$participant[i], map_df$sub_id[i], map_df$source_file[i]))
  }
  
  map_df
}


group <- extract_group(gaze_path)
cat(sprintf("\n✓ Group extracted from filename: '%s'\n", group))

cat(sprintf("\nBuilding participant map from: %s\n", behav_dir))
participant_map <- build_participant_map(behav_dir)
cat(sprintf("\n✓ %d participants mapped.\n", nrow(participant_map)))

cat(sprintf("\nLoading gaze file: %s\n", gaze_path))
df <- read_excel(gaze_path)
cat(sprintf("  Rows: %s  |  Columns: %s\n",
            format(nrow(df), big.mark = ","),
            paste(colnames(df), collapse = ", ")))

gaze_participants <- sort(unique(df$Participant))
missing <- setdiff(gaze_participants, participant_map$Participant)
if (length(missing) > 0) {
  stop(sprintf(
    "These participant numbers in the gaze file have no matching behavioral file: %s\n
    Gaze file has %d unique participants; behavioral folder has %d files.",
    paste(missing, collapse = ", "),
    length(gaze_participants),
    nrow(participant_map)
  ))
}

# add sub_id and group column
df <- df %>%
  left_join(participant_map %>% select(participant, sub_id), by = "participant") %>%
  mutate(group = group)

write_xlsx(df, out_path)
cat(sprintf("\n✓ Done! Output saved to: %s\n", out_path))
cat(sprintf("  Rows: %s  |  New columns: sub_id, group\n",
            format(nrow(df), big.mark = ",")))

cat("\nSample of added columns:\n")
df %>%
  select(participant, sub_id, group) %>%
  distinct() %>%
  head(10) %>%
  print()