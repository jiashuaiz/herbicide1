setwd("C:/Users/ALEX/Desktop/test1/demo")
getwd()
wDir = getwd()
change_path <- function(path_name){
  if (file.exists(file.path(path_name))){
    setwd(file.path(path_name))
  } else {
    dir.create(file.path(path_name))
    setwd(file.path(path_name))
  }
}

change_path("./demo")
change_path("./demo")
getwd()
setwd(wDir)
getwd()

