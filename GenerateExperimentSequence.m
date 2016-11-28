% GenerateExperimentSequence.m
% Created 10/1/15 by Adam Bosen
%
% This function takes a set of experimental parameters and generates a pseudorandom sequence of experimental trials,
% as well as pre-generating the filtered wav files if desired. The randomization assumes that all bands of interest should
% be fully crossed with all stimuli, and keeps paired trials (band of interest present/absent) within the same experiment block

function [experimentSequences] = GenerateExperimentSequence(subjectParameterFileName, preFilterStimuli, vocoderType, trialsPerBlock, nBands,...
								maleTalkerTrialMatrix,femaleTalkerTrialMatrix,sentencesToUse,synthesisBandShift)

	if(~exist('synthesisBandShift','var'))
		synthesisBandShift == 0;
	end

	%Load the subject parameters
	subjectParameters = csvread(subjectParameterFileName,1,0);
	%Parse the subject parameters into vectors and store in handles for later use
	channelNumbers = subjectParameters(:,1);
	channelLowerBounds = subjectParameters(:,2);
	channelUpperBounds = subjectParameters(:,3);

	%parse the subject ID from the parameter file name
	subjectID = subjectParameterFileName(max(strfind(subjectParameterFileName,'\'))+1:length(subjectParameterFileName)-4);

	%Re-map channels so that we're only using the nBands lowest frequencies.
	%This is accomplished by transforming both trialMatrix so that the order is preserved, so a 1 in the trial matrix corresponds to 
	%the lowest frequency in the subject's MAP.
	[~,channelOrder] = sort(channelLowerBounds);
	remappedFemaleTalkerTrialMatrix = femaleTalkerTrialMatrix;
	remappedMaleTalkerTrialMatrix = maleTalkerTrialMatrix;
	for(bandIndex = 1:nBands)
		%Replace all of band bandIndex in the trial matrices with the correct channel number
		remappedFemaleTalkerTrialMatrix(femaleTalkerTrialMatrix == bandIndex) = channelNumbers(channelOrder(bandIndex));
		remappedMaleTalkerTrialMatrix(maleTalkerTrialMatrix == bandIndex) = channelNumbers(channelOrder(bandIndex));
	end
	femaleTalkerTrialMatrix = remappedFemaleTalkerTrialMatrix;
	maleTalkerTrialMatrix = remappedMaleTalkerTrialMatrix;


	%Seed the random number generator with the subject parameter file so we get a consistent pseudorandom sequence for each subject
	randomStream = RandStream('mt19937ar','Seed',1);

	%Build an ordered table
	orderedTable = table();
	%Put dummy columns in the table, otherwise Matlab does some strange indexing
	orderedTable.stimuli = cell((size(femaleTalkerTrialMatrix,1)+size(maleTalkerTrialMatrix,1)),1);
	orderedTable.bands = cell((size(femaleTalkerTrialMatrix,1)+size(maleTalkerTrialMatrix,1)),1);
	orderedTable.preFiltered = zeros((size(femaleTalkerTrialMatrix,1)+size(maleTalkerTrialMatrix,1)),1);

	%Build a table containing each trial in the experiment
	for(trialIndex = 1:(size(femaleTalkerTrialMatrix,1)+size(maleTalkerTrialMatrix,1))) 

		%Pull the bands for this trial out of the correct trial matrix, add to the table
		%Also add the corresponding stimulus file string
		%Build the female half of the ordered table before the male half.
		if(trialIndex <= size(femaleTalkerTrialMatrix,1))
			bands = femaleTalkerTrialMatrix(trialIndex,:);
			orderedTable.stimuli{trialIndex} = ['.\Sound Files\ieee\AW' sprintf('%02d',sentencesToUse(trialIndex)) '.WAV'];
		else
			bands = maleTalkerTrialMatrix(trialIndex - size(femaleTalkerTrialMatrix,1),:);
			orderedTable.stimuli{trialIndex} = ['.\Sound Files\ieee\TA' sprintf('%02d',sentencesToUse(trialIndex)) '.WAV'];
		end
		orderedTable.bands{trialIndex} = bands; 

		%If needed, build the filtered wav files
		if(preFilterStimuli)
			orderedTable.preFiltered(trialIndex) = 1;
			%Load the original sound file
			[originalSignal, sampleRate] = audioread(orderedTable.stimuli{trialIndex});
			%Build the new file name
			fileName = orderedTable.stimuli{trialIndex};
			fileName = fileName(max(strfind(fileName,'\'))+1:length(fileName)-4);
			filteredFileName = ['.\Filtered Sound Files\' subjectID '_vocoder-' vocoderType '_shift-' num2str(synthesisBandShift) '_' fileName ...
				num2str(orderedTable.bands{trialIndex},'_%02d') '.WAV'];

			%Find the proper indices to select the bands for this trial
			trialBandIndex = zeros(1,length(bands));
			for(band = 1:length(bands))
				bands(band);
				trialBandIndex(band) = find(channelNumbers == bands(band));
			end
			%Build the filtered signal
			%Note that synthesis band shift is in bands, relative to the subject's map.  So a shift of +1 will always move the synthesis bands
			%up by one band, regardless of whether that corresponds to an upward or downward shift in frequency.
			filterBounds = struct('lowerAnalysisBounds', channelLowerBounds(trialBandIndex),...
		       			      'upperAnalysisBounds', channelUpperBounds(trialBandIndex),...
					      'lowerSynthesisBounds', channelLowerBounds(trialBandIndex + synthesisBandShift),...
					      'upperSynthesisBounds', channelUpperBounds(trialBandIndex + synthesisBandShift));
			filteredSignal = BandFilterAuditorySignal(originalSignal, sampleRate, filterBounds, vocoderType, 1);

			%Save the filtered sound file to the new file name
			audiowrite(filteredFileName,filteredSignal,sampleRate);
			%Rename all the stimulus files to point to the newly generated files
			orderedTable.stimuli{trialIndex} = filteredFileName;
		else
			orderedTable.preFiltered(trialIndex) = 0;
		end

		%Convert the bands column from an array to a string so the output works properly
		for(trialIndex2 = 1:length(orderedTable.bands))
			orderedTable.bands{trialIndex2} = num2str(orderedTable.bands{trialIndex2},'%02d,');
		end

	end

	%Randomize the order of the experiment trials.
	shuffledTable = datasample(randomStream, orderedTable, length(orderedTable.stimuli), 'Replace',false);

	%Write the experiment sequence files, in sequences of trialsPerBlock length
	for(blockIndex = 1:ceil(size(shuffledTable,1)/trialsPerBlock))
		%take the portion of the shuffled Table for this block, add it to experimentSequences
		experimentSequences{blockIndex} = shuffledTable(((blockIndex-1)*trialsPerBlock)+1:min(blockIndex*trialsPerBlock,size(shuffledTable,1)),:); 
	end

end
