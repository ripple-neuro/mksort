function TTPwaves = prepWavesForTTPsBB(dataDir, sorts, BBPath, waveFilenames, ratingThreshold, filterType)
% TTPwaves = prepWavesForTTPsBB(dataDir, sorts, BBPath, waveFilenames, ratingThreshold, filterType)
%
% Extract waveforms from broadband data files and save waveforms both with
% Cerebus-imitation filters (for sorting) and milder filters (for
% classifying TTP durations). Then, find TTP durations for the
% less-filtered waveforms.
%
% Waveforms extracted from broadband data are saved in a subdirectory of
% dataDir named 'fromBroadband'.
%
% Assumes that broadband data is collected immediately before primary data.
% That is, use sorting parameters and ratings from the first epoch of the
% sorts data.
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

% ----------------------------------------------------
%%%% GENERATE waveforms FILES FROM BROADBAND DATA %%%%
% ----------------------------------------------------

status = mkdir(dataDir, 'fromBroadband');
if status == 0
  error('Could not create subdirectory in data directory');
end

unfiltFilenames = {};

NSX = NSX_open(BBPath);
if isempty(NSX) || NSX.FID < 0
  error(lastwarn);
end

fprintf('Analyzing broadband\n');
for f = 1:length(waveFilenames)
  waveFilename = waveFilenames{f};
  loadVar = load(fullfile(dataDir, waveFilename));
  origWaveforms = loadVar.waveforms;
  clear loadVar
  
  % Check if it's an n-trode, skip if so
  if length(origWaveforms.electrode) > 1, continue; end;
  
  units = origWaveforms.units;
  ratings = origWaveforms.ratings;
  uniqueUnits = unique(units);
  uniqueUnits = uniqueUnits(uniqueUnits ~= 0 & uniqueUnits <= 4);
  if isempty(uniqueUnits), continue; end;
  
  % Figure out if any units on this electrode have high enough ratings to
  % be usable
  anyUsable = 0;
  for u = 1:length(uniqueUnits)
    % Use rating for first epoch for this unit
    rating = ratings(1).ratings(uniqueUnits(u));
    if rating >= ratingThreshold
      anyUsable = 1;
      break;
    end
  end
  if ~anyUsable, continue; end
  
  % If we get here, it means there are usable units on this electrode, so
  % read the broadband data
  fprintf('%d ', f);
  [data, time] = NSX_read(NSX, origWaveforms.electrode, 1);
  data = double(data);
  
  % Use a hack to find the threshold: take the minimum of each waveform,
  % then find the greatest of those (i.e., the smallest deviation below 0)
  thresh = max(min(origWaveforms.waves));
  
  % Now use a hack to find the thresholding point for each waveform
  threshT = find(origWaveforms.waves(:, 1) <= thresh, 1);
  
  % Threshold broadband data to get snippets with and without filtering
  filt.SOS = cerebusFilter(filterType);
  [bbWaves, bbFiltWaves, pts] = thresholdBBTwoFilters(data, thresh, threshT, size(origWaveforms.waves, 1), filt);
  
  % Convert spike point numbers to times
  spikeTimes = time(pts);
  % Need to subvert epoch boundaries
  ratings = origWaveforms.ratings(1);
  ratings.epoch(2) = length(spikeTimes);
  % Save filtered broadband waveforms file
  waveforms = waves2waveforms(bbFiltWaves, spikeTimes, origWaveforms.electrode, origWaveforms.array, ratings);
  save(fullfile(dataDir, 'fromBroadband', waveFilename), 'waveforms', '-v6');
  
  % Sort waveforms
  % Find this channel's sorts
  % This is a bit of a hassle because n-trodes have .electrode fields with
  % length > 1
  electrodes = {sorts.electrode};
  matchingElec = cellfun(@(x) length(x) == 1 && x == waveforms.electrode, electrodes);
  if isnan(waveforms.array)
    chSorts = sorts(matchingElec);
    %     chSorts = sorts([sorts.electrode] == waveforms.electrode);
  else
    chSorts = sorts([sorts.array] == waveforms.array & matchingElec);
    %     chSorts = sorts([sorts.array] == waveforms.array & [sorts.electrode] == waveforms.electrode);
  end
  % Modify sorts file to have a single epoch (originally the first epoch)
  % covering all the spikes
  chSorts.sorts = chSorts.sorts(1);
  chSorts.sorts.epochEnd = size(bbWaves, 2);
  waveforms = sortOneChannelWithoutCache(chSorts, fullfile(dataDir, 'fromBroadband'));
  
  % Re-save sorted filtered broadband waveforms
  save(fullfile(dataDir, 'fromBroadband', waveFilename), 'waveforms', '-v7');
  
  % Copy result of filtered sorts to unfiltered version, save down
  bbWaveforms = waves2waveforms(bbWaves, spikeTimes, origWaveforms.electrode, origWaveforms.array, ratings);
  bbWaveforms.units = waveforms.units;
  waveforms = bbWaveforms;
  [~, fileStem, fileExt] = fileparts(waveFilename);
  unfiltFilenames{end+1} = [fileStem '-unfilt' fileExt];
  save(fullfile(dataDir, 'fromBroadband', unfiltFilenames{end}), 'waveforms', '-v7');
end

fclose(NSX.FID);

% --------------------------------------------------
%%%% USE STANDARD FUNCTION TO GENERATE TTPwaves %%%%
% --------------------------------------------------

fprintf('\nGenerating TTPwaves\n');
if isempty(waveFilenames)
  TTPwaves = [];
else
  TTPwaves = prepWavesForTTPs(fullfile(dataDir, 'fromBroadband'), unfiltFilenames, ratingThreshold);
end




function waveforms = waves2waveforms(waves, spikeTimes, electrode, array, ratings)

waveforms.electrode = electrode;
waveforms.waves = waves;
waveforms.alignedWaves = [];
waveforms.alignMethodFcn = '';
waveforms.units = zeros(1, length(spikeTimes));
waveforms.sorted = 0;
waveforms.array = array;
waveforms.ratings = ratings;
waveforms.trialInfo = [];
waveforms.spikeTimes = spikeTimes;

