%EstimateBIFSensitivity.m
%
% This script estimates bias and variance in BIF estimates as a function of subject
% accuracy and number of experimental trials.

%Assume that the average NH BIF is the true function, these values come from results of NHAverageBIFs.R
%These values are in log odds, on an natural log scale
trueImportances = [-0.152 0.023 0.135 0.0401 0.316 0.167 0.497 0.260 0.478 0.374 0.566 0.547 0.298 0.336 0.281 0.336 0.029 0.062 0.285 0.087];
intercept = -1.922;
%Points to sample in the simulations
nTrials = [40 80 120 160 240 320 400 680];
nBaselineTrials = 40;
bandsPerTrial = 7;
nBands = length(trueImportances);

baselineSentences = 681:720;

%nRuns determines the number of repetitions of each sampled point in the stimulation
nRuns = 30;



%Find the number of words in each actual sentence in the IEEE list
ANSWER_KEY_FILE_NAME = '.\Sound Files\IEEE3_FILE_NAMES.TXT'; 
%Load the correct sentence list. The male and female lists are actually the same, just differ by file name
answerKeyFileHandle = fopen(ANSWER_KEY_FILE_NAME,'r');
sentenceRead = textscan(answerKeyFileHandle,'%s','Delimiter','\n');
sentenceRead = sentenceRead{1};
%Go through the read file, build a results table
sentenceTable = table();
for(fileLine = 1:length(sentenceRead))
	fileName = char(regexp(sentenceRead{fileLine},'ieee\\.*\.wav ','match'));
	fileName = fileName(8:length(fileName)-5);
	sentence = char(regexp(sentenceRead{fileLine},' .*','match'));
	sentence = sentence(2:length(sentence)-1);
	if(fileName)
		%If this line actually contains a sentence add it to the table
		sentenceTable = [sentenceTable;table({fileName},{sentence})];
	end

end
sentenceTable.Properties.VariableNames = {'fileNames' 'Sentences'};
wordsInSentence = cellfun(@(x) (sum(x == ' ') + sum(x == '-') + 1),sentenceTable.Sentences); 
fclose(answerKeyFileHandle);


%Iterate through the simulated number of trials 
simulatedResults = struct;
for(nTrialsIndex = 1:length(nTrials))
	experimentSentences = 1:nTrials(nTrialsIndex);
	simulatedResults(nTrialsIndex).nTrials = nTrials(nTrialsIndex);
	disp(['Testing Number of Trials : ' num2str(nTrials(nTrialsIndex))]);

	%Go through the experiment sequence trial by trial, simulate the number of words correct with those bands present
	fits = zeros(nRuns,length(trueImportances)+1);
	measuredAccuracy = zeros(nRuns,1);
	for(runIndex = 1:nRuns)
		disp(['** Simulation run: ' num2str(runIndex)]);
		sentenceOrder = [randsample(experimentSentences,nTrials(nTrialsIndex)) baselineSentences];
		%ChannelOn is a binary matrix that marks the presence or absence of a band on each trial
		channelOn = [zeros(nTrials(nTrialsIndex),nBands); ones(nBaselineTrials,nBands)];
		%Build the experiment sequence for this run
		[maleTalkerTrialMatrix femaleTalkerTrialMatrix] = ChooseTargetTrials(nTrials(nTrialsIndex)/2, nBands, bandsPerTrial, 100);
		experimentSequence = [maleTalkerTrialMatrix; femaleTalkerTrialMatrix];
		for(trialIndex = 1:size(experimentSequence,1))
			bandsInTrial = experimentSequence(trialIndex,:);
			channelOn(trialIndex,bandsInTrial) = 1;
		end

		%Simulate the subject response for each trial in this run
		totalWords = zeros(nTrials(nTrialsIndex),1);
		wordsCorrect = zeros(nTrials(nTrialsIndex),1);
		for(trialIndex = 1:size(channelOn,1))
			logOdds = sum(trueImportances(logical(channelOn(trialIndex,:)))) + intercept;
			chanceCorrect = exp(logOdds)/(1+exp(logOdds));
			%Get the number of words per trial.
			totalWords(trialIndex) = wordsInSentence(sentenceOrder(trialIndex));
			wordsCorrect(trialIndex) = sum(binornd(totalWords(trialIndex),chanceCorrect));
		end

		%Perform logistic regression on simulated data
		fits(runIndex,:) = glmfit(channelOn,[wordsCorrect totalWords],'binomial')';
		measuredAccuracy(runIndex,:) = sum(wordsCorrect(1:nTrials(nTrialsIndex)))/sum(totalWords(1:nTrials(nTrialsIndex)));
	end
	simulatedResults(nTrialsIndex).fits = fits;
	simulatedResults(nTrialsIndex).measuredAccuracy = measuredAccuracy;
end


figure;
for(nTrialsIndex = 1:length(nTrials))
	subplotHandle(nTrialsIndex) = subplot(2,4,nTrialsIndex);
	hold off; plot(trueImportances,'-b'); hold on; plot(simulatedResults(nTrialsIndex).fits(:,2:size(simulatedResults(nTrialsIndex).fits,2))','r*');
	title(['Number of Trials: ' num2str(nTrials(nTrialsIndex))]);
	maxErrorPerRun(nTrialsIndex,:) = max(abs(simulatedResults(nTrialsIndex).fits(:,2:size(simulatedResults(nTrialsIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1))');
	meanErrorPerRun(nTrialsIndex,:) = mean(abs(simulatedResults(nTrialsIndex).fits(:,2:size(simulatedResults(nTrialsIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1))');
	averageMaxError(nTrialsIndex) = mean(maxErrorPerRun(nTrialsIndex,maxErrorPerRun(nTrialsIndex,:)<2));
	averageMeanError(nTrialsIndex) = mean(meanErrorPerRun(nTrialsIndex,meanErrorPerRun(nTrialsIndex,:)<2)); 
	meanBiasPerChannel(nTrialsIndex,:) = mean(simulatedResults(nTrialsIndex).fits(:,2:size(simulatedResults(nTrialsIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1));
	STDPerRun(nTrialsIndex,:) = std((simulatedResults(nTrialsIndex).fits(:,2:size(simulatedResults(nTrialsIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1))');
	meanSTDPerChannel(nTrialsIndex,:) = std(simulatedResults(nTrialsIndex).fits(:,2:size(simulatedResults(nTrialsIndex).fits,2)));


	%Hacky test to estimate distribution of mean absolute differences between a test and a retest
	for(retestIndex = 1:240)
		%Choose two random simulation runs to pit against each other
		runs = randsample(1:nRuns,2,false);
		meanAbsDifference(retestIndex) = mean(abs(simulatedResults(nTrialsIndex).fits(runs(1),2:size(simulatedResults(nTrialsIndex).fits,2)) -...
							simulatedResults(nTrialsIndex).fits(runs(2),2:size(simulatedResults(nTrialsIndex).fits,2))));
		maxAbsDifference(retestIndex) = max(abs(simulatedResults(nTrialsIndex).fits(runs(1),2:size(simulatedResults(nTrialsIndex).fits,2)) -...
							simulatedResults(nTrialsIndex).fits(runs(2),2:size(simulatedResults(nTrialsIndex).fits,2))));
	end
	meanAbsDifference = sort(meanAbsDifference);
	maxAbsDifference = sort(maxAbsDifference);
	distMeanMAD(nTrialsIndex) = mean(meanAbsDifference);
	lowerBoundMAD(nTrialsIndex) = meanAbsDifference(7);
	upperBoundMAD(nTrialsIndex) = meanAbsDifference(234);
	distMeanMaxAD(nTrialsIndex) = mean(maxAbsDifference);
	lowerBoundMaxAD(nTrialsIndex) = maxAbsDifference(7);
	upperBoundMaxAD(nTrialsIndex) = maxAbsDifference(234);


end
linkaxes(subplotHandle,'xy');

figure;
plot([simulatedResults.nTrials]',abs(meanErrorPerRun),'ko');
hold on;
plot([simulatedResults.nTrials]',maxErrorPerRun,'r+');
plot([simulatedResults.nTrials],averageMeanError,'k-','LineWidth',1.5);
plot([simulatedResults.nTrials],averageMaxError,'r-','LineWidth',1.5);
ylabel('Absolute Error (log odds)');
xlabel('Number of Experimental Trials');
axis([0 700 0 1.55]);
set(gca,'FontSize',10,'XTick',nTrials);
set(gcf,'PaperPosition', [0 0 7.5 3]);
print('Figures\Manuscript\SensitivityToNumberOfTrials','-dpng','-r300');

