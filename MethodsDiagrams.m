% MethodsDiagrams.m
% Created by Adam Bosen on 12/1/15
%
% This script is meant to generate the components for the methods figure demonstrating the forms of filtering used
% in this experiment.

%Load an example sentence, in this case the female talker's first sentence
%"The birch canoe slid on the smooth planks"
[signal, sampleRate] = audioread('.\Sound Files\ieee\AW01.WAV');
NHsubjectParameterFile = '.\Subject Parameters\NH_SII_BANDS.csv';
NHsubjectParameters = csvread(NHsubjectParameterFile,1,0);
N5subjectParameterFile = '.\Subject Parameters\N5_RIGHT_EAR.csv';
N5subjectParameters = csvread(N5subjectParameterFile,1,0);

%Select the channels for use in this demo for both NH and N5.
%note that channels is a quick hack that assumes monotonicity from low to high frequencies in the
%parameters file, which might not always be the case.
channels = [1 5 8 12 15 18 20];
NHchannelLowerBounds = NHsubjectParameters(channels,2);
NHchannelUpperBounds = NHsubjectParameters(channels,3);
N5channelLowerBounds = N5subjectParameters(channels,2);
N5channelUpperBounds = N5subjectParameters(channels,3);

%Generate a spectrogram for the unfiltered example signal
windowLength = 0.020; %seconds
%Praat documentation claims that gaussian windowing is the way to go, and who am I to disagree?
window = gausswin(floor(windowLength*sampleRate));
dynamicRange = 65; %dB
[S, F, T] = spectrogram(signal,window,floor(length(window)/2),512,sampleRate,'yaxis');
S = 20*log10(abs(S));
%define the floor value once and keep it the same through all figures
floorVal = max(max(S)) - dynamicRange;
floorIndex = S < floorVal;
S(floorIndex) = max(max(S(floorIndex)));
figure;
h = surf(T,F,S);
axis([0 length(signal)/sampleRate 0 8000]);
colormap(flipud(gray));
set(h,'LineStyle','none');
set(gca,'FontSize',20);
xlabel('Time (s)','FontSize',24);
ylabel('Frequency (Hz)','FontSize',24);

set(gcf,'PaperUnits','inches','PaperPosition',[0 0 5 4.5])
print -dpng '.\Figures\Manuscript\UnfilteredSpectrogram.png' -r300;


%synthesize the rectangular passband vocoded signal
rectFilteredSignal = BandFilterAuditorySignal(signal, sampleRate, NHchannelLowerBounds, NHchannelUpperBounds, 'rectangular');
[S, F, T] = spectrogram(rectFilteredSignal,window,floor(length(window)/2),512,sampleRate,'yaxis');
S = 20*log10(abs(S));
floorIndex = S < floorVal;
S(floorIndex) = max(max(S(floorIndex)));
figure;
h = surf(T,F,S);
axis([0 length(signal)/sampleRate 0 8000]);
colormap(flipud(gray));
set(h,'LineStyle','none');
set(gca,'FontSize',20);
xlabel('Time (s)','FontSize',24);
ylabel('Frequency (Hz)','FontSize',24);

set(gcf,'PaperUnits','inches','PaperPosition',[0 0 5 4.5])
print -dpng '.\Figures\Manuscript\rectFilterSpectrogram.png' -r300;

%synthesize the simulated monopolar passband vocoded signal
monoFilteredSignal = BandFilterAuditorySignal(signal, sampleRate, NHchannelLowerBounds, NHchannelUpperBounds, 'monopolar');
[S, F, T] = spectrogram(monoFilteredSignal,window,floor(length(window)/2),512,sampleRate,'yaxis');
S = 20*log10(abs(S));
floorIndex = S < floorVal;
S(floorIndex) = max(max(S(floorIndex)));
figure;
h = surf(T,F,S);
axis([0 length(signal)/sampleRate 0 8000]);
colormap(flipud(gray));
set(h,'LineStyle','none');
set(gca,'FontSize',20);
xlabel('Time (s)','FontSize',24);
ylabel('Frequency (Hz)','FontSize',24);

set(gcf,'PaperUnits','inches','PaperPosition',[0 0 5 4.5])
print -dpng '.\Figures\Manuscript\monoFilterSpectrogram.png' -r300;

%Synthesize the version that would be given to the example CI listener (N5)
unvocodedFilteredSignal = BandFilterAuditorySignal(signal, sampleRate, N5channelLowerBounds, N5channelUpperBounds);
[S, F, T] = spectrogram(unvocodedFilteredSignal,window,floor(length(window)/2),512,sampleRate,'yaxis');
S = 20*log10(abs(S));
floorIndex = S < floorVal;
S(floorIndex) = max(max(S(floorIndex)));
figure;
h = surf(T,F,S);
axis([0 length(signal)/sampleRate 0 8000]);
colormap(flipud(gray));
set(h,'LineStyle','none');
set(gca,'FontSize',20);
xlabel('Time (s)','FontSize',24);
ylabel('Frequency (Hz)','FontSize',24);


set(gcf,'PaperUnits','inches','PaperPosition',[0 0 5 4.5])
print -dpng '.\Figures\Manuscript\CISpectrogram.png' -r300;

%Build a spectrogram of the monopolar passband filter
%whiteNoise = rand(60 * sampleRate,1); %generate 1 minute of white noise to pass through the filter
%BandFilterAuditorySignal(whiteNoise, sampleRate, NHchannelLowerBounds, NHchannelUpperBounds, 'monopolar', 1);
