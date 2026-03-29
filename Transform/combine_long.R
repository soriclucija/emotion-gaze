library(dplyr)
library(readr)


behav_dir <- "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Complete_data/Proto_behavior/Behavior - S/S_csv"
out_path  <- "C:/Users/lucij/Desktop/Leiden/Year 2/Internship/Data/Complete_data/Proto_behavior/Behavior - S/behavioral_GroupS_combined.csv"


files <- sort(list.files(behav_dir, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE))

if (length(files) == 0) {
  stop(paste("No CSV files found in:", behav_dir))
}

cat(sprintf("Found %d CSV files.\n\n", length(files)))

combined_df <- lapply(files, function(filepath) {
  
  basename_no_ext <- tools::file_path_sans_ext(basename(filepath))
  match <- regmatches(basename_no_ext, regexpr("P\\d+", basename_no_ext, ignore.case = TRUE))
  
  if (length(match) == 0) {
    stop(paste("Could not extract sub_id from filename:", basename(filepath)))
  }
  
  sub_id <- toupper(match)

  df <- read_csv(filepath, col_types = cols(.default = col_character()), show_col_types = FALSE)
  
  df <- df %>% mutate(sub_id = sub_id, .before = 1)
  
  cat(sprintf("  v %s  ->  sub_id: %s  (%s rows)\n", basename(filepath), sub_id, format(nrow(df), big.mark = ",")))
  
  df
  
}) %>% bind_rows()

combined_df <- combined_df %>%
  mutate(across(everything(), ~ {
    converted <- suppressWarnings(as.numeric(.x))
    if (all(is.na(converted) == is.na(.x))) converted else .x
  }))

write_csv(combined_df, out_path, na = "")

cat(sprintf("\nDone! Combined file saved to:\n  %s\n", out_path))
cat(sprintf("  Total rows  : %s\n", format(nrow(combined_df), big.mark = ",")))
cat(sprintf("  Participants: %d  ->  %s\n",
            n_distinct(combined_df$sub_id),
            paste(sort(unique(combined_df$sub_id)), collapse = ", ")))