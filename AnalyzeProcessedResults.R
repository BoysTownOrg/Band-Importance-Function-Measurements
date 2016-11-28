# AnalyzeProcessedResults.R 
# Created by Adam Bosen 10/21/15
#
# This script loads the specified processed data file (which must have already been scored), and performs logistic regression using each band as
# a predictive factor for speech intelligibility

require(xlsx)
require(ggplot2)
#NOTE: MAKE SURE YOU CHANGE subjectID, parameterFileName, nBands, and blocks FOR EACH SUBJECT ACCORDINGLY.  Otherwise you'll generate
#inaccurate figures, and there won't be any errors to tell you as such.
subjectID = "N7 Keywords Only"
#Get the band definitions for this subject
parameterFileName = "./Subject Parameters/N7_Right_Ear.dat"
#parameterFileName = paste("./Subject Parameters/",subjectID, "_Right_Ear.dat", sep = "")
nBands = 20
blocks = c("Block1", "Block2", "Block3", "Block4", "Block5", "Baseline")

if(exists('alldata'))
{
	remove(alldata)
}

parameters = read.csv(parameterFileName, sep = '\t')
#Sort the parameters so the lowest frequency channels are at the top
parameters = parameters[order(parameters$Lower.Bound),]
#Take just the first x channels (the lowest frequency channels), determined by the larger number (typically, 8, 16, or 20)
parameters = parameters[seq(1,nBands),]
#re-sort parameters so lowest channel number is first
parameters = parameters[order(parameters$Channel.Number),]

#Read the results for each file
for(block in blocks)
{
	scoredFileName = paste("./Processed Results/",subjectID,"/",subjectID, " ",block,".xlsx", sep = "")

	scoredData = read.xlsx(scoredFileName, sheetIndex = 1)

	#Build a data frame from the two files
	data = scoredData[!is.na(scoredData$Trial.Number),]
	#Go through each trial, find the active channels and mark them in the data frame
	for(trialIndex in data$Trial.Number)
	{
		channelString = toString(data$Active.Channels[data$Trial.Number == trialIndex])
		#Chop off extra characters
		channelString = substr(channelString,1,nchar(channelString) - 1)
		#Split into channel names
		channels = strsplit(channelString,split = '_')
		for(channelName in channels[[1]])
		{
			data[data$Trial.Number == trialIndex,paste('Channel',channelName,sep = "")] = 1
		}
	}
	#Find all the NAs that this introduced, replace them with zeros
	data[is.na(data)] = 0
	if(exists('alldata'))
	{
		alldata = rbind(alldata, data)
	} else {
		alldata = data
	}
}

#Convert channel indices to factors
channelColumns = grep("Channel[0-9]+",names(alldata))
alldata$numChannels = rowSums(alldata[,channelColumns])
alldata[,channelColumns] = lapply(alldata[,channelColumns],factor,levels=c(0,1),labels = c("off","on"))

#Build a string that defines the formula, then convert to a formula
formulaString = paste(c("cbind(Words.Correct,Total.Words - Words.Correct) ~ ",
			sprintf("%s + ",sort(names(alldata)[channelColumns]))),sep="",collapse= "")
formulaString = substr(formulaString,1,nchar(formulaString)-3)
formula = as.formula(formulaString)

#Run the regression
test = glm(formula, data = alldata, family="binomial")
print(summary(test))

#Run split sub tests for differences across channels due to talker
talkerFormulaString = paste(c("cbind(Words.Correct,Total.Words - Words.Correct) ~ ",
			sprintf("%s + ",sort(names(alldata)[channelColumns]))),sep="",collapse= "")
talkerFormulaString = substr(talkerFormulaString,1,nchar(talkerFormulaString)-3)
talkerFormula = as.formula(talkerFormulaString)
talkerAWTest = glm(talkerFormula, data = alldata[alldata$Talker == "AW",], family="binomial")
print(summary(talkerAWTest)) 
talkerTATest = glm(talkerFormula, data = alldata[alldata$Talker == "TA",], family="binomial")
print(summary(talkerTATest))

logodds = coef(test)
logintercept = logodds[1]
intercept = exp(logintercept)/(exp(logintercept)+1)
probabilities = exp(logodds[seq(2,length(logodds))] + logintercept)/(exp(logodds[seq(2,length(logodds))] + logintercept)+1)
logconfint = confint(test)
confint = exp(logconfint[seq(2,nrow(logconfint)),] + logintercept)/(exp(logconfint[seq(2,nrow(logconfint)),] + logintercept)+1)

midBandPoint = (parameters$Lower.Bound + parameters$Upper.Bound)/2

#Fit a quadratic function to the results to guide the eye
polyfit = lm(logodds[seq(2,length(logodds))] ~ poly(log10(midBandPoint),2))

#Print out statistics summarizing performance
baselineIndex = apply(alldata[,channelColumns] == "on", 1, all)
print(paste("Baseline performance:",round(sum(alldata$Words.Correct[baselineIndex])/sum(alldata$Total.Words[baselineIndex]),2)))
print(paste("    male talker only:",round(sum(alldata$Words.Correct[baselineIndex & alldata$Talker == "TA"])/
					  sum(alldata$Total.Words[baselineIndex & alldata$Talker == "TA"]),2)))
print(paste("  female talker only:",round(sum(alldata$Words.Correct[baselineIndex & alldata$Talker == "AW"])/
					  sum(alldata$Total.Words[baselineIndex & alldata$Talker == "AW"]),2)))
print(paste("Experiment performance:",round(sum(alldata$Words.Correct[!baselineIndex])/sum(alldata$Total.Words[!baselineIndex]),2)))
print(paste("      male talker only:",round(sum(alldata$Words.Correct[!baselineIndex & alldata$Talker == "TA"])/
					  sum(alldata$Total.Words[!baselineIndex & alldata$Talker == "TA"]),2)))
print(paste("    female talker only:",round(sum(alldata$Words.Correct[!baselineIndex & alldata$Talker == "AW"])/
					  sum(alldata$Total.Words[!baselineIndex & alldata$Talker == "AW"]),2)))
print(paste("Log intercept:",round(logintercept,3)))
print(paste("Average sum log channel contribution:",round((min(alldata$numChannels)/max(alldata$numChannels)) * sum(logodds[seq(2,length(logodds))]),3)))

#Run this histogram to check the distribution of sentence recognition scores in the experiment set
#hist(alldata$Words.Correct[!baselineIndex]/alldata$Total.Words[!baselineIndex])

plot <- ggplot() +
	geom_hline(aes(yintercept = 0), size = 1, colour = "gray80") +
	#geom_line(aes(x = midBandPoint, y = predict(polyfit)),size = 3, colour = "gray70") +
	geom_segment(aes(x = midBandPoint, xend = midBandPoint,
			 #y = confint[,1] - intercept, yend = confint[,2] - intercept), size = 1, colour = "gray50") +
			 y = logconfint[seq(2,nrow(logconfint)),1], yend = logconfint[seq(2,nrow(logconfint)),2]), size = 1, colour = "gray50") +
	geom_segment(aes(x = parameters$Lower.Bound, xend = parameters$Upper.Bound,
			 y = logodds[seq(2,length(logodds))], yend = logodds[seq(2,length(logodds))]), size = 2) +
			 #y = probabilities - intercept, yend = probabilities - intercept), size = 2) +
	coord_cartesian(ylim = c(-.63,1.35), xlim = c(90,11000)) +
	scale_y_continuous( name = "Log Odds", breaks = seq(-0.5,1.5,0.25)) +
	scale_x_log10( name = "Frequency", breaks = c(100,200,500,1000,2000,5000,10000)) +
	ggtitle(subjectID) +
	theme( panel.background = element_blank(),
	      legend.position = "none",
	      panel.grid.major = element_line(colour = "gray90"), panel.grid.minor = element_line(colour = NA),
	      panel.border = element_rect(colour = "black", fill = NA),
	      plot.title = element_text(size = 16),
	      axis.ticks.length=unit(-0.0625,"in"),
	      axis.text.x=element_text(size = 16, colour = "black",margin = margin(10,10,0,11,"pt")),
	      axis.text.y=element_text(size = 16, colour = "black",margin = margin(0,11,10,10,"pt")),
	      axis.title.x = element_text(size = 18, colour = "black"), axis.title.y = element_text(size = 18, colour = "black", angle = 90))
windows()
print(plot)
ggsave(filename = paste("Figures/",subjectID," Binomial Regression.png",sep=""), width = 6.5, height = 6)


#Talker-specific curves
talkerAWLogodds = coef(talkerAWTest)
talkerAWLogconfint = confint(talkerAWTest) 
talkerAWPolyfit = lm(talkerAWLogodds[seq(2,length(talkerAWLogodds))] ~ poly(log10(midBandPoint),2)) 
talkerTALogodds = coef(talkerTATest)
talkerTALogconfint = confint(talkerTATest) 
talkerTAPolyfit = lm(talkerTALogodds[seq(2,length(talkerTALogodds))] ~ poly(log10(midBandPoint),2)) 
print(paste("  Male talker channel CoG:",round(sum(talkerTALogodds[seq(2,length(logodds))]*seq(1,length(logodds)-1))/
					       sum(talkerTALogodds[seq(2,length(logodds))]),2)))
print(paste("Female talker channel CoG:",round(sum(talkerAWLogodds[seq(2,length(logodds))]*seq(1,length(logodds)-1))/
					       sum(talkerAWLogodds[seq(2,length(logodds))]),2)))

plot <- ggplot() +
	geom_hline(aes(yintercept = 0), size = 1, colour = "gray90") +
	#geom_line(aes(x = midBandPoint, y = predict(talkerAWPolyfit)),size = 3, colour = "red3") +
	#geom_line(aes(x = midBandPoint, y = predict(talkerTAPolyfit)),size = 3, colour = "blue3") +
	geom_segment(aes(x = midBandPoint, xend = midBandPoint,
			 y = talkerAWLogconfint[seq(2,nrow(talkerAWLogconfint)),1], 
			 yend = talkerAWLogconfint[seq(2,nrow(talkerAWLogconfint)),2]), size = 1, colour = "gray50") +
	geom_segment(aes(x = midBandPoint, xend = midBandPoint,
			 y = talkerTALogconfint[seq(2,nrow(talkerTALogconfint)),1], 
			 yend = talkerTALogconfint[seq(2,nrow(talkerTALogconfint)),2]), size = 1, colour = "gray50") +
	geom_segment(aes(x = parameters$Lower.Bound, xend = parameters$Upper.Bound,
			 y = talkerAWLogodds[seq(2,length(talkerAWLogodds))],
			 yend = talkerAWLogodds[seq(2,length(talkerAWLogodds))]), colour = "red", size = 2) +
	geom_segment(aes(x = parameters$Lower.Bound, xend = parameters$Upper.Bound,
			 y = talkerTALogodds[seq(2,length(talkerTALogodds))],
			 yend = talkerTALogodds[seq(2,length(talkerTALogodds))]), colour = "blue", size = 2) +
	coord_cartesian(ylim = c(-.90,1.55), xlim = c(90,11000)) +
	scale_y_continuous( name = "Log Odds", breaks = seq(-2,2,0.20)) +
	scale_x_log10( name = "Frequency", breaks = c(100,200,500,1000,2000,5000,10000)) +
	ggtitle(subjectID) +
	theme( panel.background = element_blank(),
	      legend.position = "none",
	      panel.grid.major = element_line(colour = NA), panel.grid.minor = element_line(colour = NA),
	      panel.border = element_rect(colour = "black", fill = NA),
	      plot.title = element_text(size = 16),
	      axis.text.x=element_text(size = 12, colour = "black"), axis.text.y=element_text(size = 12, colour = "black"),
	      axis.title.x = element_text(size = 14, colour = "black"), axis.title.y = element_text(size = 14, colour = "black", angle = 90))
windows()
print(plot)
#ggsave(filename = paste("Figures/",subjectID," Talker-Specific Binomial Regression.png",sep=""), width = 6, height = 6)
