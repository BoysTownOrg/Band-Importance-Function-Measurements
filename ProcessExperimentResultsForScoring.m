% ProcessExperimentResultsForScoring.m
% Created 10/5/15 by Adam Bosen
%
% This script reads the target experiment results file and converts it to a friendlier format for
% manually keyword-scoring subject responses.

%Set these parameters for each set of experiment results
subjectID = 'N7';
vocoderType = 'none'; %Options are 'monopolar', 'rectangular', or 'none'
subjectParameters = 'N7_Right_Ear'; %Note: this is the same as the subject parameters file name, but don't add '.dat' to this string.
experimentBlockNames = {'Baseline', 'Block1', 'Block2', 'Block3', 'Block4', 'Block5'}; %Some subjects didn't have a block 5, edit accordingly

scoreKeywordsOnly = 1;


rawResultFilePrefix = ['.\Experiment Results\' subjectID '\' subjectParameters '_vocoder-' vocoderType '_'];
if(scoreKeywordsOnly)
	processedFilePrefix = ['.\Processed Results\' subjectID ' Keywords Only\' subjectID ' Keywords Only '];
	mkdir(['.\Processed Results\' subjectID ' Keywords Only']);
else
	processedFilePrefix = ['.\Processed Results\' subjectID '\' subjectID ' '];
	mkdir(['.\Processed Results\' subjectID]);
end 

for(blockIndex = 1:length(experimentBlockNames))
	disp(['Processing ' experimentBlockNames{blockIndex}]);
	rawResultsFileName = [rawResultFilePrefix experimentBlockNames{blockIndex}];
	processedFileName  = [processedFilePrefix experimentBlockNames{blockIndex} '.csv'];
	ConvertRawResultsToProcessedCSVFile(rawResultsFileName,processedFileName, scoreKeywordsOnly);
end


