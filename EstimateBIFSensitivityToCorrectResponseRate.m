%EstimateBIFSensitivity.m
%
% This script estimates bias and variance in BIF estimates as a function of subject
% accuracy and number of experimental trials.

%Assume that the average NH BIF is the true function, these values come from results of NHAverageBIFs.R
%These values are in log odds, on an natural log scale
trueImportances = [-0.152 0.023 0.135 0.0401 0.316 0.167 0.497 0.260 0.478 0.374 0.566 0.547 0.298 0.336 0.281 0.336 0.029 0.062 0.285 0.087];

%Points to sample in the simulations
accuracies = [0.02 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.98];
nTrials = 400;
nBaselineTrials = 40;
bandsPerTrial = 7;
nBands = length(trueImportances);

experimentSentences = 1:nTrials;
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


%Iterate through the simulated accuracies
simulatedResults = struct;
for(accuracyIndex = 1:length(accuracies))
	simulatedResults(accuracyIndex).nominalAccuracy = accuracies(accuracyIndex);
	disp(['Testing Accuracy: ' num2str(accuracies(accuracyIndex))]);
	%Calculate the logistic regression intercept needed to obtain the desired accuracy, for the true importance function
	intercept = log(accuracies(accuracyIndex)/(1-accuracies(accuracyIndex))) - mean(trueImportances)*bandsPerTrial;

	%Go through the experiment sequence trial by trial, simulate the number of words correct with those bands present
	fits = zeros(nRuns,length(trueImportances)+1);
	measuredAccuracy = zeros(nRuns,1);
	for(runIndex = 1:nRuns)
		disp(['** Simulation run: ' num2str(runIndex)]);
		sentenceOrder = [randsample(experimentSentences,nTrials) baselineSentences];
		%ChannelOn is a binary matrix that marks the presence or absence of a band on each trial
		channelOn = [zeros(nTrials,nBands); ones(nBaselineTrials,nBands)];
		%Build the experiment sequence for this run
		[maleTalkerTrialMatrix femaleTalkerTrialMatrix] = ChooseTargetTrials(nTrials/2, nBands, bandsPerTrial, 100);
		experimentSequence = [maleTalkerTrialMatrix; femaleTalkerTrialMatrix];
		for(trialIndex = 1:size(experimentSequence,1))
			bandsInTrial = experimentSequence(trialIndex,:);
			channelOn(trialIndex,bandsInTrial) = 1;
		end

		%Simulate the subject response for each trial in this run
		totalWords = zeros(nTrials,1);
		wordsCorrect = zeros(nTrials,1);
		for(trialIndex = 1:size(channelOn,1))
			logOdds = sum(trueImportances(logical(channelOn(trialIndex,:)))) + intercept;
			chanceCorrect = exp(logOdds)/(1+exp(logOdds));
			%Get the number of words per trial.
			totalWords(trialIndex) = wordsInSentence(sentenceOrder(trialIndex));
			wordsCorrect(trialIndex) = sum(binornd(totalWords(trialIndex),chanceCorrect));
		end

		%Perform logistic regression on simulated data
		fits(runIndex,:) = glmfit(channelOn,[wordsCorrect totalWords],'binomial')';
		measuredAccuracy(runIndex,:) = sum(wordsCorrect(1:nTrials))/sum(totalWords(1:nTrials));
	end
	simulatedResults(accuracyIndex).fits = fits;
	simulatedResults(accuracyIndex).measuredAccuracy = measuredAccuracy;
	save('simulationResultBackup7-25-16.mat');
end


figure;
for(accuracyIndex = 1:length(accuracies))
	subplotHandle(accuracyIndex) = subplot(5,3,accuracyIndex);
	hold off; plot(trueImportances,'-b'); hold on; plot(simulatedResults(accuracyIndex).fits(:,2:size(simulatedResults(accuracyIndex).fits,2))','r*');
	title(['Correct Response Rate ' num2str(accuracies(accuracyIndex))]);
	maxErrorPerRun(accuracyIndex,:) = max(abs(simulatedResults(accuracyIndex).fits(:,2:size(simulatedResults(accuracyIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1))');
	meanErrorPerRun(accuracyIndex,:) = mean(abs(simulatedResults(accuracyIndex).fits(:,2:size(simulatedResults(accuracyIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1))');
	averageMaxError(accuracyIndex) = mean(maxErrorPerRun(accuracyIndex,maxErrorPerRun(accuracyIndex,:)<2));
	averageMeanError(accuracyIndex) = mean(meanErrorPerRun(accuracyIndex,meanErrorPerRun(accuracyIndex,:)<2));
	meanBiasPerChannel(accuracyIndex,:) = mean(simulatedResults(accuracyIndex).fits(:,2:size(simulatedResults(accuracyIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1));
	STDPerRun(accuracyIndex,:) = std((simulatedResults(accuracyIndex).fits(:,2:size(simulatedResults(accuracyIndex).fits,2)) -...
       					repmat(trueImportances,nRuns,1))');
	meanSTDPerChannel(accuracyIndex,:) = std(simulatedResults(accuracyIndex).fits(:,2:size(simulatedResults(accuracyIndex).fits,2)));
end
linkaxes(subplotHandle,'xy');

figure;
plot([simulatedResults.measuredAccuracy]',abs(meanErrorPerRun),'ko');
hold on;
plot([simulatedResults.measuredAccuracy]',maxErrorPerRun,'r+');
plot([simulatedResults.nominalAccuracy],averageMeanError,'k-','LineWidth',1.5);
plot([simulatedResults.nominalAccuracy],averageMaxError,'r-','LineWidth',1.5);
ylabel('Absolute Error (log odds)');
xlabel('Correct Response Rate (probability)');
axis([0 1 0 1.05]);
set(gca,'FontSize',10);
set(gcf,'PaperPosition', [0 0 7.5 3]);
print('Figures\Manuscript\SensitivityToPercentCorrect','-dpng','-r300');

