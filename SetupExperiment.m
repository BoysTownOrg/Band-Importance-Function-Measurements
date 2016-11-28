% SetupExperiment.m
%
% Created by A. Bosen 5/16/2016

nBands = 20;
bandsPerTrial = 7;
nTrials = 400; 
subjectID = 'NH_SII_Bands';
preFilterStimuli = 1;
vocoderType = 'rectangular'; %Options are 'none', 'rectangular', or 'monopolar', details are provided in Bosen and Chatterjee 2016.
trialsPerBlock = 80;

experimentSentences = 1:nTrials;
baselineSentences = 681:720;

nRuns = 100; 

%Generate two matrices containing the bands that will be present on each trial, one for the male talker, one for the female talker
[maleTalkerTrialMatrix femaleTalkerTrialMatrix] = ChooseTargetTrials(nTrials/2, nBands, bandsPerTrial, nRuns); 

%Build experiment sequence
subjectParameterFileName = ['.\Subject Parameters\' subjectID '.dat'];
experimentSequences = GenerateExperimentSequence(subjectParameterFileName, preFilterStimuli, vocoderType, trialsPerBlock, nBands,...
						 maleTalkerTrialMatrix, femaleTalkerTrialMatrix, experimentSentences,0);
%Write the experiment sequence files
for(blockIndex = 1:length(experimentSequences))
	writetable(experimentSequences{blockIndex},...
		['.\Experiment Sequences\' subjectID '_vocoder-' vocoderType '_Block' num2str(blockIndex)  '.dat'],'Delimiter','\t'); 
end

%Build baseline sequence
baselineTrialMatrix = repmat(1:nBands,length(baselineSentences)/2,1);
baselineSequence = GenerateExperimentSequence(subjectParameterFileName, preFilterStimuli, vocoderType, trialsPerBlock, nBands,...
						 baselineTrialMatrix, baselineTrialMatrix, baselineSentences,0);
%Write the baseline sequence file.  This assumes that baselineSentences is shorter than trialsPerBlock
writetable(baselineSequence{1},...
	['.\Experiment Sequences\' subjectID '_vocoder-' vocoderType '_Baseline.dat'],'Delimiter','\t');
