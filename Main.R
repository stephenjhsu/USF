#load the necessary libraries
library(ggplot2)
library(XML)
library(RCurl)
library(dplyr)
#may need to detach("package:plyr", unload=TRUE)

#collect the sites
AlumniUrl <- "https://www.usfca.edu/arts-sciences/graduate-programs/analytics/our-alumni"
Alumnitext <- getURLContent(AlumniUrl)
docstatAlumni <- htmlParse(Alumnitext)
nameAlumni <- xpathSApply(docstatAlumni, '//div[@class="field field-name-body field-type-text-with-summary field-label-hidden typography"]/h3', xmlValue)
degreeAlumni <- xpathSApply(docstatAlumni, '//div[@class="field field-name-body field-type-text-with-summary field-label-hidden typography"]/p', xmlValue)

StudentUrl <- "https://www.usfca.edu/arts-sciences/graduate-programs/analytics/our-students"
Studenttext <- getURLContent(StudentUrl)
docstatStudent <- htmlParse(Studenttext)
nameStudent <- xpathSApply(docstatStudent, '//div[@class="field field-name-body field-type-text-with-summary field-label-hidden typography"]/h3', xmlValue)
degreeStudent <- xpathSApply(docstatStudent, '//div[@class="field field-name-body field-type-text-with-summary field-label-hidden typography"]/p', xmlValue)

AllstudentDegrees <- append(degreeAlumni, degreeStudent)

#Clean the names and data
formatnames <- function(nodes){
      toupper(gsub("^ *(.*[^ ]) *$","\\1",gsub("\\.","",nodes)))
}


#Create clean alumni table and turn it into a list
AllstudentDegrees <- AllstudentDegrees[AllstudentDegrees != ""]
Alllist <- as.list(AllstudentDegrees)

#split list and maintain structure
splitAlllist <- strsplit(as.character(Alllist), ",")
max.length <- max(sapply(splitAlllist, length))
splitAlllist <- lapply(splitAlllist, function(x) { c(x, rep(NA, max.length-length(x)))})
AllTable <- do.call(rbind, splitAlllist)

#Analysis
Completematrix <- matrix(data=NA, nrow=105, ncol=5)
newnames <- c("Degree","Type","College","Country","Year")
colnames(Completematrix) <- newnames

#move columns and fix
AllTable <- gsub("\\.","", AllTable)
Alldf <- as.data.frame(AllTable)
Degreepattern <- "(BA|BS|B Sc|B|MA|MS|M Sc|MBA|PhD)"
Completedf <- data.frame(Completematrix)
Completedf$Degree <- Alldf$V1

#capture all the degrees
grepl(Degreepattern, Completedf$Degree)
totalDegreepattern <- "(BA|BS|Bachelor|B Sc|B Tech|B Eng|MA|MS|M Ed|M Eng|M Phil|M Sc|MBA|PhD|Certificate)"
grepl(totalDegreepattern, Completedf$Degree)
Completedf$Type <- gsub(totalDegreepattern, "", Completedf$Degree)

#somewhat get the college
Completedf$College <- Alldf$V2

#get last value
lastValue <- function(x){
      tail(x[!is.na(x)], 1)
}
Year <- apply(Alldf, 1, lastValue)
Yeardf <- as.data.frame(Year)
Yeardf <- as.numeric(as.character(Yeardf$Year))
Completedf$Year <- Yeardf

#copy alumni
Completedf$Degree <- substring(Completedf$Degree, 1, 3)
Completedf$Degree <- gsub(" ", "", Completedf$Degree)
Completedf$Degree <- as.character(Completedf$Degree)

#delete bad values 
CleanCompleteddf <- Completedf[-c(25, 39, 77, 86),]

#Graphing 

#create a new theme
abluetheme <- theme(plot.background = element_rect(fill = "lightblue", colour = "black", size = 2, linetype = "solid"), 
                    legend.background=element_rect(colour = "black", size = 1, linetype = "solid"), 
                    panel.background=element_rect(colour = "black", size = 2, linetype = "solid"), 
                    plot.title=element_text(size=15))

#find all unique degrees held by all students
CleanCompleteddf %>%
      group_by(Degree) %>%
      summarize(tot=n()) %>%
      ggplot(aes(x=Degree, y = tot)) + geom_point() +
      labs(title="All Types Degrees Held") + ylab("Number of Students") + abluetheme

#find total Bachelors, Masters, PhD held by students 
Alldegreesdf <- CleanCompleteddf 
Alldegreesdf <- Alldegreesdf %>%
      mutate(DegreeType = substring(CleanCompleteddf$Degree, 2,2))
Alldegreesdf$Degree <- substring(Alldegreesdf$Degree, 0,1) 

OverviewDegrees <- Alldegreesdf %>%
      group_by(Degree) %>%
      summarize(tot=n()) %>%
      ggplot(aes(x=Degree, y = tot)) + geom_point() +
      labs(title="Total Degrees Held") + 
      ylab("Number of Students") + abluetheme
OverviewDegrees

#find unique degrees
Alldegrees <- Alldegreesdf %>%
      group_by(Degree) %>%
      summarize(tot=n())
Alldegrees

Uniquedegrees <- Alldegrees
Uniquedegrees$tot <- c(Uniquedegrees$tot[1] - (Uniquedegrees$tot[2]+Uniquedegrees$tot[3]), Uniquedegrees$tot[2] - Uniquedegrees$tot[3], Uniquedegrees$tot[3])

Uniquedegrees %>%
      ggplot(aes(x=factor(Degree), y=tot)) +
      geom_bar(aes(fill=Degree), stat="identity") + 
      labs(title="Highest Degree") + 
      ylab("Number of Students") +
      xlab("Degree type") +
      abluetheme

#find bachelors differences only 
Bachelorsonlydf <- Alldegreesdf
Bachelorsonlydf <- subset(Bachelorsonlydf, Bachelorsonlydf$Degree == "B")

Bachelordegrees <- Bachelorsonlydf %>%
      group_by(DegreeType) %>%
      summarize(tot=n()) %>%
      ggplot(aes(x=factor(DegreeType), y=tot)) + 
      geom_bar(aes(fill=DegreeType), stat="identity") +
      labs(title="Bachelor Degree Types") + 
      xlab("Degree Type") +
      ylab("Number of Students") +
      abluetheme
Bachelordegrees

Bacheloryear <- Bachelorsonlydf %>%
      group_by(DegreeType, Year) %>%
      summarize(tot=n()) %>%
      ggplot(aes(x=factor(DegreeType), y=tot)) + 
      facet_wrap(~Year) +
      geom_bar(aes(fill=DegreeType), stat="identity") +
      labs(title="Bachelor Degree Types Per Year") + 
      xlab("Degree Type") +
      ylab("Number of Students") +
      abluetheme
Bacheloryear


