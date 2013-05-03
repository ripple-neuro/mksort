function varargout = dataImportWizard(varargin)
% DATAIMPORTWIZARD M-file for dataImportWizard.fig
%      DATAIMPORTWIZARD, by itself, creates a new DATAIMPORTWIZARD or raises the existing
%      singleton*.
%
%      H = DATAIMPORTWIZARD returns the handle to a new DATAIMPORTWIZARD or the handle to
%      the existing singleton*.
%
%      DATAIMPORTWIZARD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATAIMPORTWIZARD.M with the given input arguments.
%
%      DATAIMPORTWIZARD('Property','Value',...) creates a new DATAIMPORTWIZARD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dataImportWizard_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dataImportWizard_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
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

% Last Modified by GUIDE v2.5 09-Jan-2012 20:34:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dataImportWizard_OpeningFcn, ...
                   'gui_OutputFcn',  @dataImportWizard_OutputFcn, ...
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


%#function nev2MatWaveforms
%#function nsx2MatWaveforms


% --- Executes just before dataImportWizard is made visible.
function dataImportWizard_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dataImportWizard (see VARARGIN)

% Choose default command line output for dataImportWizard
handles.output = hObject;

if length(varargin) ~= 1
  uiwait(msgbox('Error: dataImportWizard is not a standalone application', 'No direct calls', 'error'));
  error('dataImportWizard:noDirectCalls', 'Use mksort extract data');
end

handles.defaultDataDir = varargin{1}.defaultDataDir;
handles.gentleExternFcnFail = varargin{1}.gentleExternFcnFail;

handles.dataExtractionFcns = [];


%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% INITIALIZE APPLICATION VARIABLES
%--------------------------------------------------------------------------

% This isn't really readily customizable, it just gets info together in the
% same place. To make it readily customizable, one would have to have some
% way of adding options panels to the wizard, and one would have to rigidly
% fix the argument order of the back-end functions. This seems too
% inflexible, so I didn't do it.

% Data extraction functions
dataExtractionFcn = [];

dataExtractionFcn.ext = 'nev';
dataExtractionFcn.fcn = 'nev2MatWaveforms';
dataExtractionFcn.extraArgs = {}; %{'File numbers (Matlab syntax, e.g., [2 4], leave empty for all)'; 'File letters (Matlab syntax, e.g., ''AB'', leave empty for all or if not applicable)'};
handles.dataExtractionFcns{end+1} = dataExtractionFcn;

dataExtractionFcn.ext = 'nsx';
dataExtractionFcn.fcn = 'nsx2MatWaveforms';
dataExtractionFcn.extraArgs = {}; %{'File numbers (Matlab syntax, e.g., [2 4], leave empty for all)'; 'File letters (Matlab syntax, e.g., ''AB'', leave empty for all or if not applicable)'};
handles.dataExtractionFcns{end+1} = dataExtractionFcn;


% Default data extraction function
defaultDataExtractionFcn = 'nev2MatWaveforms';


% Filter options for raw data extraction
filters = {'HP 100 Hz', 'HP 250 Hz', 'HP 750 Hz', ...
  '"Spike Narrow" Cerebus v.4 or lower', ...
  '"Spike Medium" Cerebus v.4 or lower', ...
  '"Spike Wide" Cerebus v.4 or lower'};


%--------------------------------------------------------------------------
% END OF (STRAIGHTFORWARD) CUSTOMIZABLE VARIABLES
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------


DEFs = cellfun(@(x) x.fcn, handles.dataExtractionFcns, 'UniformOutput', false);
handles.dataExtractionFcn = find(strcmp(DEFs, defaultDataExtractionFcn));

% Populate cmbFileType
exts = cellfun(@(x) x.ext, handles.dataExtractionFcns, 'UniformOutput', false);
set(handles.cmbFileType, 'String', exts);
set(handles.cmbFileType, 'Value', handles.dataExtractionFcn);

setStringsByExtractFcn(handles, 'nev');


% Set internal mode variable so we know we're at the 'opening' stage
handles.mode = 'opening';
handles.method = '';


% handles.defaultDataDir = '/data';

handles.inDirectory = '';
handles.outDirectory = '';

% Prep variables for individual selection panel
handles.allFileNames = {};
handles.filenames = cell(0, 1);   % This will be length nArrays
handles.nArrays = 1;
handles.whichArray = 1;           % Which array the user is selecting files for

handles.arrayRdbs = handles.rdbArray1;
handles.arraySelLbls = handles.lblSelected1;

set(handles.pnlArray, 'SelectionChangeFcn', @pnlArraySelChangeFcn);

% Prep optionsNev values
handles.firstSnipPt = str2double(get(handles.txtFirstPt, 'String'));
handles.finalSnipPt = str2double(get(handles.txtLastPt, 'String'));
handles.rejectArtifacts = get(handles.chkRejectArtifacts, 'Value');
handles.artifactSize = str2double(get(handles.txtArtifactSize, 'String'));
handles.conserveMem = get(handles.chkConserveMem, 'Value');

% Prep optionsNsx values
handles.preThresh = str2double(get(handles.txtPreThresh, 'String'));
handles.postThresh = str2double(get(handles.txtPostThresh, 'String'));
handles.threshRMS = str2double(get(handles.txtRMS, 'String'));
set(handles.txtArtifactSize, 'String', get(handles.txtArtifactSize, 'String'));
set(handles.chkRejectArtifactsNsx, 'Value', handles.rejectArtifacts);
set(handles.cmbFilterNsx, 'String', filters);

% Prep n-trode .ccf list
handles.ccfNames = {};

set(hObject, 'WindowStyle', 'modal');


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes dataImportWizard wait for user response (see UIRESUME)
% uiwait(handles.figDataImportWizard);


% --- Outputs from this function are returned to the command line.
function varargout = dataImportWizard_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function txtMultiDirectory_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtNArraysMulti_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lstMultiFiles_CreateFcn(hObject, eventdata, handles)
% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtDirectory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtFirstPt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtLastPt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtArtifactSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cmbFileType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtPreThresh_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtPostThresh_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtRMS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cmbFilterNsx_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtArtifactSizeNsx_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtCCFNev_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txtCCFNsx_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







function btnCancel_Callback(hObject, eventdata, handles)

handles.output = [];
guidata(hObject, handles);
delete(handles.figDataImportWizard);


function btnNext_Callback(hObject, eventdata, handles)

switch handles.mode
  case 'opening'
    % We're in the 'opening' mode, user has just selected a data selection
    % spec
    
    % Hide this panel
    set(handles.pnlSelectDataScheme, 'Visible', 'off');
    
    % Set mode, enable the correct panel
    if get(handles.rdbDatafile, 'Value')
      % Use 'datafile001' or 'datafileA001' spec
      handles.method = 'datafile';
      set(handles.pnlDirectory, 'Visible', 'on');
    elseif get(handles.rdbAlpha, 'Value')
      % Use alphabetical spec
      handles.method = 'alpha';
      set(handles.pnlDirectory, 'Visible', 'on');
    elseif get(handles.rdbMulti, 'Value')
      % Use individual file selection spec
      handles.method = 'multi';
      % Set up message with correct datafile type
      arch = computer;
      if length(arch) >= 4 && strcmp(arch(1:4), 'MACI')
        key = 'Cmd';
      else
        key = 'Ctrl';
      end
      
      set(handles.lblFilesMulti, 'String', sprintf('Hold %s to select multiple files', key));
      set(handles.pnlMulti, 'Visible', 'on');
    end
    
    handles.mode = 'select';
    
    % Disable the Next button until the user selects a directory
    set(handles.btnNext, 'Enable', 'off');
    
    guidata(hObject, handles);
    
    
  case 'select'
    % We're in the 'select' mode, user has just selected input files
    
    % Enable the correct panel, change message
    set(handles.pnlMulti, 'Visible', 'off');
    set(handles.lblSelectDirectory, 'String', 'Select output directory');
    set(handles.txtDirectory, 'String', '');
    set(handles.pnlDirectory, 'Visible', 'on');
    
    handles.mode = 'output';
    
    % Disable the Next button until the user selects a directory
    set(handles.btnNext, 'Enable', 'off');
    
    guidata(hObject, handles);
    

    
  case 'output'
    % We're in the 'output' mode, user has just selected a directory to
    % save the output files
    set(handles.pnlDirectory, 'Visible', 'off');
    set(handles.pnlMulti, 'Visible', 'off');
    
    handles.mode = 'options';

    % Need to figure out which set of options to display based on which
    % extraction function is selected
    DEF = handles.dataExtractionFcns{handles.dataExtractionFcn};
    switch DEF.fcn
      case 'nev2MatWaveforms'
        set(handles.pnlOptionsNev, 'Visible', 'on');
      case 'nsx2MatWaveforms'
        set(handles.pnlOptionsNsx, 'Visible', 'on');
    end

    set(handles.btnNext, 'String', 'Import');
    
    guidata(hObject, handles);
    
    
    
  case 'options'
    % We're ready to do the real work, so call the worker function and
    % display the wait message
    set(handles.pnlOptionsNev, 'Visible', 'off');
    set(handles.pnlOptionsNsx, 'Visible', 'off');
    set(handles.pnlWait, 'Visible', 'on');
    set(gcbf, 'Pointer', 'watch');
    set(handles.btnNext, 'Enable', 'off');
    set(handles.btnCancel, 'Enable', 'off');
    drawnow;
    
    % Import!
    processFiles(handles);
    
    % Clean up interface, display 'finished' message
    set(handles.btnNext, 'String', 'Close');
    set(handles.btnNext, 'Enable', 'on');
    handles.mode = 'done';
    set(gcbf, 'Pointer', 'arrow');
    set(handles.lblWait, 'String', 'Import complete.');
    
    guidata(hObject, handles);

    
    
  case 'done'
    % All is finished, close
    delete(handles.figDataImportWizard);
end



function txtDirectory_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtDirectory as text
%        str2double(get(hObject,'String')) returns contents of txtDirectory as a double
str = get(hObject, 'String');

switch handles.mode
  % If we're in 'select' mode, user is selecting an input directory
  case 'select'
    handles.inDirectory = str;
    guidata(hObject, handles);
    
    % Need to ensure there are relevant files in the directory
    if exist(str, 'dir')
      ext = handles.dataExtractionFcns{handles.dataExtractionFcn}.ext;
      fNames = filterOnExt(str, ext);
      if ~isempty(fNames)
        set(handles.btnNext, 'Enable', 'on');
        return;
      end
    end
    
    set(handles.btnNext, 'Enable', 'off');
    
  case 'output'
    % If we're in 'output' mode, user is selecting a save directory
    handles.outDirectory = str;
    guidata(hObject, handles);
    set(handles.btnNext, 'Enable', 'on');
end



function btnDirectoryBrowse_Callback(hObject, eventdata, handles)

switch handles.mode
  case 'select'
    message = 'Folder containing data files:';
    defaultDir = handles.defaultDataDir;
  case 'output'
    message = 'Folder to save output:';
    defaultDir = handles.inDirectory;
end

try
  theDir = uigetdir(defaultDir, message);
catch
  theDir = uigetdir('.', message);
end
% Handle a click on Cancel
if theDir == 0, return; end;

set(handles.txtDirectory, 'String', theDir);
txtDirectory_Callback(handles.txtDirectory, eventdata, handles);



function txtMultiDirectory_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtMultiDirectory as text
%        str2double(get(hObject,'String')) returns contents of txtMultiDirectory as a double
str = get(hObject, 'String');
ext = handles.dataExtractionFcns{handles.dataExtractionFcn}.ext;

handles.inDirectory = str;

set(handles.btnNext, 'Enable', 'off');

if exist(str, 'dir')
  fNames = filterOnExt(str, ext);
  
  handles.allFileNames = fNames;
  
  set(handles.lstMultiFiles, 'String', fNames);
  set(handles.lstMultiFiles, 'Value', 1);
  
  if ~isempty(fNames)
    set(handles.btnNext, 'Enable', 'on');
  else
    set(handles.btnNext, 'Enable', 'off');
  end
end

% Reset everything
handles.filenames = cell(1, 0);
handles.whichArray = 1;
set(handles.txtNArraysMulti, 'String', '1');
guidata(hObject, handles);

% Update controls
lstMultiFiles_Callback(handles.lstMultiFiles, [], handles);

handles = guidata(hObject);

% Update multiple array handling (only really needed if this is the second
% time a directory is being loaded)
txtNArraysMulti_Callback(handles.txtNArraysMulti, [], handles);



function btnMultiBrowse_Callback(hObject, eventdata, handles)

try
  inDir = uigetdir(handles.defaultDataDir, 'Folder containing data files:');
catch
  inDir = uigetdir('.', 'Folder containing data files:');
end
% Handle a click on Cancel
if inDir == 0, return; end;

set(handles.txtMultiDirectory, 'String', inDir);
txtMultiDirectory_Callback(handles.txtMultiDirectory, eventdata, handles);



function lstMultiFiles_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lstMultiFiles contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstMultiFiles
contents = get(hObject,'String');
values = get(hObject, 'Value');
sel = contents(values)';

handles.filenames{handles.whichArray} = sel;
set(handles.arraySelLbls(handles.whichArray), 'String', num2str(length(sel)));

guidata(hObject, handles);



function txtNArraysMulti_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txtNArraysMulti as text
%        str2double(get(hObject,'String')) returns contents of txtNArraysMulti as a double
prevNArrays = handles.nArrays;

% Check that we got a number
nArrays = str2double(get(hObject, 'String'));
if isnan(nArrays)
  set(hObject, 'String', num2str(handles.nArrays));
  return;
end

% Maintain a number of arrays between 1 and 9
if nArrays < 1
  nArrays = 1;
  set(hObject, 'String', num2str(nArrays));
elseif nArrays > 9
  nArrays = 9;
  set(hObject, 'String', num2str(nArrays));
end

handles.nArrays = nArrays;

if nArrays > 1
  set(handles.pnlArray, 'Visible', 'on');
else
  set(handles.pnlArray, 'Visible', 'off');
end

% Add or delete from the cell array of selected files
nDiff = nArrays - prevNArrays;
if nDiff > 0
  for a = prevNArrays+1:nArrays
    handles.filenames{a} = {};
  end
elseif nDiff < 0
  handles.filenames = handles.filenames(1:nArrays, :);
end

% Manage array selection radio buttons and file selected counters
if nDiff > 0
  % Adding arrays
  lastPosRdb = get(handles.arrayRdbs(prevNArrays), 'Position');
  lastPosLbl = get(handles.arraySelLbls(prevNArrays), 'Position');
  
  for i = prevNArrays+1:nArrays
    lastPosRdb(2) = lastPosRdb(2) - 1.5;
    lastPosLbl(2) = lastPosLbl(2) - 1.5;
    
    handles.arrayRdbs(i) = uicontrol('Style', 'Radio', 'String', ['Array ' num2str(i)], ...
      'Units', 'characters', 'Position', lastPosRdb, 'parent', handles.pnlArray);
    handles.arraySelLbls(i) = uicontrol('Style', 'text', 'String', '0', ...
      'Units', 'characters', 'Position', lastPosLbl, 'parent', handles.pnlArray);
  end
  
elseif nDiff < 0
  % Removing arrays
  for i = prevNArrays:-1:nArrays+1
    delete(handles.arrayRdbs(i));
    delete(handles.arraySelLbls(i));
  end
  
  handles.arrayRdbs = handles.arrayRdbs(1:nArrays);
  handles.arraySelLbls = handles.arraySelLbls(1:nArrays);
  
  % Select the first array, to be safe
  set(handles.rdbArray1, 'Value', 1);
  eventdata = [];
  eventdata.NewValue = handles.rdbArray1;
  guidata(hObject, handles);

  pnlArraySelChangeFcn(handles.pnlArray, eventdata);
  handles = guidata(hObject);
end

guidata(hObject, handles);



function btnNArraysMultiPlus_Callback(hObject, eventdata, handles)
set(handles.txtNArraysMulti, 'String', num2str(handles.nArrays + 1));
txtNArraysMulti_Callback(handles.txtNArraysMulti, [], handles);


function btnNArraysMultiMinus_Callback(hObject, eventdata, handles)
if handles.nArrays > 1
  set(handles.txtNArraysMulti, 'String', num2str(handles.nArrays - 1));
end
txtNArraysMulti_Callback(handles.txtNArraysMulti, [], handles);



function pnlArraySelChangeFcn(hObject, eventdata)
% User just changed which array is selected, when on individual file
% selection mode
handles = guidata(hObject);

handles.whichArray = find(handles.arrayRdbs == eventdata.NewValue, 1);

% Narrow down which filenames should be displayed (remove those taken)
allNames = handles.allFileNames;
allArrays = 1:handles.nArrays;
otherArrays = allArrays(allArrays ~= handles.whichArray);
fNames = handles.filenames;
if ~isempty(otherArrays)
  otherNames = {fNames{otherArrays}};
  useFileNames = allNames(~ismember(allNames, [otherNames{:}]));
else
  useFileNames = allNames;
end

set(handles.lstMultiFiles, 'String', useFileNames);

% If the user has already made selections, implement them. If not, select
% first one
if isempty(fNames{handles.whichArray})
  set(handles.lstMultiFiles, 'Value', 1);
else
  used = find(ismember(useFileNames, fNames{handles.whichArray}));
  set(handles.lstMultiFiles, 'Value', used);
end

% Handles get saved inside
lstMultiFiles_Callback(handles.lstMultiFiles, eventdata, handles)



function txtFirstPt_Callback(hObject, eventdata, handles)
val = floor(str2double(get(hObject, 'String')));
if ~isnan(val) && val >= 1
  handles.firstSnipPt = val;
end
set(hObject, 'String', num2str(handles.firstSnipPt));
guidata(hObject, handles);



function txtLastPt_Callback(hObject, eventdata, handles)
val = floor(str2double(get(hObject, 'String')));
if ~isnan(val) && val >= 1
  handles.finalSnipPt = val;
end
set(hObject, 'String', num2str(handles.finalSnipPt));
guidata(hObject, handles);



function chkConserveMem_Callback(hObject, eventdata, handles)
handles.conserveMem = get(hObject, 'Value');
guidata(hObject, handles);



function chkRejectArtifacts_Callback(hObject, eventdata, handles)
handles.rejectArtifacts = get(hObject, 'Value');
if handles.rejectArtifacts
  set(handles.txtArtifactSize, 'Enable', 'on');
else
  set(handles.txtArtifactSize, 'Enable', 'off');
end
guidata(hObject, handles);



function txtArtifactSize_Callback(hObject, eventdata, handles)
val = str2double(get(hObject, 'String'));
if ~isnan(val)
  handles.artifactSize = val;
end
set(hObject, 'String', num2str(handles.artifactSize));
guidata(hObject, handles);



function cmbFileType_Callback(hObject, eventdata, handles)
% When changing the file type to extract, change the example text, and set
% the internal extract function tracking.

oldExt = handles.dataExtractionFcns{handles.dataExtractionFcn}.ext;
handles.dataExtractionFcn = get(hObject, 'Value');

setStringsByExtractFcn(handles, oldExt);

guidata(hObject, handles);



function txtPostThresh_Callback(hObject, eventdata, handles)
val = str2double(get(hObject, 'String'));
if ~isnan(val) && val >= 1/30
  handles.postThresh = val;
end
set(hObject, 'String', num2str(handles.postThresh));
guidata(hObject, handles);



function txtPreThresh_Callback(hObject, eventdata, handles)
val = str2double(get(hObject, 'String'));
if ~isnan(val) && val >= 0
  handles.preThresh = val;
end
set(hObject, 'String', num2str(handles.preThresh));
guidata(hObject, handles);



function txtRMS_Callback(hObject, eventdata, handles)
val = str2double(get(hObject, 'String'));
if ~isnan(val)
  val = -abs(val);
  handles.threshRMS = val;
end
set(hObject, 'String', num2str(handles.threshRMS));
guidata(hObject, handles);



function chkRejectArtifactsNsx_Callback(hObject, eventdata, handles)
handles.rejectArtifacts = get(hObject, 'Value');
if handles.rejectArtifacts
  set(handles.txtArtifactSizeNsx, 'Enable', 'on');
else
  set(handles.txtArtifactSizeNsx, 'Enable', 'off');
end
guidata(hObject, handles);



function txtArtifactSizeNsx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject, 'String'));
if ~isnan(val)
  handles.artifactSize = val;
end
set(hObject, 'String', num2str(handles.artifactSize));
guidata(hObject, handles);



function cmbFilterNsx_Callback(hObject, eventdata, handles)
% Nothing needs to happen here, the name stores the data we need



function chkNTrodeNev_Callback(hObject, eventdata, handles)
% If the user wants to specify an n-trode configuration file, enable that
% selection, possibly disable the 'next' button

if get(hObject, 'Value')
  [success, ccfNames] = checkForCCFFiles(handles);
  
  set(handles.lblNTrodeNev, 'Enable', 'on');
  
  if success
    set(handles.lblNTrodeNev, 'String', '[Config files found]');
    handles.ccfNames = ccfNames;
  else
    set(handles.lblNTrodeNev, 'String', '[Config files missing]');
    set(hObject, 'Value', false);
    handles.ccfNames = {};
  end
else
  handles.ccfNames = {};
end

guidata(hObject, handles);



function chkNTrodeNsx_Callback(hObject, eventdata, handles)
% If the user wants to specify an n-trode configuration file, enable that
% selection, possibly disable the 'next' button

if get(hObject, 'Value')
  [success, ccfNames] = checkForCCFFiles(handles);
  
  set(handles.lblNTrodeNsx, 'Enable', 'on');
  
  if success
    set(handles.lblNTrodeNsx, 'String', '[Config files found]');
    handles.ccfNames = ccfNames;
  else
    set(handles.lblNTrodeNsx, 'String', '[Config files missing]');
    set(hObject, 'Value', false);
    handles.ccfNames = {};
  end
else
  handles.ccfNames = {};
end

guidata(hObject, handles);





%%

function processFiles(handles)

filenames = getDatafileFilenames(handles);

% Prepare additional options for extract
snippetLen = handles.finalSnipPt - handles.firstSnipPt + 1;
if handles.rejectArtifacts
  artifactThresh = handles.artifactSize;
else
  artifactThresh = Inf;
end

fcn = handles.dataExtractionFcns{handles.dataExtractionFcn}.fcn;

% If using n-trodes, process them
if handles.gentleExternFcnFail
  try
    nTrodes = CCFFilenamesToNTrodeStructs(handles.inDirectory, handles.ccfNames);
  catch err
    uiwait(msgbox(sprintf('Import failed. Error was: %s : %s', err.identifier, err.message)));
  end
else
  nTrodes = CCFFilenamesToNTrodeStructs(handles.inDirectory, handles.ccfNames);
end

% Process main data files
switch fcn
  case 'nev2MatWaveforms'
    if handles.gentleExternFcnFail
      try
        nev2MatWaveforms(handles.inDirectory, handles.outDirectory, filenames, artifactThresh, snippetLen, handles.firstSnipPt, handles.conserveMem);
      catch err
        uiwait(msgbox(sprintf('Import failed. Error was: %s : %s', err.identifier, err.message)));
      end
    else
      nev2MatWaveforms(handles.inDirectory, handles.outDirectory, filenames, artifactThresh, snippetLen, handles.firstSnipPt, handles.conserveMem);
    end
    
    if ~isempty(nTrodes)
      fprintf('Processing n-trodes\n');
      if handles.gentleExternFcnFail
        try
          combineWaveformsForNTrodes(handles.outDirectory, nTrodes);
        catch err
          uiwait(msgbox(sprintf('Import failed. Error was: %s : %s', err.identifier, err.message)));
        end
      else
        combineWaveformsForNTrodes(handles.outDirectory, nTrodes);
      end
    end
    
  case 'nsx2MatWaveforms'
    filterNames = get(handles.cmbFilterNsx, 'String');
    filterName = filterNames{get(handles.cmbFilterNsx, 'Value')};
    snippetLenTime = handles.preThresh + handles.postThresh;
    if handles.gentleExternFcnFail
      try
        nsx2MatWaveforms(handles.inDirectory, handles.outDirectory, filenames, handles.threshRMS, filterName, snippetLenTime, handles.preThresh, artifactThresh, nTrodes);
      catch err
        uiwait(msgbox(sprintf('Import failed. Error was: %s : %s', err.identifier, err.message)));
      end
    else
      nsx2MatWaveforms(handles.inDirectory, handles.outDirectory, filenames, handles.threshRMS, filterName, snippetLenTime, handles.preThresh, artifactThresh, nTrodes);
    end
end



function names = filterOnExt(thePath, ext)
if strcmp(ext, 'nsx')
  d = dir(fullfile(thePath, '*.ns*'));
  d = d(arrayfun(@(x) ~isnan(str2double(x.name(end))), d));
else
  d = dir(fullfile(thePath, ['*.' ext]));
end

d = d(~[d.isdir]);
names = {d.name};



function filenames = getDatafileNamedFileNames(directory, ext)

% Get names in this folder starting with 'datafile' and with the right
% extension
if strcmp(ext, 'nsx')
  folder = dir(fullfile(directory, 'datafile*.ns*'));
  folder = folder(arrayfun(@(x) ~isnan(str2double(x.name(end))), folder));
else
  folder = dir(fullfile(directory, ['datafile*.' ext]));
end

nameTemplate = ['datafile.' ext];

fNames = {};
% Take the filename if it's not a directory, and is
% datafile###.{ext} or datafileL###.{ext}
for f = 1:length(folder)
  if ~folder(f).isdir
    name = folder(f).name;
    if length(name) == length(nameTemplate) + 3 && ~isnan(str2double(name(9:11))) || ...
        length(name) == length(nameTemplate) + 4 && isletter(name(9)) && ~isnan(str2double(name(10:12)))
      fNames{end+1} = name; %#ok<AGROW>
    end
  end
end

% Find the letter for each array
letters = cell(1, length(fNames));
for n = 1:length(fNames)
  letters{n} = getLetterAndNumber(fNames{n});
end
uniqueLetters = unique(letters);

% Cycle through arrays, collecting filenames
filenames = cell(1, length(uniqueLetters));
for lett = 1:length(uniqueLetters)
  thisArray = cellfun(@(x) strcmp(x, uniqueLetters{lett}), letters);
  filenames{lett} = fNames(thisArray);
end



function filenames = getAllFileNames(directory, ext)
filenames{1} = filterOnExt(directory, ext);



function [lett, num] = getLetterAndNumber(fn)
% Figure out letters and numbers from a datafile named datafile###.{ext} or
% datafileL###.{ext}. If no letter, lett is ''
if isletter(fn(9))
  % Letters are optional
  lett = fn(9);
  num = str2double(fn(10:12));
else
  lett = '';
  num = str2double(fn(9:11));
end


function setStringsByExtractFcn(handles, oldExt)
% Change the example text (e.g., 'datafile001.nev').
% repWhat is the old value, new value will be whatever file extension is
% selected now.

DEF = handles.dataExtractionFcns{handles.dataExtractionFcn};
ext = DEF.ext;

labels = {'lblDatafile', 'lblAlphabetical'};

for lbl = 1:length(labels)
  oldStr = get(handles.(labels{lbl}), 'String');
  newStr = regexprep(oldStr, oldExt, ext);
  set(handles.(labels{lbl}), 'String', newStr);
end



function [success, ccfNames] = checkForCCFFiles(handles)
% Check for a .ccf file corresponding to each "main" data file (.nev or
% .nsx), return whether files were found and their names (no path)

filenames = getDatafileFilenames(handles);

ccfNames = cell(size(filenames));

for array = 1:length(filenames)
  [~, nameStem] = fileparts(filenames{array}{1});
  
  ccfName = fullfile(handles.inDirectory, [nameStem '.ccf']);
  
  ccfNames{array} = [nameStem '.ccf'];
  
  if ~exist(ccfName, 'file')
    uiwait(msgbox(sprintf('The first "main" data file for each Cerebus must have a corresponding configuration file (.ccf) in the same directory, to identify n-trodes. Could not find file: %s', [nameStem '.ccf']), 'Missing .ccf', 'warn'));
    success = false;
    return;
  end
end

success = true;



function [filenames, ext] = getDatafileFilenames(handles)
% Return the names of the datafiles to be used (no path)

ext = handles.dataExtractionFcns{handles.dataExtractionFcn}.ext;

switch handles.method
  case 'datafile'
    filenames = getDatafileNamedFileNames(handles.inDirectory, ext);
    
  case 'alpha'
    filenames = getAllFileNames(handles.inDirectory, ext);
    
  case 'multi'
    filenames = handles.filenames;
    % Already have filenames
    
  otherwise
    error('getDatafileFilenames:unknownMode', 'Unknown file processing mode: %s', handles.method);
end
