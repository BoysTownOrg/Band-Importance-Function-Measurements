function varargout = ExecuteTest(varargin)
% EXECUTETEST MATLAB code for ExecuteTest.fig
%      EXECUTETEST, by itself, creates a new EXECUTETEST or raises the existing
%      singleton*.
%
%      H = EXECUTETEST returns the handle to a new EXECUTETEST or the handle to
%      the existing singleton*.
%
%      EXECUTETEST('Property','Value',...) creates a new EXECUTETEST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ExecuteTest_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ExecuteTest_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ExecuteTest

% Last Modified by GUIDE v2.5 30-Sep-2015 16:37:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExecuteTest_OpeningFcn, ...
                   'gui_OutputFcn',  @ExecuteTest_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

end


% --- Executes just before ExecuteTest is made visible.
function ExecuteTest_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ExecuteTest (see VARARGIN)

% Choose default command line output for ExecuteTest
handles.output = hObject;

%Load the subject parameters and experiment sequence
%We assume that the first line offprintf(handles.outputFile, the file is a header, and shouldn't be read in
subjectParameterFile = varargin{2};
experimentSequenceFile = varargin{3};
subjectParameters = dlmread(subjectParameterFile,'\t',1,0);
%Parse the subject parameters into vectors and store in handles for later use
handles.channelNumbers = subjectParameters(:,1);
handles.channelLowerBounds = subjectParameters(:,2);
handles.channelUpperBounds = subjectParameters(:,3);

%Keep experiment sequence as a table, since it's easier to work with later
handles.experimentSequence = readtable(experimentSequenceFile,'Delimiter','\t');

%Set the current and final trial indices
handles.currentTrial = 1;
handles.lastTrial = size(handles.experimentSequence,1);

%Open the output file
handles.outputFile = fopen(['.\Experiment Results\' ...  
				experimentSequenceFile(max(strfind(experimentSequenceFile,'\'))+1:length(experimentSequenceFile)-4)...
			],'a');

%Write a header to the output file
fprintf(handles.outputFile,'TrialNumber\tSentenceDuration\tTimeToResponseStart\tTimeToResponseEnd\tSoundFile\tActiveChannels\tSubjectResponse\n');

%Disable the response button until the subject hears the first stimuli
handles.EnterResponseButton.Enable = 'off';
handles.ResponseText.Enable = 'off';

%Write to the progress box
handles.ProgressText.String = ['0 of ' num2str(handles.lastTrial) ' completed'];
drawnow;

%Initialize the reaction time variables
handles.TrialStartTime = 0;
handles.ResponseStartTime = 0;
handles.SentenceDuration = 0;

% Update handles structure
guidata(hObject, handles);

end

%Make sure that if we're closing the program prematurely we close the output file
function EnterResponseButton_DeleteFcn(hObject, eventdata, handles)
	if(exist('handles.outputFile','var'))
		fclose(handles.outputFile);
	end
end


% --- Executes during object creation, after setting all properties.
function ResponseText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ResponseText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usuhandles.experimentSequence{handles.currentTrial,2}ally have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function ResponseText_Callback(hObject, eventdata, handles)

end

% --- Outputs from this function are returned to the command line.
function varargout = ExecuteTest_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLABhandles.experimentSequence{handles.currentTrial,2}
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

end

%Play the sound for this trial, then gray the start trial button and highlight the response entry button
function StartTrialButton_Callback(hObject, eventdata, handles)
	%Load the raw sound file
	soundFile = char(handles.experimentSequence{handles.currentTrial,1});
	[originalSignal, sampleRate] = audioread(soundFile);
	handles.SentenceDuration = length(originalSignal)/sampleRate;
	%Check if this is a pre-generated sound file.  If so, skip all the filtering
	if(handles.experimentSequence{handles.currentTrial,3})
		filteredSignal = originalSignal;
	else
		%Filter the sound file to contain only information in the specified bands for this trial
		bands = str2num(char(handles.experimentSequence{handles.currentTrial,2}));
		%Find the proper indices to select the bands for this trial
		bandIndex = zeros(1,length(bands));
		for(band = 1:length(bands))
			bands(band);
			bandIndex(band) = find(handles.channelNumbers == bands(band));
		end
		%Build the filtered signal
		filteredSignal = BandFilterAuditorySignal(originalSignal, sampleRate,...
			handles.channelLowerBounds(bandIndex), handles.channelUpperBounds(bandIndex));
	end
	%Disable playing the sound again, this will be re-enabled after the subject enters a response
	handles.StartTrialButton.Enable = 'off';
	%Enable the response entry button
	handles.EnterResponseButton.Enable = 'on';
	handles.ResponseText.Enable = 'on';
	%Give focus to the text box, so subjects can easily enter their responses
	uicontrol(handles.ResponseText);
	%Play the sound after a 250 ms delay
	pause(0.25);
	sound(filteredSignal,sampleRate);
	%Record the current time, for reaction times 
	handles.TrialStartTime = tic;
	% Update handles structure
	guidata(handles.figure1, handles);

end

%Record the subject response, re-enable the play sound button, and check if we're done with the expeiment
function EnterResponseButton_Callback(hObject, eventdata, handles)
	%Get the time the response was entered
	responseEndTime = toc(handles.TrialStartTime);
	%Write trial information and subject response to output file
	%We need to escape backslash characters in the file name
	soundFileName = char(handles.experimentSequence{handles.currentTrial,1});
	soundFileName = strrep(soundFileName, '\','\\');
	drawnow;
	%TODO: add audio file duration, time until response start, and time until response finish to output.
	fprintf(handles.outputFile,[num2str(handles.currentTrial) '\t'...
					num2str(handles.SentenceDuration) '\t'...
					num2str(handles.ResponseStartTime) '\t'...
					num2str(responseEndTime) '\t' ...
					soundFileName '\t'...
				       	char(handles.experimentSequence{handles.currentTrial,2}) '\t'...
					handles.ResponseText.String '\n']);
	%Clear the text in the response text box
	handles.ResponseText.String = '';
	%Write to the progress box
	handles.ProgressText.String = [num2str(handles.currentTrial) ' of ' num2str(handles.lastTrial) ' completed'];
	drawnow;
	%Check if we're done with the experiment
	if(handles.currentTrial == handles.lastTrial) 
		%Close this gui
		close(handles.figure1); 
	else 
		%Advance to the next trial
		handles.currentTrial = handles.currentTrial + 1;
		handles.ResponseStartTime = 0;
		handles.TrialStartTime = 0;
		%Disable this button, enable the play sound button
		handles.EnterResponseButton.Enable = 'off';
		handles.ResponseText.Enable = 'off';
		handles.StartTrialButton.Enable = 'on';
		% Update handles structure
		guidata(handles.figure1, handles);
	end 
end




%If the repsonse button is enabled, treat this as a keypress
function EnterResponseButton_KeyPressFcn(hObject, eventdata, handles)
	if(strcmp(eventdata.Key,'return'))
		%Check if the response button is enabled, if so, call the button press callback
		if(strcmp(handles.EnterResponseButton.Enable,'on'))
			EnterResponseButton_Callback(hObject, eventdata, handles);
		end
	end
end

function ResponseText_KeyPressFcn(hObject, eventdata, handles)
	%If this is the first time the subject has pressed a key this trial, record the time
	%as the start of their response
	if(handles.ResponseStartTime == 0)
		handles.ResponseStartTime = toc(handles.TrialStartTime);
		guidata(handles.figure1, handles); 
	end
	EnterResponseButton_KeyPressFcn(hObject, eventdata, handles);
end

function StartTrialButton_KeyPressFcn(hObject, eventdata, handles)
	if(strcmp(eventdata.Key,'return'))
		%Check if the play button is enabled, if so, call the play button callback
		if(strcmp(handles.StartTrialButton.Enable, 'on'))
			StartTrialButton_Callback(hObject, eventdata, handles);
		end
	end
end

%Check where the response should be directed and call the callback accordingly
function figure1_KeyPressFcn(hObject, eventdata, handles)
	if(strcmp(eventdata.Key,'return'))
		if(strcmp(handles.StartTrialButton.Enable, 'on'))
			StartTrialButton_KeyPressFcn(hObject, eventdata, handles);
		elseif(strcmp(handles.EnterResponseButton.Enable,'on'))
			EnterResponseButton_KeyPressFcn(hObject, eventdata, handles);
		end
	end
end
