function varargout = TTPReviewer(varargin)
% This is the main file for the TTP reviewer GUI.
%
% This file is part of the spike sorting software package MKsort, licensed
% under GPL version 2.
% 
% Copyright (C) 2010, 2011, 2012, 2013 The Board of Trustees of The Leland
% Stanford Junior University
% 
% Written by Matt Kaufman
% 
% Please see mksort.m for full license and contact details.

% GUIDE help immediately below.
% TTPREVIEWER M-file for TTPReviewer.fig
%
%      TTPReviewer expects a single argument: a path to a folder containing
%      a TTPwaves.mat file. However, this path should be a string inside a
%      cell array like {'/net/data/myDataFolder'} since just specifying a
%      string makes GUIDE-based applications think you're trying to call a
%      member function.
%
%
%      TTPREVIEWER, by itself, creates a new TTPREVIEWER or raises the existing
%      singleton*.
%
%      H = TTPREVIEWER returns the handle to a new TTPREVIEWER or the handle to
%      the existing singleton*.
%
%      TTPREVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TTPREVIEWER.M with the given input arguments.
%
%      TTPREVIEWER('Property','Value',...) creates a new TTPREVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TTPReviewer_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TTPReviewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%

% Last Modified by GUIDE v2.5 12-Apr-2009 13:54:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TTPReviewer_OpeningFcn, ...
                   'gui_OutputFcn',  @TTPReviewer_OutputFcn, ...
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


% --- Executes just before TTPReviewer is made visible.
function TTPReviewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TTPReviewer (see VARARGIN)

if isempty(varargin)
  complainAndClose();
end

% Try to load TTPwavesBB.mat or TTPwaves.mat
temp = varargin{1};
handles.path = temp{1};
if exist(fullfile(handles.path, 'TTPwavesBB.mat'), 'file')
  handles.filename = 'TTPwavesBB.mat';
elseif exist(fullfile(handles.path, 'TTPwaves.mat'), 'file')
    handles.filename = 'TTPwaves.mat';
else
  uiwait(msgbox('Must provide a path containing TTPwavesBB.mat or TTPwaves.mat'));
  error('Bad path');
end

  loadVar = load(fullfile(handles.path, handles.filename));

handles.TTPwaves = loadVar.TTPwaves;

handles.badRatingColor = [0 1 0];  % Green
handles.goodColor = [0 0 1];       % Blue
handles.notGoodColor = [0.6 0.6 0.6];  % Gray



handles.nWaves = str2double(get(handles.txtNWaves, 'String'));
handles.firstWave = 1;
handles.waveHs = [];  % Handles to the displayed waves
handles.peakHs = [];  % Handles to the circles at each wave's peak
handles.selected = NaN;

% Get rid of axis ticks
activateAxes(gcbf, handles.axWaves);
hold on;
set(handles.axWaves, 'XTick', []);
set(handles.axWaves, 'YTick', []);
set(handles.axWaves, 'XColor', 'w');
set(handles.axWaves, 'YColor', 'w');
set(handles.axWaves, 'DrawMode', 'fast');

% Make clicking the background deactivate an active wave
set(handles.axWaves, 'ButtonDownFcn', @deactivateWaves);

handles.minRating = str2double(get(handles.txtMinRating, 'String'));

includeExcludeEnabling(handles);
previousNextEnabling(handles);

displayWaves(handles);
handles = guidata(hObject);


% Choose default command line output for TTPReviewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TTPReviewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TTPReviewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATION FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------

% IMPORTANT:

% Create functions execute during object creation, after setting all
% properties.

% handles    empty - handles not created until after all CreateFcns called

% These are almost all useless.


function txtNWaves_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtMinRating_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------


function txtNWaves_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtNWaves as text
%        str2double(get(hObject,'String')) returns contents of txtNWaves as a double
% Ensure sane value
val = round(str2double(get(hObject, 'String')));
if isnan(val) || val < 1
  set(hObject, 'String', num2str(handles.nWaves));
  return;
elseif val > length(handles.TTPwaves)
  set(hObject, 'String', num2str(length(handles.TTPwaves)));
  handles.nWaves = length(handles.TTPwaves);
else
  set(hObject, 'String', num2str(val));
  handles.nWaves = val;
end
% Make sure firstWave lines up with a multiple of nWaves + 1
handles.firstWave = 1 + handles.nWaves * floor(handles.firstWave / handles.nWaves);
% Enable previous/next set buttons as appropriate
previousNextEnabling(handles);

displayWaves(handles);



% --- Executes on button press in btnExclude.
function btnExclude_Callback(hObject, eventdata, handles)
% Set selected wave as not good
if ~isnan(handles.selected)
  handles.TTPwaves(handles.selected).good = 0;
  set(hObject, 'Enable', 'off');
  displayWaves(handles);
end



% --- Executes on button press in btnInclude.
function btnInclude_Callback(hObject, eventdata, handles)
% Set selected wave as good
if ~isnan(handles.selected)
  handles.TTPwaves(handles.selected).good = 1;
  set(hObject, 'Enable', 'off');
  displayWaves(handles);
end



% --- Executes on button press in btnPrevSet.
function btnPrevSet_Callback(hObject, eventdata, handles)
handles.firstWave = handles.firstWave - handles.nWaves;
displayWaves(handles);



% --- Executes on button press in btnNextSet.
function btnNextSet_Callback(hObject, eventdata, handles)
handles.firstWave = handles.firstWave + handles.nWaves;
displayWaves(handles);



% --- Executes on button press in chkShowTime.
function chkShowTime_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of chkShowTime
displayWaves(handles);



% --- Executes on button press in btnDone.
function btnDone_Callback(hObject, eventdata, handles)
% Save down new 'good' specifications, marking waves that are below the
% rating threshold as bad.
TTPwaves = handles.TTPwaves;
for w = 1:length(TTPwaves)
  if TTPwaves(w).rating < handles.minRating
    TTPwaves(w).good = 0;
  end
end
save(fullfile(handles.path, handles.filename), 'TTPwaves');
close(gcbf);



function txtMinRating_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtMinRating as text
%        str2double(get(hObject,'String')) returns contents of txtMinRating as a double
val = str2double(get(hObject, 'String'));
if isnan(val)
  set(hObject, 'String', num2str(handles.minRating));
else
  handles.minRating = val;
end
displayWaves(handles);



%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NON-CALLBACK FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------


function displayWaves(handles)
% Find last wave to display
maxWave = min(handles.firstWave + handles.nWaves - 1, length(handles.TTPwaves));
% If user is viewing last set of waveforms, enable Done button
if maxWave == length(handles.TTPwaves)
  set(handles.btnDone, 'Enable', 'on');
end
% De-select waves
handles.selected = NaN;
handles.waveHs = [];
handles.peakHs = [];
activateAxes(gcbf, handles.axWaves);
cla;
hold on;
maxLen = 0;
theMax = 0;
theMin = -1;
% Display each wave
for w = handles.firstWave:maxWave
  % Color based on whether the rating passes muster and whether the wave is
  % marked good or not.
  if handles.TTPwaves(w).rating < handles.minRating
    color = handles.badRatingColor;
  elseif handles.TTPwaves(w).good
    color = handles.goodColor;
  else
    color = handles.notGoodColor;
  end
  
  
  % Find min, normalize wave, plot it, set ButtonDownFcn so it can be
  % activated by clicking it.
  [thisMin, mini] = min(handles.TTPwaves(w).wave);
  normWave = handles.TTPwaves(w).wave / -thisMin;
  alignPt = mini - 1 + find(handles.TTPwaves(w).wave(mini:end) > 0, 1);
  % Handle pathological case
  if isempty(alignPt)
    alignPt = floor(length(normWave) / 2);
  end
  xs = ((0 : length(handles.TTPwaves(w).wave)-1)+(125-alignPt)) * 1000000/handles.TTPwaves(w).sampleRate;
  hw = plot(xs, normWave, 'color', color, 'LineWidth', 1);
  set(hw, 'ButtonDownFcn', @clickWave);
  handles.waveHs(end+1) = hw;
  
  theMax = max(theMax, max(normWave));
  maxLen = max(maxLen, length(handles.TTPwaves(w).wave));
  
  % Plot peak circle
  TTPx = xs(mini) + handles.TTPwaves(w).TTP;
  TTPy = normWave(mini + round(handles.TTPwaves(w).TTP * handles.TTPwaves(w).sampleRate/1000000));
  hp = plot(TTPx, TTPy, 'ko', 'MarkerSize', 6);
  handles.peakHs(end+1) = hp;
end

% Make a selected wave thick
if ~isnan(handles.selected)
  sel = handles.selected - handles.firstWave + 1;
  set(handles.waveHs(sel), 'LineWidth', 3);
  set(handles.peakHs(sel), 'LineWidth', 3);
end

% If requested, show time axis
if get(handles.chkShowTime, 'Value')
  maxVal = maxLen * 1000000 / handles.TTPwaves(1).sampleRate;
  maxVal = 100 * floor(maxVal / 100);
  params.tickLocations = (0:100:maxVal);
  params.tickLabelLocations = params.tickLocations;
  params.tickLabels = {};
  for v = 0:100:maxVal
    params.tickLabels{end+1} = num2str(v);
  end
  params.fontSize = 11;
  params.axisOffset = -1.05;
  AxisMMC(0, params.tickLocations(end), params);
end

axLims([-10 maxLen * 1000000/handles.TTPwaves(w).sampleRate 1.2*theMin, 1.1*theMax]);
previousNextEnabling(handles);
guidata(handles.axWaves, handles);



function complainAndClose()
uiwait(msgbox('TTPReviewer should be called with TTPwaves as an argument', 'Need argument', 'warn'));
error('TTPReviewer needs to be called with TTPWaves as an argument');



function activateAxes(hf, ha)
% Use instead of axes(ha). If the axes already exist, it skips bringing the
% plot to the front, giving focus, etc. and runs *much* faster (>1000x).
try
  set(hf, 'CurrentAxes', ha);
catch
  axes(ha);
end



function axLims(limits)
% Use instead of axis(axLim) to set axis limits. Skips whatever else axis
% does, runs *much* faster (>1000x).
ha = gca;
try
  set(ha, 'XLim', limits(1:2));
  set(ha, 'YLim', limits(3:4));
catch
  axis(limits);
end


function includeExcludeEnabling(handles)
s = handles.selected;
if ~isnan(s)
  if handles.TTPwaves(s).good
    set(handles.btnExclude, 'Enable', 'on');
    set(handles.btnInclude, 'Enable', 'off');
  else
    set(handles.btnExclude, 'Enable', 'off');
    set(handles.btnInclude, 'Enable', 'on');
  end
else
  set(handles.btnExclude, 'Enable', 'off');
  set(handles.btnInclude, 'Enable', 'off');
end



function previousNextEnabling(handles)
if handles.firstWave > 1
  set(handles.btnPrevSet, 'Enable', 'on');
else
  set(handles.btnPrevSet, 'Enable', 'off');
end
if handles.firstWave + handles.nWaves - 1 < length(handles.TTPwaves)
  set(handles.btnNextSet, 'Enable', 'on');
else
  set(handles.btnNextSet, 'Enable', 'off');
end



function clickWave(hObject, eventdata)
handles = guidata(hObject);
waveNum = find(handles.waveHs == hObject);
handles.selected = handles.firstWave - 1 + waveNum;
for h = handles.waveHs
  set(h, 'LineWidth', 1);
end
for h = handles.peakHs
  set(h, 'LineWidth', 1);
end
set(hObject, 'LineWidth', 3);
set(handles.peakHs(waveNum), 'LineWidth', 3);
includeExcludeEnabling(handles);
guidata(hObject, handles);



function deactivateWaves(hObject, eventdata)
handles = guidata(hObject);
handles.selected = NaN;
for h = handles.waveHs
  set(h, 'LineWidth', 1);
end
for h = handles.peakHs
  set(h, 'LineWidth', 1);
end
includeExcludeEnabling(handles);
guidata(hObject, handles);


