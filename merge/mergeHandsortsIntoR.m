function mergeHandsortsIntoR(handSortPath, RFullPath, newRFullPath)
% For now at least, we're going to exclude all 0-units, since almost no one
% uses them. If you want a channel with frank multi-unit activity, hoop it
% and rate it poorly (but not 0).
%
% Note that if you stop and restart recordings a lot (i.e., generate many
% many separate data files such that the clock keeps getting reset), this
% function is unnecessarily slow. Could be optimized for that (see
% subfunction monotonizeSpikeAndTrialTimes).
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

if nargin ~= 3
  error('mergeHandsortsIntoR requires 3 arguments');
end

fprintf('Loading R struct\n');

loadVar = load(RFullPath);
R = loadVar.R;

% Load sorts structure, figure out which channels are worth including
loadVar = load(fullfile(handSortPath, 'sorts.mat'));
sorts = loadVar.sorts;

waveformFiles = {};

alpha = alphabet();
for ch = 1:length(sorts)
  if sorts(ch).onlineSorted || sorts(ch).userSorted
    if isnan(sorts(ch).array)
      lett = '';
    else
      lett = alpha(sorts(ch).array);
    end
    waveformFiles{end+1} = makeWaveFilename(lett, sorts(ch).electrode);
  end
end

% Clear 'unit' and 'unitRatings' fields of R struct
for trial = 1:length(R)
  R(trial).unit = [];
  R(trial).unitRatings =  [];
end

fprintf('Carving spike times into trials, merging with R\n');
fprintf('File (of %d):', length(waveformFiles));

SU = [];
lastUnit = 0;
for wf = 1:length(waveformFiles)
  fprintf(' %d', wf); if ~mod(wf, 20), fprintf('\n'); end;
  loadVar = load(fullfile(handSortPath, waveformFiles{wf}));
  % Check whether we have multiple arrays or not
  if isnan(sorts(1).array)
    channel = find([sorts.electrode] == loadVar.waveforms.electrode);
  else
    channel = find([sorts.electrode] == loadVar.waveforms.electrode & [sorts.array] == loadVar.waveforms.array);
  end
  handSorted = sorts(channel).userSorted;
  [R, SU, lastUnit] = mergeOneHandsortIntoR(loadVar.waveforms, R, SU, handSorted, lastUnit);
  clear loadVar
end

fprintf('\nSaving R struct...\n');

w = whos('R', 'SU');
if w(1).bytes + w(2).bytes > 2140000000
  save(newRFullPath, '-v7.3', 'R', 'SU');
else
  save(newRFullPath, '-v7', 'R', 'SU');
end

fprintf('Done.\n');





function [R, SU, lastUnit] = mergeOneHandsortIntoR(waveforms, R, SU, handSorted, lastUnit)

uniqueUnits = unique(waveforms.units);
uniqueUnits = uniqueUnits(uniqueUnits ~= 0);

if isempty(uniqueUnits)
  return;
end

% Fill in SU entries
for u = 1:length(uniqueUnits)
  SU.unitLookup(lastUnit+u, :) = [waveforms.electrode, uniqueUnits(u), handSorted];
  if ~isnan(waveforms.array)
    SU.arrayLookup(lastUnit+u) = waveforms.array;
  end
end

% Build a little table of epoch start-end times.
% Each row is an epoch, with the first column being the start spike # of
% that epoch, and the second column being the stop spike # for that epoch.
for ep = 1:length(waveforms.ratings)
  epochTimes(ep, :) = waveforms.ratings(ep).epoch;
end

% Get lists of the start and stop times of trials
[trStarts, trEnds] = getTrialStartsEnds(R, waveforms.array);


% There may be 'resets' in the times when Cerebus was stopped and
% re-started. Find and monotonize these.
[times, trStarts, trEnds] = monotonizeSpikeAndTrialTimes(waveforms.spikeTimes, trStarts, trEnds);


spike = 1;
nSpikes = length(times);
for tr = 1:length(R)
  trStart = trStarts(tr);
  trEnd = trEnds(tr);
  
  if isnan(trStart)
    continue;
  end
  
  % Find the first spike of the trial
  while times(spike) < trStart && spike < nSpikes
    spike = spike + 1;
  end
  if spike <= nSpikes
    firstSpike = spike;
  else
    break;
  end
  
  % Find the last spike of the trial
  while times(spike) <= trEnd && spike < nSpikes
    spike = spike + 1;
  end
  lastSpike = spike - 1;
  
  % Figure out which epoch this is. Note that the trial may span 2 epochs.
  epochs = find(firstSpike <= epochTimes(:, 2) & lastSpike >= epochTimes(:, 1))';

  if lastSpike >= firstSpike
    sTimes = times(firstSpike:lastSpike);
    units = waveforms.units(firstSpike:lastSpike);
    for u = 1:length(uniqueUnits)
      % Insert spikeTimes
      R(tr).unit(lastUnit+u).spikeTimes = sTimes(units == uniqueUnits(u))' - trStart;

      if ~isempty(epochs)
        ratings = [];
        for epoch = epochs
          ratings(end+1) = waveforms.ratings(epoch).ratings(uniqueUnits(u));
        end
      else
        ratings = 0;
      end
      R(tr).unitRatings(lastUnit+u) = min(ratings);
    end
  end
end


lastUnit = lastUnit + length(uniqueUnits);



function [trStarts, trEnds] = getTrialStartsEnds(R, array)
% Make lists of the start and stop times of trials

% Check which type of R struct we're using
% Rig 1 with one array uses CerebusInfo
% Rig 1 with two arrays uses CerebusInfoA and CerebusInfoB
% RigC uses timeCerebusStart
if isfield(R, 'CerebusInfo')
  cerTiming = 'CerebusInfo';
elseif isfield(R, 'CerebusInfoA')
  cerTiming = 'CerebusInfoA';
elseif isfield(R, 'timeCerebusStart');
  cerTiming = 'timeCerebusStart';
else
  error('Unrecognized Cerebus alignment field');
end

% If using CerebusInfo and more than one array, complain but don't die
if strcmp(cerTiming, 'CerebusInfo') && ~isnan(array) && array > 1
  warning('Should not use CerebusInfo with more than one array. Clock drift can cause poor alignment.');
end

alpha = alphabet();

% Make lists of the start and stop times of trials
trStarts = NaN(1, length(R));
trEnds = NaN(1, length(R));
for tr = 1:length(R)
  switch cerTiming
    case 'CerebusInfo'
      if ~isempty(R(tr).CerebusInfo)
        % Convert seconds to ms
        trStarts(tr) = R(tr).CerebusInfo.startTime * 1000;
        trEnds(tr) = R(tr).CerebusInfo.endTime * 1000;
      end
      
    case 'CerebusInfoA'
      if isnan(array)
        letter = 'A';
      else
        letter = alpha(array);
      end
      field = ['CerebusInfo' letter];
      
      if ~isempty(R(tr).(field))
        % Convert seconds to ms
        trStarts(tr) = R(tr).(field).startTime * 1000;
        trEnds(tr) = R(tr).(field).endTime * 1000;
      end

    case 'timeCerebusStart'
      if ~isnan(R(tr).timeCerebusStart(1))
        % Convert Cerebus 30kHz samples to ms
        trStarts(tr) = R(tr).timeCerebusStart(1) / 30;
        trEnds(tr) = R(tr).timeCerebusEnd(end) / 30;
      end
  end
end



function [times, trStarts, trEnds] = monotonizeSpikeAndTrialTimes(times, trStarts, trEnds)

% Note that this gives us the last spike BEFORE the non-monotonicity
spikeNonMono = find(diff(times) < 0);

% There may be NaNs in the trial start times
% Again, get last trial BEFORE the non-monotonicity
notNaNs = find(~isnan(trStarts));
trStartsNoNaNs = trStarts(notNaNs);
% Take the non-mono indices found by diff, and use them as indices for
% notNaNs to restore the indexing into trStarts
trNonMono = notNaNs(diff(trStartsNoNaNs) < 0);

% Use same trick for trEnds, separately. We'll need this later to check
% whether the reset happened in the middle of a trial
notNaNs = find(~isnan(trEnds));
trEndsNoNaNs = trEnds(notNaNs);
trNonMonoEnds = notNaNs(diff(trEndsNoNaNs) < 0);


% Check that there are the same number of resets in the spike times and the
% trial times. If not, we don't know how to align; error
if length(spikeNonMono) ~= length(trNonMono)
  error('mergeHandsortsIntoR:unequalTimeResets', 'Different number of timing resets in trial time data and spike time data');
end

% If there are resets, monotonize them
if ~isempty(spikeNonMono)
  % Figure out how big the offsets have to be in order to monotonize each
  % reset, then add it
  for r = 1:length(spikeNonMono)
    % Need to use bigger of previous spike time and previous trial
    % start/end time
    prevSpike = times(spikeNonMono(r));
    prevTrStart = trStarts(trNonMono(r));
    prevTrEnd = trEnds(trNonMono(r));
    
    % use +1 for safety (in case the post-reset time is 0)
    offset = 1 + max([prevSpike prevTrStart prevTrEnd]);
    
    % Apply offset. Yes, this does more additions than strictly necessary:
    % when multiple resets are present, offsets get added repeatedly to
    % values late in the sequence. But it's easy, and generally cheap
    % relative to other operations in the merge unless there are tons of
    % resets.
    trStarts(trNonMono(r)+1:end) = trStarts(trNonMono(r)+1:end) + offset;
    times(spikeNonMono(r)+1:end) = times(spikeNonMono(r)+1:end) + offset;
    
    % Need to check trEnds separately, since we found the
    % non-monotonicities based on trStarts and the reset may have happened
    % in the middle of a trial
    trEnds(trNonMonoEnds(r)+1:end) = trEnds(trNonMonoEnds(r)+1:end) + offset;
  end
end


