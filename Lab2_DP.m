function varargout = Lab2_DP(varargin)
% LAB2_DP MATLAB code for Lab2_DP.fig
%      LAB2_DP, by itself, creates a new LAB2_DP or raises the existing
%      singleton*.
%
%      H = LAB2_DP returns the handle to a new LAB2_DP or the handle to
%      the existing singleton*.
%
%      LAB2_DP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LAB2_DP.M with the given input arguments.
%
%      LAB2_DP('Property','Value',...) creates a new LAB2_DP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Lab2_DP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Lab2_DP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Lab2_DP

% Last Modified by GUIDE v2.5 20-Apr-2016 12:26:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Lab2_DP_OpeningFcn, ...
                   'gui_OutputFcn',  @Lab2_DP_OutputFcn, ...
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


% --- Executes just before Lab2_DP is made visible.
function Lab2_DP_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Lab2_DP (see VARARGIN)

% Choose default command line output for Lab2_DP
handles.output = hObject;
handles.DAGain = 10;
handles.RShunt = 1;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Lab2_DP wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Lab2_DP_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnInitialise.
function btnInitialise_Callback(hObject, eventdata, handles)
% hObject    handle to btnInitialise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.textStatus,'string','Initializing...'); %update UI


%% Setup parameters
DaqName = 'Dev3';
Fs = 1000;
SamplingSize = 2;
bufferSize = 150;
%% analogue parameters
DAGain =  handles.DAGain;
RShunt = handles.RShunt;


%% DAQ Initialization----------------------- 
info = daqhwinfo('nidaq')
ai = analoginput('nidaq',DaqName)
ao = analogoutput('nidaq',DaqName)

handles.ao = ao;
handles.ai = ai;

%% Save the change to the structure
guidata(hObject,handles)

%% Adding Channels-------------------------
 addchannel(ai,0) %add GND ref Channel
 addchannel(ai,1) %add V_Sense Channel
 addchannel(ai,2) %add V_input Channel
 addchannel(ai,3) %add SD_sense Channel
 addchannel(ao,0) %add V_cmd out channet
 set(ai,'SampleRate',Fs) %set Sampling rate
 set(ai,'SamplesPerTrigger',SamplingSize) %setup sampling Size
 set(ai,'InputType','SingleEnded');
 
 putsample(ao,0);
 
 set(handles.textStatus,'string','Initialized'); %update UI
 
 data = zeros(bufferSize,2); %databuffer
  
 handles.running =1;
 handles.data = data;
 guidata(hObject,handles)
 
 while (handles.running)
     
      %% Acqurie data
    start(ai) % start the analog input channel
    [acquiredData,time] = getdata(ai); % sample some data
    
    GNDData = acquiredData(:,1); %get CH0 data
    CH1Data = acquiredData(:,2); %get CH1 data
    CH2Data = acquiredData(:,3); %get CH2 data
    CH3Data = acquiredData(:,4); %get CH3 data
    
    senseData = mean(CH1Data - GNDData); %remove Ground baseline and store
    cmdData = mean(CH2Data - GNDData); %remove Ground baseline and store
    SDData = mean(CH3Data - GNDData); %remove Ground baseline and store
    
    set(handles.textStatus3,'string',...
            sprintf('Vo:%.2f V %.2f V %.2f V',senseData,cmdData,SDData) );
        
    if(SDData < 5)
        set(handles.textShut,'string','SD: OK');
    elseif(SDData >5)
        set(handles.textShut,'string','SD: ACTIVATED');
    else
        set(handles.textShut,'string','');
    end
        
     %% Manupulate data on to buffer 
    data = handles.data;
    inputSize = 1;
    data(1:end-inputSize,:) = data(1+inputSize:end,:);
    data(end-inputSize+1:end,:) = [senseData,cmdData];
    handles.data = data;
    guidata(hObject,handles)   
        
    I_sense = (senseData/ ( DAGain * RShunt) ) ;
    
    
    plot(data,'parent',handles.axes1);
    set(handles.axes1, 'YLim', [0,(4)]);
    
     
    I_sense_ma = (I_sense * 1000);
    set(handles.textCurrentVal,'string',...
            sprintf('%.0f mA',I_sense_ma ) );
    
    
    pause(0.02)
 end
 
 
 

% --- Executes on slider movement.
function sliderInput_Callback(hObject, eventdata, handles)
% hObject    handle to sliderInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

value =get(hObject,'Value');

currentValue = value * 300;
set(handles.textUserInput,'string',...
            sprintf('%.2f mA',currentValue) );


% --- Executes during object creation, after setting all properties.
function sliderInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in btnSet.
function btnSet_Callback(hObject, eventdata, handles)
% hObject    handle to btnSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ao = handles.ao;

DAGain =  handles.DAGain;
RShunt = handles.RShunt;

value =get(handles.sliderInput,'Value');
currentValue = value * 300;

I_cmd = currentValue/1000; % in amp
    
V_out = (I_cmd * ( DAGain * RShunt) );

putsample(ao,V_out);
set(handles.textStatus2,'string',...
            sprintf('Vo:%.2f V',V_out) );


% --- Executes on button press in btnForce.
function btnForce_Callback(hObject, eventdata, handles)
% hObject    handle to btnForce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ao = handles.ao;
ai = handles.ai;

DAGain =  handles.DAGain;
RShunt = handles.RShunt;

for currentValue = 200:3:350

    I_cmd = currentValue/1000; % in amp

    V_out = (I_cmd * ( DAGain * RShunt) );

    putsample(ao,V_out);
    set(handles.textStatus2,'string',...
                sprintf('Vo:%.2f V',V_out) );
   
    pause(0.02)    
end

guidata(hObject,handles)
        
        
        
