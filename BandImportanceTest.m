function varargout = BandImportanceTest(varargin)
% BANDIMPORTANCETEST MATLAB code for BandImportanceTest.fig
%      BANDIMPORTANCETEST, by itself, creates a new BANDIMPORTANCETEST or raises the existing
%      singleton*.
%
%      H = BANDIMPORTANCETEST returns the handle to a new BANDIMPORTANCETEST or the handle to
%      the existing singleton*.
%
%      BANDIMPORTANCETEST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BANDIMPORTANCETEST.M with the given input arguments.
%
%      BANDIMPORTANCETEST('Property','Value',...) creates a new BANDIMPORTANCETEST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BandImportanceTest_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BandImportanceTest_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BandImportanceTest

% Last Modified by GUIDE v2.5 30-Sep-2015 11:07:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BandImportanceTest_OpeningFcn, ...
                   'gui_OutputFcn',  @BandImportanceTest_OutputFcn, ...
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


% --- Executes just before BandImportanceTest is made visible.
function BandImportanceTest_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BandImportanceTest (see VARARGIN)

% Choose default command line output for BandImportanceTest
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BandImportanceTest wait for user response (see UIRESUME)
% uiwait(handles.figure1);

end

% --- Outputs from this function are returned to the command line.
function varargout = BandImportanceTest_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

end

% Check if the subject and experiment parameters have been set and if so, start the experiment
function StartExperiment_Callback(hObject, eventdata, handles)

	%Check if parameter files are actually defined, as in, are files that ends in .dat
	subjectFile  = handles.SubjectParameters.String;
	sequenceFile = handles.ExperimentSequence.String;
	if(exist(subjectFile, 'file') == 2 & exist(sequenceFile, 'file') == 2)
		ExecuteTest(hObject,subjectFile,sequenceFile);
	else

	end
	

end

%Load the subject parameters when this string changes
function SubjectParameterSelection_Callback(hObject, eventdata, handles)
	
end

% --- Executes during object creation, after setting all properties.
function SubjectParameters_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubjectParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function ExperimentSequenceSelection_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
end

% --- Executes during object creation, after setting all properties.
function ExperimentSequence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


function SelectSubjectFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% handles    structure with handles and user data (see GUIDATA)
	[subjectFileName,subjectPathName,FilterIndex] = uigetfile('./Subject Parameters/*.dat','Select the Subject Parameter File');
	if(subjectFileName ~= 0)
		handles.SubjectParameters.String = [subjectPathName subjectFileName];
	end
end

function SelectExperimentFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	[experimentFileName,experimentPathName,FilterIndex] = uigetfile('./Experiment Sequences/*.dat','Select the Subject Parameter File');
	if(experimentFileName ~= 0)
		handles.ExperimentSequence.String = [experimentPathName experimentFileName];
	end
end
