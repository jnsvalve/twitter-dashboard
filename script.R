
# Source: https://jsta.rbind.io/blog/making-a-twitter-dashboard-with-r/

# Load dependencies

library(rtweet)
library(magrittr)
library(dplyr)
library(DT)


# Setup rtweet

# You should enable R access to the twitter API via an access token.
# See the instructions at http://rtweet.info/articles/auth.html.

# whatever name you assigned to your created app
appname <- "rtweet-tokens-jnsvalve"

# api key
key <- "5lUojPz8j6ou5qAWptMt1Httg"

# api secret
secret <- "XTFA9awlD82ZnfWGXm0jxCZUEkcmhE9JtVtsIFXt7GFX5ZfV3X"

# create token named "twitter_token"
twitter_token <- create_token(
  app = appname,
  consumer_key = key,
  consumer_secret = secret
)


# Saving tokens

# At this point, you technically have enough to start using rtweet functions—you’d just need to set the token argument
# equal to twitter_token (the token object we just created).

# Rather than creating a token every time you open R, remembering where you saved your token(s) or passwords,
# and specifying a token every time you use a function, users are encouraged to save tokens as an environment variable.

# To save a personal access token as an environment variable, save the twitter_token object created earlier in your
# computer’s home directory (to locate your home directory, you can enter normalizePath("~/") into your R console,
# or follow the directions below for what I think is the easiest method).

# Use saveRDS() to save twitter_token to your home directory. The code below should locate and construct the path to
# your home directory for you. Assuming you’ve saved your token as twitter_token, the final line in the code below
# will save your token for you as well.

# path of home directory
home_directory <- path.expand("~/")

# combine with name for token
file_name <- file.path(home_directory, "twitter_token.rds")

# save token to home directory
saveRDS(twitter_token, file = file_name)


# Environment variable

# The last step is to create an environment variable that points to the saved twitter token.
# This makes sure that the token will be read and available to use every time you start R.

# Create a plain text file containing the path to your token object and save it to your home directory as “.Renviron”.

# To create a plain text file in R, modify the code below. Change TWITTER_PAT location to match the path you used
# earlier (in the example below, you’d want to change “/Users/mwk/twitter_token.rds”). You can also create a plain
# text document in any text editor like TextEdit or Notepad.
# If you’re using Rstudio, select File > New File > Text File.

# Important: Make sure the last line of “.Renviron” is blank.
# I achieved this in the code below by including fill = TRUE in the cat function.

# On my mac, the .Renviron text looks like this:
#     TWITTER_PAT=/Users/mwk/twitter_token.rds

# assuming you followed the procodures to create "file_name"
#     from the previous code chunk, then the code below should
#     create and save your environment variable.

cat(paste0("TWITTER_PAT=", file_name),
  file = file.path(home_directory, ".Renviron"),
  append = TRUE
)

# After you’ve setup an access token, you can pull some twitter favorites.
# In order to make things more readable lets select only a few columns and sort the data by descending date.
# For the purposes of this blog post I only show one pull.
# You may want to add a few lines of code here
# to compare the current pull against a previously pulled archive and merge the two.

user_name <- "jnsvalve"
my_likes <- get_favorites(user_name, n = 100) %>%
  select("created_at", "screen_name", "text", "urls_expanded_url") %>%
  arrange(desc("created_at"))

# Datestamp and URL formatting

# Now you may want to deal with the fact that the datestamp includes the time
# (this will take up unnecessary space in our dashboard). Although there are many ways to fix the datestamp,
# I’ll use old-school non-lubridate formatting:

my_likes$created_at <- strptime(as.POSIXct(my_likes$created_at), format = "%Y-%m-%d")
my_likes$created_at <- format(my_likes$created_at, "%Y-%m-%d")

# Another bit of formatting you many want is to make the content URLs clickable.
# In their current form they will simply appear as text.
# I used this stackoverflow tip by BigDataScientist to make the URLs clickable:

createLink <- function(x) {
  if (is.na(x)) {
    return("")
  } else {
    sprintf(paste0(
      '<a href="', URLdecode(x), '" target="_blank">',
      substr(x, 1, 25), "</a>"
    ))
  }
}

my_likes$urls_expanded_url <- lapply(
  my_likes$urls_expanded_url,
  function(x) sapply(x, createLink)
)

# Rendering dashboard

# Finally, we can use the datatable package to create our searchable dashboard.
# The first list of options is passed directly to the DataTables javascript library wrapped by the DT package.
# Here I also set some other options to supress row numbering, fill as much of the browser window as possible,
# and clean up the column name labels. You can read more about datatable adjustments at https://rstudio.github.io/DT/.

# Next, I ran the dashboard through some additional formatting lines to make it more readable
# by decreasing the font size and making the tweet text column larger.

my_table <- datatable(my_likes,
  options = list(
    scrollX = TRUE, autoWidth = TRUE,
    columnDefs = list(list(
      width = "70%",
      targets = c(2)
    ))
  ),
  rownames = FALSE,
  fillContainer = TRUE,
  width = "100%",
  colnames = c("Date", "Handle", "Text", "URL")
)

my_table <- formatStyle(my_table, columns = 1:4, fontSize = "70%")
my_table <- formatStyle(my_table, columns = 3, width = "500px")

# Thats it. We’ve made a searchable twitter favorite dashboard!
# If you are using RStudio you can view it in the Viewer pane by evaluating the dashboard name in the console:

my_table

# You can also save the dashboard for local viewing in a browser with saveWidget
# (the following assumes you use firefox):

temp_file <- tempfile()
saveWidget(my_table, temp_file)

system(paste("firefox", temp_file))

# Finally, you can render your dashboard on a webpage.
# Mine is hosted on my Hugo blogdown site (https://jsta.rbind.io/tweets).
# I found it necessary to embed my dashboard in an iframe using the widgetframe package:

library(widgetframe)

frameWidget(my_table,
  width = "100%", height = 800,
  options = frameOptions(allowfullscreen = TRUE)
)


## create token
twitter_token <- create_token(app = appname, 
                              consumer_key = key, consumer_secret = secret) 

## search tweets with explicit token arg
search_tweets("lang:en", token = twitter_token)

# Regardless of whether the above code works, can you paste the output from the following as well?
  
  ## print TWITTER_PAT environment variable
  Sys.getenv("TWITTER_PAT")

## print token fetched by `get_token()` function
get_token()

## print session info
sessionInfo()