function TTPwaves = prepWavesForTTPs(path, filenames, ratingThreshold, varargin)
% This function generates a TTPwaves file from the various waveforms files,
% only for units where the max rating is >= ratingThreshold.
%
% The final, optional argument can be used to specify a filter file. If
% unused, no filter will be used.
%
% TTPwaves is returned as [] if no waves crossed the threshold.
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

% TODO: is it worth making the sampling rate here variable?

% Assigning TTPwaves to [] so that we can check if any TTPs got measured.
% I.e., there were no ratings that cross the ratings threshold.
TTPwaves = [];

alignMethod = 4;          % Take best of upswing and downswing
sampleRate = 30000;       % Sampling rate in Hz
nWaveLimit = 300;         % # of waves to use to find mean wave
minWavesToClassify = 10;  % We'll require this many waves to average


i = 0;

if isempty(varargin)
  filt = 0;
else
  filt = 1;
  myFilt = load(varargin{1});
end

for f = 1:length(filenames)
  % Load waveforms and units
  loadVar = load(fullfile(path, filenames{f}));
  % Check if it's an n-trode, skip if so
  if length(loadVar.waveforms.electrode) > 1, continue; end;
  
  origWaves = loadVar.waveforms.waves';  % waves is now becomes nWaves x nPts
  units = loadVar.waveforms.units;
  ratings = loadVar.waveforms.ratings;
  uniqueUnits = unique(units);
  uniqueUnits = uniqueUnits(uniqueUnits ~= 0 & uniqueUnits <= 4);
  if isempty(uniqueUnits), continue; end;
  
  % Loop through units
  for u = 1:length(uniqueUnits)
    
    % Find best-rated epoch for this unit
    bestEpoch = 0;
    bestRating = 0;
    for r = 1:size(ratings)
      if ~isempty(ratings(r).ratings) && ratings(r).ratings(uniqueUnits(u)) > bestRating
        bestRating = ratings(r).ratings(uniqueUnits(u));
        bestEpoch = r;
      end
    end
    
    % From ratings, figure out which waves are candidates
    % If we don't find anything at or above the rating threshold, move on
    if bestRating < ratingThreshold, continue; end;
    % If we found a best epoch...
    if bestEpoch ~= 0
      interval = ratings(bestEpoch).epoch(1):ratings(bestEpoch).epoch(2);
    % Otherwise, no epoch was rated > 0, but we're OK with that
    else
      interval = 1:size(origWaves, 1);
    end
    
    % Check for enough waves, and trim down to nWaveLimit if needed
    thisUnit = interval(1) - 1 + find(units(interval) == uniqueUnits(u));
    if length(thisUnit) > nWaveLimit
      thisUnit = thisUnit(1:nWaveLimit);
    elseif length(thisUnit) < minWavesToClassify
      continue;
    end
    
    % Take only relevant waves
    waves = origWaves(thisUnit, :);
    
    
    % We're going to clip off front of wave in alignment, so save baseline
    baseline = mean(mean(waves(:, 1:2)));

    troughPoint = 10;

    awaves = alignSpline(waves, troughPoint, [], alignMethod);
    cwaves = cleanWaveforms(awaves);
    
    meanWave = mean(cwaves, 1);
    
    valleyWave = mean(cleanWaveforms(alignSpline(waves, troughPoint, [], 2)));
    
    
    if filt
      meanWave = sosfilt(myFilt.SOS, meanWave);
      valleyWave = sosfilt(myFilt.SOS, valleyWave);
    end
    
    
    % Find TTP
    wave = meanWave - baseline;
    
    [wmin, mini] = min(wave);

    % The post peak is where the derivative first goes negative
    diffs = diff(wave);
    postPeak = mini + find(diffs(mini+1:end) < 0, 1);
    % If we found the post-peak, include this cell
    if ~isempty(postPeak)
      i = i + 1;

      TTPwaves(i).electrode = loadVar.waveforms.electrode;
      TTPwaves(i).array = loadVar.waveforms.array;
      TTPwaves(i).unit = uniqueUnits(u);
      TTPwaves(i).good = 1;
      % We've spline interpolated by a factor of 10, and want the result in
      % microseconds
      TTPwaves(i).TTP = (postPeak-mini)/sampleRate * 100000;
      TTPwaves(i).baseline = baseline;
      TTPwaves(i).wave = meanWave;
      TTPwaves(i).valleyWave = valleyWave;
      TTPwaves(i).filtered = filt;
      TTPwaves(i).sampleRate = sampleRate*10;
      TTPwaves(i).rating = bestRating;
    end
  end
end

% save(fullfile(path, 'TTPwaves.mat'), 'TTPwaves');
