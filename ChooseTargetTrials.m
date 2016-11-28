% ChooseTargetTrials.m
% Created 11/5/15 by A. Bosen

function [maleTalkerTrialMatrix femaleTalkerTrialMatrix] = ChooseTargetTrials(nTrials, nBands, bandsPerTrial, nRuns)

assert(mod(nTrials*bandsPerTrial/nBands,1)==0, 'ERROR:  There will be an uneven number of bands over the experiment.  Adjust nTrials, bandsPerTrial, or nBands so that nTrials*bandsPerTrial/nBands is an integer value.');

possibleTrials = nchoosek([1:nBands],bandsPerTrial);

%Determine how many exhaustive sets of trials we have, based on the combinatorics and the total number of trials
nCompleteSets = floor(nTrials/size(possibleTrials,1));
%Determine how many remaining trials we have, to do the subset selection over
%NOTE: the code below assumes that nRemainderTrials is nonzero.  If it is zero, you can just repeat possibleTrials nCompleteSets times to build
%a trial matrix.
nRemainderTrials = mod(nTrials,size(possibleTrials,1));

expectedBandCount = bandsPerTrial/nBands * nRemainderTrials;

if(nRemainderTrials > 0)
	%Set up parallel computation for the main loop of this program
	%nCores = 3;
	%poolobj = parpool('local',nCores);


	%Generate trial sets nRuns times, choose the best (minimum difference in maximum and minimum band intersection)
	runSamples = cell(1,nRuns);
	runIntersection = cell(1,nRuns);
	%parfor
	for(runNumber = 1:nRuns)
		disp(['Starting Run ' num2str(runNumber)]);

		%Choose a random nRemainderTrials of the available trials
		sample = datasample(possibleTrials,nRemainderTrials,1,'Replace',false);


		%Try to rebalance the array by replacing samples with higher than expected bands with less than expected bands
		for(lcv1 = 1:20000)
			%Find out how many times each band appears in the random sample
			bandCount = zeros(1,nBands);
			for(lcv2 = 1:nBands)
				bandCount(lcv2) = sum(sum(sample == lcv2));
			end
			%if the bandCount has little variance then we should stop and finish by hand
			if(std(bandCount) <= 0.15*nBands)
				break;
			end

			%Choose the band that occurs most frequently
			bandNumbers = 1:nBands;
			[~,replacedBandIndex] = max(bandCount);
			replacedBand = bandNumbers(replacedBandIndex);

			%Choose a random trial that contains that band
			sampleIndex = (1:nRemainderTrials)';
			replacedTrial = datasample(sampleIndex(logical(sum(sample == replacedBand,2))),1);

			%Choose a random less frequently than expected band
			newBand = datasample(bandNumbers(bandCount < expectedBandCount),1);

			%Choose a random trial not currently in the sample that contains that band
			newBand = datasample(setxor(sample,possibleTrials,'rows'),1);

			%Replace the trial in the sample with the trial not in the sample
			sample(replacedTrial,:) = newBand; 
		end

		%Manually move bands around, without swapping out whole trials.
		while(std(bandCount) > 0)
			%Choose a random more frequent than expected band
			bandNumbers = 1:nBands;
			replacedBand = datasample(bandNumbers(bandCount > expectedBandCount),1);
			
			%Choose a random trial that contains that band
			sampleIndex = (1:nRemainderTrials)';
			replacedTrial = datasample(sampleIndex(logical(sum(sample == replacedBand,2))),1);
			bandIndex = 1:bandsPerTrial;
			replacedBandPosition = bandIndex(sample(replacedTrial,:) == replacedBand);

			%Choose a random less frequenty than expected band that is not already in this trial
			possibleNewBands = setdiff(bandNumbers(bandCount < expectedBandCount),sample(replacedTrial,:));
			if(length(possibleNewBands) > 0)
				newBand = datasample(possibleNewBands,1);

				%Replace the old band (individual value) with the new band
				sample(replacedTrial,replacedBandPosition) = newBand;
			end

			bandCount = zeros(1,nBands);
			for(lcv2 = 1:nBands)
				bandCount(lcv2) = sum(sum(sample == lcv2));
			end
		end

		%Sort the rows of the sample matrix
		sample = sort(sample,2);

		%Calculate size of intersection (Band 1 and Band 2). This should be
		%roughly equal for each pair of bands, to balance their co-occurance
		intersection = zeros(nBands);

		for(band1 = 1:nBands)
			for(band2 = (band1+1):nBands)
				%Index all trials that contain band 1
				containsBand1 = logical(sum(sample == band1,2));
				%Index all trials that contain band 2
				containsBand2 = logical(sum(sample == band2,2));

				intersection(band1,band2) = sum(containsBand1 & containsBand2);

			end
		end


		runSamples(runNumber) = {sample};
		runIntersection(runNumber) = {intersection};
		runIntersectionRange(runNumber) = max(max(intersection)) - min(min(intersection(intersection ~= 0)));
	end

	%Delete the parallel pool
	%delete(poolobj);

	bestIntersectionRange = min(runIntersectionRange); 

	%Choose all runs that produced the best intersection range
	bestRangeIndex = cellfun(@(x) bestIntersectionRange == (max(max(x)) - min(min(x(x~=0)))),runIntersection);
	bestIntersection = runIntersection(bestRangeIndex);
	bestRangeSamples = runSamples(bestRangeIndex);

	if(length(bestRangeSamples) > 1)
		intersectionSurface = bestIntersection{1} + bestIntersection{2};
		maleTalkerTrialMatrix = bestRangeSamples{1};
		femaleTalkerTrialMatrix = bestRangeSamples{2}; 
	else
		secondBestIntersectionRange = min(runIntersectionRange(runIntersectionRange>bestIntersectionRange));
		secondBestRangeIndex = cellfun(@(x) secondBestIntersectionRange == (max(max(x)) - min(min(x(x~=0)))),runIntersection);
		secondBestIntersection = runIntersection(secondBestRangeIndex);
		secondBestRangeSamples = runSamples(secondBestRangeIndex);
		intersectionSurface = bestIntersection{1} + secondBestIntersection{1};
		maleTalkerTrialMatrix = bestRangeSamples{1};
		femaleTalkerTrialMatrix = secondBestRangeSamples{1}; 
	end
	intersectionSurface(intersectionSurface == 0) = NaN;
	figure;
	surf(intersectionSurface);
	title('Band co-occurance Frequency');
	xlabel('Band 1');
	ylabel('Band 2');
	zlabel('Number of Times Bands Occur Together in Incomplete Set');

	%Preappend the complete trial sets to the trial matrix
	if(nCompleteSets > 0)
		maleTalkerTrialMatrix = [repmat(possibleTrials,nCompleteSets,1);maleTalkerTrialMatrix];
		femaleTalkerTrialMatrix = [repmat(possibleTrials,nCompleteSets,1);femaleTalkerTrialMatrix];

	end
else
	maleTalkerTrialMatrix = [repmat(possibleTrials,nCompleteSets,1)];
	femaleTalkerTrialMatrix = [repmat(possibleTrials,nCompleteSets,1)];
end


end
