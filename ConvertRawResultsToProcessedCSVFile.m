% ConvertRawDataToProcessedCSVFile.m
% Created 10/5/15 by Adam Bosen
%
% This script reads the target experiment results file and converts it to a friendlier format for
% manually keyword-scoring subject responses.
% If scoreKeywordsOnly is true, the correct answers will only contain words that were in all capital letters.

function [] = ConvertRawResultsToProcessedCSVFile(rawResultsFileName, processedFileName, scoreKeywordsOnly)

ANSWER_KEY_FILE_NAME = '.\Sound Files\IEEE3_FILE_NAMES.TXT';

if(~exist('scoreKeywordsOnly'))
	scoreKeywordsOnly = 0;
end


%Load the raw result file
resultTable = readtable(rawResultsFileName,'Delimiter','\t');
resultTable.numChannels = cellfun(@(x) length(strfind([x],',')),resultTable.ActiveChannels);

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
		if(scoreKeywordsOnly)
			keywords = strjoin(regexp(sentence,'[A-Z]{2,}','match'),' ');
			sentenceTable = [sentenceTable;table({fileName},{keywords})];
		else
			sentenceTable = [sentenceTable;table({fileName},{sentence})];
		end
	end

end
sentenceTable.Properties.VariableNames = {'fileNames' 'Sentences'};
sentenceTable.NumWords = cellfun(@(x) (sum(x == ' ') + sum(x == '-') + 1),sentenceTable.Sentences);

%Open the processed output file for writing
processedFileHandle = fopen(processedFileName,'w');

%Go through each response in the results table and write an easy-to-score version to the output file
%Add a header to the file
fprintf(processedFileHandle, 'Trial Number,Sentence Duration,Time To Response Start,Time to Response End,Talker,Active Channels,Subject Responses / Target Sentences,Words Correct,Total Words\n');
for(trialIndex = 1:length(resultTable.TrialNumber))
	%Find the correct sentence to go with this trial
	sentenceName = cell2mat(regexp(resultTable.SoundFile{trialIndex},'_[A-Z]+[0-9]+_','match')); 
	fileName = sentenceName(4:length(sentenceName)-1);
	sentenceIndex = strcmp(sentenceTable.fileNames, fileName);
	if(scoreKeywordsOnly)
		%capitalize any keywords found in the subject response, for easier scoring.
		keywords =  regexp(sentenceTable.Sentences(sentenceIndex),' ','split');
		keywordIndex = cell2mat(arrayfun(@colon, cell2mat(regexp(upper(resultTable.SubjectResponse(trialIndex)),keywords{:},'start')),...
							   cell2mat(regexp(upper(resultTable.SubjectResponse(trialIndex)),keywords{:},'end')),...
					'UniformOutput',false));
		responseWithKeywordsUpperCase = resultTable.SubjectResponse{trialIndex};
		responseWithKeywordsUpperCase(keywordIndex) = upper(responseWithKeywordsUpperCase(keywordIndex));
		resultTable.SubjectResponse(trialIndex) = {responseWithKeywordsUpperCase};
	else
		%make everything lowercase for easier comparison
		resultTable.SubjectResponse(trialIndex) = lower(resultTable.SubjectResponse(trialIndex));
		sentenceTable.Sentences(sentenceIndex) = lower(sentenceTable.Sentences(sentenceIndex));
	end
		%Remove commas from the subject responses and target sentences, since they muck up excel's parsing
		resultTable.SubjectResponse(trialIndex) = strrep(resultTable.SubjectResponse(trialIndex),',','');
		sentenceTable.Sentences(sentenceIndex) = strrep(sentenceTable.Sentences(sentenceIndex),',','');
	%Write the results to the output file
	fprintf(processedFileHandle,...
		cell2mat([num2str(resultTable.TrialNumber(trialIndex)) ',' ...
		num2str(resultTable.SentenceDuration(trialIndex)) ',' ...
		num2str(resultTable.TimeToResponseStart(trialIndex)) ','...
		num2str(resultTable.TimeToResponseEnd(trialIndex)) ','...
		sentenceName(2:3) ',' ...
		strrep(resultTable.ActiveChannels(trialIndex),',','_') ',' ...
	       	resultTable.SubjectResponse(trialIndex) ',,'...
	       	num2str(sentenceTable.NumWords(sentenceIndex)) '\n']));
	fprintf(processedFileHandle,...
		cell2mat([',,,,,,' sentenceTable.Sentences(sentenceIndex) ',,\n']));
end

%Close the output file
fclose(processedFileHandle);

end
