% BandFilterAuditorySignal.m
% Created 9/29/15 by A. Bosen
% This function takes an input waveform and filters it so it only contains the specified acoustic bands.
% The full filtering algorithm is described in Bosen and Chatterjee 2016.
%
% Inputs
% signal - the raw signal to be filtered
% samplingFrequency - the filtering algorithm needs to know the sampling frequencies, so it can properly
%	              define the filter cutoffs
% filterBounds - a struct , with four array fields of the same length: lowerAnalysisBounds, upperAnalysisBounds, lowerSynthesisBounds, upperSyntheisBounds
%                these bounds determine the band limits of the analysis and synthesis bands, accordingly.  For conventional vocoding, the analysis and
%                synthesis band limits should match, but manipulation of synthesis relative to analysis can produce compression/expansion or frequency
%                shift effects.
% vocoderFilterType - (optional) if set to 'monopolar' or 'rectangular', noise vocodes the the filtered signal with the according synthesis filter
% plotSpectrum - (optional) if set to a nonzero value, plots the spectrum of the input and output
%
% Outputs
% filteredSignal - the sum of the input signal after being filtered through the specified filter bands

function [filteredSignal] = BandFilterAuditorySignal(signal, samplingFrequency, filterBounds, vocoderFilterType, plotSpectrum)

FILTER_ORDER = 2000;

%Check if optional arguments are defined, if not, set them to zero
if(~exist('vocoderFilterType','var'))
	vocoderFilterType = 'none';
elseif(~strcmp(lower(vocoderFilterType),'rectangular') & ~strcmp(lower(vocoderFilterType),'monopolar') & ~strcmp(lower(vocoderFilterType),'none'))
	%This isn't a valid filter type, so we throw an error
	throw(MException('Invalid Filter Type: %s'),vocoderFilterType);
end
if(~exist('plotSpectrum','var'))
	plotSpectrum = 0;
end

%Pad the input signal
paddedSignal = [zeros(FILTER_ORDER,1);signal;zeros(FILTER_ORDER,1)];
%preallocate filtering results
filteredSignals = zeros(length(paddedSignal),length(filterBounds));
%Go through each specified band and create the filtered signal
%Build a single wideband carrier to use with all signals
noiseCarrier = randn(length(paddedSignal),1);
noiseCarrier = noiseCarrier - mean(noiseCarrier);
for(bandIndex = 1:length(filterBounds.lowerAnalysisBounds))
	%Design the filter
	analysisBandFilter = designfilt('bandpassfir', 'FilterOrder', FILTER_ORDER,...
       		'CutoffFrequency1', filterBounds.lowerAnalysisBounds(bandIndex), 'CutoffFrequency2', filterBounds.upperAnalysisBounds(bandIndex),...
	        'SampleRate', samplingFrequency);
		%Filter the signal to get the analysis band
		analysisBand = filtfilt(analysisBandFilter,paddedSignal);
	if(strcmp(lower(vocoderFilterType),'none'))
		filteredSignals(:,bandIndex) = analysisBand;
	else
		%extract the analysis band's envelope
		envelope = abs(hilbert(analysisBand));
		%low pass filter the envelope, 300 Hz cutoff, 4th order butterworth filter (2nd order, ran through twice via filtfilt)
		[B, A] = butter(1, 300/(samplingFrequency/2), 'low');
		envelope = filtfilt(B, A, envelope);
		%Generate some band-filtered noise and apply the envelope to it
		if(strcmp(lower(vocoderFilterType),'rectangular')) 
			%Determine if we need to build a separate synthesis filter
			if((filterBounds.lowerAnalysisBounds(bandIndex) == filterBounds.lowerSynthesisBounds(bandIndex)) &...
			   (filterBounds.upperAnalysisBounds(bandIndex) == filterBounds.upperSynthesisBounds(bandIndex)))
				synthesisBandFilter = analysisBandFilter;
			else
				synthesisBandFilter = designfilt('bandpassfir', 'FilterOrder', FILTER_ORDER,...
								'CutoffFrequency1', filterBounds.lowerSynthesisBounds(bandIndex),...
							       	'CutoffFrequency2', filterBounds.upperSynthesisBounds(bandIndex),...
								'SampleRate', samplingFrequency);
			end
			%Multiply the carrier and the envelope, then filter it into the desired shape.
			filteredSignals(:,bandIndex) = filtfilt(synthesisBandFilter, noiseCarrier .* envelope);
		elseif(strcmp(lower(vocoderFilterType),'monopolar'))
			%Use equation 6 from Mesnildrey and Macherey 2015 to build the filter amplitude, then use fir2 to build the filter
			d = 1; %orthogonal distance from electrode to nerve, assumed to be a fixed 1 mm
			beta = 1; %Unitless, the proportionality coefficient
			freqAxis = 0:(samplingFrequency/2);
			greenwoodLocations = log10(((freqAxis./165.4) + 1))./0.06;
			centerLocation = log10(((mean([filterBounds.lowerSynthesisBounds(bandIndex) filterBounds.upperSynthesisBounds(bandIndex)])./165.4) + 1))./0.06;
			magFreqResponse = ((d^3)./(((greenwoodLocations - centerLocation).^2 + d^2).^(1.5))).^(1/beta);
			normalizedFreqAxis = freqAxis./(samplingFrequency/2);
			%we build the filter to be magFreqResponse^0.5 because filtfilt runs the signal through the filter TWICE
			monopolarFilter = fir2(FILTER_ORDER, normalizedFreqAxis, magFreqResponse.^0.5);
			filteredSignals(:,bandIndex) = filtfilt(monopolarFilter, 1, noiseCarrier .* envelope);
		end
		%Normalize the synthesis band energy to match the analysis band 
		filteredSignals(:,bandIndex) = filteredSignals(:,bandIndex) * (rms(analysisBand) / rms(filteredSignals(:,bandIndex)));
	end
end

%Remove padding
filteredSignals = filteredSignals(FILTER_ORDER + 1:size(filteredSignals,1)-FILTER_ORDER,:);
%Rebuild the stimulus by summing the band-filtered signal components
filteredSignal = sum(filteredSignals,2);

%plot the spectra of the input, each filter, and the sum output
if(plotSpectrum)
	freqAxis = 0:samplingFrequency/length(signal):samplingFrequency-(1/length(signal));
	%Plot the original signal
	ax(1) = subplot(3,1,1);
	semilogx(freqAxis,20*log10(abs(fft(signal))));
	axis([20 samplingFrequency/2 -40 80]);
	set(gca,'XTick',[100,1000,10000],'XTickLabel',{'0.1';'1';'10'});
	title('Input Spectrum');
	ax(2) = subplot(3,1,2);
	semilogx(freqAxis,20*log10(abs(fft(filteredSignals))));
	axis([20 samplingFrequency/2 -40 80]);
	set(gca,'XTick',[100,1000,10000],'XTickLabel',{'0.1';'1';'10'});
	title('Filter Outputs');
	ax(3) = subplot(3,1,3);
	semilogx(freqAxis,20*log10(abs(fft(filteredSignal))));
	axis([20 samplingFrequency/2 -40 80]);
	set(gca,'XTick',[100,1000,10000],'XTickLabel',{'0.1';'1';'10'});
	title('Sum Output');
	linkaxes(ax);
	xlabel('Frequency (kHz)');

end

end
