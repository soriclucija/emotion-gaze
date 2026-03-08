# Input and output folders
input_folder  <- "C:/Users/lucij/Desktop/Proto_behavior/Behavior - S/S_txt"
output_folder <- "C:/Users/lucij/Desktop/Proto_behavior/Behavior - S/S_csv"

# Create output folder if needed
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

# Get list of files with exactly three-digit participant numbers
files <- list.files(
  path = input_folder,
  pattern = "^S_P[0-9]{3}\\.txt$",
  full.names = TRUE
)

# Loop over each file
for (file_path in files) {
  
  data <- read.delim(
    file_path,
    header = FALSE,
    sep = "\t",
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-16LE"
  )
  
  # Remove first row
  data <- data[-1, ]
  
  # Use second row as column names
  colnames(data) <- data[1, ]
  
  # Remove that row
  data <- data[-1, ]
  
  # Create output filename
  output_name <- sub("\\.txt$", ".csv", basename(file_path))
  output_path <- file.path(output_folder, output_name)
  
  # Save file
  write.csv(data, output_path, row.names = FALSE)
  
  cat("Saved:", output_name, "\n")
}

cat("All files processed successfully.\n")

