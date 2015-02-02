function varargout = mksort(varargin)
% mksort. It's a heck of a spikesorter.
%
% This is the master component of MKsort. See user documentation.
%
% This software, MKsort, allows users to import electrophysiology data and
% classify waveforms as coming from different units ("sort spikes"). It
% also provides tools for examining the stability of these isolations over
% time, rating the isolations, measuring spike widths, and examining the
% functional tuning of the sorted units.
% 
% Copyright (C) 2010, 2011, 2012, 2013 The Board of Trustees of The Leland
% Stanford Junior University
% 
% Written by Matt Kaufman
% antimatt+ss AT gmail DOT com
% One Bungtown Road
% Cold Spring Harbor, NY 11724
% 
% Distribution and contributions by Ripple LLC
% 
% Report bugs to https://github.com/ripple-neuro/mksort/issues or send email
% to support@rppl.com.
% 
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; version 2 of the License.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.�See the GNU General
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA� 02110-1301, USA.

% GUIDE help immediately below
% mksort M-mnufile for mksort.fig
%      mksort, by itself, creates a new mksort or raises the existing
%      singleton*.
%
%      H = mksort returns the handle to a new mksort or the handle to
%      the existing singleton.
%
%      mksort('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in mksort.m with the given input arguments.
%
%      mksort('Property','Value',...) creates a new mksort or raises the
%      existing singleton.  Starting from the left, property value pairs are
%      applied to the GUI before mksort_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mksort_OpeningFcn via varargin.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 31-Oct-2011 22:47:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mksort_OpeningFcn, ...
                   'gui_OutputFcn',  @mksort_OutputFcn, ...
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


% SEE ALSO: oneChannelSorter.m

% Key data structures:

% ---------------------------------------------------------------------------------------
% waveforms structures (one per channel) -- if this struct is changed, it must also
%   be changed in function checkWaveformsStruct:
% 
% waveforms
%   .electrode  (matches electrode in previews)
%   .spikeTimes(nWaves)
%   .waves(nPts, nWaves)   (in mV)
%   .alignedWaves(nPts - q, nWaves) [ =[] ]  (q may be 0 or 1 or 2)
%   .alignMethodFcn [ ='' ]
%   .units(nWaves) [ =zeros ]
%   .sorted = 0|1
%   .array [ = NaN ]
%   .ratings(nEpochs)
%     .ratings(nMaxUnits)
%     .epoch = [start stop]
%   .trialInfo [ =[] ]
%     .trial(nWaves)
%     .condition(nTrials)
%     .trialStartTimes(nTrials)
%     .trialEndTimes(nTrials)
%   .sourceFiles
%     .filenames{nFiles}
%     .spikesByFile(nFiles x 2)
% 
% ----------------------------------------------------------------------------------------
% previews structure (in previews.mat):
% 
% previews(channel)
%   .electrode
%   .array [ = NaN ]
%   .throughDay
%     (same as waveforms struct, but with subsampled waveforms for quick display in multi-view)
%   .throughDayAligned [ = [] ]  (aligned version of throughDay if this channel has been sorted)
%   .throughDayUnits (which units throughDay waves belong to, again for plotting)
%   .throughDaySpikeNums  (the spike numbers of throughDay -- needed to sort with epochs)
%   .PCAPts [ = [] ]
% 
% -----------------------------------------------------------------------------------------
% sorting structure (in sorts.mat and internal to oneChannelSorter):
% 
% sorts(channel)
%   .sorts(nEpochs)
%     .epochStart   (in spike indices)
%     .epochEnd    (in spike indices)
%     .alignMethodFcn [ =[] ]
%     .sortMethodFcn [ =[] ]
%     .(methodType)
%       .unitsDefined   (list of units defined)
%       .differentiated = 0|1
%       .ratings = [] | length(nUnitsTotal)
%       .waveLims = [start end]
%       .params(>=maxUnitDefined+1)
%         .acceptance
%         .(other fields internal to this type)
%     ...
%   .electrode
%   .array [ = NaN ]
%   .nPCADims [ =0 ]
%   .autocorrs(nUnits)
%     .lags(nTimes+1)
%     .values(nTimes)
%     .percRefractoryViolations
%     .lockout = 1.6 | 1.0666, usually
%   .waveEnvelope(4)
%     .bottom [ = [] ]
%     .top [ =[] ]
%   .onlineSorted = 0|1
%   .userSorted = 0|1
%   .fullySorted = 0|1
%   .rated = 0|1  (if userSorted == 0, .rated == 0; this is whether all sorts have been hand-rated)
%   .maxRatings [ = zeros(1, 4) ]
%   .viewMode = 'Waveform' | 'PCA'
%   .differentiated = 0|1
% 
% ----------------------------------------------------------------------------------------
% mksort->oneChannelSorter communication structure:
% 
% channelInfo
%   .sorts
%   .preview
%   .path
%   .array
%   .thisChannel
% ----------------------------------------------------------------------------------------



% Below lines present to make it possible to compile with mcc

%#function mergeHandsortsIntoR
%#function sortByTemplate
%#function sortByPCAEllipses
%#function trialInfoFromR



% --- Executes just before mksort is made visible.
function mksort_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% varargin   command line arguments to mksort (see VARARGIN)

% Choose default command line output for mksort
handles.output = hObject;

handles.trialInfoFcns = [];
handles.mergeSortsIntoDataFcns = [];

% Check that helpers have been sourced.  This ensures that if mksort has 
% already been run one in the given Matlab session, that we don't continue
% to add endlessly to the path.  If you add a source directory, you may need to 
% clear the path before this will run.
w = which('oneChannelSorter');
fPath = fileparts(which('mksort'));
if isempty(w)
  addpath(fullfile(fPath, 'alignWaves'));
  addpath(fullfile(fPath, 'dataImportWizard'));
  addpath(fullfile(fPath, 'fileExtraction'));
  addpath(fullfile(fPath, 'merge'));
  addpath(fullfile(fPath, 'singleChannelEngine'));
  addpath(fullfile(fPath, 'sortAlgorithms'));
  addpath(fullfile(fPath, 'sortEngine'));
  addpath(fullfile(fPath, 'stats'));
  addpath(fullfile(fPath, 'trialConditionInfo'));
  addpath(fullfile(fPath, 'TTPTool'));
  addpath(fullfile(fPath, 'userCustomizable'));
  addpath(fullfile(fPath, 'util'));
  addpath(fullfile(fPath, 'aboutDialog'));
  addpath(fullfile(fPath, 'splashScreen'));
end

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% INITIALIZE APPLICATION VARIABLES
% USER-CUSTOMIZABLE
%--------------------------------------------------------------------------

% Main GUI options

% Number of rows and columns per screenful
handles.nRows = 6;
handles.nCols = 8;

handles.waveMultiplier = 0.001;  % Scales the waveforms

handles.ptsToShow = 32;          % Max waveform length, in samples, to display

handles.nWavesPerChannel = 75;   % Default # of waveforms to display from each channel
handles.nClusterPtsPerChannel = 100; % Same for PCA


% File options
% handles.defaultDataDir = '/data/SS';


% Set up for functions to add trial/condition info into sorts
trialInfoFcn = [];
trialInfoFcn.extraArgs = {};


% Set up for merge functions
mergeSortsIntoDataFcn = [];
mergeSortsIntoDataFcn.extraArgs = {};


% Colors for channel backgrounds
handles.userSortedRatedColor = [1 1 1];              % White
handles.userSortedUnratedColor = [0.92 0.92 0.92];   % Light gray
handles.onlineSortedRatedColor = [1 1 0.9];          % Light yellow
handles.onlineSortedUnratedColor = [1 0.95 0.89];    % Tan
handles.unsortedColor = [1 0.9 0.9];                 % Red-pink
handles.modifiedRatedColor = [0.8 0.8 0.8];          % Gray
handles.modifiedUnratedColor = [0.85 0.77 0.77];     % Gray-red



% Whether to catch an error produced by a dataExtractionFcn or 
% mergeSortsIntoDataFcn. 1 makes for a nice, friendly interface but makes
% debugging the algorithm harder, since the error is caught.
handles.gentleExternFcnFail = 1;

handles.redRefracViolThresh = 2;    % Percent refractory violations before showing # in red

if ~isfield(handles, 'threshold')
  handles.threshold = 1.2;          % Initial display threshold. 1.2 is nice.
end

handles.maxUnits = 4;               % Max number of units that can be handled

shrinkFonts = 1;                    % Cross-platform font size issue. Whether to shrink font size on linux.

% Set pref defaults

% Call the user-defined function setup for trial/condition info function
% and merge functions
try
  userPrefsMKsort;
catch me
  uiwait(msgbox(sprintf('Problem loading user preferences file.\nError was: %s.\nUser preferences file will be ignored past that point.', me.message), 'Pref load failed', 'modal'));
end

% TODO: If mksort is run multiple times, the trial condition->R structure
% tab gets added... multiple times.
% Ensure valid prefs
if ~isfield(handles, 'defaultDataDir') || ~ischar(handles.defaultDataDir)
  handles.defaultDataDir = '/data/SS';
end
if ~isfield(handles, 'trialInfoFcns') || ~iscell(handles.trialInfoFcns) || ~isfield(handles.trialInfoFcns{end}, 'label') || ~isfield(handles.trialInfoFcns{end}, 'fcn')
  fprintf('Using defaults for trialInfoFcns\n');
  trialInfoFcn = [];
  trialInfoFcn.label = 'R structure';
  trialInfoFcn.fcn = 'trialInfoFromR';
  handles.trialInfoFcns = {trialInfoFcn};
end
if ~isfield(handles, 'mergeSortsIntoDataFcns') || ~iscell(handles.mergeSortsIntoDataFcns) || ~isfield(handles.mergeSortsIntoDataFcns{end}, 'label') || ~isfield(handles.mergeSortsIntoDataFcns{end}, 'fcn')
  fprintf('Using defaults for mergeSortsIntoDataFcns\n');
  mergeSortsIntoDataFcn = [];
  mergeSortsIntoDataFcn.label = 'R structure';
  mergeSortsIntoDataFcn.fcn = 'mergeHandsortsIntoR';
  mergeSortsIntoDataFcn.extraArgs = {};
  handles.mergeSortsIntoDataFcns = {mergeSortsIntoDataFcn};
end
if ~exist('defaultTrialInfoFcn', 'var')
  defaultTrialInfoFcn = 'trialInfoFromR';
end
if ~exist('defaultMergeSortsIntoDataFcn', 'var')
  defaultMergeSortsIntoDataFcn = 'mergeHandsortsIntoR';
end



%--------------------------------------------------------------------------
% END OF (STRAIGHTFORWARD) USER-CUSTOMIZABLE VARIABLES
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------




% Things in here only need to be done when mksort is launched from the
% command line, not when it's raised by oneChannelSorter.
if isempty(varargin)
  % Check if mksort has already been open.  This may allow for positioning
  % mksort window based on screen resolution or user preferences.
  if ~isfield(handles, 'isopen')
    % Load splash screen
    splashScreen(fullfile(fPath, 'splashScreen/mksort_splash_square.png'), 2);
    handles.isopen = 1;
    % if this is the first open, position mksort to be in the center of the
    % screen and use 1/3 of the horizontal real estate and most of the
    % vertical.
    % TODO: allow for user preferences to determine screen size.
    screenSize = get(0, 'ScreenSize');
    % these parameters were found entirely by trial and error, but seem to
    % work on a variety of monitors.
    defaultWidth = 0.5 * screenSize(3);
    defaultHeight = 0.85 * screenSize(4);

    % get whatever the orginal units are, should be 'characters'
    units = get(handles.figure1, 'units');
    set(handles.figure1, 'units', 'pixels');
    set(handles.figure1, 'position', ...
      [(screenSize(3) - defaultWidth) / 2, ...
      (screenSize(4) - defaultHeight) / 2, defaultWidth, defaultHeight]);
    % set units back to orginal in case there's some code expecting it
    set(handles.figure1, 'units', units);
  end
  % Should match oneChannelSorter
  handles.sortColors = [0.5 0.5 0.5;
    0 0 1;
    1 0 0;
    0 1 0;
    0.5 0 0.5];

  handles.spacing = 0.01;  % How much margin to leave in each channel, so we avoid the border

  handles.gridColor = [0.7 0.7 0.7];

  handles.fastSave = 1;

  handles.autocorrHs = [handles.axISI1, handles.axISI2, handles.axISI3, handles.axISI4];

  handles.dataExtractOption = 1;  % Will be overriden by fixChecks
  handles.trialInfoOption = 1;    % Will be overriden by fixChecks
  handles.sortMergeOption = 1;    % Will be overriden by fixChecks
  
  % Keep the handle to the instance of oneChannelSorter so that we can
  % close it when mksort is closed
  handles.oneChannelSorterH = [];
  
  % The data directory
  handles.dataDir = '';
  
  handles.cerebusFilters = {'HP 100 Hz', 'HP 250 Hz', 'HP 750 Hz', ...
  '"Spike Narrow" Cerebus v.4 or lower', ...
  '"Spike Medium" Cerebus v.4 or lower', ...
  '"Spike Wide" Cerebus v.4 or lower'};
  
  
  % Generate trial/condition info function options menu
  tifs = handles.trialInfoFcns;
  for tif = 1:length(handles.trialInfoFcns)
    handles.(['mnu' tifs{tif}.fcn]) = uimenu(handles.mnuTrialInfoOptions, ...
      'Tag', ['mnu' tifs{tif}.fcn], 'Label', tifs{tif}.label, ...
      'Callback', 'mksort(''fixChecks'',gcbo,[],guidata(gcbo))');
  end

  % Select default data extraction option
  children = get(handles.mnuTrialInfoOptions, 'Children');
  for child = children
    set(child, 'Checked', 'off');
  end
  set(handles.(['mnu' defaultTrialInfoFcn]), 'Checked', 'on');

  
  % Generate merge sorts into data function options menu
  smfs = handles.mergeSortsIntoDataFcns;
  for smf = 1:length(handles.mergeSortsIntoDataFcns)
    handles.(['mnu' smfs{smf}.fcn]) = uimenu(handles.mnuSortMergeOptions, ...
      'Tag', ['mnu' smfs{smf}.fcn], 'Label', smfs{smf}.label, ...
      'Callback', 'mksort(''fixChecks'',gcbo,[],guidata(gcbo))');
  end

  % Select default data extraction option
  children = get(handles.mnuSortMergeOptions, 'Children');
  for child = children
    set(child, 'Checked', 'off');
  end
  set(handles.(['mnu' defaultMergeSortsIntoDataFcn]), 'Checked', 'on');
  
  
  % Set # waves/channel to display
  set(handles.txtNWaves, 'String', num2str(handles.nWavesPerChannel));

  % Set threshold
  set(handles.txtThreshold, 'String', num2str(handles.threshold));
  
  % Set WindowButtonDownFcn so we can handle clicks in axMulti
  set(hObject, 'WindowButtonDownFcn', @multiClick);
  
  % Set font sizes on linux, since default fonts on linux are really big.
  % Can't use islinux, since that returns true for Mac as well
  sysType = computer;
  if strcmp(sysType, 'GLNX86') || strcmp(sysType, 'GLNXA64')
    handles.isLinux = 1;
    if shrinkFonts
      for h = findobj(hObject,'FontSize', 10)'
        set(h, 'FontSize', 8);
      end
    end
  else
    handles.isLinux = 0;
  end
  
  % When mksort is closed, we want oneChannelSorter to be closed, too.
  set(hObject, 'CloseRequestFcn', @closeApps);
end



% If mksort was called by oneChannelSorter with an argument, that
% means the user has sorted a channel. So, process the sorted channel.
% Otherwise, set up data fields with empty/NaN values and set up display.
if length(varargin) == 2
  handles = processNewChannel(handles, varargin{1}, varargin{2});
  handles.selectedCh = varargin{2};
  guidata(hObject, handles);
  displayChannels(handles);
else
  handles.previews = [];
  handles.sorts = [];
  handles.firstRow = NaN;

  handles.selectedCh = NaN;
  handles.selectionRectH = NaN;

  % Get rid of ticks for all axes, set properties to accelerate drawing
  for child = get(hObject, 'Children')'
    if strcmp(get(child, 'Type'), 'axes')
      activateAxes(gcbf, child);
      hold on;
      set(child, 'XTick', []);
      set(child, 'YTick', []);
      set(child, 'XColor', 'w');
      set(child, 'YColor', 'w');
      setupAxesForFastDraw(child);
    end
  end
  guidata(hObject, handles);
end


% UIWAIT makes mksort wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mksort_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure

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

function sldMulti_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function txtNWaves_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function txtThreshold_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK FUNCTIONS (NON-MENU)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------


% --- Executes on slider movement.
function sldMulti_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% Try block because nothing may be loaded
try
  handles.firstRow = handles.maxFirstRow - round(get(hObject, 'Value')) + 1;
  set(hObject, 'Value', round(get(hObject, 'Value')));
  displayChannels(handles);
end



% --- Executes on button press in btnSortChannels.
function btnSortChannels_Callback(hObject, eventdata, handles)
% Sort each channel that isn't marked fully sorted, since that means a fast
% save was performed on it.

% We must first close oneChannelSorter so that we don't accidentally render
% into it if the user clicks it in impatience.
success = closeOneChannelSorter(handles.oneChannelSorterH);
if ~success
  uiwait(msgbox('Could not close oneChannelSorter. Sorting aborted.', 'modal'));
  return;
end

set(gcbf, 'Pointer', 'watch');
drawnow;

channels = find(~[handles.sorts.fullySorted]);
if ~isempty(channels)
  hw = waitbar(0, 'Sorting modified channels', 'Name', 'Sorting');
  for ch = 1:length(channels)
    handles = sortModifiedCh(handles, channels(ch));
    figure(handles.figure1);
    displayChannels(handles);
    waitbar(ch/length(channels), hw);
    figure(hw);
    drawnow;
    handles = guidata(handles.axMulti);
  end
end

try delete(hw); end;
set(gcbf, 'Pointer', 'arrow');
% uiwait(msgbox('All channels sorted'));



function txtNWaves_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtNWaves as text
%        str2double(get(hObject,'String')) returns contents of txtNWaves as a double
% Ensure sane value
val = round(str2double(get(hObject, 'String')));
if isnan(val) || val < 1
  set(hObject, 'String', num2str(handles.nWavesPerChannel));
else
  handles.nWavesPerChannel = val;
end
displayChannels(handles);



function txtThreshold_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtThreshold as text
%        str2double(get(hObject,'String')) returns contents of txtThreshold as a double
% Ensure sane value
val = str2double(get(hObject, 'String'));
if isnan(val) || val < 1
  set(hObject, 'String', num2str(handles.threshold));
else
  handles.threshold = val;
end
displayChannels(handles);





%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK FUNCTIONS (MENUS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------



function mnuAbout_Callback(hObject, eventdata, handles)
% Load about dialog with info about Stanford licensing and GPLv2 details.
uiwait(aboutDialog());

function mnuLoadPreview_Callback(hObject, eventdata, handles)
% Get directory to load.
while 1
  try
    handles.dataDir = uigetdir(handles.defaultDataDir, 'Select data directory');
  catch
    handles.dataDir = uigetdir('.', 'Select data directory');
  end
  if handles.dataDir == 0
    return;
  % Make sure there are appropriately-named files in this directory.
  elseif ~exist(fullfile(handles.dataDir, 'sorts.mat'), 'file') || ~exist(fullfile(handles.dataDir, 'previews.mat'))
    uiwait(msgbox('Please select a directory containing extracted waveform files, a sorts.mat file, and a previews.mat file', '', 'help', 'modal'));
    continue;
  else
    break;
  end
end

loadDirectory(handles);



function mnuExtractDataFiles_Callback(hObject, eventdata, handles)
opts.defaultDataDir = handles.defaultDataDir;
opts.gentleExternFcnFail = handles.gentleExternFcnFail;
uiwait(dataImportWizard(opts));



function mnuAddTrialInfo_Callback(hObject, eventdata, handles)
% Check for no file loaded
if isempty(handles.previews)
    uiwait(msgbox('No neural data loaded'));
    return; 
end;

addTrialInfoOpt = handles.trialInfoFcns{handles.trialInfoOption};
set(gcbf, 'Pointer', 'watch');
drawnow;

% Run add trial/condition info function, catch errors only if
% gentleExternFcnFail == 1.
evalStr = [addTrialInfoOpt.fcn '(''' handles.dataDir ''')'];
if handles.gentleExternFcnFail
  try
    eval(evalStr);
  catch err
    uiwait(msgbox(sprintf('Adding trial/condition info failed. Error was: %s : %s', err.identifier, err.message), 'modal'));
  end
else
  eval(evalStr);
end

set(gcbf, 'Pointer', 'arrow');



function mnuMergeSorts_Callback(hObject, eventdata, handles)
% Check for no file loaded

if isempty(handles.previews)
    uiwait(msgbox('No neural data loaded'));
    return; 
end;

if any(~[handles.sorts.fullySorted])
  uiwait(msgbox('All channels must be fully sorted before merge. Please click the ''Sort modified channels'' button before merging.'), 'modal');
  return;
end

% Merge handsorts into a data structure of the user's choosing.
[RFilename, RPath] = uigetfile(handles.dataDir, 'Select file with behavioral data to merge into:');
if RFilename == 0, return; end;   % Handle cancel
[pathstr, RName, RExt] = fileparts(RFilename);
suggestedNewName = fullfile(RPath, [RName ',ss' RExt]);
[newRFilename, newRFilePath] = uiputfile(suggestedNewName, 'File to save merged data:');
if newRFilename == 0, return; end;

% Figure out which extraction option is selected
extractOpt = handles.mergeSortsIntoDataFcns{handles.sortMergeOption};

% Same logic as above.
set(handles.lblMergingSortsWait, 'Visible', 'on');
set(gcbf, 'Pointer', 'watch');
drawnow;
if ~isempty(extractOpt.extraArgs)
  error('extra arguments not implemented yet');
else
  if handles.gentleExternFcnFail
    try
      feval(extractOpt.fcn, handles.dataDir,fullfile(RPath, RFilename), fullfile(newRFilePath, newRFilename));
    catch err
      uiwait(msgbox(sprintf('Merge failed. Error was: %s : %s', err.identifier, err.message), 'modal'));
    end
  else
    feval(extractOpt.fcn, handles.dataDir, fullfile(RPath, RFilename), fullfile(newRFilePath, newRFilename));
  end
end
set(handles.lblMergingSortsWait, 'Visible', 'off');
set(gcbf, 'Pointer', 'arrow');



function mnuDispDataDir_Callback(hObject, eventdata, handles)
if isempty(handles.dataDir)
  uiwait(msgbox('No data loaded', 'modal'));
else
  uiwait(msgbox(handles.dataDir, 'Data directory'));
end



function mnuTTP_Callback(hObject, eventdata, handles)

% Check for no file loaded
if isempty(handles.previews), return; end;
% Check all channels sorted
if ~all([handles.sorts.fullySorted])
  uiwait(msgbox('All modified channels must be processed before using this option', 'modal'));
  return;
end

filenames = getSortedFilenames(handles);
if isempty(filenames)
  uiwait(msgbox('no channels are sorted.'));
  return;
end
% Ask user for rating threshold
ratingThreshold = requestMinRating(handles);

% Check for user cancel
if isempty(ratingThreshold), return; end;

set(gcbf, 'Pointer', 'watch');
set(handles.lblTTPsWait, 'Visible', 'on');
drawnow;

% Re-filter data
% Do all the real computation, generate TTPwaves.mat
TTPwaves = prepWavesForTTPs(handles.dataDir, filenames, ratingThreshold);
set(gcbf, 'Pointer', 'arrow');
set(handles.lblTTPsWait, 'Visible', 'off');

if isempty(TTPwaves)
  uiwait(msgbox('no sorted waves crossed rating threshold'));
else
  save(fullfile(handles.dataDir, 'TTPwaves.mat'), 'TTPwaves');
  % Launch waveform reviewer
  mnuReviewTTPs_Callback(hObject, [], handles);
  % Load results
  mnuPlotTTPs_Callback(hObject, [], handles);
end
% save(fullfile(handles.dataDir, 'TTPwaves.mat'), 'TTPwaves');
% 
% 
% % Launch waveform reviewer
% mnuReviewTTPs_Callback(hObject, [], handles);
% 
% set(gcbf, 'Pointer', 'arrow');
% set(handles.lblTTPsWait, 'Visible', 'off');
% 
% % Load results
% mnuPlotTTPs_Callback(hObject, [], handles);

function mnuTTPBB_Callback(hObject, eventdata, handles)

% Check for no file loaded
if isempty(handles.previews), return; end;
% Check all channels sorted
if ~all([handles.sorts.fullySorted])
  uiwait(msgbox('All modified channels must be processed before using this option', 'modal'));
  return;
end

[filenames, unitArrays] = getSortedFilenames(handles);
% Ask user for rating threshold
ratingThreshold = requestMinRating(handles);

% Check for user cancel
if isempty(ratingThreshold), return; end;

arrays = unique([handles.previews.array]);
if any(isnan(arrays)), arrays = 1; end

% Ask user for broadband file(s)
BBPath{1} = handles.dataDir;
if length(arrays) == 1
  [BBFilename{1}, BBPath{1}] = uigetfile(fullfile(BBPath{1}, '*.ns5'), 'Select file with broadband data:');
  if BBFilename{1} == 0, return; end;   % Handle cancel
  if ~strcmp(BBFilename{1}, 'bb001.ns5')
    uiwait(msgbox('Filename must be bb001.ns5', 'modal'));
    return;
  end
else
  alpha = alphabet();
  for arr = 1:length(arrays)
    [BBFilename{arr}, BBPath{arr}] = uigetfile(fullfile(BBPath{1}, '*.ns5'), sprintf('Select file with broadband data for array %d:', arrays(arr)));
    if BBFilename{arr} == 0, return; end;   % Handle cancel
    if ~strcmp(BBFilename(arr), sprintf('bb%c001.ns5', alpha(arrays(arr))))
      uiwait(msgbox('Filename must be bbL001.ns5, where L corresponds to the letter for that array', 'modal'));
      return;
    end
  end
end

% Ask user for filter settings
uiwait(getFilterSelection(handles, hObject));
filtname = get(hObject, 'UserData');
if isempty(filtname)
  return;
end

set(gcbf, 'Pointer', 'watch');
set(handles.lblTTPsWait, 'Visible', 'on');
drawnow;

% Loop through each BB file and collect TTPwaves
TTPwaves = [];
sorts = handles.sorts;
theseFilenames = filenames;
theseSorts = sorts;
for arr = 1:length(arrays)
  if length(arrays) > 1
    theseFilenames = filenames(unitArrays == arrays(arr));
    theseSorts = sorts([sorts.array] == arrays(arr));
  end
  try
    theseTTPwaves = prepWavesForTTPsBB(handles.dataDir, theseSorts, fullfile(BBPath{arr}, BBFilename{arr}), theseFilenames, ratingThreshold, filtname);
    for u = 1:length(theseTTPwaves)
      theseTTPwaves(u).array = arrays(arr);
    end
    TTPwaves = [TTPwaves, theseTTPwaves];
  catch err
    uiwait(msgbox(err.message, 'modal'));
    return;
  end
end
save(fullfile(handles.dataDir, 'TTPwavesBB.mat'), 'TTPwaves');

% Launch waveform reviewer
mnuReviewTTPs_Callback(hObject, [], handles);

set(gcbf, 'Pointer', 'arrow');
set(handles.lblTTPsWait, 'Visible', 'off');

% Load results
mnuPlotTTPs_Callback(hObject, [], handles);



function mnuReviewTTPs_Callback(hObject, eventdata, handles)

% Check for no file loaded
if isempty(handles.previews), return; end;

if ~exist(fullfile(handles.dataDir, 'TTPwavesBB.mat'), 'file') && ...
    ~exist(fullfile(handles.dataDir, 'TTPwaves.mat'), 'file')
  msgbox('Calculate TTP durations first.');
else
  set(gcbf, 'Pointer', 'watch');
  try
    uiwait(TTPReviewer({handles.dataDir}));
  catch err
    warning(err.message);
  end
  set(gcbf, 'Pointer', 'arrow');
end



function mnuPlotTTPs_Callback(hObject, eventdata, handles)

% Check for no file loaded
if isempty(handles.previews), return; end;

if exist(fullfile(handles.dataDir, 'TTPwavesBB.mat'), 'file')
  TTPFilename = 'TTPwavesBB.mat';
elseif exist(fullfile(handles.dataDir, 'TTPwaves.mat'), 'file')
  TTPFilename = 'TTPwaves.mat';
else
  msgbox('Calculate TTP durations first.');
  return;
end

% Ask user for classification thresholds
while 1
  prompts = {'Max for narrow-spiking (\mus)'; 'Min for broad-spiking (\mus)'};
  winTitle = 'Thresholds';
  defaults = {'170'; '200'};
  nQues = 1;
  options.Interpreter = 'tex';
  answer = inputdlg(prompts, winTitle, nQues, defaults, options);
  if isempty(answer)  % Indicates user hit cancel
    return;
  end
  try
    nsThresh = str2double(answer{1});
    bsThresh = str2double(answer{2});
    if isnan(nsThresh) || isnan(bsThresh)
      uiwait(msgbox('Thresholds must be numbers', 'Invalid input', 'modal'));
    else
      break;
    end
  end
end
loadVar = load(fullfile(handles.dataDir, TTPFilename));
plotTTPs(loadVar.TTPwaves, nsThresh, bsThresh);



function mnuApplyOtherDaysSorts_Callback(hObject, eventdata, handles)

% Check for no file loaded
if isempty(handles.previews), return; end;

% If the user has already sorted some channels, ask if they'd like to
% preserve those sorts (and overwrite unsorted)
if any([handles.sorts.userSorted])
  button = questdlg('Some channels are already sorted. Preserve these sorts (currently unsorted channels will be overwritten)?', 'Sorted channels');
  switch button
    case 'Yes'
      preserve = 1;
    case 'No'
      preserve = 0;
    case 'Cancel'
      return;
  end
else
  preserve = 0;
end

% Get directory to apply sorts from
while 1
  path = uigetdir(handles.dataDir, 'Select data directory');
  if path == 0 % Handle cancel
    return;
  % Make sure there are appropriately-named files in this directory.
  elseif ~exist(fullfile(path, 'sorts.mat'), 'file')
    uiwait(msgbox('Please select a directory containing a sorts.mat file', '', 'help', 'modal'));
    continue;
  else
    break;
  end
end

% Figure out first available backup name for sorts.mat
back = 1;
while 1
  backupName = sprintf('sorts.bak%d', back);
  if ~exist(fullfile(handles.dataDir, backupName), 'file')
    break;
  end
  back = back + 1;
end


try
  % Load desired sorts.mat
  loadVar = load(fullfile(path, 'sorts.mat'));
  sorts = loadVar.sorts;
catch
  % Check for load failure
  uiwait(msgbox('Operation failed, check that source directory permits read', 'Read failed', 'warn', 'modal'));
  return;
end

% Check for match in arrays. Fail if only one is NaN or numbers disagree
if (isnan(sorts(1).array) + isnan(handles.sorts(1).array)) == 1 || ...
    ~isnan(sorts(1).array) && ~isnan(handles.sorts(1).array) && ...
    ~isequal(unique([sorts.array]), unique([handles.sorts.array]))
  uiwait(msgbox('Operation failed, different number of arrays', '', 'warn', 'modal'));
  return;
end



% Copy original sorts.mat to backup
success = copyfile(fullfile(handles.dataDir, 'sorts.mat'), fullfile(handles.dataDir, backupName));
if ~success
  uiwait(msgbox('Operation failed, check that sorts directory is not read-only', 'Copy failed', 'warn', 'modal'));
  return;
end

set(gcbf, 'Pointer', 'watch');
drawnow;

% Compile the array/electrode information for each channel (and correctly
% handle single (NaN) array)
if isnan(sorts(1).array)
  newChInfo = {sorts.electrode};
else
  newChInfo = arrayfun(@(x) [x.array, x.electrode], sorts, 'UniformOutput', false);
end

alpha = alphabet();

% Loop through channels, replace this data with other sorts file's data
chFailed = 0;
for ch = 1:length(handles.sorts)
  % If this channel is sorted, and user asked to preserve sorted channels,
  % skip
  if handles.sorts(ch).userSorted && preserve
    continue;
  end
  
  % Grab data for this channel
  if isnan(sorts(1).array)
    oldChInfo = handles.sorts(ch).electrode;
  else
    oldChInfo = [handles.sorts(ch).array handles.sorts(ch).electrode];
  end

  % Find corresponding channel in other day's data
  newCh = find(cellfun(@(x) isequal(x, oldChInfo), newChInfo));
  
  % If missing the corresponding channel, flag for warning at end
  if isempty(newCh)
    chFailed = 1;
    continue;
  end
  

  % Only copy data if this channel was sorted on one day or the other
  if sorts(newCh).userSorted || handles.sorts(ch).userSorted
    % Need to find this channel's number of waveforms (if applying actual
    % sorts and not "non-sorts"). This isn't cached in sorts.mat unless the
    % user actually sorted this channel, unfortunately. This first option
    % will therefore only help if user isn't using the 'preserve' option.
    if sorts(newCh).userSorted
      if ~isempty(handles.sorts(ch).sorts)
        % User sorted channel, can just snag last epochEnd
        epochEnd = handles.sorts(end).epochEnd;
      else
        % Need to load waveforms file
        if isnan(handles.sorts(ch).array)
          filename = makeWaveFilename('', handles.sorts(ch).electrode);
        else
          filename = makeWaveFilename(alpha(handles.sorts(ch).array), handles.sorts(ch).electrode);
        end
        try
          loadVar = load(fullfile(handles.dataDir, filename));
        catch
          uiwait(msgbox(sprintf('Failed to load file: %s, operation failed', fullfile(handles.dataDir, filename)), 'Load failed', 'modal'));
          return;
        end
        
        epochEnd = size(loadVar.waveforms.waves, 2);
        clear loadVar
      end
    end
    
    handles.sorts(ch) = sorts(newCh);
    % Use only first epoch
    handles.sorts(ch).sorts = handles.sorts(ch).sorts(1);
    handles.sorts(ch).sorts.epochEnd = epochEnd;
    % Mark as not fully sorted, unrated
    handles.sorts(ch).fullySorted = 0;
    handles.sorts(ch).rated = 0;
    % Clear ratings in active sort method.
    maxUnits = length(handles.sorts(ch).maxRatings);
    handles.sorts(ch).maxRatings = zeros(1, maxUnits);
    sortMethod = handles.sorts(ch).sorts.sortMethodType;
    handles.sorts(ch).sorts.(sortMethod).ratings = zeros(1, maxUnits);
  end
end

sorts = handles.sorts;

save(fullfile(handles.dataDir, 'sorts.mat'), 'sorts', '-v6');

set(gcbf, 'Pointer', 'arrow');
drawnow;

if chFailed
  uiwait(msgbox('Some channels did not have corresponding information in the other day''s data. Operation otherwise successful.', 'Missing channels', 'help', 'modal'));
end

loadDirectory(handles);



function mnuShowElectrodeNums_Callback(hObject, eventdata, handles)
checkUncheckMenu(hObject);
displayChannels(handles);



function mnuShowNumUnits_Callback(hObject, eventdata, handles)
checkUncheckMenu(hObject);
displayChannels(handles);



function mnuFastSave_Callback(hObject, eventdata, handles)
fixChecks(hObject, eventdata, handles);

function mnuFullSave_Callback(hObject, eventdata, handles)
fixChecks(hObject, eventdata, handles);



% These are not menus that do anything on click (they contain items)
function mnuFile_Callback(hObject, eventdata, handles)
function mnuOptions_Callback(hObject, eventdata, handles)
function mnuSortMergeOptions_Callback(hObject, eventdata, handles)
function mnuTools_Callback(hObject, eventdata, handles)
function mnuView_Callback(hObject, eventdata, handles)
function mnuTrialInfoOptions_Callback(hObject, eventdata, handles)
function mnuSaveMode_Callback(hObject, eventdata, handles)
function mnuHelp_Callback(hObject, eventdata, handles)



%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------



function fixChecks(hObject, eventdata, handles)
% Make only one option selectable, deal with internal variables
children = get(get(hObject, 'Parent'), 'Children');
for child = children
  set(child, 'Checked', 'off');
end
set(hObject, 'Checked', 'on');

switch get(hObject, 'Parent')
  case handles.mnuTrialInfoOptions
    handles.trialInfoOption = find(children == hObject);
  case handles.mnuSortMergeOptions
    handles.sortMergeOption = find(children == hObject);
  case handles.mnuSaveMode
    handles.fastSave = (hObject == handles.mnuFastSave);
end

guidata(hObject, handles);




function checkUncheckMenu(hObject)
% Check or uncheck a menu item
checked = strcmp(get(hObject, 'Checked'), 'on');
if checked
  set(hObject, 'Checked', 'off');
else
  set(hObject, 'Checked', 'on');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% MAIN DISPLAY FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayChannels(handles)
if isempty(handles.previews), return; end;

% Figure out row info and which channels will be shown
firstRow = handles.firstRow;
lastRow = handles.firstRow + handles.nRows - 1;
channels = handles.nCols * (firstRow-1) + 1 : lastRow * handles.nCols;
channels(channels > length(handles.previews)) = [];

% Prep axes
activateAxes(gcbf, handles.axMulti);
cla;
axLims([0 handles.nCols-handles.spacing 0 handles.nRows]);
hold on;

try
  delete(handles.selectionRectH);
end
handles.selectionRectH = NaN;

% Draw panels
for ch = 1:length(channels)
  displayCh(handles, channels(ch), 1 + floor((ch-1)/handles.nCols), mod(ch-1, handles.nCols) + 1);
end

% Select a channel, if previously-selected channel is on-screen
if handles.selectedCh >= channels(1) && handles.selectedCh <= channels(end)
  handles = selectChannel(handles, handles.selectedCh);
end

guidata(handles.axMulti, handles);

function displayCh(handles, channel, row, col)
pr = handles.previews(channel);
sorts = handles.sorts(channel);
sp = handles.spacing;
xOffset = col - 1;
yOffset = handles.nRows - row + 0.5;

% Plot background color
color = getBackgroundColor(sorts, handles);
rectangle('Position', [xOffset yOffset-0.5 1 1], 'FaceColor', color, ...
  'EdgeColor', handles.gridColor);

% Electrode number
if strcmp(get(handles.mnuShowElectrodeNums, 'Checked'), 'on')
  text(xOffset+0.05, yOffset+0.44, ...
    num2str(handles.previews(channel).electrode), 'FontSize', 7);
end

% Units defined
if strcmp(get(handles.mnuShowNumUnits, 'Checked'), 'on')
  nUnits = 0;
  for u = 1:length(handles.sorts(channel).autocorrs)
    if ~isempty(handles.sorts(channel).autocorrs(u).values)
      nUnits = nUnits + 1;
    end
  end
  if nUnits > 0
    text(xOffset+0.05, yOffset+0.3, num2str(nUnits), 'FontSize', 7, ...
      'color', [1 0 0]);
  end
end


% Plot waveforms or PCA points
viewMode = sorts.viewMode;

% Might have no PCA points if we just did a fast save
if strcmp(viewMode, 'PCA') && isempty(pr.PCAPts)
  viewMode = 'Waveform';
  PCAStamp = true;
else
  PCAStamp = false;
end

switch viewMode
  case 'Waveform'
    % Use alignedWaves if they exist
    if isempty(pr.throughDayAligned)
      wavesToUse = pr.throughDay;
    else
      wavesToUse = pr.throughDayAligned;
    end
    % Deal with threshold if it's >1
    if handles.threshold > 1
      mins = min(wavesToUse);
      thresh = max(mins) * handles.threshold;
      toUse = (mins < thresh);
      wavesToUse = wavesToUse(:, toUse);
      units = pr.throughDayUnits(toUse);
    else
      units = pr.throughDayUnits;
    end

    nWaves = size(wavesToUse, 2);
    nthWave = max(floor(nWaves / handles.nWavesPerChannel), 1);
    nTimes = min(floor(size(wavesToUse, 1)/2), floor(handles.ptsToShow/2));

    % Each box is 1 unit wide
    times = xOffset + (0:(1-sp)/(nTimes-1):1-sp);

    % Use only points through ptsToShow, rescale waves
    lastPt = min(handles.ptsToShow, size(wavesToUse, 1));
    values = handles.waveMultiplier * wavesToUse(2:2:lastPt, 1:nthWave:nWaves) + yOffset;

    % Get rid of excessively large values
    values(values - yOffset > 0.5) = yOffset + 0.5;
    values(values - yOffset < -0.5) = yOffset - 0.5;

    units = units(1:nthWave:nWaves);

    % Plot all waves on this channel for a given unit at once, for speed.
    % Separate them with NaNs so they plot right.
    x = times;
    uniqueUnits = unique(units);
    uniqueUnits(uniqueUnits > handles.maxUnits) = [];
    if ~isempty(uniqueUnits)
      for unit = uniqueUnits
        isUnit = (units == unit);
        nThisUnit = sum(isUnit);
        xs = repmat([x NaN], [1 nThisUnit]);
        wavesWithNaNs = [values(:, isUnit); NaN * ones(1, nThisUnit)];
        % When we vectorize the matrix, columns stay intact
        plot(xs, wavesWithNaNs(:), 'color', handles.sortColors(unit+1, :));
      end
    end

  case 'PCA'
    pts = pr.PCAPts(1:2, :);
    % Need this info to rescale points
    minX = min(pts(1,:));
    maxX = max(pts(1,:));
    minY = min(pts(2,:));
    maxY = max(pts(2,:));
    xRange = (maxX-minX) * (1 + 4*sp);
    yRange = (maxY-minY) * (1 + 4*sp);
    
    nPts = size(pts, 2);
    nthPt = max(floor(nPts / handles.nClusterPtsPerChannel), 1);
    
    units = pr.throughDayUnits;
    units = units(1:nthPt:nPts);
    
    % Rescale points, add offsets to plot them in the right spot
    scaledPts = bsxfun(@rdivide, pts(:, 1:nthPt:nPts), [xRange; yRange]);
    scaledPts = bsxfun(@plus, scaledPts, [xOffset+sp-minX/xRange; yOffset-0.5+2*sp-minY/yRange]);
    
    % Use same speed trick as above--plot all points for a given unit at
    % once
    uniqueUnits = unique(units);
    uniqueUnits(uniqueUnits > handles.maxUnits) = [];
    if ~isempty(uniqueUnits)
      for unit = uniqueUnits
        isUnit = (units == unit);
        plot(scaledPts(1, isUnit), scaledPts(2, isUnit), '.', 'color', handles.sortColors(unit+1, :));
      end
    end
end

if PCAStamp
  text(xOffset + 0.5, yOffset, 'PCA', 'HorizontalAlignment', 'center');
end


function color = getBackgroundColor(sorts, handles)
% Returns the appropriate color for a given channel's sorting status
if ~sorts.fullySorted
  if sorts.rated
    color = handles.modifiedRatedColor;
  else
    color = handles.modifiedUnratedColor;
  end
elseif sorts.userSorted
  if sorts.rated
    color = handles.userSortedRatedColor;
  else
    color = handles.userSortedUnratedColor;
  end
elseif sorts.onlineSorted
  if sorts.rated
    color = handles.onlineSortedRatedColor;
  else
    color = handles.onlineSortedUnratedColor;
  end
else
  color = handles.unsortedColor;
end



function multiClick(hObject, eventdata)
% Handle a click on the main plot
% This is the WindowButtonDownFcn for the whole figure, to make
% double-clicking more reliable and faster, but that means we have to do
% some extra stuff to figure out where on the plot we are.
handles = guidata(hObject);

% If user clicks right mouse button, ignore
if strcmp(get(gcbf, 'SelectionType'), 'alt')
  return;
else
  % Otherwise, figure out if we're inside the multi-view plot, and where
  figPos = get(gcbf, 'Position');
  axPos = get(handles.axMulti, 'Position');
  ptClicked = get(gcbf, 'CurrentPoint');
  
  % If user clicks outside axes, abort
  if ptClicked(1) < figPos(3) * axPos(1) || ptClicked(1) > figPos(3) * (axPos(1)+axPos(3)) || ...
      ptClicked(2) < figPos(4) * axPos(2) || ptClicked(2) > figPos(4) * (axPos(2)+axPos(4))
    return;
  else
    % User clicked inside the multi-view plot.
    % x = leftXLim + axXRange * (figX - axX) / axWidth
    xLims = get(handles.axMulti, 'XLim');
    yLims = get(handles.axMulti, 'YLim');
    x = xLims(1) + (xLims(2) - xLims(1)) * (ptClicked(1) / figPos(3) - axPos(1)) / axPos(3);
    y = yLims(1) + (yLims(2) - yLims(1)) * (ptClicked(2) / figPos(4) - axPos(2)) / axPos(4);
  end
end

%%%%% Figure out which channel was clicked on %%%%%
firstRow = handles.firstRow;
nRows = handles.nRows;
nCols = handles.nCols;

% Find row and column, then figure out which channel this is
col = ceil(x);
row = nRows - floor(y);
channel = (firstRow + row - 2) * nCols + col;

% Make sure it's a valid channel
if isnan(channel) || channel > length(handles.previews)
  return;
end

prevClicked = handles.selectedCh;

% Check for double-click and for whether OK to short-circuit (that is, if
% it's the same channel that was already selected but this isn't a
% double-click).
doubleClick = strcmp(get(gcbf, 'SelectionType'), 'open');
if prevClicked == channel && ~doubleClick
  return;
end

% For robustness, if the user is clicking a new channel, reset triple-click
% protector
if prevClicked ~= channel
  set(handles.axMulti, 'UserData', []);
end

% Select this channel
handles = selectChannel(handles, channel);

% Display autocorrelations
displayAutocorrs(handles, channel);

% Display waveform envelopes
displayWaveformEnvelopes(handles, channel);

% If double-click (and not already loading), send channel to
% oneChannelSorter
if doubleClick && isempty(get(handles.axMulti, 'UserData'))
  set(handles.axMulti, 'UserData', 'busy');
  handles = sendChannelToOneChannelSorter(handles, channel, handles.fastSave);
  set(handles.axMulti, 'UserData', []);
end

guidata(hObject, handles);



function handles = sendChannelToOneChannelSorter(handles, channel, fast)
% Sends this channel to oneChannelSorter.
% fast is whether to do a fast save or not, sortAndSave is whether to do a
% full sort, save, and return immediately or whether to allow the user to
% actually sort the channel.
channelInfo = [];
channelInfo.sorts = handles.sorts(channel);
if ~fast
  channelInfo.preview = handles.previews(channel);
end
channelInfo.path = handles.dataDir;
channelInfo.array = handles.previews(channel).array;
channelInfo.thisChannel = channel;
handles.oneChannelSorterH = oneChannelSorter(channelInfo);



function handles = sortModifiedCh(handles, ch)
% Loads needed data structures for this channel, calls sortWaveformsEngine
% to sort it, modifies data structures as needed, then saves everything
% down.

sorts = handles.sorts;

[waveforms, theseSorts, PCAPts, filename] = sortOneChannelWithoutCache(sorts(ch), handles.dataDir);

sorts(ch) = theseSorts;
previews = handles.previews;

if ~isempty(waveforms.alignedWaves)
    previews(ch).throughDayAligned = waveforms.alignedWaves(:, previews(ch).throughDaySpikeNums);
end

% Update previews
previews(ch).throughDayUnits = waveforms.units(previews(ch).throughDaySpikeNums);
if ~isempty(PCAPts)
  previews(ch).PCAPts = PCAPts(:, previews(ch).throughDaySpikeNums);
end

% Save all three files. This is slower but more robust to crashes.
save(fullfile(handles.dataDir, filename), 'waveforms', '-v7');
save(fullfile(handles.dataDir, 'previews.mat'), 'previews', '-v6');
save(fullfile(handles.dataDir, 'sorts.mat'), 'sorts', '-v6');

handles.sorts = sorts;
handles.previews = previews;



function handles = selectChannel(handles, channel)
% Select this channel: update internal data, move selection rectangle
handles.selectedCh = channel;
% if isa(handles.selectionRectH, 'matlab.graphics.primitive.Rectangle')
if ~ishandle(handles.selectionRectH)
  handles.selectionRectH = rectangle('EdgeColor', 'g', 'LineWidth', 1);
  guidata(handles.axMulti, handles);  % Here in case of errors, to prevent multiple rectangles
end
s = handles.spacing;
col = mod(channel - 1, handles.nCols) + 1;
row = ceil(channel / handles.nCols) - handles.firstRow + 1;
set(handles.selectionRectH, 'Position', [col-1+s, handles.nRows-row+s, 1-2*s, 1-2*s]);



function displayAutocorrs(handles, channel)

autocorrs = handles.sorts(channel).autocorrs;
nAutocorrs = length(autocorrs);

plotAutocorrsInAxes(autocorrs, nAutocorrs, handles.maxUnits, handles.autocorrHs, 1 - (1-handles.sortColors(2:end,:))/1.5, handles.redRefracViolThresh);



function displayWaveformEnvelopes(handles, channel)
% This displays the 5% to 95% quantiles of each unit's waveforms. This
% function would have been simpler to write with transparency (alpha), but
% then the renderer switches over to OpenGL, which doesn't render all the
% traces as nicely. Unfortunately, you can't mix renderers within a figure.
sorts = handles.sorts(channel);

ratingXOffset = 0.02; % Starting x-value for ratings
waveMax = 0;
waveMin = 0;
waveLen = 0;

anyUnits = 0;
% Display wave envelope, if calculated
activateAxes(gcbf, handles.axWaveforms);
cla;
% First, display the fills in a lighter color, in the order of unit
% definition.
for u = 1:handles.maxUnits
  envelope = sorts.waveEnvelope(u);
  if ~isempty(envelope.top)
    if ~anyUnits
      anyUnits = 1;
      set(gca, 'color', [1 1 1]);
    end
    waveMax = max(waveMax, max(envelope.top));
    waveMin = min(waveMin, min(envelope.bottom));
    waveLen = length(envelope.top);
    x = 0:(waveLen-1);
    x = [x fliplr(x)] / (waveLen-1);
    fill(x, [envelope.top fliplr(envelope.bottom)], 1-(1-handles.sortColors(u+1, :))/2, 'EdgeColor', 'none');
  end
end

% Now, display boundary lines, in reverse order of definition. This ensures
% that every unit's boundaries are unambiguous.
if anyUnits
  for u = handles.maxUnits:-1:1
    envelope = sorts.waveEnvelope(u);
    if ~isempty(envelope.top)
      waveMax = max(waveMax, max(envelope.top));
      waveMin = min(waveMin, min(envelope.bottom));
      waveLen = length(envelope.top);
      x = 0:(waveLen-1);
      x = x / (waveLen-1);
      plot(x, envelope.top, x, envelope.bottom, 'color', handles.sortColors(u+1, :));
    end
  end
end

% Gray plot if unused
if ~anyUnits
  set(gca, 'color', [0.9 0.9 0.9]);
end

if anyUnits
  % Find range for envelopes, scale plot
  if waveLen > 0
    maxMax = max(abs([waveMin waveMax]));
    waveMin = -1.1 * maxMax;
    waveMax = 1.1 * maxMax;
    axLims([0 1 waveMin waveMax]);
  end

  % Note if differentiated
  if sorts.differentiated
    text(ratingXOffset, -1.05 * maxMax, 'dV', 'FontSize', 9);
  end

  % Print ratings at top of wave envelope plot
  for u = 1:handles.maxUnits
    if ~isempty(sorts.waveEnvelope(u).top)
      text(ratingXOffset, 1.05 * maxMax, num2str(sorts.maxRatings(u)), 'color', handles.sortColors(u+1, :), 'VerticalAlignment', 'top', 'FontSize', 9);
      ratingXOffset = ratingXOffset + 0.2;
    end
  end
end



function hf = getFilterSelection(handles, mnuHandle)
% Generates a window allowing the user to select between Cerebus filters
% that their data might have been collected with. For use with
% mnuTTPBB_Callback.

% Clear any existing UserData
set(mnuHandle, 'UserData', []);

% Create fig
hf = figure('Position', [100000 1 300 150], 'Name', 'Select filter', 'NumberTitle', 'off', 'WindowStyle', 'modal');
backColor = get(hf, 'Color');

% Create text label and popup menu
uicontrol('Style', 'text', 'Units', 'normalized', 'String', 'Select filter used in spikesorted data:', ...
  'Position', [0.1 0.7 0.85 0.2], 'BackgroundColor', backColor, 'HorizontalAlignment', 'left');
hm = uicontrol('Style', 'popup', 'String', handles.cerebusFilters, ...
  'Units', 'normalized', 'Position', [0.1 0.55 0.8 0.1]);

% Pack data to store
udata.hm = hm;
udata.hf = hf;
udata.mnuHandle = mnuHandle;
set(hf, 'UserData', udata);

% Create buttons
uicontrol('Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'Position', [0.05 0.1 0.4 0.2], 'Callback', @closeFilterSelectOK);
uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.55 0.1 0.4 0.2], 'Callback', @closeFilterSelectCancel);

% Position window
movegui(hf, 'center');



function closeFilterSelectOK(hObject, eventdata)
% Grab filter name, pack into calling menu's UserData, close window
udata = get(gcbf, 'UserData');
hm = udata.hm;
strs = get(hm, 'String');
sel = get(hm, 'Value');

filtname = strs{sel};

set(udata.mnuHandle, 'UserData', filtname);
close(udata.hf);


function closeFilterSelectCancel(hObject, eventdata)
% Pack [] into calling menu's UserData, close window
udata = get(gcbf, 'UserData');
set(udata.mnuHandle, 'UserData', []);
close(udata.hf);






%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OTHER FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------


function loadDirectory(handles)
% Try to close oneChannelSorter, then load the directory specified in
% handles.dataDir . Also sets up window, displays previews, etc.

% Try to close oneChannelSorter if it's open. The reason for this is that
% if the user opens one set of previews, starts to sort a channel, opens a
% different set of previews, then tries to save the sorts, we need a
% mechanism to ensure the sorts don't get saved into the wrong dataset. So,
% we just demand that oneChannelSorter gets closed before loading a new
% dataset.
success = closeOneChannelSorter(handles.oneChannelSorterH);
if ~success
  return;
end


temp = load(fullfile(handles.dataDir, 'previews.mat'));
handles.previews = temp.previews;
temp = load(fullfile(handles.dataDir, 'sorts.mat'));
handles.sorts = temp.sorts;
clear temp

% Set up display
handles.firstRow = 1;
handles.selectedCh = 1;

% Set up scrolling
handles.nRowsData = ceil(length(handles.previews)/handles.nCols);
handles.maxFirstRow = max(handles.nRowsData - handles.nRows + 1, 1);
if handles.maxFirstRow == 1
  set(handles.sldMulti, 'Enable', 'off');
else
  set(handles.sldMulti, 'Enable', 'on');
  set(handles.sldMulti, 'Min', 1);
  set(handles.sldMulti, 'Max', handles.maxFirstRow);
  set(handles.sldMulti, 'Value', handles.maxFirstRow);
  step = 1 / (handles.maxFirstRow - 1);
  set(handles.sldMulti, 'SliderStep', [step step]);
end


% Select this channel
handles = selectChannel(handles, handles.selectedCh);

% Display autocorrelations
displayAutocorrs(handles, handles.selectedCh);

% Display waveform envelopes
displayWaveformEnvelopes(handles, handles.selectedCh);

displayChannels(handles);



function handles = processNewChannel(handles, comm, channelN)
% Take a channel's info from oneChannelSorter
handles.sorts(channelN) = comm.sortInfo;
sorts = handles.sorts;
% Save without compression, since these files are accessed so frequently
% and aren't really that big.
save(fullfile(handles.dataDir, 'sorts.mat'), 'sorts', '-v6');

% If there is a preview field in the comm structure, this means
% oneChannelSorter was using non-fast saving, so we should update and save
% down the preview structure. Otherwise, we won't.
if isfield(comm, 'preview')
  fields = fieldnames(comm.preview);
  for f = 1:length(fields)
    handles.previews(channelN).(fields{f}) = comm.preview.(fields{f});
  end
  previews = handles.previews;
  save(fullfile(handles.dataDir, 'previews.mat'), 'previews', '-v6');
end

handles.prevClicked = NaN;

% Select this channel
handles = selectChannel(handles, channelN);

% Display autocorrelations
displayAutocorrs(handles, channelN);

% Display waveform envelopes
displayWaveformEnvelopes(handles, channelN);



function [filenames, arrays] = getSortedFilenames(handles)
% Find filenames for files that have been sorted (either by hand or online)
filenames = {};
arrays = [];
alpha = alphabet();
for ch = 1:length(handles.sorts)
  if handles.sorts(ch).userSorted || handles.sorts(ch).onlineSorted
    if isnan(handles.sorts(ch).array)
      lett = '';
    else
      lett = alpha(handles.sorts(ch).array);
    end
    filenames{end+1} = makeWaveFilename(lett, handles.sorts(ch).electrode);
    arrays(end+1) = handles.sorts(ch).array;
  end
end



function ratingThreshold = requestMinRating(handles)

% Ask user for rating threshold
while 1
  answer = inputdlg('Please enter the minimum acceptable rating (0.0-4.0):', 'Minimum rating', 1, {'2.1'});
  if isempty(answer)  % Indicates user hit cancel
    set(gcbf, 'Pointer', 'arrow');
    set(handles.lblTTPsWait, 'Visible', 'off');
    ratingThreshold = '';
    return;
  end
  ratingThreshold = str2double(answer{1});
  if isnan(ratingThreshold)
    uiwait(msgbox('Rating threshold must be a number', 'Invalid input'));
  else
    break;
  end
end



function success = closeOneChannelSorter(oneChannelSorterH)
% This code allows oneChannelSorter to refuse to close (e.g., if there are
% unsaved sorts and the user declines a dialog asking whether they want to
% discard their work). So, we ask OCS to close; if it errors, we didn't
% have OCS open and we can call that 'success', or if it closes nicely, we
% also get success.
try
  success = close(oneChannelSorterH);
catch
  success = 1;
end



function closeApps(hObject, eventdata)
% This allows oneChannelSorter to refuse to close (e.g., if there are
% unsaved sorts and the user declines a dialog asking whether they want to
% discard their work). So, we ask OCS to close; if it errors, we didn't
% have OCS open and we can call that 'success', or if it closes nicely, we
% also get success.
handles = guidata(hObject);
success = closeOneChannelSorter(handles.oneChannelSorterH);
if success
  delete(hObject);
end



function str = randomHelp()
% No comment
helpStrs = {'You don''t really need help';
  'Look inside yourself';
  'Gopal says help is unacceptable';
  'Consider astrology';
  'Cook yourself a nice dinner';
  'Don''t cry wolf';
  'God helps those who help themselves. With this program, that''s pretty much your only choice.';
  'Fail';
  'A student came to Joshu and asked for help. Joshu hit the student with a stick. Just then, the student was enlightened.';
  'For assistance, scream loudly until someone comes';
  'For assistance, call Jenny at 867-5309.';
  'You''re lucky this option doesn''t just crash the program';
  'Write Ann Landers, you big crybaby';
  'Bees';
  'Sorry, I can''t help, I have TB';
  'Ask a cougar';
  'Try clicking harder';
  'Ask not what this program can do for you, but what you can do for this program';
  'A spike sorted is a spike earned';
  'Error code 103762b: incompetent user';
  'Whatever your problem is, it''s a feature, not a bug';
  'The first rule of spikesorting is: you do not talk about spikesorting';
  'The second rule of spikesorting is: you do NOT. TALK. about SPIKESORTING.';
  'Nanobees'};

str = helpStrs{ceil(rand * length(helpStrs))};
