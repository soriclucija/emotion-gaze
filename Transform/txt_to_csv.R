input_folder  <- "C:/Users/lucij/Desktop/Proto_behavior/Behavior - S/S_txt"
output_folder <- "C:/Users/lucij/Desktop/Proto_behavior/Behavior - S/S_csv"

# create output folder if needed
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


files <- list.files(
  path = input_folder,
  pattern = "^S_P[0-9]{3}\\.txt$",
  full.names = TRUE
)

for (file_path in files) {
  
  data <- read.delim(
    file_path,
    header = FALSE,
    sep = "\t",
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-16LE"
  )
  
  data <- data[-1, ]
  
  colnames(data) <- data[1, ]
  
  data <- data[-1, ]
  
  output_name <- sub("\\.txt$", ".csv", basename(file_path))
  output_path <- file.path(output_folder, output_name)
  
  write.csv(data, output_path, row.names = FALSE)
  
  cat("Saved:", output_name, "\n")
}

cat("All files processed successfully.\n")

