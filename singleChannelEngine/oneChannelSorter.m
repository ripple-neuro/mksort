function varargout = oneChannelSorter(varargin)
% ONECHANNELSORTER M-file for oneChannelSorter.fig
%
% This is the main component of the actual channel sorting interface. See
% user documentation.
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
%      ONECHANNELSORTER, by itself, creates a new ONECHANNELSORTER or raises the existing
%      singleton*.
%
%      H = ONECHANNELSORTER returns the handle to a new ONECHANNELSORTER or the handle to
%      the existing singleton*.
%
%      ONECHANNELSORTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ONECHANNELSORTER.M with the given input arguments.
%
%      ONECHANNELSORTER('Property','Value',...) creates a new ONECHANNELSORTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before oneChannelSorter_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to oneChannelSorter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help oneChannelSorter

% Last Modified by GUIDE v2.5 28-Nov-2011 10:36:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @oneChannelSorter_OpeningFcn, ...
                   'gui_OutputFcn',  @oneChannelSorter_OutputFcn, ...
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



% CODE SECTIONS:
%
% Opening function -- contains tons of initialization, all the
%     straightforward user-customizable variables in the marked section
%
% Creation functions -- almost all useless, ignore.
%
% Callback functions -- most UI control, and logic when it was brief
%
% GUI functions -- lots more UI control, when logic was shared or complex
%
% Sort-type specific functions -- specific to a 'type' of sort algorithm
%     (see user-customizable section below for explanation). These mostly
%     deal with managing sort objects for each type of sort (e.g., hoops or
%     ellipses) and setting up data structures.
%
% Mouse handling -- mostly move functions for sort objects, also includes
%     other mouse-related functions (such as drawing the template line).
%
% Sorting functions -- all the functions closely related to actually
%     sorting waveforms.
%
% Other functions -- odds and ends that just didn't fit elsewhere. Avoid
%     putting functions here if possible. Includes epoch handling,
%     waveform alignment, and file loading among other things.


% SEE ALSO: mksort.m


% All sort functions and alignment functions must be included in %#function
% lines below in order to compile the code with mcc.

%#function greedyTemplates
%#function mahalanobisTemplates
%#function PCACluster2Lin
%#function PCACluster2Nearest
%#function noAlign
%#function alignOnFallLin
%#function alignOnRiseLin
%#function alignOnMin
%#function alignOnFallLinExact
%#function alignOnRiseLinExact





% --- Executes just before oneChannelSorter is made visible.
function oneChannelSorter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% varargin   command line arguments to oneChannelSorter (see VARARGIN)

% Choose default command line output for oneChannelSorter
handles.output = hObject;


% Check that this app was called from mksort, and appropriate data was
% supplied. Otherwise, complain and close.
if isempty(varargin)
  complainAndClose;
end

arg = varargin{1};
requiredFields = {'sorts', 'path', 'array', 'thisChannel'};
if ~all(isfield(arg, requiredFields))
  complainAndClose;
end

% If this is the first open, resize this using the window size.  Otherwise,
% don't touch.
% TODO: Make width and height  true parameters and allow for this to be user 
% configurable
if ~isfield(handles, 'isopen')
  screenSize = get(0, 'ScreenSize');
  % Make this the same width but a little shorter than mksort figure.
  defaultWidth = 0.5 * screenSize(3);
  defaultHeight = 0.8 * screenSize(4);
  % put this a little right and below the mksort figure.
  defaultX = (screenSize(3) - defaultWidth) / 2 + 30; 
  defaultY = (screenSize(4) - defaultHeight) / 2;
  % convert units to pixels so that we may make use of the actual screen
  % size.
  units = get(hObject, 'units');
  set(hObject, 'units', 'pixels');
  set(hObject, 'position', [defaultX, defaultY, defaultWidth, ...
    defaultHeight]);
  % ensure units remains in the same units in case of later calculations.
  set(hObject, 'units', units);
  % set field for checking next time this is called
  handles.isopen = 1;
end
set(handles.lblLoading, 'Visible', 'on');

% This will hold all of our sorts data. It is somewhat complicated. See the
% documentation in mksort.m
handles.sorts = [];

%%% Load file %%%
handles = loadWaveformFile(handles, arg);

handles.sortMethods = {};
handles.alignMethods = {};

method = [];


%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% INITIALIZE APPLICATION VARIABLES
% USER-CUSTOMIZABLE
%--------------------------------------------------------------------------


%%%%%%%%%%%%%%
% Sort methods
%%%%%%%%%%%%%%


% type is the 'class' of sort method. Template permits using both templates
% defined in terms of waveforms, and hoops. It probably does most of what
% you'd want for waveform-space work. Each type must have certain things
% defined in order to work. There must be a 'panel' of controls on the GUI
% named pnl{type} , e.g., pnlTemplate . For each type, there must also be
% functions:
%
% {type}Init
% clearUnit{type}
% rebuildSortObjects{type}
% sortBy{type}
%
% See the code section SORT-TYPE SPECIFIC FUNCTIONS for examples (the
% functions that actually do the work!). sortBy{type} are in the
% sortEngine folder.

method.type = 'Template';
% view determines which view will be used with this sort method. Waveform
% and 2-4D PCA are supported.
method.view = 'Waveform';

% One sortMethod is defined immediately below, in combination with the
% parameters above.
% name appears in the drop-down menu
% classifyFcn is the function that actually get used for sorting. Different
%   sort 'type's have different prototypes for the sort function (see
%   code for prototype).
% explicitZeroUnit is whether the 0-unit is defined by the user
% Adding code as below will automatically populate the drop-down menu.
method.name = 'Mahalanobis templates';
method.classifyFcn = 'mahalanobisTemplates';
method.explicitZeroUnit = 1;
handles.sortMethods{end+1} = method;

% method.name = 'Greedy templates';
% method.classifyFcn = 'greedyTemplates';
% method.explicitZeroUnit = 0;
% handles.sortMethods{end+1} = method;




method.type = 'PCAEllipses';
method.view = 'PCA';
method.explicitZeroUnit = 0;

% method.name = 'PCA ellipses, contained';
% method.classifyFcn = 'PCACluster2Lin';
% handles.sortMethods{end+1} = method;

method.name = 'PCA ellipses, nearest';
method.classifyFcn = 'PCACluster2Nearest';
method.explicitZeroUnit = 1;
handles.sortMethods{end+1} = method;



% Initialize data fields for each sort method type
% If you make a new sort type, add the init function below.
handles = TemplateInit(handles);
handles = PCAEllipsesInit(handles);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Waveform alignment methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% These are the functions to align waveforms. Add code as below to
% automatically populate the drop-down menu.

method = [];
method.legacy = 0;

method.name = 'No alignment';
method.alignFcn = 'noAlign';
handles.alignMethods{end+1} = method;

method.name = 'Initial decline';
method.alignFcn = 'alignOnFallLinExact';
handles.alignMethods{end+1} = method;

method.name = 'Post-trough rise';
method.alignFcn = 'alignOnRiseLinExact';
handles.alignMethods{end+1} = method;

% Legacy methods
method.legacy = 1;

method.name = 'Rise (legacy)';
method.alignFcn = 'alignOnRiseLin';
handles.alignMethods{end+1} = method;

method.name = 'Decline (legacy)';
method.alignFcn = 'alignOnFallLin';
handles.alignMethods{end+1} = method;

% method.name = 'Minimum';
% method.alignFcn = 'alignOnMin';
% handles.alignMethods{end+1} = method;

% method.name = 'Trough center-of-mass';
% method.alignFcn = 'alignMethodName';
% handles.alignMethods{end+1} = method;


handles.disableNTrodeTemplateSort = 0;       % whether to disable waveform-mode sorting of n-trodes
handles.defaultSortMethod = 1;               % which sort method to start with for an unsorted channel (0 to use last used)
handles.defaultEllipseWidth = 2;             % default value for ellipse diameter in SDs of each dimension
handles.defaultAcceptance = 50;              % default value for unit acceptance sliders
handles.dragHandleSize = 0.015;              % size for hoop/ellipse drag handles
handles.redRefracViolThresh = 2;             % percent refractory violations before number turns red on autocorrelation plot
handles.defaultNWaves = 100;                 % Default # of waves displayed
handles.PCADispMult = 20;                    % one wants to see more points for PCA than for waveforms, this is factor more
handles.initialZoom = 250;                   % initial zoom voltage (waveform view)
handles.maxVoltage = 2000;                   % Max waveform plot voltage
handles.indivUnitsMaxVoltage = 500;          % Sets the scale for individual unit plots
handles.troughDepthNBins = 20;               % # of bins for trough depth histogram
shrinkFonts = 1;                             % Cross-platform font size issue. Most will want 0, 1 if fonts appear too large.

%--------------------------------------------------------------------------
% END OF (STRAIGHTFORWARD) USER-CUSTOMIZABLE VARIABLES
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------



handles.zoomFactor = 0.85;                   % zoom slider works as z^v, where this is z and v is the slider value
handles.nPCABinsPerDim = 40;                 % NOT CURRENTLY USED (for displaying grayscale heat map of point density)
handles.maxUnits = 4;                        % If this is changed, have to change the GUI too!

% Note that indexing for handles of axUnit plots is not the same as for the
% ISIs !
% Build arrays of certain handles for convenience
% changeWIndividual unit plots (includes 0-unit)
handles.axUnitHs = [handles.axUnit0, handles.axUnit1, handles.axUnit2, handles.axUnit3, handles.axUnit4];
% Autocorr plots (omits 0-unit, poorly named, sorry)
handles.axISIHs = [handles.axISI1, handles.axISI2, handles.axISI3, handles.axISI4];
% Acceptance sliders (includes 0-unit)
handles.sldAcceptHs = [handles.sldAccept0, handles.sldAccept1, handles.sldAccept2, handles.sldAccept3, handles.sldAccept4];
% Rating text boxes (omits 0-unit)
handles.ratingHs = [handles.txtRating1, handles.txtRating2, handles.txtRating3, handles.txtRating4]; 
% PCA dimension display buttons
handles.PCABtnHs = [handles.btnPCA12, handles.btnPCA13, handles.btnPCA23, handles.btnPCA14, handles.btnPCA24, handles.btnPCA34];

% Hold drag handles for hoops/ellipses
handles.dragHs = [];

% This holds the waveforms currently being displayed, nPts x nWaves
handles.wavesShown = [];

% Indices of those waves
handles.wavesShownIndices = [];

% This holds all shown waveforms PCA'd, if they've been calculated
handles.PCAPts = [];

% This holds the PCA points currently being shown, if relevant
handles.PCAShown = [];

% Which PCA dimensions are displayed, if applicable
handles.PCADimsShown = [1 2];

handles.minPCADims = 2;                      % min # of dimensions to use in PCA
handles.maxPCADims = 4;                      % max # of dimensions to use in PCA

handles.PCACenter = zeros(1, handles.maxPCADims);

% Cache max and min info for each wave, and global values
handles.maxes = [];
handles.mins = [];
handles.globalMax = [];
handles.globalMin = [];


% Handle of the active sort object
handles.activeSortObj = NaN;

% Handles of all graphical objects used in sorting. Must be managed so they
% come out in front when plotting, and can be destroyed and regenerated
% appropriately.
handles.sortObjects = [];

% Handles to sort epoch rectangles on the timeline plot
handles.sortEpochRectHs = [];

% Handle to the rectangle that show what time range is plotted on the
% timeline, when active
handles.sortEpochTickH = [];

% Populate options in cmbSortMethod
sortMethodNames = {};
for method = 1:length(handles.sortMethods)
  sortMethodNames{method} = handles.sortMethods{method}.name;
end
set(handles.cmbSortMethod, 'String', sortMethodNames);

% Fcn of the active sort method. Maintained separately so that
% handles.sorts itself contains enough information for sorting to use on
% reload
try
  sortMethodFcns = {};
  for method = 1:length(handles.sortMethods)
    sortMethodFcns{method} = handles.sortMethods{method}.classifyFcn;
  end

  sortMethod = find(strcmp(sortMethodFcns, handles.sortInfo.sorts(1).sortMethodFcn));
  set(handles.cmbSortMethod, 'Value', sortMethod);
  handles.sortMethod = sortMethod;
catch
  if handles.defaultSortMethod ~= 0
    handles.sortMethod = handles.defaultSortMethod;
    set(handles.cmbSortMethod, 'Value', handles.sortMethod);
  else
    % This is the active sortMethod
    handles.sortMethod = get(handles.cmbSortMethod, 'Value');
  end
  handles.sorts.sortMethodFcn = handles.sortMethods{handles.sortMethod}.classifyFcn;
  handles.sorts.sortMethodType = handles.sortMethods{handles.sortMethod}.type;
end


% Populate options in cmbAlignMethod

alignMethodFcns = {};
for method = 1:length(handles.alignMethods)
  alignMethodFcns{method} = handles.alignMethods{method}.alignFcn;
end
% Check for using a legacy alignMethod.
includeLegacy = 0;
try
  if ~isempty(handles.sortInfo.sorts(1).alignMethodFcn)
    alignMethod = strcmp(alignMethodFcns, handles.sortInfo.sorts(1).alignMethodFcn);
    if handles.alignMethods{alignMethod}.legacy
      includeLegacy = 1;
    end
  end
end

alignMethodNames = {};
for method = 1:length(handles.alignMethods)
  alignMethodNames{method} = handles.alignMethods{method}.name;
end

if ~includeLegacy
  legacy = cellfun(@(x) x.legacy, handles.alignMethods);
  alignMethodNames = alignMethodNames(~legacy);
  alignMethodFcns = alignMethodFcns(~legacy);
end

set(handles.cmbAlignMethod, 'String', alignMethodNames);

% Set the active alignMethodFcn. Same reason as sortMethodFcn above.
try
  if isempty(handles.sortInfo.sorts(1).alignMethodFcn)
    alignMethod = find(strcmp(alignMethodFcns, 'noAlign'));
    set(handles.cmbAlignMethod, 'Value', alignMethod);
    handles.waveforms.alignedWaves = handles.waveforms.waves;
  else
    alignMethod = find(strcmp(alignMethodFcns, handles.sortInfo.sorts(1).alignMethodFcn));
    set(handles.cmbAlignMethod, 'Value', alignMethod);
  end
catch
  alignMethod = find(strcmp(alignMethodFcns, 'noAlign'));
  set(handles.cmbAlignMethod, 'Value', alignMethod);
  handles.sorts.alignMethodFcn = 'noAlign';
end

handles.activeUnit = 1;   % Which unit we're affecting
handles.activeEpoch = 1;  % Which epoch we're affecting
handles.firstWaveToShow = 1;   % Only matters if displaying waveforms by time of day
handles.waveIntervalSeed = 1;   % Seed for display of waveforms at intervals through day

handles.templateLine = [];   % Holds the handles of the template selection line, briefly

% Populate options in cmbTroughDepthHist
troughDepthOptions = {};
troughDepthOptions{end+1} = 'Trough depth hist';
troughDepthOptions{end+1} = 'Peak height hist';
troughDepthOptions{end+1} = 'FR over trials';
set(handles.cmbTroughDepthHist, 'String', troughDepthOptions);
handles.showFROverDay = (get(handles.cmbTroughDepthHist, 'Value') == 3);

% Populate options in cmbNPCADims
nPCADims = {};
for d = handles.minPCADims:handles.maxPCADims
  nPCADims{end+1} = num2str(d);
end
set(handles.cmbNPCADims, 'String', nPCADims);

% If we're in PCA mode, ensure that we start with the right number of
% dimensions
% Default is max
if handles.sortInfo.nPCADims ~= 0
  handles.nPCADims = handles.sortInfo.nPCADims;
else
  handles.nPCADims = handles.maxPCADims;
end
PCADimBtnEnabling(handles, handles.nPCADims);
set(handles.cmbNPCADims, 'Value', find((handles.minPCADims:handles.maxPCADims) == handles.nPCADims));
% Enable and select buttons appropriately
for btn = handles.PCABtnHs
  set(btn, 'Value', 0);
end
set(handles.PCABtnHs(1), 'Value', 1);

% Initialize chkDifferentiate
set(handles.chkDifferentiate, 'Value', handles.sortInfo.differentiated);

% Initialize ratings
for r = 1:length(handles.ratingHs)
  set(handles.ratingHs(r), 'String', '0');
end
% If there were ratings in the sorts file, use them.
sortMethodType = handles.sortMethods{handles.sortMethod}.type;
ratings = handles.sorts(handles.activeEpoch).(sortMethodType).ratings;
if ~isempty(ratings)
  for r = 1:length(ratings)
    set(handles.ratingHs(r), 'String', num2str(handles.sorts(handles.activeEpoch).(sortMethodType).ratings(r)));
  end
end

% Initialize waveform limits
set(handles.txtStartWaveTime, 'String', num2str(handles.sorts(handles.activeEpoch).(sortMethodType).waveLims(1)));
set(handles.txtEndWaveTime, 'String', num2str(handles.sorts(handles.activeEpoch).(sortMethodType).waveLims(2)));

% Initialize chkChangeCurrentEpoch
set(handles.chkChangeCurrentEpoch, 'Value', 1);


% Each row holds a color used when sorting. First row is for unit 0, second
% is for unit 1, etc.
handles.sortColors = [0.5 0.5 0.5;
                      0.3 0.3 1;
                      1 0.2 0.2;
                      0.2 1 0.2;
                      0.5 0.2 0.5];

% Color of unit highlight box
handles.selectColor = [0.7 0.2 0];


% Figure out what types of sorting we have available, verify that data
% fields exist for each type, and verify that there exists an appropriate
% control panel for each type.
sortMethodTypes = {};
for method = 1:length(handles.sortMethods)
  sortMethodTypes{method} = handles.sortMethods{method}.type;
end
sortMethodTypes = unique(sortMethodTypes);

for sortType = 1:length(sortMethodTypes)
  if ~isfield(handles.sorts, sortMethodTypes{sortType})
    error('No initialization exists for sort method type %s.', sortMethodTypes{sortType});
  end
  if ~isfield(handles, ['pnl' sortMethodTypes{sortType}])
    error('No control panel exists for sort method type %s. There must be an object named pnl%s', sortMethodTypes{sortType}, sortMethodTypes{sortType});
  end
end
handles.sortMethodTypes = sortMethodTypes;


% Get rid of ticks for all axes, set to fast draw, disable panning
hp = pan(handles.figOneChannelSorter);
for child = findobj(hObject, 'Type', 'axes')'
  % Sometimes fails if user launches oneChannelSorter multiple times
  % quickly.
  try
    activateAxes(handles.figOneChannelSorter, child);
    hold on;
    set(child, 'XTick', []);
    set(child, 'YTick', []);
    set(child, 'XColor', 'w');
    set(child, 'YColor', 'w');
    setupAxesForFastDraw(child);
    setAllowAxesPan(hp, child, false);
  end
end

% Enable panning for axWaves
activateAxes(handles.figOneChannelSorter, handles.axWaves);
setAllowAxesPan(hp, handles.axWaves, true);


% Set acceptance slider default values.
for h = handles.sldAcceptHs
  % Again, this sometimes fails if the user launches oneChannelSorter
  % multiple times quickly.
  try
    set(h, 'Value', handles.defaultAcceptance);
  end
end

% Set default zoom
try
  set(handles.sldZoom, 'Value', log(handles.initialZoom/handles.maxVoltage)/log(handles.zoomFactor));
  set(handles.lblZoomScale, 'String', sprintf('%c%d %cV', 177, handles.initialZoom, 181));
end

% When switching between Waveform and PCA view, adjust number of points
% displayed
switch handles.sortMethods{handles.sortMethod}.view
  case 'PCA'
    set(handles.txtNWaves, 'String', num2str(handles.defaultNWaves * handles.PCADispMult));
  otherwise
    set(handles.txtNWaves, 'String', num2str(handles.defaultNWaves));
end

% Will prevent displayWaveforms from updating the display. This is useful
% when rebuilding sort objects.
handles.preventDisplayUpdate = 0;

% Initialize plotting threshold
handles.thresh = 0;
set(handles.sldPlotThreshold, 'Value', 0);


% Label channel
alpha = alphabet();
if isnan(handles.array)
  set(handles.lblChannelVal, 'String', num2str(handles.sortInfo.electrode));
else
  set(handles.lblChannelVal, 'String', sprintf('%s %d', alpha(handles.array), handles.sortInfo.electrode));
end

% Ensure that axes start clear
activateAxes(gcbf, handles.axWaves);
cla;
for ax = handles.axUnitHs
  activateAxes(gcbf, ax);
  cla;
end
activateAxes(gcbf, handles.axTimeline);
cla;

% Create an initial sort epoch, initialize timeline
handles.sorts.epochStart = 1;
handles.sorts.epochEnd = length(handles.waveforms.spikeTimes);
activateAxes(gcbf, handles.axTimeline);
cla;
axLims([0 handles.sorts.epochEnd 0 1]);
handles.sortEpochRectHs = rectangle('Position', [1 0 handles.sorts.epochEnd 1], 'EdgeColor', [0.5 0.5 0.5], 'FaceColor', [0.5 1 0.5]);

% Set up time slider
nWaves = size(handles.waveforms.waves, 2);
nWavesShown = str2double(get(handles.txtNWaves, 'String'));
set(handles.sldTime, 'Max', nWaves - nWavesShown + 1);
set(handles.sldTime, 'Value', 1);
set(handles.sldTime, 'Min', 1);
set(handles.sldTime, 'SliderStep', [min(nWavesShown/nWaves, 1), 0.1]);

% Generate alignedWaves if they don't exist
if size(handles.waveforms.alignedWaves, 2) ~= size(handles.waveforms.waves, 2)
  handles.waveforms.alignedWaves = alignWaveforms(handles, handles.waveforms.waves);
end

% Make the interface options make sense
handles = makeInterfaceConsistent(handles);

% If this is an n-trode, disable waveform alignment
if length(handles.sortInfo.electrode) > 1
  set(handles.cmbAlignMethod, 'Enable', 'off');
else
  set(handles.cmbAlignMethod, 'Enable', 'on');
end

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

% If we got sorting parameters from the waveforms file, this will produce
% the corresponding objects.
handles = rebuildSortObjects(handles, handles.sortInfo.sorts, 1);
handles.sortInfo.sorts = [];

% Do the actual display
displayWaveforms(handles);
handles = guidata(gcf);

handles.saved = 1;

% Update handles structure
guidata(hObject, handles);

displayTroughDepths(handles);

set(handles.lblLoading, 'Visible', 'off');

% Make it so that when user tries to close this application it checks
% whether their sorts are saved or not, and asks for confirmation if
% they're not
set(hObject, 'CloseRequestFcn', @closeIfSaved);


% UIWAIT makes oneChannelSorter wait for user response (see UIRESUME)
% uiwait(handles.figOneChannelSorter);






% --- Outputs from this function are returned to the command line.
function varargout = oneChannelSorter_OutputFcn(hObject, eventdata, handles) 
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

% These are almost all useless.



function txtNWaves_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sldPlotThreshold_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function sldTime_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function cmbAlignMethod_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cmbSortMethod_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sldAccept1_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function sldAccept2_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function sldAccept3_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function sldAccept4_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function sldAccept0_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function txtStartWaveTime_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtEndWaveTime_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtRating1_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtRating2_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtRating3_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtRating4_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cmbChannel_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sldZoom_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function cmbTroughDepthHist_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cmbNPCADims_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
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
% Number of waves/points to plot.

val = str2double(get(hObject, 'String'));
% Make sure we have a sane value
if isnan(val) || val < 1
  set(hObject, 'String', '100');
  return;
elseif val > size(handles.waveforms.alignedWaves, 2)
  set(hObject, 'String', num2str(size(handles.waveforms.alignedWaves, 2)));
end
nWavesShown = str2double(get(handles.txtNWaves, 'String'));
% Time slider max (have to ensure we're not beyond the new end first)
maxTime = size(handles.waveforms.alignedWaves, 2) - nWavesShown + 1;
if get(handles.sldTime, 'Value') > maxTime
  set(handles.sldTime, 'Value', maxTime);
end
set(handles.sldTime, 'Max', maxTime);

displayWaveforms(handles);



% --- Executes on slider movement.
function sldPlotThreshold_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
displayWaveforms(handles);



% --- Executes on slider movement.
function sldTime_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

set(hObject, 'Value', round(get(hObject, 'Value')));

% Set the first point in time we see when viewing consecutive waveforms by
% time
handles.firstWaveToShow = round(get(hObject, 'Value'));
epoch = getCurrentEpoch(handles);
% If we've switched epochs, need to rebuild sorting objects
if epoch ~= handles.activeEpoch
  handles.activeEpoch = epoch;
  handles = rebuildSortObjects(handles, handles.sorts, 0);
end

displayWaveforms(handles);



% --- Executes on selection change in cmbAlignMethod.
function cmbAlignMethod_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns cmbAlignMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cmbAlignMethod
% Figure out method, store it
alignMethodFcn = handles.alignMethods{get(hObject, 'Value')}.alignFcn;

% Check if we actually need to do anything
if strcmp(handles.waveforms.alignMethodFcn, alignMethodFcn)
  return;
end

for epoch = 1:length(handles.sorts)
  handles.sorts(epoch).alignMethodFcn = alignMethodFcn;
end
handles.waveforms.alignMethodFcn = alignMethodFcn;

set(gcbf, 'Pointer', 'watch');
drawnow;

% Do the alignment
try
  handles.waveforms.alignedWaves = feval(alignMethodFcn, handles.waveforms.waves);
catch
  set(gcbf, 'Pointer', 'arrow');
  uiwait(msgbox(sprintf('Algorithm %s not implemented yet, or the function has produced an error.', alignMethodFcn), 'modal'));
  return;
end
set(gcbf, 'Pointer', 'arrow');

if strcmp(handles.sortMethods{handles.sortMethod}.view, 'PCA')
  handles = regenPCASpace(handles);
else
  handles.PCAPts = [];
end
handles = markSortChanged(handles);
displayWaveforms(handles);



% --- Executes on button press in btnNWavesMore.
function btnNWavesMore_Callback(hObject, eventdata, handles)
val = str2double(get(handles.txtNWaves, 'String'));
nWavesShown = num2str(floor(val * 3/2));
set(handles.txtNWaves, 'String', nWavesShown);
nWavesShown = str2double(get(handles.txtNWaves, 'String'));
% Time slider max (have to ensure we're not beyond the new end first)
maxTime = size(handles.waveforms.alignedWaves, 2) - nWavesShown + 1;
if get(handles.sldTime, 'Value') > maxTime
  set(handles.sldTime, 'Value', maxTime);
end
set(handles.sldTime, 'Max', maxTime);

displayWaveforms(handles);



% --- Executes on button press in btnNWavesLess.
function btnNWavesLess_Callback(hObject, eventdata, handles)
val = str2double(get(handles.txtNWaves, 'String'));
nWavesShown = num2str(ceil(val * 2/3));
set(handles.txtNWaves, 'String', nWavesShown);
nWavesShown = str2double(get(handles.txtNWaves, 'String'));
% Time slider max (have to ensure we're not beyond the new end first)
maxTime = size(handles.waveforms.alignedWaves, 2) - nWavesShown + 1;
if get(handles.sldTime, 'Value') > maxTime
  set(handles.sldTime, 'Value', maxTime);
end
set(handles.sldTime, 'Max', maxTime);

displayWaveforms(handles);



% --- Executes on selection change in cmbSortMethod.
function cmbSortMethod_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns cmbSortMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cmbSortMethod

set(gcbf, 'Pointer', 'watch');
drawnow;

% Clear WindowButtonDownFcn, prevent template drawing and panning from
% crossing modes
set(gcbf, 'WindowButtonDownFcn', '');
hp = pan(handles.figOneChannelSorter);
set(hp, 'Enable', 'off');

% Figure out new method, store it.
oldMethod = handles.sortMethod;
handles.sortMethod = get(hObject, 'Value');
for ep = 1:length(handles.sorts)
  handles.sorts(ep).sortMethodFcn = handles.sortMethods{handles.sortMethod}.classifyFcn;
  handles.sorts(ep).sortMethodType = handles.sortMethods{handles.sortMethod}.type;
end

newType = handles.sortMethods{handles.sortMethod}.type;
oldType = handles.sortMethods{oldMethod}.type;
set(handles.chkDifferentiate, 'Value', handles.sorts(handles.activeEpoch).(newType).differentiated);



% When switching between Waveform and PCA view, adjust number of points
% displayed, wave limits if relevant, sldTime limit
oldView = handles.sortMethods{oldMethod}.view;
newView = handles.sortMethods{handles.sortMethod}.view;
% Number of points displayed
nWavesShown = str2double(get(handles.txtNWaves, 'String'));
if strcmp(oldView, 'Waveform') && ~strcmp(newView, 'Waveform')
  % Waveform to PCA
  newNWaves = handles.PCADispMult * nWavesShown;
  set(handles.txtNWaves, 'String', num2str(newNWaves));
  set(handles.btnPan, 'Visible', 'on');
elseif ~strcmp(oldView, 'Waveform') && strcmp(newView, 'Waveform')
  % PCA to waveform
  newNWaves = ceil(nWavesShown/handles.PCADispMult);
  set(handles.txtNWaves, 'String', num2str(newNWaves));
  set(handles.btnPan, 'Visible', 'off');
else
  % No switch
  newNWaves = nWavesShown;
end
% Time slider max (have to ensure we're not beyond the new end first)
maxTime = size(handles.waveforms.alignedWaves, 2) - newNWaves + 1;
if get(handles.sldTime, 'Value') > maxTime
  set(handles.sldTime, 'Value', maxTime);
end
set(handles.sldTime, 'Max', maxTime);


handles = makeInterfaceConsistent(handles);
handles = markSortChanged(handles);

displayWaveforms(handles);

% Need to do this after displayWaveforms so that axis limits are right when
% we build the sort objects
handles = guidata(hObject);
% When switching between sort types, need to rebuild sort objects
if ~strcmp(oldType, newType)
  handles = rebuildSortObjects(handles, handles.sorts, 1);
end
% If switching differentiation states, need to clear some things related to
% plot scaling
if handles.sorts(handles.activeEpoch).(newType).differentiated ~= handles.sorts(handles.activeEpoch).(oldType).differentiated
  handles.maxes = [];
  handles.mins = [];
  handles.globalMax = [];
  handles.globalMin = [];
end
displayWaveforms(handles);

set(gcbf, 'Pointer', 'arrow');




% --- Executes on slider movement.
function sldAccept0_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = changeAcceptance(handles, hObject);
displayWaveforms(handles);

function sldAccept1_Callback(hObject, eventdata, handles)
handles = changeAcceptance(handles, hObject);
displayWaveforms(handles);

function sldAccept2_Callback(hObject, eventdata, handles)
handles = changeAcceptance(handles, hObject);
displayWaveforms(handles);

function sldAccept3_Callback(hObject, eventdata, handles)
handles = changeAcceptance(handles, hObject);
displayWaveforms(handles);

function sldAccept4_Callback(hObject, eventdata, handles)
handles = changeAcceptance(handles, hObject);
displayWaveforms(handles);



% --- Executes on button press in btnChangeWaveSeed.
function btnChangeWaveSeed_Callback(hObject, eventdata, handles)
% Display a different set of waves.
handles.waveIntervalSeed = handles.waveIntervalSeed + 1;
displayWaveforms(handles);



function txtStartWaveTime_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtStartWaveTime as text
%        str2double(get(hObject,'String')) returns contents of txtStartWaveTime as a double
startPt = str2double(get(handles.txtStartWaveTime, 'String'));
endPt = str2double(get(handles.txtEndWaveTime, 'String'));

% Ensure sane value
if isnan(startPt) || startPt < 1
  startPt = 1;
end

if startPt >= endPt
  startPt = endPt - 1;
end

handles = changeWaveLims(handles, startPt, endPt);
displayWaveforms(handles);



function txtEndWaveTime_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtEndWaveTime as text
%        str2double(get(hObject,'String')) returns contents of txtEndWaveTime as a double
startPt = str2double(get(handles.txtStartWaveTime, 'String'));
endPt = str2double(get(handles.txtEndWaveTime, 'String'));

% Ensure sane value
if isnan(endPt) || endPt < 1
  endPt = startPt + 1;
end

if endPt <= startPt
  endPt = startPt + 1;
end

handles = changeWaveLims(handles, startPt, endPt);
displayWaveforms(handles);



function txtRating1_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtRating1 as text
%        str2double(get(hObject,'String')) returns contents of txtRating1 as a double
changeRating(handles, hObject);

function txtRating2_Callback(hObject, eventdata, handles)
changeRating(handles, hObject);

function txtRating3_Callback(hObject, eventdata, handles)
changeRating(handles, hObject);

function txtRating4_Callback(hObject, eventdata, handles)
changeRating(handles, hObject);



% --- Executes on button press in btnFullSort.
function btnFullSort_Callback(hObject, eventdata, handles)
% Sort everything. Woo!
if ~handles.sortInfo.fullySorted
  set(gcbf, 'Pointer', 'watch');
  drawnow;

  startPt = str2double(get(handles.txtStartWaveTime, 'String'));
  endPt = str2double(get(handles.txtEndWaveTime, 'String'));

  if ~get(handles.chkDifferentiate, 'Value')
    waves = handles.waveforms.alignedWaves(startPt:endPt, :);
  else
    waves = diff(handles.waveforms.alignedWaves(startPt:endPt, :));
  end
  handles.waveforms.units = sortWaveforms(handles, waves);
  handles.sortInfo.fullySorted = 1;
  handles = recalculateAutocorrs(handles);
  handles.sortInfo.waveEnvelope = calculateWaveEnvelopes(handles.waveforms.alignedWaves(2:end-1, :), handles.waveforms.units, length(handles.axUnitHs)-1);

  displayWaveforms(handles);
  
  set(gcbf, 'Pointer', 'arrow');
end
if handles.showFROverDay
  showFROverDay(handles);
end



% --- Executes on selection change in cmbChannel.
function cmbChannel_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns cmbChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cmbChannel
msgbox('Not implemented yet');



% --- Executes on button press in btnSelectTemplate.
function btnSelectTemplate_Callback(hObject, eventdata, handles)
% Set up axWaves's ButtonDownFcn so that when they click on the plot
% they'll start drawing the template
handles = markSortChanged(handles);

handles.origWindowButtonDownFcn = get(gcbf, 'WindowButtonDownFcn');
set(gcbf, 'WindowButtonDownFcn', @startTemplate);

set(gcbf, 'Pointer', 'crosshair');

guidata(hObject, handles);



% --- Executes on button press in btnClearUnit.
function btnClearUnit_Callback(hObject, eventdata, handles)
unit = handles.activeUnit;
methodType = handles.sortMethods{handles.sortMethod}.type;
% Execute this sort type's clearUnit function first, to let it destroy any
% associated sorting objects.
handles = feval(['clearUnit' methodType], handles);

% Clear fields, mark unit undefined, clear rating
epochs = epochsToAffect(handles);
for epoch = epochs
  if isempty(handles.sorts(epoch).(methodType).params)
    continue;
  end
  fields = fieldnames(handles.sorts(epoch).(methodType).params);
  for f = 1:length(fields)
    handles.sorts(epoch).(methodType).params(unit+1).(fields{f}) = [];
  end
  handles.sorts(epoch).(methodType).unitsDefined(handles.sorts(epoch).(methodType).unitsDefined == unit) = [];
  % Clear ratings
  if unit ~= 0
    handles.sorts(epoch).(methodType).ratings(unit) = 0;
  end
end

if unit ~= 0
  set(handles.ratingHs(unit), 'String', '0');
end

handles.activeSortObj = NaN;

% Clear autocorr
if ~isempty(handles.sortInfo.autocorrs)
  if unit ~= 0
    handles.sortInfo.autocorrs(unit).values = [];
  end
end
handles = markSortChanged(handles);
displayWaveforms(handles);



% --- Executes on button press in btnTuningConsistency.
function btnTuningConsistency_Callback(hObject, eventdata, handles)
% Brings up the tuning consistency plots, if the trialInfo field isn't
% empty
if isempty(handles.waveforms.trialInfo)
  uiwait(msgbox('No trial/condition information. Add this through the menu in the multi-channel window', 'Trial info not added'));
  return;
end

% Check that any sorts are defined
unitsDefined = allDefinedUnits(handles);
unitsDefined(unitsDefined == 0) = [];      % Exclude explicit zero-unit if relevant
if isempty(unitsDefined)
  uiwait(msgbox('Please sort some units first', 'Sorts required', 'modal'));
  return;
end

% If data isn't fully sorted, do it now
if ~handles.sortInfo.fullySorted
  btnFullSort_Callback(hObject, [], handles);
  handles = guidata(hObject);
end

% Generate the plots
figure('Name', 'Tuning consistency analysis', 'Position', [100 100 900 400], 'NumberTitle', 'off');
ha = subplot(1, 2, 1);
set(ha, 'Position', [0.07 0.1 0.41 0.83]);
tuningConsistencyPlot(handles);

ha = subplot(1, 2, 2);
set(ha, 'Position', [0.56 0.1 0.41 0.83])
FRByCondAndTimePlot(handles);



% --- Executes on button press in chkDifferentiate.
function chkDifferentiate_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of chkDifferentiate

clearActiveSortObjects(handles.axWaves, [], handles);
handles = guidata(hObject);

set(gcbf, 'Pointer', 'watch');
drawnow;

method = handles.sortMethods{handles.sortMethod};

for epoch = 1:length(handles.sorts)
  handles.sorts(epoch).(method.type).differentiated = get(hObject, 'Value');
end

switch method.view
  % If we're using PCA, need to rebuild PCA coefficients
  case 'PCA'
    handles = regenPCASpace(handles);
    % Reset pan
    handles.PCACenter = zeros(1, length(handles.PCACenter));
end

handles.activeUnit = 1;
handles.maxes = [];
handles.mins = [];
handles.globalMax = [];
handles.globalMin = [];

handles = markSortChanged(handles);
displayWaveforms(handles);

set(gcbf, 'Pointer', 'arrow');



% --- Executes on button press in btnNewReqHoop.
function btnNewReqHoop_Callback(hObject, eventdata, handles)
activateAxes(gcbf, handles.axWaves);
xLims = get(gca, 'XLim');
yLims = get(gca, 'YLim');
r = [range(xLims) range(yLims)]; % Range
ym = 0.1;                        % y range multiplier for initial size

x = round(mean(xLims));
yMin = mean(yLims) - r(2) * ym;
yMax = mean(yLims) + r(2) * ym;

epochs = epochsToAffect(handles);
% All the hard work done inside newReqHoop
[handles, hoopHandle] = newReqHoop(handles, x, yMin, yMax, epochs, 0);

guidata(handles.axWaves, handles);

sortNewHoop(hoopHandle);



% --- Executes on button press in btnDeleteHoop.
function btnDeleteHoop_Callback(hObject, eventdata, handles)
thisHoop = handles.activeSortObj;

if isnan(thisHoop), return; end;

epochs = epochsToAffect(handles);
epochs(epochs == handles.activeEpoch) = [];  % We'll deal with the active epoch specially, to make absolutely sure things work

findHoop = (handles.sorts(handles.activeEpoch).Template.params(handles.activeUnit+1).hoopHs == thisHoop);
pos = handles.sorts(handles.activeEpoch).Template.params(handles.activeUnit+1).hoops(findHoop, :);
% Clear hoop for this epoch
handles.sorts(handles.activeEpoch).Template.params(handles.activeUnit+1).hoopHs(findHoop) = [];
handles.sorts(handles.activeEpoch).Template.params(handles.activeUnit+1).hoops(findHoop, :) = [];

% Clear hoop for other epochs, if applicable
for epoch = epochs
  hoops = handles.sorts(epoch).Template.params(handles.activeUnit+1).hoops;
  if ~isempty(hoops)
    row = find(hoops(:,1) == pos(1) & hoops(:,2) == pos(2) & hoops(:,3) == pos(3));
    if ~isempty(row)
      handles.sorts(epoch).Template.params(handles.activeUnit+1).hoops(row, :) = [];
      handles.sorts(epoch).Template.params(handles.activeUnit+1).hoopHs(row) = [];
    end
  end
end

handles.activeSortObj = NaN;
handles = clearDragHs(handles);
delete(thisHoop);
handles.sortObjects(handles.sortObjects == thisHoop) = [];
handles = markSortChanged(handles);

% If a hoop was all that defined this unit, mark it undefined
for epoch = [epochs handles.activeEpoch]
  if isempty(handles.sorts(epoch).Template.params(handles.activeUnit+1).hoops) && ...
      isempty(handles.sorts(epoch).Template.params(handles.activeUnit+1).inTemplate)
    handles.sorts(epoch).Template.unitsDefined(handles.sorts(epoch).Template.unitsDefined == handles.activeUnit) = [];
    if handles.activeUnit > 0
      set(handles.ratingHs(handles.activeUnit), 'String', '0');
    end
  end
end

displayWaveforms(handles);



% --- Executes on button press in btnSave.
function btnSave_Callback(hObject, eventdata, handles)
set(handles.lblSaving, 'Visible', 'on');
set(gcbf, 'Pointer', 'watch');
drawnow;

% At the moment, must fully sort before saving, even with fast save.
btnFullSort_Callback(hObject, eventdata, handles);
handles = guidata(hObject);

% Figure out filename, save down waveforms file
sortInfo = handles.sortInfo;
alpha = alphabet();
if isnan(sortInfo.array)
  lett = '';
else
  lett = alpha(sortInfo.array);
end
waveFilename = makeWaveFilename(lett, sortInfo.electrode);
waveFilename = fullfile(handles.path, waveFilename);


waveforms = handles.waveforms;

waveforms.sorted = 1;

% Add ratings to waveforms structure
method = handles.sortMethods{handles.sortMethod};
for epoch = 1:length(handles.sorts)
  waveforms.ratings(epoch).ratings = handles.sorts(epoch).(method.type).ratings;
  waveforms.ratings(epoch).epoch = [handles.sorts(epoch).epochStart handles.sorts(epoch).epochEnd];
end

if ~handles.fastSave
  save(waveFilename, 'waveforms');
end


% Set up comm structure to be sent to mksort. Includes sortInfo and, if 
% applicable, preview

comm.sortInfo = handles.sortInfo;

% Check whether this channel is completely rated, find max ratings for each
% unit
allRated = 1;
comm.sortInfo.maxRatings = zeros(1, length(handles.axUnitHs) - 1);
for epoch = 1:length(handles.sorts)
  units = handles.sorts(epoch).(method.type).unitsDefined;
  for u = units(units ~= 0)
    if handles.sorts(epoch).(method.type).ratings(u) == 0
      allRated = 0;
    else
      comm.sortInfo.maxRatings(u) = max(comm.sortInfo.maxRatings(u), handles.sorts(epoch).(method.type).ratings(u));
    end
  end
end
comm.sortInfo.rated = allRated;

comm.sortInfo.nPCADims = handles.nPCADims;
comm.sortInfo.differentiated = get(handles.chkDifferentiate, 'Value');
comm.sortInfo.viewMode = method.view;

comm.sortInfo.sorts = handles.sorts;


% If we're doing a full save, pass back preview structure
if ~handles.fastSave
  comm.sortInfo.fullySorted = 1;
  
  preview = handles.preview;
  
  comm.preview.throughDayAligned = handles.waveforms.alignedWaves(:, preview.throughDaySpikeNums);
  comm.preview.throughDayUnits = handles.waveforms.units(preview.throughDaySpikeNums);
  
  switch method.view
    case 'PCA'
      comm.preview.PCAPts = handles.PCAPts(:, preview.throughDaySpikeNums);
    otherwise
      comm.preview.PCAPts = [];
  end
else
  comm.sortInfo.fullySorted = 0;
end

handles.saved = 1;

guidata(hObject, handles);

set(gcbf, 'Pointer', 'arrow');
set(handles.lblSaving, 'Visible', 'off');

% Send data to mksort, so that it can update and save down sorts (and
% previews if applicable)
mksort(comm, handles.thisChannel);



% --- Executes on button press in btnNewEllipse.
function btnNewEllipse_Callback(hObject, eventdata, handles)
activateAxes(gcbf, handles.axWaves);

% Get a quick estimate of the std dev of each dimension
usedDims = size(handles.PCAPts, 1);
nPts = size(handles.PCAPts, 2);
maxPts = min(nPts, 100000);

nDims = handles.maxPCADims;

stds = ones(1, nDims);
stds(1:usedDims) = std(handles.PCAPts(:, 1:maxPts), 0, 2)';

epochs = epochsToAffect(handles);
% All the hard work done inside newEllipse
[handles, ellipseHandle] = newEllipse(handles, epochs, handles.defaultEllipseWidth .* [-stds ./ 2, stds]);

guidata(handles.axWaves, handles);

sortNewHoop(ellipseHandle);



% --- Executes on button press in btnDeleteEllipse.
function btnDeleteEllipse_Callback(hObject, eventdata, handles)
thisEllipse = handles.activeSortObj;

if isnan(thisEllipse), return; end;

epochs = epochsToAffect(handles);
epochs(epochs == handles.activeEpoch) = [];  % We'll deal with the active epoch specially, to make absolutely sure things work

findEllipse = (handles.sorts(handles.activeEpoch).PCAEllipses.params(handles.activeUnit+1).ellipseHs == thisEllipse);
pos = handles.sorts(handles.activeEpoch).PCAEllipses.params(handles.activeUnit+1).ellipses(findEllipse, :);
% Clear ellipse for this epoch
handles.sorts(handles.activeEpoch).PCAEllipses.params(handles.activeUnit+1).ellipseHs(findEllipse) = [];
handles.sorts(handles.activeEpoch).PCAEllipses.params(handles.activeUnit+1).ellipses(findEllipse, :) = [];

% Clear ellipse for other epochs, if applicable
for epoch = epochs
  if length(handles.sorts(epoch).PCAEllipses.params) > handles.activeUnit
    ellipses = handles.sorts(epoch).PCAEllipses.params(handles.activeUnit+1).ellipses;
    if ~isempty(ellipses)
      row = ones(size(ellipses, 1), 1);
      for i = 1:4
        row = row & ellipses(:,i) == pos(i);
      end
      if any(row)
        handles.sorts(epoch).PCAEllipses.params(handles.activeUnit+1).ellipses(row, :) = [];
        handles.sorts(epoch).PCAEllipses.params(handles.activeUnit+1).ellipseHs(row) = [];
      end
    end
  end
end

handles.activeSortObj = NaN;
handles = clearDragHs(handles);
delete(thisEllipse);
handles.sortObjects(handles.sortObjects == thisEllipse) = [];
handles = markSortChanged(handles);

% If this ellipse was all that defined this unit, mark it undefined
for epoch = [epochs handles.activeEpoch]
  if length(handles.sorts(epoch).PCAEllipses.params) > handles.activeUnit
    if isempty(handles.sorts(epoch).PCAEllipses.params(handles.activeUnit+1).ellipses)
      handles.sorts(epoch).PCAEllipses.unitsDefined(handles.sorts(epoch).PCAEllipses.unitsDefined == handles.activeUnit) = [];
      if handles.activeUnit > 0
        set(handles.ratingHs(handles.activeUnit), 'String', '0');
      end
    end
  end
end

displayWaveforms(handles);



% --- Executes on slider movement.
function sldZoom_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
voltage = handles.maxVoltage*handles.zoomFactor^get(hObject, 'Value');
set(handles.lblZoomScale, 'String', sprintf('%c%d %cV', 177, round(voltage), 181));
handles = rebuildSortObjects(handles, handles.sorts, 0);
displayWaveforms(handles);



% --- Executes on selection change in cmbTroughDepthHist.
function cmbTroughDepthHist_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns cmbTroughDepthHist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cmbTroughDepthHist
displayTroughDepths(handles);



% --- Executes on button press in btnClearTemplate.
function btnClearTemplate_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of btnClearTemplate
active = handles.activeUnit;

epochs = epochsToAffect(handles);

for epoch = epochs
  handles.sorts(epoch).Template.params(active+1).inTemplate = [];
  handles.sorts(epoch).Template.params(active+1).outTemplate = [];
  handles.sorts(epoch).Template.params(active+1).templateStart = [];
  handles.sorts(epoch).Template.params(active+1).templateEnd = [];
end
handles = markSortChanged(handles);

% If this was all that defined the unit, mark it undefined
for epoch = epochs
  if isempty(handles.sorts(epoch).Template.params(handles.activeUnit+1).hoops)
    handles.sorts(epoch).Template.unitsDefined(handles.sorts(epoch).Template.unitsDefined == handles.activeUnit) = [];
    if active > 0
      set(handles.ratingHs(active), 'String', '0');
    end
  end
end

displayWaveforms(handles);



% --- Executes on button press in btnNewSortEpoch.
function btnNewSortEpoch_Callback(hObject, eventdata, handles)
% Figure out where to insert this epoch
% May re-write this eventually, but for now, only allow a new epoch
% following all the other epochs
currTime = get(handles.sldTime, 'Value');
if currTime == 1
  msgbox('Cannot create a new epoch at time 1.');
  return;
end

% All the hard work done inside newEpoch
handles = newEpoch(handles, currTime);
guidata(hObject, handles);



% --- Executes on button press in btnDeleteSortEpoch.
function btnDeleteSortEpoch_Callback(hObject, eventdata, handles)
ep = handles.activeEpoch;

activateAxes(gcbf, handles.axTimeline);

if length(handles.sorts) == 1
  msgbox('Cannot delete sole epoch');
  return;
end
  
% Have to treat first epoch differently from all other epochs
if ep == 1
  % Delete epoch in sorts structure
  handles.sorts(ep + 1).epochStart = handles.sorts(ep).epochStart;
  handles.sorts(ep) = [];
  
  % Modify following rectangle, delete this rectangle on the timeline
  thisPos = get(handles.sortEpochRectHs(ep), 'Position');
  nextPos = get(handles.sortEpochRectHs(ep+1), 'Position');
  nextPos(1) = thisPos(1);
  nextPos(3) = nextPos(3) + thisPos(3);
  set(handles.sortEpochRectHs(ep+1), 'Position', nextPos);
  delete(handles.sortEpochRectHs(ep));
  handles.sortEpochRectHs(ep) = [];
  
  handles.activeEpoch = 1;
else
  % Delete epoch in sorts structure
  handles.sorts(ep - 1).epochEnd = handles.sorts(ep).epochEnd;
  handles.sorts(ep) = [];
  
  % Modify previous rectangle, delete this rectangle on the timeline
  thisPos = get(handles.sortEpochRectHs(ep), 'Position');
  prevPos = get(handles.sortEpochRectHs(ep-1), 'Position');
  prevPos(3) = prevPos(3) + thisPos(3);
  set(handles.sortEpochRectHs(ep-1), 'Position', prevPos);
  delete(handles.sortEpochRectHs(ep));
  handles.sortEpochRectHs(ep) = [];
  
  handles.activeEpoch = ep - 1;
end

colorEpochRects(handles);

handles = markSortChanged(handles);

handles = rebuildSortObjects(handles, handles.sorts, 0);
displayWaveforms(handles);



% --- Executes on button press in chkChangeCurrentEpoch.
function chkChangeCurrentEpoch_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of chkChangeCurrentEpoch
%
% No code needed, just maintains state



% --- Executes on selection change in cmbNPCADims.
function cmbNPCADims_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns cmbNPCADims contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cmbNPCADims
set(gcbf, 'Pointer', 'watch');
drawnow;

strs = get(hObject, 'String');
nDims = str2double(strs{get(hObject, 'Value')});

oldNDims = handles.nPCADims;
handles.nPCADims = nDims;

% Enable/disable buttons
PCADimBtnEnabling(handles, nDims);

updateViewLabel(handles);

% Regenerate PCA space or cut down dimensions in PCAPts, re-display
handles = markSortChanged(handles);
if oldNDims >= nDims
  handles.PCAPts = handles.PCAPts(1:nDims, :);
  btnPCA12_Callback(handles.btnPCA12, [], handles);
else
  % If we have the coeffs cached, no need to re-generate
  if size(handles.sorts(1).PCAEllipses.PCACoeffs, 1) >= nDims
    handles = regenPCAPts(handles);
  else
    handles = regenPCASpace(handles);
  end
  displayWaveforms(handles);
end

set(gcbf, 'Pointer', 'arrow');




% --- Executes on button press in btnPCA123.
function btnPCA123_Callback(hObject, eventdata, handles)
% Shows the 3-D PCA plot in a new, small figure. User can only rotate it,
% this view doesn't support interaction.
params = handles.sorts(handles.activeEpoch).PCAEllipses.params;

uniqueUnits = unique(handles.unitsShown);
uniqueUnits(uniqueUnits > handles.maxUnits) = [];
if ~isempty(uniqueUnits)
  hf = figure('Name', '3-D PCA View', 'NumberTitle', 'off');
  hold on;

  % For each unit, plot points and ellipsoids
  for unit = uniqueUnits
    isUnit = (handles.unitsShown == unit);
    % Data points
    plot3(handles.PCAShown(1, isUnit), handles.PCAShown(2, isUnit), handles.PCAShown(3, isUnit), '.', 'color', handles.sortColors(unit+1, :), 'MarkerSize', 6);
    % Ellipsoids
    if ~isempty(params(unit+1).ellipses)
      colormap(handles.sortColors(1:uniqueUnits(end)+1, :));
      for e = 1:size(params(unit+1).ellipses, 1)
        ell = params(unit+1).ellipses(e, :);
        nDims = length(ell) / 2;
        % Radii
        r = [ell(nDims+1)/2, ell(nDims+2)/2, ell(nDims+3)/2];
        % Centers
        c = [ell(1)+r(1), ell(2)+r(2), ell(3)+r(3)];
        [x, y, z] = ellipsoid(c(1), c(2), c(3), r(1), r(2), r(3), 30);
        h = surf(x, y, z, (unit + 1) * ones(size(z)));
        set(h, 'LineStyle', 'none');
        alpha(h, 0.4);
      end
    end
  end
  xlabel('PC 1');
  ylabel('PC 2');
  zlabel('PC 3');
end
% Position camera, make it so that rotation won't change size
campos([-75 -75 75]);
camva('manual');
camva(8);
% Enable rotation
rotate3d(hf);



% --- Executes on button press in btnPCA12.
function btnPCA12_Callback(hObject, eventdata, handles)
changePCADimBtns(hObject, handles, [1 2]);


% --- Executes on button press in btnPCA13.
function btnPCA13_Callback(hObject, eventdata, handles)
changePCADimBtns(hObject, handles, [1 3]);


% --- Executes on button press in btnPCA14.
function btnPCA14_Callback(hObject, eventdata, handles)
changePCADimBtns(hObject, handles, [1 4]);


% --- Executes on button press in btnPCA23.
function btnPCA23_Callback(hObject, eventdata, handles)
changePCADimBtns(hObject, handles, [2 3]);


% --- Executes on button press in btnPCA24.
function btnPCA24_Callback(hObject, eventdata, handles)
changePCADimBtns(hObject, handles, [2 4]);


% --- Executes on button press in btnPCA34.
function btnPCA34_Callback(hObject, eventdata, handles)
changePCADimBtns(hObject, handles, [3 4]);



% --- Executes on button press in btnPan.
function btnPan_Callback(hObject, eventdata, handles)
hp = pan(handles.figOneChannelSorter);
set(hp, 'Enable', 'on', 'ActionPostCallback', @postPanFcn);





%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------


function colorSwitches(hObject, eventdata, handles)
% Make sure at least one of each option is checked for color options
set(hObject, 'Value', 1);
if hObject == handles.rdbWaveSamplingByTime || hObject == handles.rdbWaveSamplingAtIntervals
  set(handles.rdbColorBySort, 'Value', 1);
end
timeOfDayEnabling(hObject, eventdata, handles);
handles = guidata(hObject);
displayWaveforms(handles);



function timeOfDayEnabling(hObject, eventdata, handles)
% Handles enabling and disabling of time slider and other UI functions
% depending on the point coloration option selected

if get(handles.rdbColorBySort, 'Value') && get(handles.rdbWaveSamplingByTime, 'Value')
  % Enable time slider
  set(handles.sldTime, 'Enable', 'on');
  % Enable clicking timeline to jump to time
  for eh = handles.sortEpochRectHs
    set(eh, 'ButtonDownFcn', @jumpToEpoch);
  end
  % Show current time tick on timeline
  if isempty(handles.sortEpochTickH)
    currTime = get(handles.sldTime, 'Value');
    nWavesShown = str2double(get(handles.txtNWaves, 'String'));
    activateAxes(gcbf, handles.axTimeline);
    handles.sortEpochTickH = rectangle('Position', [currTime 0 nWavesShown 1], 'EdgeColor', 'k', 'FaceColor', 'none');
  end
  % Enable new/delete epoch buttons
  set(handles.btnNewSortEpoch, 'Enable', 'on');
  set(handles.btnDeleteSortEpoch, 'Enable', 'on');
  % Make sure sorting control buttons are enabled (if not n-trode or in PCA
  % mode)
  method = handles.sortMethods{handles.sortMethod};
  if ~handles.disableNTrodeTemplateSort || length(handles.sortInfo.electrode) == 1 || strcmp(method.view, 'PCA')
    panel = handles.(['pnl' method.type]);
    for child = get(panel, 'Children')
      set(child, 'Enable', 'on');
    end
    % Need to keep PC dimension buttons enabled/disabled as appropriate
    PCADimBtnEnabling(handles, handles.nPCADims);
  end
else
  % Disable time slider
  set(handles.sldTime, 'Enable', 'off');
  % Disable clicking timeline
  for eh = handles.sortEpochRectHs
    set(eh, 'ButtonDownFcn', []);
  end
  % Remove timeline current time tick
  if ~isempty(handles.sortEpochTickH)
    try
      delete(handles.sortEpochTickH);
    end
    handles.sortEpochTickH = [];
  end
  % Disable new/delete epoch buttons
  set(handles.btnNewSortEpoch, 'Enable', 'off');
  set(handles.btnDeleteSortEpoch, 'Enable', 'off');
  % Make sure sorting control buttons are disabled if there's more than one
  % epoch OR we have an n-trode and we're not in PCA mode, enabled
  % otherwise
  method = handles.sortMethods{handles.sortMethod};
  panel = handles.(['pnl' method.type]);
  if length(handles.sorts) > 1 || ...
      length(handles.sortInfo.electrode) > 1 && handles.disableNTrodeTemplateSort && strcmp(method.view, 'Waveform')
    for child = get(panel, 'Children')
      set(child, 'Enable', 'off');
    end
  else
    for child = get(panel, 'Children')
      set(child, 'Enable', 'on');
    end
    % Need to keep PC dimension buttons enabled/disabled as appropriate
    PCADimBtnEnabling(handles, handles.nPCADims);
  end
end
handles.waveIntervalSeed = 1;
guidata(hObject, handles);



function handles = changeAcceptance(handles, hObject)
% Store acceptance values. displayWaveforms should be called after this.
methodType = handles.sortMethods{handles.sortMethod}.type;
whichAccept = (handles.sldAcceptHs == hObject);
epochs = epochsToAffect(handles);
for epoch = epochs
  handles.sorts(epoch).(methodType).params(whichAccept).acceptance = get(hObject, 'Value');
end
handles = markSortChanged(handles);



function changeRating(handles, hObject)
% Enforce sane values, prevent rating an undefined unit, store rating
val = str2double(get(hObject, 'String'));

unitsDefined = allDefinedUnits(handles);
thisRating = find(handles.ratingHs == hObject, 1);

if isnan(val) || val < 0 || val > 4 || ~ismember(thisRating, unitsDefined)
  val = 0;
  set(hObject, 'String', '0');
end

sortMethod = handles.sortMethods{handles.sortMethod};
epochs = epochsToAffect(handles);
for epoch = epochs
  if isempty(handles.sorts(epoch).(sortMethod.type).ratings)
    handles.sorts(epoch).(sortMethod.type).ratings = zeros(1, length(handles.axUnitHs)-1);
  end
  handles.sorts(epoch).(sortMethod.type).ratings(thisRating) = val;
end
guidata(hObject, handles);



function handles = changeWaveLims(handles, startPt, endPt)
% Store wave limits
sortMethodType = handles.sortMethods{handles.sortMethod}.type;
% Check for hoops that would be out of bounds; if found, abort
if strcmp(sortMethodType, 'Template')
  for epoch = 1:length(handles.sorts)
    for u = 1:length(handles.sorts(epoch).Template.params)
      if ~isempty(handles.sorts(epoch).Template.params(u).hoops) && ...
          (any(handles.sorts(epoch).Template.params(u).hoops(:, 1) > endPt) || ...
          any(handles.sorts(epoch).Template.params(u).hoops(:, 1) < startPt))
        uiwait(msgbox('Hoops must be inside new boundaries', 'modal'));
        set(handles.txtStartWaveTime, 'String', num2str(handles.sorts(epoch).(sortMethodType).waveLims(1)));
        set(handles.txtEndWaveTime, 'String', num2str(handles.sorts(epoch).(sortMethodType).waveLims(2)));
        return;
      end
    end
  end
end
for epoch = 1:length(handles.sorts)
  handles.sorts(epoch).(sortMethodType).waveLims(1) = startPt;
  handles.sorts(epoch).(sortMethodType).waveLims(2) = endPt;
end
set(handles.txtStartWaveTime, 'String', num2str(startPt));
set(handles.txtEndWaveTime, 'String', num2str(endPt));

handles = markSortChanged(handles);



function changePCADimBtns(hObject, handles, dims)
% When user clicks a button that changes which PCA dimensions are to be
% displayed, this should get called. dims is the dimensions to be
% displayed, like [2 3].
set(hObject, 'Value', 1);
for btnH = handles.PCABtnHs(handles.PCABtnHs ~= hObject)
  set(btnH, 'Value', 0);
end
handles.PCADimsShown = dims;
handles = rebuildSortObjects(handles, handles.sorts, 0);
displayWaveforms(handles);



function PCADimBtnEnabling(handles, nDims)
% Enables the PCA dimension view buttons (1 x 2, 2 x 3, etc) based on how
% many dimensions are given in nDims. Only equipped to handle 2-4!
switch nDims
  case 2
    for btn = 1:6
      set(handles.PCABtnHs(btn), 'Enable', 'off');
    end
    set(handles.btnPCA123, 'Enable', 'off');
  case 3
    for btn = 1:3
      set(handles.PCABtnHs(btn), 'Enable', 'on');
    end
    for btn = 4:6
      set(handles.PCABtnHs(btn), 'Enable', 'off');
    end
    set(handles.btnPCA123, 'Enable', 'on');
  case 4
    for btn = 1:6
      set(handles.PCABtnHs(btn), 'Enable', 'on');
    end
    set(handles.btnPCA123, 'Enable', 'on');
end



function colorEpochRects(handles)
% Make the rectangles on the timeline a lovely gradient of shades from
% green to blue. Lovely.
nEpochs = length(handles.sorts);
if nEpochs == 1
  set(handles.sortEpochRectHs(1), 'EdgeColor', [0.5 0.5 0.5], 'FaceColor', [0.5 1 0.5]);
else
  for r = 1:nEpochs
    cAddend = (r-1) / (nEpochs - 1);
    color = [0 1-cAddend cAddend];
    set(handles.sortEpochRectHs(r), 'EdgeColor', [0.5 0.5 0.5], 'FaceColor', color);
  end
end



function highlightIndividualUnitPlot(hObject, handles)
for h = handles.axUnitHs
  set(h, 'Box', 'off', 'XColor', 'w', 'YColor', 'w', 'LineWidth', 0.1);
end
set(hObject, 'Box', 'on', 'XColor', handles.selectColor, 'YColor', ...
  handles.selectColor, 'LineWidth', 2);



function handles = rebuildSortObjects(handles, sorts, fullRebuild)
% fullRebuild is whether to rebuild all the sortObjects (after loading a
% new waveform structure, say) or just the active one (e.g., when switching
% epochs).

if isempty(sorts), return; end;

% Figure out which sort method we're using, robustly--methods may have
% changed since the data was saved
methodFcns = {};
for m = 1:length(handles.sortMethods)
  methodFcns{end+1} = handles.sortMethods{m}.classifyFcn;
end
method = find(strcmp(sorts(1).sortMethodFcn, methodFcns));
if isempty(method)
  error('Sort method not available: %s', sorts.sortMethodFcn);
end

% Delete old objects
for sortObj = handles.sortObjects
  try
    delete(sortObj);
  catch
    warning('oneChannelSorter::rebuildSortObjects: Sort object not found (not a big deal)');
  end
end
handles.sortObjects = [];
handles.dragHs = [];

% Replace handles.sorts
handles.sorts = sorts;

% If this is a full rebuild, deal with epochs
if fullRebuild
  % Clear old epoch rectangles and tick
  for rh = handles.sortEpochRectHs
    try
      delete(rh);
    catch
      warning('oneChannelSorter::rebuildSortObjects: epoch rectangle not found (not a big deal)');
    end
  end
  handles.sortEpochRectHs = [];
  try
    delete(handles.sortEpochTickH);
  end
  handles.sortEpochTickH = [];

  % Build new epoch rectangles
  activateAxes(gcbf, handles.axTimeline);
  for ep = 1:length(sorts)
    epochStart = sorts(ep).epochStart;
    epochEnd = sorts(ep).epochEnd;
    hr = rectangle('Position', [epochStart 0 epochEnd-epochStart 1]);
    handles.sortEpochRectHs(end+1) = hr;
    set(hr, 'ButtonDownFcn', @jumpToEpoch);
  end
  
  % Re-color all the rectangles on the timeline
  colorEpochRects(handles);
  
  % This function generates the tick, if needed
  timeOfDayEnabling(handles.sldTime, [], handles);
  handles = guidata(handles.axWaves);
end

active = handles.activeUnit;

% Call appropriate rebuildSortObjects(Type) function
sortMethodType = handles.sortMethods{method}.type;
handles = feval(['rebuildSortObjects' sortMethodType], handles, fullRebuild);

handles.activeUnit = active;

% Fill in ratings
% Copy active acceptances onto sliders
sortClass = sorts(handles.activeEpoch).(sortMethodType);
for u = 1:length(sortClass.params)
  if ~isempty(sortClass.params(u).acceptance)
    set(handles.sldAcceptHs(u), 'Value', sortClass.params(u).acceptance);
  end
end
% Now, copy active ratings into rating text boxes
if ~isempty(sortClass.ratings)
  for u = 1:length(sortClass.ratings)
    set(handles.ratingHs(u), 'String', num2str(sortClass.ratings(u)));
  end
end

% Copy active limits into limit text boxes
set(handles.txtStartWaveTime, 'String', num2str(sortClass.waveLims(1)));
set(handles.txtEndWaveTime, 'String', num2str(sortClass.waveLims(2)));

% Clear active sort objects, so we don't get a mismatch between the active
% unit and the last sort object created being active
clearActiveSortObjects(handles.axWaves, [], handles);
handles = guidata(handles.axWaves);



function updateViewLabel(handles)
view = handles.sortMethods{handles.sortMethod}.view;
if strcmp(view, 'PCA')
  view = [num2str(handles.nPCADims) 'D PCA view'];
else
  view = [view ' view'];
end
set(handles.lblView, 'String', [view ' ']);



function postPanFcn(hObject, eventdata)
handles = guidata(hObject);
hp = pan(handles.figOneChannelSorter);

% Exploit an undocumented handle in the pan object, so it can disable
% itself
hm = hp.ModeHandle;
set(hm, 'Blocking', false);

% Disable panning
set(hp, 'Enable', 'off');

% Restore life as normal
set(hm, 'Blocking', true);

% Save new center
xLims = get(handles.axWaves, 'XLim');
yLims = get(handles.axWaves, 'YLim');

handles.PCACenter(handles.PCADimsShown(1)) = mean(xLims);
handles.PCACenter(handles.PCADimsShown(2)) = mean(yLims);

displayWaveforms(handles);



function handles = makeInterfaceConsistent(handles)
% Make sure things are enabled and disabled appropriately
currMethod = handles.sortMethod;

% UI control panels for this sort type
for m = 1:length(handles.sortMethods)
  set(handles.(['pnl' handles.sortMethods{m}.type]), 'Visible', 'off');
end
set(handles.(['pnl' handles.sortMethods{currMethod}.type]), 'Visible', 'on');

updateViewLabel(handles);

handles.activeUnit = 1;

% Enabling of zero-unit acceptance slider
if handles.sortMethods{currMethod}.explicitZeroUnit
  set(handles.sldAccept0, 'Enable', 'on');
else
  set(handles.sldAccept0, 'Enable', 'off');
end

% Plot threshold slider
if strcmp(handles.sortMethods{currMethod}.view, 'Waveform')
  set(handles.sldPlotThreshold, 'Enable', 'on');
else
  set(handles.sldPlotThreshold, 'Enable', 'off');
end

% Enable/disable Pan button
if strcmp(handles.sortMethods{currMethod}.view, 'PCA')
  set(handles.btnPan, 'Visible', 'on');
else
  set(handles.btnPan, 'Visible', 'off');
end

timeOfDayEnabling(handles.axWaves, [], handles);
handles = guidata(handles.axWaves);
activateUnit(handles.axUnit1, [], handles);



function complainAndClose()
uiwait(msgbox('oneChannelSorter should only be called by mksort!', 'No direct calls', 'warn'));
error('Cannot launch oneChannelSorter directly, call mksort');



function displayTroughDepths(handles)
% This function implements the little plot in the upper-right corner. It
% can either display a histogram of trough depths, histogram of trough
% peaks, or the firing rates of each unit over time.

hObject = handles.axTroughDepthHist;
option = get(handles.cmbTroughDepthHist, 'Value');
activateAxes(gcbf, hObject);
cla;

switch option
  case 1
    % Trough depths
    % Abs or the plot looks backwards
    depths = abs(min(handles.waveforms.alignedWaves));
    [vals, bins] = hist(depths, handles.troughDepthNBins);
    bh = bar(bins, vals);
    set(bh, 'EdgeColor', [0.2 0.2 0.2], 'FaceColor', [0.2 0.2 0.2], 'BarWidth', 1);
    axis tight;
    axLim = axis;
    axLim(4) = axLim(4) * 1.2;  % Set nice limits
    axLims(axLim);
    handles.showFROverDay = 0;
  case 2
    % Peak heights
    peaks = max(handles.waveforms.alignedWaves);
    [vals, bins] = hist(peaks, handles.troughDepthNBins);
    bh = bar(bins, vals);
    set(bh, 'EdgeColor', [0.2 0.2 0.2], 'FaceColor', [0.2 0.2 0.2], 'BarWidth', 1);
    axis tight;
    axLim = axis;
    axLim(4) = axLim(4) * 1.2;  % Set nice limits
    axLims(axLim);
    handles.showFROverDay = 0;
  case 3
    % Firing rate over time
    handles.showFROverDay = 1;
    if handles.sortInfo.fullySorted
      showFROverDay(handles);
    end
end
guidata(handles.axWaves, handles);



function plotTemplateBounds(handles, unit)
% This function plots the mean and StdDev lines on the individual unit
% plots.

% Find points to plot. dStart and dEnd are for the points displayed, tStart
% and tEnd are for the template, 
dStart = str2double(get(handles.txtStartWaveTime, 'String'));
dEnd = str2double(get(handles.txtEndWaveTime, 'String'));
tStart = handles.sorts(handles.activeEpoch).Template.params(unit+1).templateStart;
tEnd = handles.sorts(handles.activeEpoch).Template.params(unit+1).templateEnd;

% plotXs are the x-coordinates to plot, tPts are which points in the
% template we'll access
plotXs = max(dStart, tStart):min(dEnd, tEnd);
tPts = plotXs(1)-tStart+1 : plotXs(1)-tStart+length(plotXs);

means = handles.sorts(handles.activeEpoch).Template.params(unit+1).inTemplate.means';
stds = handles.sorts(handles.activeEpoch).Template.params(unit+1).inTemplate.stds';
acc = handles.sorts(handles.activeEpoch).Template.params(unit+1).acceptance;

h = plot(plotXs, means(tPts) + acc/25 * stds(tPts), '--', 'color', handles.sortColors(unit+1, :)/3);
set(h, 'ButtonDownFcn', @activateParentUnit);
h = plot(plotXs, means(tPts), '-', 'color', handles.sortColors(unit+1, :)/3);
set(h, 'ButtonDownFcn', @activateParentUnit);
h = plot(plotXs, means(tPts) - acc/25 * stds(tPts), '--', 'color', handles.sortColors(unit+1, :)/3);
set(h, 'ButtonDownFcn', @activateParentUnit);



function [handles, hh] = newReqHoop(handles, x, yMin, yMax, epochs, rebuild)
% Generates a new hoop (for the Template sort type).
activateAxes(gcbf, handles.axWaves);
xLims = get(gca, 'XLim');
yLims = get(gca, 'YLim');
r = [range(xLims) range(yLims)]; % axis range, for positioning and sizing the new hoop
xm = 0.015;                      % x range multiplier for display

% Build the new hoop with an I-beam shape. Draws vertical part
% (bottom->top), then bottom (left->right), then top. Color is darker than
% waveforms, so it doesn't get visually lost.
hh = plot([x x NaN x-r(1)*xm x+r(1)*xm NaN x-r(1)*xm x+r(1)*xm], ...
  [yMin yMax NaN yMin yMin NaN yMax yMax], ...
  'color', handles.sortColors(1+handles.activeUnit, :)/2, 'LineWidth', 1.5);

% Fix line thickness on linux
if handles.isLinux
  set(hh, 'LineWidth', 3);
end

draggableActPlusUp(hh, @hoopMove, @sortNewHoop);

unit = handles.activeUnit + 1;

d.unit = handles.activeUnit;
set(hh, 'UserData', d);

% Store data for the hoop in the current epoch or across all epochs, as
% selected
for epoch = epochs
  % Unit may not exist in params structure
  if length(handles.sorts(epoch).Template.params) < unit
    handles.sorts(epoch).Template.params(unit).hoopHs = hh;
    handles.sorts(epoch).Template.params(unit).hoops(1, :) = [x yMin yMax];
    handles.sorts(epoch).Template.params(unit).acceptance = handles.defaultAcceptance;
  else
    handles.sorts(epoch).Template.params(unit).hoopHs(end+1) = hh;
    handles.sorts(epoch).Template.params(unit).hoops(end+1, :) = [x yMin yMax];
  end
  handles.sorts(epoch).Template.unitsDefined = unique([handles.sorts(epoch).Template.unitsDefined handles.activeUnit]);
end

handles.sortObjects = [handles.sortObjects, hh];

guidata(handles.axWaves, handles);

hoopMove(hh, rebuild);

handles = guidata(handles.axWaves);



function [handles, he] = newEllipse(handles, epochs, ell, rebuild)

nDims = length(ell)/2;

dims = handles.PCADimsShown;

pos = [ell(dims(1:2)) ell(dims(1:2)+nDims)];

activateAxes(gcbf, handles.axWaves);
he = rectangle('Position', pos, 'Curvature', [1 1], ...
  'EdgeColor', handles.sortColors(1+handles.activeUnit, :)/2, 'LineWidth', 1.5);

% Fix line thickness on linux
if handles.isLinux
  set(he, 'LineWidth', 3);
end

draggableActPlusUp(he, @ellipseMove, @sortNewEllipse);

unit = handles.activeUnit + 1;

d.unit = handles.activeUnit;
set(he, 'UserData', d);

% Store data for the ellipse in the current epoch or across all epochs, as
% selected
for epoch = epochs
  % Unit may not exist in params structure
  if length(handles.sorts(epoch).PCAEllipses.params) < unit
    handles.sorts(epoch).PCAEllipses.params(unit).ellipseHs = he;
    handles.sorts(epoch).PCAEllipses.params(unit).ellipses(1, :) = ell;
    handles.sorts(epoch).PCAEllipses.params(unit).acceptance = handles.defaultAcceptance;
  else
    handles.sorts(epoch).PCAEllipses.params(unit).ellipseHs(end+1) = he;
    handles.sorts(epoch).PCAEllipses.params(unit).ellipses(end+1, :) = ell;
  end
  handles.sorts(epoch).PCAEllipses.unitsDefined = unique([handles.sorts(epoch).PCAEllipses.unitsDefined handles.activeUnit]);
end

handles.sortObjects = [handles.sortObjects, he];

if ~exist('rebuild', 'var') || ~rebuild
  handles = markSortChanged(handles);
  rebuild = 0;
end

guidata(handles.axWaves, handles);


ellipseMove(he, rebuild);
handles = guidata(handles.axWaves);



function handles = markSortChanged(handles)
% Save that channel is not fully sorted, obliterate validity of online
% sorting, clear autocorrs, clear FR over day if relevant
handles.sortInfo.fullySorted = 0;
handles.sortInfo.onlineSorted = 0;
handles.sortInfo.userSorted = 1;
handles.saved = 0;
for u = 1:length(handles.sortInfo.autocorrs)
  handles.sortInfo.autocorrs(u).values = [];
end
if handles.showFROverDay
  activateAxes(gcbf, handles.axTroughDepthHist);
  cla;
end
activateAxes(gcbf, handles.axWaves);



function showFROverDay(handles)
% Show firing rate over day in little plot in upper right. Should only be
% called when needed.
% This function is written for speed.

% # of pts to show
totalPts = 100;

activateAxes(gcbf, handles.axTroughDepthHist);
cla;
hold on;
uniqueUnits = unique(handles.waveforms.units);
uniqueUnits = uniqueUnits(uniqueUnits ~= 0 & uniqueUnits <= handles.maxUnits);

if isempty(uniqueUnits)
  cla;
  return;
end

% first and last are first and last spike times
first = handles.waveforms.spikeTimes(1);
last = handles.waveforms.spikeTimes(end);
% perLen is how long each rate-calculation-period lasts, in ms
perLen = (last - first) / totalPts;

maxRate = 0;
for u = uniqueUnits
  % spike times for this unit
  sTimes = round(handles.waveforms.spikeTimes(handles.waveforms.units == u));
  
  rate = hist(sTimes, totalPts) * 1000 / perLen;
  plot(rate, 'color', handles.sortColors(u+1, :));
  maxRate = max(maxRate, max(rate));
end

maxRate = max(maxRate, 1);  % Ensure maxRate is at least 1, for plotting
axLims([-8, totalPts, -maxRate/10, maxRate*1.1]);  % Leave space for 'axis' labels
text(0, -maxRate/10, '0', 'FontSize', 8, 'VerticalAlignment', 'bottom');          % Time 0
text(100, -maxRate/10, num2str(round(last/1000)), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'FontSize', 8);  % Time last
text(-8, 0, '0', 'FontSize', 8);                   % Rate 0
text(-8, floor(maxRate), num2str(floor(maxRate)), 'FontSize', 8);  % Rate max



function tuningConsistencyPlot(handles)
nDims = 3;

hold on;

method = handles.sorts(handles.activeEpoch).(handles.sortMethods{handles.sortMethod}.type);
w = handles.waveforms;
goodTrials = ~isnan(w.trialInfo.trial);    % Which spikes are in usable trials (1 x nSpikes)
trialLengths = w.trialInfo.trialEndTimes - w.trialInfo.trialStartTimes;  % Length of each trial (1 x nTrials)
unitsDefined = allDefinedUnits(handles);
unitsDefined(unitsDefined == 0) = [];      % Exclude explicit zero-unit if relevant
for unit = unitsDefined
  thisUnit = (w.units == unit);            % Which spikes are in this unit (1 x nSpikes)
  goodEnough = goodTrials & thisUnit;      % Which spikes are in this unit and in good trials (1 x nSpikes)
  trials = w.trialInfo.trial(goodEnough);  % Trial numbers, by spike, for the goodEnough spikes
  
  % Take the PCA of the spike waveforms in this unit.
  if ~method.differentiated
    [~, scores] = princomp_mksort(zscore_mksort(w.alignedWaves(:, thisUnit)'));
  else
    [~, scores] = princomp_mksort(zscore_mksort(diff(w.alignedWaves(:, thisUnit))'));
  end
  scores = scores(goodTrials(thisUnit), 1:nDims);  % PCA scores for goodEnough spikes
  conditions = w.trialInfo.condition(trials);      % Condition number, by spike, for goodEnough spikes
  uniqueConditions = unique(conditions(~isnan(conditions)));   % List of unique conditions
  
  
  FR = zeros(1, max(uniqueConditions));
  aboveMed = zeros(nDims, max(uniqueConditions));
  belowMed = zeros(nDims, max(uniqueConditions));

  lineStyles = {'--', '-.', ':'};

  for c = 1:length(uniqueConditions)
    % Logical array whether each goodEnough spike is in this condition
    thisCond = (conditions == uniqueConditions(c));
    % Logical array of whether each trial is in the current condition and
    % was a good trial
    condTrials = (w.trialInfo.condition == uniqueConditions(c) & ~isnan(w.trialInfo.trialStartTimes));
    
    % Figure out the firing rate for this condition. This is the total
    % number of goodEnough spikes, divided by the sum of the lengths of the
    % trials they came from
    FR(c) = sum(thisCond) * 1000 / sum(trialLengths(condTrials));
    
    % Now try splitting each cluster based on PCA dimension. We'll try the
    % first nDims different dimensions.
    for dim = 1:nDims
      med = median(scores(:, dim));
      % The firing rate for each half of the cluster is as above, but
      % segregated based on waveform shape and multiplied by 2 to account
      % for only having ~2 the spikes.
      aboveMed(dim, c) = 2 * sum(thisCond & scores(:, dim)' >= med) * 1000 / sum(trialLengths(condTrials));
      belowMed(dim, c) = 2 * sum(thisCond & scores(:, dim)' <= med) * 1000 / sum(trialLengths(condTrials));
    end
    
  end
  
  % Plot
  plot(uniqueConditions, FR(1:length(uniqueConditions)), '-', 'color', handles.sortColors(unit+1, :), 'LineWidth', 2);
  for dim = 1:nDims
    plot(uniqueConditions, aboveMed(dim, 1:length(uniqueConditions)), lineStyles{dim}, 'color', handles.sortColors(unit+1, :));
    plot(uniqueConditions, belowMed(dim, 1:length(uniqueConditions)), lineStyles{dim}, 'color', handles.sortColors(unit+1, :));
  end
  
end

if length(uniqueConditions) > 1
  set(gca, 'XLim', [uniqueConditions(1) uniqueConditions(end)]);
end
xlabel('Condition');
ylabel('Firing rate (spikes/s)');
title('Firing rate by condition');



function FRByCondAndTimePlot(handles)
smoothKernel = 6;  % How many trials to smooth over
meanSmoothKernelPts = 20;  % How many points to use in finding the mean
colorRand = 0.7;   % How much to randomize color traces

hold on;

w = handles.waveforms;

goodTrials = ~isnan(w.trialInfo.trial);    % Which spikes are in usable trials (1 x nSpikes)
trialLengths = w.trialInfo.trialEndTimes - w.trialInfo.trialStartTimes;  % Length of each trial (1 x nTrials)
uniqueTrials = unique(w.trialInfo.trial(goodTrials));        % Unique trial numbers from good trials
conditions = w.trialInfo.condition(uniqueTrials);            % Condition for each trial in uniqueTrials
uniqueConds = unique(conditions(~isnan(conditions)));        % Unique conditions (from good trials)

if isempty(uniqueConds)
  uiwait(msgbox('No conditions were assigned by user-supplied function', 'No conditions', 'modal'));
  return;
end

unitsDefined = allDefinedUnits(handles);
unitsDefined(unitsDefined == 0) = [];      % Exclude explicit zero-unit if relevant
maxT = [];
FRs = {};
for unit = unitsDefined
  thisUnit = (w.units == unit);            % Which spikes are in this unit (1 x nSpikes)
  goodEnough = goodTrials & thisUnit;      % Which spikes are in this unit and in good trials (1 x nSpikes)
  trials = w.trialInfo.trial(goodEnough);  % Trial numbers, by spike, for the goodEnough spikes
  spikesPerTrial = histc(trials, uniqueTrials);    % How many goodEnough spikes from this unit occurred in each trial
  theseTrialLengths = trialLengths(uniqueTrials);  % Length of each good trial

  FRs{unit} = spikesPerTrial * 1000 ./ theseTrialLengths;
  
  % Pull out trace for each condition, box filter with a boxcar length
  % smoothKernel, and plot
  for cond = uniqueConds
    condTrials = (conditions == cond);
    try
      FRCumSum = [0 cumsum(FRs{unit}(condTrials))];
      theseTrials = uniqueTrials(condTrials);
      color = handles.sortColors(unit+1, :) - colorRand/2 * [1 1 1] + colorRand * rand(1, 3);
      color = max(min(color, [1 1 1]), [0 0 0]);
      kern = min(smoothKernel, length(FRCumSum)-1);
      plot(theseTrials(1:end-kern+1), (FRCumSum(kern+1:end) - FRCumSum(1:end-kern))/kern, 'color', color);
      maxT(end+1) = theseTrials(end-kern+1);
    end
  end
end

% Plot means over all conditions
for unit = unitsDefined
  kernel = ceil(length(uniqueTrials) / meanSmoothKernelPts);
  try
    FRCumSum = [0 cumsum(FRs{unit})];
    color = handles.sortColors(unit+1, :) * 0.7;
    color = max(min(color, [1 1 1]), [0 0 0]);
    plot(uniqueTrials(1:end-kernel+1), (FRCumSum(kernel+1:end) - FRCumSum(1:end-kernel))/kernel, 'color', color, 'LineWidth', 2);
  end
end

% If there's more than one sort epoch, add ticks at the epoch boundaries
if length(handles.sorts) > 1
  % Convert epoch spike-valued boundaries to trial-valued boundaries
  bounds = [handles.sorts.epochEnd];
  boundsTrs = [uniqueTrials(1) zeros(1, length(bounds))];  % boundsTrs indexed differently than bounds!
  
  % Need to find last non-NaN trial number after each boundary
  for ep = 1:length(bounds)
    % Check for having run out of trials, put those epoch bounds just after
    % previous one
    if bounds(ep) < boundsTrs(ep)  % Note extra '1' at beginning of boundsTrs
      boundsTrs(ep+1) = boundsTrs(ep) + 1;
    else
      % Otherwise, find the next non-NaN value
      for tr = bounds(ep):length(w.trialInfo.trial)
        if ~isnan(w.trialInfo.trial(tr))
          boundsTrs(ep+1) = w.trialInfo.trial(tr);
          break;
        end
      end
      
      % If we ran off the end and didn't get a trial number, put it just
      % past the previous one
      if boundsTrs(ep+1) == 0
        boundsTrs(ep+1) = max([boundsTrs(ep)+1 uniqueTrials(end)]);
      end
    end
  end
  % Ensure proper x-axis scaling for last epoch
  maxT = max([maxT boundsTrs(end)]);
  
  % Plot the ticks
  yLims = get(gca, 'Ylim');
  tickBottom = yLims(2) - 0.05 * (diff(yLims));
  tickTop = yLims(2);
  xs = [repmat(boundsTrs, 2, 1); NaN(1, length(boundsTrs))];
  ys = repmat([tickBottom tickTop NaN], 1, length(boundsTrs));
  plot(xs(:), ys, 'k-');
end

if ~isempty(maxT)
  set(gca, 'XLim', [uniqueTrials(1)-1 maxT(end)]);
end
xlabel('Trial');
ylabel('Smoothed firing rate (spikes/s)');
title('Firing rate over time (by condition)');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% MAIN DISPLAY FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayWaveforms(handles)
% This is a key function. Note also that it will save down the handles
% passed to it, so guidata need not be called before displayWaveforms.
% Make sure to grab handles with guidata afterwards if needed, though.

if handles.preventDisplayUpdate, return; end;

view = handles.sortMethods{handles.sortMethod}.view;

waveforms = handles.waveforms;

% Set up waveform start/end times
startPt = str2double(get(handles.txtStartWaveTime, 'String'));
endPt = str2double(get(handles.txtEndWaveTime, 'String'));
if endPt > size(waveforms.alignedWaves, 1)
  endPt = size(waveforms.alignedWaves, 1);
  handles = changeWaveLims(handles, startPt, endPt);
end

% If we're in PCA view, and the coefficients haven't been calculated,
% calculate them.
switch view
  case 'PCA'
    if isempty(handles.PCAPts)
      handles = regenPCASpace(handles);
    end
end

% Don't allow scaling below -2 mV or above +2 mV
% We also have to extract only the portion of the waveforms we'll be using
if isempty(handles.maxes)
  % We cache these values because scaleWaves is large and this section of
  % the code takes a while.
  if ~get(handles.chkDifferentiate, 'Value')
    scaleWaves = waveforms.alignedWaves(startPt:endPt, :);
  else
    scaleWaves = diff(waveforms.alignedWaves(startPt:endPt, :));
  end
  handles.maxes = max(scaleWaves);
  handles.mins = min(scaleWaves);
  handles.globalMax = max(handles.maxes);
  handles.globalMin = min(handles.mins);
  clear scaleWaves
  
  % Check for sanity
  if max([abs(handles.globalMax) abs(handles.globalMin)]) < 0.001
    uiwait(msgbox('Largest value appears to be smaller than 1 microvolt. Possible problem with voltage scaling (should be in units of mV).', 'Scaling', 'help'));
  end
end
waveMin = max(-handles.maxVoltage, handles.globalMin);
waveMax = min(handles.maxVoltage, handles.globalMax);


% Figure out what data to show, and sort it.
handles = sortDataForPlotting(handles, view, startPt, endPt, waveMin, waveMax);

% Compensate for the differentiate checkbox changing the number of points
if get(handles.chkDifferentiate, 'Value')
  endPt = endPt - 1;
end


% Plot on main axes
handles = displayMainPlot(handles, view, startPt, endPt);

% Plot on individual unit axes
handles = plotIndividualUnits(handles, startPt, endPt, waveMin, waveMax);

% Plot autocorrelations, if applicable
handles = plotAutocorrs(handles);

guidata(handles.axWaves, handles);
activateUnit(handles.axUnitHs(handles.activeUnit+1), [], handles);



%%%%%%%%%%% HELPERS TO displayWaveforms() %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = sortDataForPlotting(handles, view, startPt, endPt, waveMin, waveMax)
% Figure out what data to plot, sort it, generate some other associated
% fields holding info about the displayed waves

nWavesToDisp = str2double(get(handles.txtNWaves, 'String'));
nWavesToDisp = min(nWavesToDisp, size(handles.waveforms.alignedWaves, 2));

switch view
  case 'Waveform'
    % Deal with plotting threshold slider
    zoomVal = handles.zoomFactor ^ get(handles.sldZoom, 'Value');
    maxThresh = handles.maxVoltage * zoomVal;
    handles.thresh = get(handles.sldPlotThreshold, 'Value');
    maxThresh = min(maxThresh, waveMax);
    minThresh = max(-maxThresh, waveMin);
    handles.thresh = min(handles.thresh, maxThresh);
    handles.thresh = max(handles.thresh, minThresh);
    set(handles.sldPlotThreshold, 'Value', handles.thresh);
    set(handles.sldPlotThreshold, 'Min', minThresh);
    set(handles.sldPlotThreshold, 'Max', maxThresh);
    % toUse holds the indices of alignedWaves that clear the threshold
    if handles.thresh == 0
      toUse = 1:size(handles.waveforms.alignedWaves, 2);
    elseif handles.thresh > 0
      toUse = find(handles.maxes >= handles.thresh);
    else
      toUse = find(handles.mins <= handles.thresh);
    end
    
  case 'PCA'
    toUse = 1:size(handles.waveforms.alignedWaves, 2);
end

% Make sure interaction of time slider and threshold get handled OK
time = get(handles.sldTime, 'Value');
handles.firstWaveToShow = find(toUse >= time, 1);


nWaves = length(toUse);
nthWave = floor(nWaves/nWavesToDisp);
nthWave = max(nthWave, 1);  % Make sure nthWave is at least 1!


% Figure out which waves to show based on display/coloring options
% toShow is which waveforms to show, of those in toUse
if get(handles.rdbWaveSamplingAtIntervals, 'Value') || get(handles.rdbColorByTime, 'Value')
  % Not showing waves by time of day
  toShow = handles.waveIntervalSeed - 1 + 1:nthWave:nWaves;
else
  % Showing waves by time of day
  % If sldTime is far towards late, and we're using a threshold, can run
  % off the end. So, if we're past the end of usable waves (determined by
  % threshold), reduce the value of sldTime to the last one we can use.
  if time > toUse(end)
    time = toUse(end);
    set(handles.sldTime, 'Value', time);
  end
  % Complex expression at end ensures we don't run off the end of the data
  toShow = handles.firstWaveToShow - 1 + (1:min(nWavesToDisp, nWaves-handles.firstWaveToShow));
  % Update rectangle on timeline showing which waves are plotted
  pos = get(handles.sortEpochTickH, 'Position');
  if ~isempty(toShow)
    pos(1) = toUse(toShow(1));
    pos(3) = max(toUse(toShow(end)) - toUse(toShow(1)), 1);  % Ensure width isn't 0
    set(handles.sortEpochTickH, 'Position', pos);
  end
end

% Fill in wavesShown, and account for the differentiate checkbox
if ~get(handles.chkDifferentiate, 'Value')
  handles.wavesShown = handles.waveforms.alignedWaves(startPt:endPt, toUse(toShow));
else
  handles.wavesShown = diff(handles.waveforms.alignedWaves(startPt:endPt, toUse(toShow)));
end
handles.wavesShownIndices = toUse(toShow);

% Use existing units if no sorting defined, else use the latest sorting
% parameters
if length(handles.sorts) == 1 && isempty(handles.sorts.(handles.sortMethods{handles.sortMethod}.type).params)
  % Online sorting
  handles.unitsShown = handles.waveforms.units(toUse(toShow));
elseif handles.sortInfo.fullySorted
  % Already fully sorted, don't sort again
  handles.unitsShown = handles.waveforms.units(toUse(toShow));
else
  % Need to sort
  handles.unitsShown = sortWaveforms(handles, handles.wavesShown, handles.wavesShownIndices);
end

% If we're in PCA view, grab the PCA-projected points
switch view
  case 'PCA'
    handles.PCAShown = handles.PCAPts(:, handles.wavesShownIndices);
end



function handles = displayMainPlot(handles, view, startPt, endPt)
activateAxes(gcbf, handles.axWaves);
children = get(gca, 'Children');
% Don't delete the sortObjects
children = children(~ismember(children, handles.sortObjects));
for c = children
  delete(c);
end
hold on;
nToShow = size(handles.wavesShown, 2);

% This plot works totally differently for Waveform and PCA view
switch view
  
  case 'Waveform'
    plot([startPt endPt], [0 0], 'color', [0.8 0.8 0.5]);  % Zero line
    plot([startPt endPt], handles.thresh*[1 1], 'color', [0.5 0.5 0.5]); % View threshold line
    
    if ~get(handles.rdbColorByTime, 'Value');
      % Color by sorts
      % Making a bajillion plots takes too long, but we still need to color
      % each unit. So, we construct a single plot object for each unit
      % separated with NaNs, then plot each (whole) unit with its color.
      uniqueUnits = unique(handles.unitsShown);
      uniqueUnits(uniqueUnits > handles.maxUnits) = [];
      if ~isempty(uniqueUnits)
        for unit = uniqueUnits
          isUnit = (handles.unitsShown == unit);
          nThisUnit = sum(isUnit);
          xs = repmat([startPt:endPt NaN], [1 nThisUnit]);
          wavesWithNaNs = [handles.wavesShown(:, isUnit); NaN * ones(1, nThisUnit)];
          % When we vectorize the matrix, columns stay intact
          plot(xs, wavesWithNaNs(:), 'color', handles.sortColors(unit+1, :));
        end
      end
    else
      % Color by time. Can't use plotting tricks, because each wave is a
      % different color. Nuts.
      for w = 1:nToShow
        wth = handles.wavesShownIndices(w) / size(handles.waveforms.waves, 2);
        plot(startPt:endPt, handles.wavesShown(:, w), 'color', [0 1-wth wth]);
      end
    end
    
    % Account for zoom
    zoomVal = handles.zoomFactor ^ get(handles.sldZoom, 'Value');
    axLims([startPt endPt -handles.maxVoltage*zoomVal handles.maxVoltage*zoomVal]);
    
    
  case 'PCA'
    if ~get(handles.rdbColorByTime, 'Value');
      % Similar speed trick as above, plot all markers for a given unit at
      % once
      uniqueUnits = unique(handles.unitsShown);
      uniqueUnits(uniqueUnits > handles.maxUnits) = [];
      if ~isempty(uniqueUnits)
        for unit = uniqueUnits
          isUnit = (handles.unitsShown == unit);
          plot(handles.PCAShown(handles.PCADimsShown(1), isUnit), handles.PCAShown(handles.PCADimsShown(2), isUnit), '.', 'color', handles.sortColors(unit+1, :), 'MarkerSize', 6);
        end
      end
    else
      % Again, no trick for color by time since each point is a different
      % color.
      for w = 1:nToShow
        plot(handles.PCAShown(handles.PCADimsShown(1), w), handles.PCAShown(handles.PCADimsShown(2), w), '.', 'color', [0 1-w/nToShow w/nToShow]);
      end
    end
    plot(0, 0, '+r');
    
    minX = min(handles.PCAPts(handles.PCADimsShown(1),:));
    maxX = max(handles.PCAPts(handles.PCADimsShown(1),:));
    minY = min(handles.PCAPts(handles.PCADimsShown(2),:));
    maxY = max(handles.PCAPts(handles.PCADimsShown(2),:));
    
    rx = 1.1 * max(abs([minX maxX]));
    ry = 1.1 * max(abs([minY maxY]));
    
    cx = handles.PCACenter(handles.PCADimsShown(1));
    cy = handles.PCACenter(handles.PCADimsShown(2));
    
    % Account for zoom
    % Slightly weird since zoom is calibrated via voltage
    zoomVal = handles.zoomFactor ^ get(handles.sldZoom, 'Value');
    zoomFactor = handles.maxVoltage * zoomVal / handles.initialZoom;

    axLims(zoomFactor .* [-rx rx -ry ry] + [cx cx cy cy]);

    % To instead use grayscale heat map, use the below code. The problem is
    % color-coding by unit...
    % [vals, centers] = hist3(handles.PCAPts', handles.nPCABinsPerDim*[1 1]);
    % hi = image([centers{1}(1) centers{1}(end)], [centers{2}(1) centers{2}(end)], ...
    %   flipud(vals'));
    % colormap(gray(max(handles.PCAPts(:))));

    % Show which dimensions are being displayed
    maxDispX = cx + zoomFactor * rx / 1.07;
    maxDispY = cy + zoomFactor * ry / 1.07;
    text(maxDispX, maxDispY, sprintf('%d\n+ %d', handles.PCADimsShown(2), handles.PCADimsShown(1)));
end

% Sometimes we lose track of sort objects; this isn't good, but we should
% still just get rid of them.
for h = handles.sortObjects
  try
    uistack(h, 'top');
  catch
    warning('Lost track of a sortObject somehow. Not a big deal.');
    handles.sortObjects(handles.sortObjects == h) = [];
  end
end




function handles = plotIndividualUnits(handles, startPt, endPt, waveMin, waveMax)
% Plots the waveforms on the individual unit plots at the bottom.

waveMin = max(waveMin, -handles.indivUnitsMaxVoltage);
waveMax = min(waveMax, handles.indivUnitsMaxVoltage);
methodType = handles.sortMethods{handles.sortMethod}.type;

% Do each unit.
for u = 0:length(handles.axUnitHs) - 1
  activateAxes(gcbf, handles.axUnitHs(u+1));
  % Clear the plot
  children = get(gca, 'Children');
  for c = children
    delete(c);
  end

  hold on;
  
  % Use the same speed trick as in displayMainPlot above
  isUnit = (handles.unitsShown == u);
  nThisUnit = sum(isUnit);
  xs = repmat([startPt:endPt NaN], [1 nThisUnit]);
  wavesWithNaNs = [handles.wavesShown(:, isUnit); NaN * ones(1, nThisUnit)];
  % When we vectorize the matrix, columns stay intact
  h = plot(xs, wavesWithNaNs(:), 'color', handles.sortColors(u+1, :));

  set(h, 'ButtonDownFcn', @activateParentUnit);
  
  % If there's a template, display it
  epoch = handles.activeEpoch;
  if strcmp(methodType, 'Template') && ...
      length(handles.sorts(epoch).Template.params) > u && ...
      ~isempty(handles.sorts(epoch).Template.params(u+1).inTemplate)
    plotTemplateBounds(handles, u);
  end
  
  pad = 0.01 * (endPt - startPt);
  axLims([startPt-pad endPt+pad waveMin waveMax]);
end



function handles = plotAutocorrs(handles)
nAutocorrs = length(handles.sortInfo.autocorrs);

if ~handles.sortInfo.fullySorted
  for u = 1:handles.maxUnits
    handles.sortInfo.autocorrs(u).values = [];
  end
end

plotAutocorrsInAxes(handles.sortInfo.autocorrs, nAutocorrs, handles.maxUnits, handles.axISIHs, handles.sortColors(2:end,:), handles.redRefracViolThresh);




%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SORT-TYPE SPECIFIC FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------



function handles = TemplateInit(handles)
% Init function for Template sort type
handles.sorts.Template.params(1).hoopHs = [];
handles.sorts.Template.params(1).hoops = [];
handles.sorts.Template.params(1).inTemplate = [];
handles.sorts.Template.params(1).outTemplate = [];
handles.sorts.Template.params(1).templateStart = [];
handles.sorts.Template.params(1).templateEnd = [];
handles.sorts.Template.params(1).acceptance = [];
handles.sorts.Template.waveLims = [1 size(handles.waveforms.waves, 1)];
handles.sorts.Template.differentiated = 0;
handles.sorts.Template.ratings = zeros(1, 4);
handles.sorts.Template.unitsDefined = [];



function handles = clearUnitTemplate(handles)
% Handles clearing sort objects when a unit is cleared for the Template
% sort type.
% All params fields get cleared in the parent clearUnit, so all we actually
% need to do is delete the hoop objects and remove them from sortObjects
unit = handles.activeUnit;

handles = clearDragHs(handles);

% Check for trying to clear a unit undefined for this epoch
if length(handles.sorts(handles.activeEpoch).Template.params) > unit
  hhs = handles.sorts(handles.activeEpoch).Template.params(unit+1).hoopHs;
  for h = hhs
    delete(h);
  end
  handles.sortObjects(ismember(handles.sortObjects, hhs)) = [];
end



function handles = rebuildSortObjectsTemplate(handles, fullRebuild)
% Rebuilds sort objects for the Template sort type. fullRebuild is whether
% to rebuild all objects for all epochs (when loading a new waveforms file)
% or just the active ones (when switching epoch views).
% Active epoch is taken to be handles.activeEpoch

% Display everything once, so that limits are OK and we get normal hoop
% widths
set(handles.txtStartWaveTime, 'String', num2str(handles.sorts(handles.activeEpoch).Template.waveLims(1)));
set(handles.txtEndWaveTime, 'String', num2str(handles.sorts(handles.activeEpoch).Template.waveLims(2)));
displayWaveforms(handles);
handles = guidata(handles.axWaves);

% Prevent re-displaying everything every time a hoop is constructed
handles.preventDisplayUpdate = 1;

% Rebuild graphical hoop objects
params = handles.sorts(handles.activeEpoch).Template.params;
% For each unit defined
for u = 1:length(params)
  % Clear old hoops
  handles.sorts(handles.activeEpoch).Template.params(u).hoops = [];
  handles.sorts(handles.activeEpoch).Template.params(u).hoopHs = [];

  handles.activeUnit = u-1;

  % Generate hoops
  for hoop = 1:size(params(u).hoops, 1)
    handles = newReqHoop(handles, params(u).hoops(hoop, 1), params(u).hoops(hoop, 2), params(u).hoops(hoop, 3), handles.activeEpoch, 1);
  end
end

handles.preventDisplayUpdate = 0;



function handles = PCAEllipsesInit(handles)
% Init function for PCAEllipses sort type
handles.sorts.PCAEllipses.params(1).ellipseHs = [];
handles.sorts.PCAEllipses.params(1).ellipses = [];
handles.sorts.PCAEllipses.params(1).acceptance = [];
handles.sorts.PCAEllipses.PCACoeffs = [];
handles.sorts.PCAEllipses.differentiated = 0;
handles.sorts.PCAEllipses.ratings = zeros(1, 4);
handles.sorts.PCAEllipses.unitsDefined = [];
handles.sorts.PCAEllipses.waveLims = [1 size(handles.waveforms.waves, 1)];



function handles = clearUnitPCAEllipses(handles)
% Handles clearing sort objects when a unit is cleared for the PCAEllipses
% sort type.
% All params fields get cleared in the parent clearUnit, so all we actually
% need to do is delete the ellipse objects and remove them from sortObjects
unit = handles.activeUnit;

handles = clearDragHs(handles);

% Check for trying to clear a unit undefined for this epoch
if length(handles.sorts(handles.activeEpoch).PCAEllipses.params) > unit
  hes = handles.sorts(handles.activeEpoch).PCAEllipses.params(unit+1).ellipseHs;
  for h = hes
    delete(h);
  end
  handles.sortObjects(ismember(handles.sortObjects, hes)) = [];
end



function handles = rebuildSortObjectsPCAEllipses(handles, sorts, fullRebuild)
% Rebuilds sort objects for the PCAEllipses sort type. fullRebuild is whether
% to rebuild all objects for all epochs (when loading a new waveforms file)
% or just the active ones (when switching epoch views).
% Active epoch is taken to be handles.activeEpoch

% Prevent unnecessary regeneration of PCA space by regenerating points
% first
if isempty(handles.PCAPts)
  handles = regenPCAPts(handles);
end

% Display everything once, so that limits are OK and we get normal handle
% sizes
displayWaveforms(handles);
handles = guidata(handles.axWaves);

% Prevent re-displaying everything every time an ellipse is constructed
handles.preventDisplayUpdate = 1;

% Rebuild graphical ellipse objects
params = handles.sorts(handles.activeEpoch).PCAEllipses.params;
% For each unit defined
for u = 1:length(params)
  % Clear old ellipses
  handles.sorts(handles.activeEpoch).PCAEllipses.params(u).ellipses = [];
  handles.sorts(handles.activeEpoch).PCAEllipses.params(u).ellipseHs = [];

  handles.activeUnit = u-1;

  % Generate ellipses
  for e = 1:size(params(u).ellipses, 1)
    handles = newEllipse(handles, handles.activeEpoch, params(u).ellipses(e, :), 1);
  end
end

handles.preventDisplayUpdate = 0;

% rebuildSortObjects enables all objects on our panel, so we need to fix
% the dimension buttons, only enabling the right ones
PCADimBtnEnabling(handles, handles.nPCADims);







%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE HANDLING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------


function activateUnit(hObject, eventdata, handles)
% Handles clicks in any of the unit waveform plots. Needs to set that unit
% as active and move the highlight rectangle appropriately.

% Bail if this is the unsorted waveforms plot and the current sort method
% doesn't include explicit zero-unit definition
if hObject == handles.axUnit0
  if ~handles.sortMethods{handles.sortMethod}.explicitZeroUnit
    return;
  end
end

unitNum = find(handles.axUnitHs == hObject) - 1;

% If we get here, user clicked a valid plot. Clear any highlighting of
% other unit plots, highlight this plot, and make this the active unit.
highlightIndividualUnitPlot(hObject, handles);
activateAxes(gcbf, hObject);
handles.activeUnit = unitNum;

guidata(hObject, handles);



function activateParentUnit(hObject, eventdata)
% Callback for the plot objects on the individual unit plots, so that
% clicking them wil still activate the plot
activateUnit(get(hObject, 'Parent'), eventdata, guidata(hObject));



function hoopMove(h, noChange)
% The move function for hoops (Template sort method type)

handles = guidata(h);

% Make sure the right unit is active
UserData = get(h, 'UserData');
unit = UserData.unit;
if handles.activeUnit ~= unit
  activateUnit(handles.axUnitHs(unit+1), [], handles);
  handles = guidata(h);
  activateAxes(gcbf, handles.axWaves);
end

% Round x position to nearest whole value, so we're on a real time point
x = get(h, 'XData');
roundX = round(x(1));
lBound = str2double(get(handles.txtStartWaveTime, 'String'));
rBound = str2double(get(handles.txtEndWaveTime, 'String'));
if roundX < lBound
  roundX = lBound;
elseif roundX > rBound
  roundX = rBound;
end
xDiff = roundX - x(1);
x = x + xDiff;
set(h, 'XData', x);

y = get(h, 'YData');
xLims = get(gca, 'XLim');
yLims = get(gca, 'YLim');
width = handles.dragHandleSize * range(xLims);
height = handles.dragHandleSize * range(yLims);

% Find epochs to affect
epochs = epochsToAffect(handles);

% For each epoch to affect, add coordinates to hoop position storage
findHoop = (handles.sorts(handles.activeEpoch).Template.params(handles.activeUnit+1).hoopHs == h);
pos = handles.sorts(handles.activeEpoch).Template.params(handles.activeUnit+1).hoops(findHoop, :);
for epoch = epochs
  if epoch == handles.activeEpoch
    hoopN = (handles.sorts(handles.activeEpoch).Template.params(unit+1).hoopHs == h);
  else
    % Check that unit exists for this epoch
    hoopN = [];
    if length(handles.sorts(epoch).Template.params) > handles.activeUnit
      hoops = handles.sorts(epoch).Template.params(handles.activeUnit+1).hoops;
      if ~isempty(hoops)
        hoopN = find(hoops(:,1) == pos(1) & hoops(:,2) == pos(2) & hoops(:,3) == pos(3));
      end
    end
  end
  if ~isempty(hoopN)
    % X coordinate
    handles.sorts(epoch).Template.params(unit+1).hoops(hoopN, 1) = roundX;
    % Y coordinate
    handles.sorts(epoch).Template.params(unit+1).hoops(hoopN, 2) = min(y);
    handles.sorts(epoch).Template.params(unit+1).hoops(hoopN, 3) = max(y);
  end
end


% If this is a newly-active hoop, make draggable handles
% Destroy old handles if applicable
if handles.activeSortObj ~= h
  handles = clearDragHs(handles);
  handles.activeSortObj = NaN;
end
try
  set(handles.dragHs(1), 'Position', [x(1)-width/2 y(1)-height/2 width height]);
  set(handles.dragHs(2), 'Position', [x(1)-width/2 y(2)-height/2 width height]);
catch
  % Build new handles
  bottom = rectangle('Position', [x(1)-width/2 y(1)-height/2 width height], 'FaceColor', 'k');
  top = rectangle('Position', [x(1)-width/2 y(2)-height/2 width height], 'FaceColor', 'k');
  handles.dragHs = [bottom, top];
  handles.sortObjects = [handles.sortObjects, handles.dragHs];
  draggableActPlusUp(bottom, 'v', @moveHoopHandle, @sortNewHoop);
  draggableActPlusUp(top, 'v', @moveHoopHandle, @sortNewHoop);
  handles.activeSortObj = h;
  set(handles.dragHs(1), 'Position', [x(1)-width/2 y(1)-height/2 width height]);
  set(handles.dragHs(2), 'Position', [x(1)-width/2 y(2)-height/2 width height]);
end

if ~exist('noChange', 'var') || ~noChange
  handles = markSortChanged(handles);
end

guidata(h, handles);



function moveHoopHandle(h)
% Move function for the little draggable handles on the hoops
handles = guidata(h);

% Make sure the right unit is active
UserData = get(handles.activeSortObj, 'UserData');
unit = UserData.unit;
if handles.activeUnit ~= unit
  activateUnit(handles.axUnitHs(unit+1), [], handles);
  handles = guidata(h);
  activateAxes(gcbf, handles.axWaves);
end

yData = get(handles.activeSortObj, 'YData');

% Bottom
if h == handles.dragHs(1)
  pts = [1 4 5];
  bOrT = 2;  % BottomOrTop, holds index for reqHoops column to change
% Top
elseif h == handles.dragHs(2)
  pts = [2 7 8];
  bOrT = 3;
else
  error('moveHoopHandle: somehow lost track of drag handles');
end

pos = get(h, 'Position');
yData(pts) = pos(2) + pos(4)/2;

% Alter the active hoop
unit = handles.activeUnit;
hoopN = (handles.sorts(handles.activeEpoch).Template.params(unit+1).hoopHs == handles.activeSortObj);
handles.sorts(handles.activeEpoch).Template.params(unit+1).hoops(hoopN, bOrT) = pos(2) + pos(4)/2;
set(handles.activeSortObj, 'YData', yData);
handles = markSortChanged(handles);
guidata(h, handles);



function ellipseMove(h, noChange)
% The move function for ellipses (PCAEllipses sort method type)

handles = guidata(h);

% Make sure the right unit is active
UserData = get(h, 'UserData');
unit = UserData.unit;
if handles.activeUnit ~= unit
  activateUnit(handles.axUnitHs(unit+1), [], handles);
  handles = guidata(h);
  % If the unit failed to activate, something is wrong -- could be, for
  % example, we tried to activate a left-over 0-unit ellipse when this
  % algorithm doesn't support an explicit 0-unit. If so, bail.
  if handles.activeUnit ~= unit, return; end;
  
  activateAxes(gcbf, handles.axWaves);
end

dims = handles.PCADimsShown;
nDims = handles.maxPCADims;

pos = get(h, 'Position');

xLims = get(handles.axWaves, 'XLim');
yLims = get(handles.axWaves, 'YLim');

% % Ensure we're in bounds
% % Actually, think there's no need...
% if pos(1) < xLims(1)
%   pos(1) = xLims(1);
%   set(h, 'Position', pos);
% elseif pos(2) < yLims(1)
%   pos(2) = yLims(1);
%   set(h, 'Position', pos);
% elseif pos(1) + pos(3) > xLims(2)
%   pos(1) = xLims(2) - pos(3);
%   set(h, 'Position', pos);
% elseif pos(2) + pos(4) > yLims(2)
%   pos(2) = yLims(2) - pos(4);
%   set(h, 'Position', pos);
% end

% Find epochs to affect
epochs = epochsToAffect(handles);

% For each epoch to affect, add coordinates to ellipse position storage
unit = handles.activeUnit;
findEllipse = (handles.sorts(handles.activeEpoch).PCAEllipses.params(handles.activeUnit+1).ellipseHs == h);
fullPos = handles.sorts(handles.activeEpoch).PCAEllipses.params(handles.activeUnit+1).ellipses(findEllipse, :);
toChange = [dims(1:2) (nDims+dims(1:2))];
for epoch = epochs
  if epoch == handles.activeEpoch
    ellipseN = find(handles.sorts(handles.activeEpoch).PCAEllipses.params(unit+1).ellipseHs == h);
  else
    % Check that unit exists for this epoch
    ellipseN = [];
    if length(handles.sorts(epoch).PCAEllipses.params) > handles.activeUnit
      ellipses = handles.sorts(epoch).PCAEllipses.params(handles.activeUnit+1).ellipses;
      if ~isempty(ellipses)
        row = ones(size(ellipses, 1), 1);
        for i = 1:4
          row = row & ellipses(:,i) == fullPos(i);
        end
        ellipseN = find(row);
      end
    end
  end
  if ~isempty(ellipseN)
    handles.sorts(epoch).PCAEllipses.params(unit+1).ellipses(ellipseN, toChange) = pos;
  end
end


width = handles.dragHandleSize * range(xLims);
height = handles.dragHandleSize * range(yLims);

% If this is a newly-active ellipse, make draggable handles
% Destroy old handles if applicable
if handles.activeSortObj ~= h
  handles = clearDragHs(handles);
  handles.activeSortObj = NaN;
end
try
  % Drag handle order is left bottom right top
  set(handles.dragHs(1), 'Position', [pos(1)-width/2 pos(2)+pos(4)/2-height/2 width height]);
  set(handles.dragHs(2), 'Position', [pos(1)+pos(3)/2-width/2 pos(2)-height/2 width height]);
  set(handles.dragHs(3), 'Position', [pos(1)+pos(3)-width/2 pos(2)+pos(4)/2-height/2 width height]);
  set(handles.dragHs(4), 'Position', [pos(1)+pos(3)/2-width/2 pos(2)+pos(4)-height/2 width height]);
catch
  % Build new handles
  left = rectangle('Position', [pos(1)-width/2 pos(2)+pos(4)/2-height/2 width height], 'FaceColor', 'k');
  bottom = rectangle('Position', [pos(1)+pos(3)/2-width/2 pos(2)-height/2 width height], 'FaceColor', 'k');
  right = rectangle('Position', [pos(1)+pos(3)-width/2 pos(2)+pos(4)/2-height/2 width height], 'FaceColor', 'k');
  top = rectangle('Position', [pos(1)+pos(3)/2-width/2 pos(2)+pos(4)-height/2 width height], 'FaceColor', 'k');
  handles.dragHs = [left, bottom, right, top];
  handles.sortObjects = [handles.sortObjects, handles.dragHs];
  draggableActPlusUp(left, 'h', @moveEllipseHandle, @sortNewEllipse);
  draggableActPlusUp(bottom, 'v', @moveEllipseHandle, @sortNewEllipse);
  draggableActPlusUp(right, 'h', @moveEllipseHandle, @sortNewEllipse);
  draggableActPlusUp(top, 'v', @moveEllipseHandle, @sortNewEllipse);
  handles.activeSortObj = h;
  set(handles.dragHs(1), 'Position', [pos(1)-width/2 pos(2)+pos(4)/2-height/2 width height]);
  set(handles.dragHs(2), 'Position', [pos(1)+pos(3)/2-width/2 pos(2)-height/2 width height]);
  set(handles.dragHs(3), 'Position', [pos(1)+pos(3)-width/2 pos(2)+pos(4)/2-height/2 width height]);
  set(handles.dragHs(4), 'Position', [pos(1)+pos(3)/2-width/2 pos(2)+pos(4)-height/2 width height]);
end

if ~exist('noChange', 'var') || ~noChange
  handles = markSortChanged(handles);
end

guidata(h, handles);



function moveEllipseHandle(h)
% Move function for the little draggable handles on the ellipses
handles = guidata(h);

% Make sure the right unit is active
UserData = get(handles.activeSortObj, 'UserData');
unit = UserData.unit;
if handles.activeUnit ~= unit
  activateUnit(handles.axUnitHs(unit+1), [], handles);
  handles = guidata(h);
  activateAxes(gcbf, handles.axWaves);
end

dims = handles.PCADimsShown;
nDims = handles.maxPCADims;

epos = get(handles.activeSortObj, 'Position');
hpos = get(h, 'Position');
x = hpos(1) + hpos(3)/2;
y = hpos(2) + hpos(4)/2;

% Left
if h == handles.dragHs(1)
  epos(3) = epos(1) + epos(3) - x;
  if epos(3) <= 0, return; end;  % Check for cross-over
  epos(1) = x;
  changed = 'h';
% Bottom
elseif h == handles.dragHs(2)
  epos(4) = epos(2) + epos(4) - y;
  if epos(4) <= 0, return; end;  % Check for cross-over
  epos(2) = y;
  changed = 'v';
% Right
elseif h == handles.dragHs(3)
  epos(3) = x - epos(1);
  if epos(3) <= 0, return; end;  % Check for cross-over
  changed = 'h';
% Top
elseif h == handles.dragHs(4)
  epos(4) = y - epos(2);
  if epos(4) <= 0, return; end;  % Check for cross-over
  changed = 'v';
else
  error('moveHoopHandle: somehow lost track of drag handles');
end

% Alter the active ellipse
unit = handles.activeUnit;
ellipseN = (handles.sorts(handles.activeEpoch).PCAEllipses.params(unit+1).ellipseHs == handles.activeSortObj);
toChange = [dims(1:2) (nDims+dims(1:2))];
handles.sorts(handles.activeEpoch).PCAEllipses.params(unit+1).ellipses(ellipseN, toChange) = epos;

set(handles.activeSortObj, 'Position', epos);

% Alter drag handles as needed
if strcmp('h', changed)
  % If we changed left or right handle, move top and bottom
  cx = epos(1) + epos(3)/2;
  for dh = [2 4]
    pos = get(handles.dragHs(dh), 'Position');
    pos(1) = cx - pos(3)/2;
    set(handles.dragHs(dh), 'Position', pos);
  end
else
  % If we changed top or bottom handle, move left and right
  cy = epos(2) + epos(4)/2;
  for dh = [1 3]
    pos = get(handles.dragHs(dh), 'Position');
    pos(2) = cy - pos(4)/2;
    set(handles.dragHs(dh), 'Position', pos);
  end
end

handles = markSortChanged(handles);
guidata(h, handles);



function clearActiveSortObjects(hObject, eventdata, handles)
% Callback for axWaves, to deactivate active hoops/whatever.
handles = clearDragHs(handles);
handles.activeSortObj = NaN;
guidata(hObject, handles);



function handles = clearDragHs(handles)
% Delete drag handles, clear handles.dragHs, remove them from sortObjects
if ~isempty(handles.dragHs)
  for i = 1:length(handles.dragHs)
    try
      delete(handles.dragHs(i));
    end
  end
  handles.sortObjects(ismember(handles.sortObjects, handles.dragHs)) = [];
  handles.dragHs = [];
end



function startTemplate(hObject, eventdata)
% This gets triggered when the user clicks inside axWaves after clicking
% the 'Select template' button. We'll set up the line, then transfer
% control to drawTemplateLine.
%
% We could have just set the ButtonDownFcn property of axWaves, but then we
% wouldn't be able to start drawing the line on top of a trace. Instead, we
% set the figure's button-down function, and just calculate where in the
% axes we must be.
handles = guidata(hObject);

% If user clicks right mouse button, abort template selection
if strcmp(get(gcbf, 'SelectionType'), 'alt')
  set(gcbf, 'Pointer', 'arrow');
else
  figPos = get(gcbf, 'Position');
  axPos = get(handles.axWaves, 'Position');
  ptClicked = get(gcbf, 'CurrentPoint');
  
  % If user clicks outside axes, abort template selection
  if ptClicked(1) < figPos(3) * axPos(1) || ptClicked(1) > figPos(3) * (axPos(1)+axPos(3)) || ...
      ptClicked(2) < figPos(4) * axPos(2) || ptClicked(2) > figPos(4) * (axPos(2)+axPos(4))
    set(gcbf, 'Pointer', 'arrow');
  else
    % User clicked inside the plot.
    % x = leftXLim + axXRange * (figX - axX) / axWidth
    xLims = get(handles.axWaves, 'XLim');
    yLims = get(handles.axWaves, 'YLim');
    x = xLims(1) + (xLims(2) - xLims(1)) * (ptClicked(1) / figPos(3) - axPos(1)) / axPos(3);
    y = yLims(1) + (yLims(2) - yLims(1)) * (ptClicked(2) / figPos(4) - axPos(2)) / axPos(4);
    
    handles.startTemplate = [x y]; % coordinates of clicked point
    % Change motion function to drawTemplateLine, set ButtonUpFcn to
    % endTemplate, and save the original ButtonUpFcn
    handles.origWindowButtonMotionFcn = get(gcbf, 'WindowButtonMotionFcn');
    handles.origWindowButtonUpFcn = get(gcbf, 'WindowButtonUpFcn');
    set(gcbf, 'WindowButtonMotionFcn', @drawTemplateLine);
    set(gcbf, 'WindowButtonUpFcn', @endTemplate);
    activateAxes(gcbf, handles.axWaves);
    % Start the line
    handles.templateLine = plot([x x], [y y], '-', 'color', handles.sortColors(handles.activeUnit+1,:));
    guidata(hObject, handles);
  end
end

% Restore figure property
set(gcbf, 'WindowButtonDownFcn', handles.origWindowButtonDownFcn);



function finishTemplateDraw(handles)
set(gcbf, 'WindowButtonDownFcn', handles.origWindowButtonDownFcn);
set(gcbf, 'WindowButtonMotionFcn', handles.origWindowButtonMotionFcn);
set(gcbf, 'WindowButtonUpFcn', handles.origWindowButtonUpFcn);



function drawTemplateLine(hObject, eventdata)
% While in the middle of drawing the template line, update every time the
% mouse is moved
handles = guidata(hObject);
currPt = get(handles.axWaves, 'CurrentPoint');
currPt = currPt(1, 1:2);  % Coordinates of mouse pointer
lh = handles.templateLine;
xData = get(lh, 'XData');
yData = get(lh, 'YData');
xData(2) = currPt(1);
yData(2) = currPt(2);
set(lh, 'XData', xData);
set(lh, 'YData', yData);
drawnow;  % Needed to update the display frequently



function endTemplate(hObject, eventdata)
% This is triggered when user is drawing the template selection line and
% releases the mouse button. At that point, we need to restore the original
% motion functions etc and actually generate the template.
handles = guidata(hObject);
set(gcbf, 'Pointer', 'arrow');
% Restore figure properties
set(gcbf, 'WindowButtonMotionFcn', handles.origWindowButtonMotionFcn);
set(gcbf, 'WindowButtonUpFcn', handles.origWindowButtonUpFcn);
lh = handles.templateLine;
handles.templateLine = [];
xData = get(lh, 'XData');
yData = get(lh, 'YData');
delete(lh);
guidata(hObject, handles);
% Create the template
newTemplate(handles, [xData(1) yData(1)], [xData(2) yData(2)]);



function jumpToEpoch(hObject, eventdata)
% Callback for the colored rectangles on the timeline. Clicking them makes
% the time jump to the start of the epoch.
handles = guidata(hObject);
pos = get(hObject, 'Position');
start = pos(1);
for sortEpoch = 1:length(handles.sorts)
  if handles.sorts(sortEpoch).epochStart == start
    set(handles.sldTime, 'Value', start);
    sldTime_Callback(handles.sldTime, [], handles);  % saves handles inside, no need to call guidata directly
    break;
  end
end



  
%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SORTING FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------

function units = sortWaveforms(handles, waveforms, varargin)
% This is the master waveform-sorting function. It is a wrapper for the
% actual sorting engine, sortWaveformsEngine.
%
% waveforms should be a matrix of waveforms, nPts x nWaveforms
%
% Optional argument is a vector of indices for these waves. This is needed
% to make sorting selected waveforms work with epochs, since we need to
% know which epoch each spike is in. Kind of a hack, but if you're not
% sorting all the waveforms, use this.
%
% units is a vector nWaveforms long of which unit each waveform belongs to.

method = handles.sortMethods{handles.sortMethod};

if isempty(varargin)
  units = sortWaveformsEngine(method, waveforms, handles.PCAPts, handles.sorts);
else
  units = sortWaveformsEngine(method, waveforms, handles.PCAPts, handles.sorts, varargin{1});
end



function sortNewHoop(h)
% When a new hoop is put down, just re-sort and display everything. This
% could probably be optimized.
handles = guidata(h);
displayWaveforms(handles);



function sortNewEllipse(h)
% When a new ellipse is put down, just re-sort and display everything. This
% could probably be optimized.
handles = guidata(h);
displayWaveforms(handles);



function handles = recalculateAutocorrs(handles)
% Calculate autocorrelations. Must be fully sorted.
if handles.sortInfo.fullySorted
  consecutiveUnits = handles.waveforms.units;
else
  error('Cannot calculate autocorrs without sorting first');
end

uniqueUnits = unique(consecutiveUnits);
uniqueUnits = uniqueUnits(uniqueUnits ~= 0 & uniqueUnits <= handles.maxUnits);
for u = uniqueUnits
  % Safety check for invalid lockout
  if handles.sortInfo.autocorrs(u).lockout == 0
    handles.sortInfo.autocorrs(u).lockout = 1e-8;
  end
  
  spikeTimes = handles.waveforms.spikeTimes(consecutiveUnits == u);
  %   autocorr = autocorrSpikesOneMS(spikeTimes, 10, handles.sortInfo.autocorrs(u).lockout);
  autocorr = ISIOneMS(spikeTimes, 10, handles.sortInfo.autocorrs(u).lockout);
  handles.sortInfo.autocorrs(u) = autocorr;
end



function doesIntersect = linIntersect(a1, a2, b1, b2)
% Checks whether two line segments cross.
% Found this formula online, it seems to work nicely and it's fast.
% a1 and a2 are the [x, y] endpoints of the first line segment,
% b1 and b2 are the endpoints for the second line segment
doesIntersect = ...
  (det([1,1,1; a1(1),a2(1),b1(1); a1(2),a2(2),b1(2)]) * det([1,1,1; a1(1),a2(1),b2(1); a1(2),a2(2),b2(2)]) <= 0) && ...
  (det([1,1,1; a1(1),b1(1),b2(1); a1(2),b1(2),b2(2)]) * det([1,1,1; a2(1),b1(1),b2(1); a2(2),b1(2),b2(2)]) <= 0);



function newTemplate(handles, p1, p2)
% Logic to generate a template once the line is drawn.
% p1 and p2 are the [x, y] coordinates of the two ends of the line drawn.

waves = handles.wavesShown;
startPt = str2double(get(handles.txtStartWaveTime, 'String'));
endPt = str2double(get(handles.txtEndWaveTime, 'String'));
% Only test line segments for the right time period.
minX = floor(min(p1(1), p2(1)));
maxX = ceil(max(p1(1), p2(1)));

% If we somehow ended up off the waveform, abort
if minX < startPt || maxX > endPt
  return;
end

crossed = zeros(1, size(waves, 2));
% Check each wave
for w = 1:size(waves, 2)
  % Check each plausible segment
  for x = minX:maxX-1
    if linIntersect(p1, p2, [x waves(x-startPt+1, w)], [x+1 waves(x-startPt+2, w)])
      crossed(w) = 1;
      break;
    end
  end
end
% Crossed is whether each waveform was crossed by the drawn line
crossed = logical(crossed);

active = handles.activeUnit;

% If no waveforms selected, ignore this attempt at defining a template
if sum(crossed) ~= 0
  % Calculate the template mean, StdDev, etc.
  epochs = epochsToAffect(handles);
  for epoch = epochs
    handles.sorts(epoch).Template.params(active+1).inTemplate.means = mean(waves(:, crossed), 2);
    handles.sorts(epoch).Template.params(active+1).inTemplate.stds = std(waves(:, crossed), 0, 2);
    handles.sorts(epoch).Template.params(active+1).outTemplate.means = mean(waves(:, ~crossed), 2);
    handles.sorts(epoch).Template.params(active+1).outTemplate.stds = std(waves(:, ~crossed), 0, 2);
    handles.sorts(epoch).Template.params(active+1).templateStart = startPt;
    handles.sorts(epoch).Template.params(active+1).templateEnd = str2double(get(handles.txtEndWaveTime, 'String'));
    % If we're defining a template on a differentiated waveform, the end is
    % actually shorter than the waveform window by one
    if get(handles.chkDifferentiate, 'Value')
      handles.sorts(epoch).Template.params(active+1).templateEnd = handles.sorts(epoch).Template.params(active+1).templateEnd - 1;
    end
    
    handles.sorts(epoch).Template.params(active+1).acceptance = get(handles.sldAcceptHs(active+1), 'Value');
    
    handles.sorts(epoch).Template.unitsDefined = unique([handles.sorts(epoch).Template.unitsDefined handles.activeUnit]);
  end
  
  displayWaveforms(handles);
end





%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OTHER FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------



function handles = regenPCASpace(handles)
% Run PCA on waveforms.
if ~handles.sorts(1).PCAEllipses.differentiated
 [coeffs, scores] = ...
   princomp_mksort(zscore_mksort(handles.waveforms.alignedWaves'));
else
  [coeffs, scores] = ...
    princomp_mksort(zscore_mksort(diff(handles.waveforms.alignedWaves)'));
end
for epoch = 1:length(handles.sorts)
  handles.sorts(epoch).PCAEllipses.PCACoeffs = coeffs(:, 1:handles.maxPCADims)';
end
handles.PCAPts = scores(:, 1:handles.nPCADims)';
handles.PCAShown = [];



function handles = regenPCAPts(handles)
% Use existing PCA coeffs to regenerate the PCA scores.
if isempty(handles.sorts(1).PCAEllipses.PCACoeffs)
  handles = regenPCASpace(handles);
else
  coeffs = handles.sorts(1).PCAEllipses.PCACoeffs(1:handles.nPCADims, :);
  if ~handles.sorts(1).PCAEllipses.differentiated
    handles.PCAPts = ...
      coeffs * zscore_mksort(handles.waveforms.alignedWaves, 2);
  else
    handles.PCAPts = ...
      coeffs * zscore_mksort(diff(handles.waveforms.alignedWaves), 2);
  end
  handles.PCAShown = [];
end



function alignedWaves = alignWaveforms(handles, waves)
% Call waveform alignment function
alignMethod = handles.alignMethods{get(handles.cmbAlignMethod, 'Value')};
alignedWaves = feval(alignMethod.alignFcn, waves);



function handles = loadWaveformFile(handles, arg)
% arg is the structure passed by mksort.

handles.path = arg.path;
if isfield(arg, 'preview')
  handles.preview = arg.preview;
  handles.fastSave = 0;
else
  handles.fastSave = 1;
end
handles.sortInfo = arg.sorts;
handles.array = arg.array;
handles.thisChannel = arg.thisChannel;

alpha = alphabet();
if isnan(handles.sortInfo.array)
  lett = '';
else
  lett = alpha(handles.sortInfo.array);
end
filename = makeWaveFilename(lett, handles.sortInfo.electrode);

try
  loadVar = load(fullfile(handles.path, filename));
catch
  uiwait(msgbox(sprintf('Failed to load file: %s', fullfile(handles.path, filename)), 'Load failed', 'modal'));
  error('loadWaveformFile:unreadableWaveforms', 'Could not load waveforms file');
end

checkWaveformsStruct(loadVar.waveforms);

handles.waveforms = loadVar.waveforms;

clear loadVar



function epoch = getCurrentEpoch(handles)
% Figure out which epoch we're looking at.
currTime = get(handles.sldTime, 'Value');
for ep = 1:length(handles.sorts)
  if currTime < handles.sorts(ep).epochEnd
    epoch = ep;
    return;
  end
end



function handles = newEpoch(handles, epochStart)
% Generate a new epoch
%
% Note that we will never be creating a new first epoch, but could be
% middle or last

activateAxes(gcbf, handles.axTimeline);

% Figure out what the new epoch's cardinal position will be
epochStarts = [handles.sorts.epochStart];

newNum = find(epochStarts > epochStart, 1);
if isempty(newNum)
  newNum = length(handles.sorts) + 1;
end

epochEnd = handles.sorts(newNum - 1).epochEnd;


% Build new epoch
newEpoch = handles.sorts(newNum - 1);
newEpoch.epochStart = epochStart;
newEpoch.epochEnd = epochEnd;

% Truncate the previous epoch
handles.sorts(newNum - 1).epochEnd = epochStart - 1;

% Stitch before, new, and after together
handles.sorts = [handles.sorts(1:newNum-1) newEpoch handles.sorts(newNum:end)];


% Modify old rectangle, mint a new rectangle on the timeline
pos = get(handles.sortEpochRectHs(newNum-1), 'Position');
pos(3) = epochStart - 1 - pos(1);
set(handles.sortEpochRectHs(newNum-1), 'Position', pos);
hr = rectangle('Position', [epochStart 0 epochEnd-epochStart 1]);
handles.sortEpochRectHs = [handles.sortEpochRectHs(1:newNum-1) hr handles.sortEpochRectHs(newNum:end)];
set(hr, 'ButtonDownFcn', @jumpToEpoch);

% Re-color all the rectangles on the timeline
colorEpochRects(handles);

handles = markSortChanged(handles);

handles.activeEpoch = newNum;
uistack(handles.sortEpochTickH, 'top');



function epochs = epochsToAffect(handles)
% Returns either the active epoch index or a vector of all the epochs
% depending on whether 'Modify current epoch only' is checked.
if get(handles.chkChangeCurrentEpoch, 'Value')
  epochs = handles.activeEpoch;
else
  epochs = 1:length(handles.sorts);
end


function unitsDefined = allDefinedUnits(handles)
unitsDefined = [];
for ep = 1:length(handles.sorts)
  unitsDefined = [unitsDefined handles.sorts(ep).(handles.sortMethods{handles.sortMethod}.type).unitsDefined];
end
unitsDefined = unique(unitsDefined);



function closeIfSaved(hObject, eventdata)
handles = guidata(hObject);
if handles.saved
  delete(hObject);
else
  selection = questdlg('Discard sorts without saving?', 'Close', 'Save', 'Don''t save', 'Cancel', 'Save');
  switch selection
    case 'Save'
      btnSave_Callback(handles.btnSave, [], handles);
      delete(hObject);
    case 'Don''t save'
      delete(hObject);
    case 'Cancel'
      return;
  end
end
