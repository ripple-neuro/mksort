function trialInfoFromR(waveDataDir)
% trialInfoFromR(waveDataDir)
%
% For use with "Add trial/condition info". 
%
% This system should probably be broken up into a wrapper and smaller
% user-defined components. Currently, this function is responsible for
% asking the user what function they want to use for parsing their data
% structure (in this case, a data structure called an "R" structure), then
% calls that function to get data out of the structure, loops through the
% waveforms files to add that data, and re-saves the waveforms files.
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

%% Have user specify R struct
[RFile, RPath] = uigetfile(waveDataDir, 'Select R structure');
if RFile == 0, return; end;   % Handle cancel

%% Have user specify function to determine conditions for this R struct
while 1
  answer = inputdlg('Specify function to determine condition identities from R structure', 'Select condition-determining function', 1);
  if isempty(answer), return; end;   % Handle cancel
  condFcn = answer{1};
  existence = which(condFcn);
  if isempty(existence)
    uiwait(msgbox(sprintf('Function %s cannot be found. Please add it to your path or specify a different function', condFcn), 'Function not found'));
  else
    break;
  end
end

%% Load R struct
fprintf('Loading R struct...\n');
loadVar = load(fullfile(RPath, RFile));
R = loadVar.R;
clear loadVar


%% Figure out what's in the directory

% Get waveform file names in this folder
folder = dir(waveDataDir);
waveFilenames = {};
for f = 1:length(folder)
  if length(folder(f).name) > 10
    if strcmp(folder(f).name(1:10), 'waveforms_')
      waveFilenames{end+1} = folder(f).name; %#ok<AGROW>
    end
  end
end


%% Initialize cell arrays for the data returned by the user-defined function

conditions = {};
trStarts = {};
trEnds = {};


%% Loop through waveforms files
fprintf('File (of %d):', length(waveFilenames));

for w = 1:length(waveFilenames)
  
  %% Load waveforms file
  fprintf(' %d', w); if ~mod(w, 20), fprintf('\n'); end;
  
  loadVar = load(fullfile(waveDataDir, waveFilenames{w}));
  waveforms = loadVar.waveforms;
  
  
  
  %% If we haven't yet gotten info for this array, call user-defined function to get it
  % Call an external, user-specified function to figure out which condition
  % each trial corresponds to, and what portion of the trial we should care
  % about
  array = waveforms.array;
  if isnan(array)
    array = 1;
  end
  if length(conditions) < array || isempty(conditions{array})
    [conditions{array}, trStarts{array}, trEnds{array}] = feval(condFcn, R, waveforms.array); %#ok<AGROW>
  end

  
  
  %% Initialize fields to add
  waveforms.trialInfo.trial = NaN * zeros(1, length(waveforms.spikeTimes));
  waveforms.trialInfo.condition = conditions{array};
  waveforms.trialInfo.trialStartTimes = trStarts{array};
  waveforms.trialInfo.trialEndTimes = trEnds{array};
  
  
  %% For each trial, figure out which spikes were members.
  % Leave NaNs when the spike is outside the desired portion of any trial
  spike = 1;
  lastRealTrEnd = -Inf;
  times = waveforms.spikeTimes;
  nSpikes = length(times);
  for tr = 1:length(R)
    trStart = trStarts{array}(tr);
    trEnd = trEnds{array}(tr);
    
    if isnan(trStart)
      continue;
    end

    % If trials showed non-monotonicity, find non-monotonic boundary in
    % spikes
    if lastRealTrEnd > trEnd
      while times(spike) > times(spike - 1) && spike < nSpikes
        spike = spike + 1;
      end
    end

    lastRealTrEnd = trEnd;

    while times(spike) < trStart && spike < nSpikes
      spike = spike + 1;
    end
    if spike <= nSpikes
      firstSpike = spike;
    else
      break;
    end

    while times(spike) <= trEnd && spike < nSpikes && times(spike) >= trStart
      spike = spike + 1;
    end
    lastSpike = spike;

    if lastSpike >= firstSpike
      waveforms.trialInfo.trial(firstSpike:lastSpike) = tr;
    end
  end
  
  save(fullfile(waveDataDir, waveFilenames{w}), 'waveforms');
end

clear loadVar

fprintf('\nDone.\n');
