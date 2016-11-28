# NHAverageBIFs.R
# Created by Adam Bosen 1/27/16
#
# This script loads the specified processed data files (which must have already been scored), and averages logistic regression across band
# across all subjects included

require(xlsx)
require(ggplot2)
vocoderType = "Rectangular"
subjects = c("NHA87 Keywords Only", "NHA70 Keywords Only", "NHA42 Keywords Only", "NHA94 Keywords Only", "NHA92 Keywords Only")
#vocoderType = "Monopolar"
#subjects = c("NHA48 Keywords Only", "NHA95 Keywords Only", "NHA90 Keywords Only", "NHA93 Keywords Only", "NHA84 Keywords Only")
if(exists('allData'))
{
	remove(allData)
}
for(subjectID in subjects)
{
	blocks = c("Block1", "Block2", "Block3", "Block4", "Block5", "Baseline")
	if(exists('subjectData'))
	{
		remove(subjectData)
	}

	#Get the band definitions for this subject
	parameterFileName = paste("./Subject Parameters/NH_SII_Bands.dat", sep = "")
	parameters = read.csv(parameterFileName, sep = '\t')
	#Sort the parameters so the lowest frequency channels are at the top
	parameters = parameters[order(parameters$Lower.Bound),]
	#Take just the first x channels (the lowest frequency channels), determined by the larger number (typically, 6, 16, or 20)
	parameters = parameters[seq(1,20),]
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
		if(exists('subjectData'))
		{
			subjectData = rbind(subjectData, data)
		} else {
			subjectData = data
		}
	}

	#Convert channel indices to factors
	channelColumns = grep("Channel[0-9]+",names(subjectData))
	subjectData$numChannels = rowSums(subjectData[,channelColumns])
	subjectData[,channelColumns] = lapply(subjectData[,channelColumns],factor,levels=c(0,1),labels = c("off","on"))

	#Build a string that defines the formula, then convert to a formula
	formulaString = paste(c("cbind(Words.Correct,Total.Words - Words.Correct) ~ ",
				sprintf("%s + ",sort(names(subjectData)[channelColumns]))),sep="",collapse= "")
	formulaString = substr(formulaString,1,nchar(formulaString)-3)
	formula = as.formula(formulaString)

	#Run the regression
	test = glm(formula, data = subjectData, family="binomial")
	print(summary(test))

	#Run split sub tests for differences across channels due to talker
	talkerFormulaString = paste(c("cbind(Words.Correct,Total.Words - Words.Correct) ~ ",
				sprintf("%s + ",sort(names(subjectData)[channelColumns]))),sep="",collapse= "")
	talkerFormulaString = substr(talkerFormulaString,1,nchar(talkerFormulaString)-3)
	talkerFormula = as.formula(talkerFormulaString)
	talkerAWTest = glm(talkerFormula, data = subjectData[subjectData$Talker == "AW",], family="binomial")
	print(summary(talkerAWTest)) 
	talkerTATest = glm(talkerFormula, data = subjectData[subjectData$Talker == "TA",], family="binomial")
	print(summary(talkerTATest))

	logodds = coef(test)
	logintercept = logodds[1]
	if(exists('allData'))
	{
		allData = rbind(allData,logodds)
	} else {
		allData = logodds
	}

}

row.names(allData) = subjects

#Average data from all subjects
averageBIF = colMeans(allData)
#Assuming normality, calculate 95% confints for each band
sdBIF = apply(allData,2,sd)
confIntRange = qnorm(0.975)*sdBIF/sqrt(nrow(allData))
upperBound = averageBIF + confIntRange
lowerBound = averageBIF - confIntRange

midBandPoint = (parameters$Lower.Bound + parameters$Upper.Bound)/2
#Fit a quadratic function to the results to guide the eye
polyfit = lm(averageBIF[seq(2,length(averageBIF))] ~ poly(log10(midBandPoint),2))


plot <- ggplot() +
	geom_hline(aes(yintercept = 0), size = 1, colour = "gray90") +
	geom_point(aes(x = rep(midBandPoint,each=nrow(allData)), y = as.vector(allData[,seq(2,length(averageBIF))])), size = 2) +
	coord_cartesian(ylim = c(-.70,1.10), xlim = c(90,11000)) +
	scale_y_continuous( name = "Log Odds", breaks = seq(-2,2,0.20)) +
	scale_x_log10( name = "Frequency", breaks = c(100,200,500,1000,2000,5000,10000)) +
	ggtitle(paste("NH ", vocoderType ," Passband Average",sep="")) +
	theme( panel.background = element_blank(),
	      legend.position = "none",
	      panel.grid.major = element_line(colour = NA), panel.grid.minor = element_line(colour = NA),
	      panel.border = element_rect(colour = "black", fill = NA),
	      plot.title = element_text(size = 16),
	      axis.text.x=element_text(size = 12, colour = "black"), axis.text.y=element_text(size = 12, colour = "black"),
	      axis.title.x = element_text(size = 14, colour = "black"), axis.title.y = element_text(size = 14, colour = "black", angle = 90))
windows()
print(plot)


plot <- ggplot() +
	geom_hline(aes(yintercept = 0), size = 1, colour = "gray80") +
	#geom_line(aes(x = midBandPoint, y = predict(polyfit)),size = 3, colour = "gray70") +
	geom_rect(aes(xmin = parameters$Lower.Bound, xmax = parameters$Upper.Bound,
			 ymin = lowerBound[seq(2,length(lowerBound))], ymax = upperBound[seq(2,length(upperBound))]), size = 1, fill= "gray50") +
	geom_segment(aes(x = parameters$Lower.Bound, xend = parameters$Upper.Bound,
			 y = averageBIF[seq(2,length(averageBIF))], yend = averageBIF[seq(2,length(averageBIF))]), size = 2) +
	coord_cartesian(ylim = c(-.63,1.35), xlim = c(90,11000)) +
	scale_y_continuous( name = "Log Odds", breaks = seq(-0.5,1.5,0.25)) +
	scale_x_log10( name = "Frequency", breaks = c(100,200,500,1000,2000,5000,10000)) +
	ggtitle(paste("NH ", vocoderType ," Passband Average",sep="")) +
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
ggsave(filename = paste("Figures/NH ", vocoderType, " Average Binomial Regression.png",sep=""), width = 6.5, height = 6) 
