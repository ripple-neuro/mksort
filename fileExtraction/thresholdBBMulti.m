function [waves, spikeTimes] = thresholdBBMulti(data, threshes, preThresh, waveLen)
% [waves, spikeTimes] = thresholdBBMulti(data, threshes, preThresh, waveLen)
%
% This function extracts waveforms from broadband data, and allows multiple
% channels to be linked together as an n-trode for purposes of finding
% threshold crossings. The data should have already been filtered.
%
% The data is then thresholded at the thresh value, and waveforms of length
% waveLen are extracted. Waveforms have their threshold crossing at time
% point preThresh+1. The 'times' of the start of each waveform is returned
% as spikeTimes, in units of data points.
%
% data should be a cell array of vectors (one per channel), threshes a
% vector of thresholds.
%
% waves will have snippets concatenated.
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


%% Enforce sanity on data

lengths = cellfun(@length, data);
if ~all(lengths == lengths(1))
  error('thresholdBBMulti:unequalDataLengths', 'Data lengths not equal on channels of an n-trode');
end

if length(data) ~= length(threshes)
  error('thresholdBBMulti:oneThreshPerChannel', 'Wrong number of thresholds specified relative to channels');
end


%% Pre-calculate some handy values
blackoutLen = waveLen - 1;
maxT = length(data{1}) - waveLen + preThresh + 1;


%% Loop through channels, find all points below threshold, 'or' them
subThresh = data{1} <= threshes(1);

if length(data) > 1
  for e = 2:length(data)
    subThresh = subThresh | data{e} <= threshes(e);
  end
end


%% Clip out threshold crossings that are too close
% We want to imitate the Blackrock state machine for this. That is, we will
% only take a snippet if it crosses threshold after the lockout is over.

% Prepend with zero to fix indexing from diff
crossings = [0 diff(subThresh) > 0];

% Drop crossings too close to the start of recording
crossings(1:preThresh) = 0;

% Kill crossings that follow too close after another crossing
t = preThresh + 1;
while t < maxT
  if crossings(t)
    crossings(t+1:t+blackoutLen) = 0;
    t = t + waveLen;
  else
    t = t + 1;
  end
end

% Drop crossings too close to the end of recording
crossings(maxT+1:end) = 0;


%% Find the spike times
spikeTimes = find(crossings) - preThresh;


%% Collect the snippets

% The expression below is complicated, but fast. Here's the logic.
% Loop through each electrode. For that electrode, we're going to grab all
% the snippet points at once. To do so, we'll start with the row vector of
% threshold crossing times. We'll then repeat that row so we have waveLen
% identical rows of threshold crossing times. To each column, we'll add a
% little count up to make the points span the snippet times. Since we have
% a correctly-sized matrix, this gives us the snippets packed together
% correctly when we index into data{e}.

waves = cell(1, length(data));
for e = 1:length(data)
  waves{e} = data{e}(bsxfun(@plus, repmat(spikeTimes, waveLen, 1), (0:waveLen-1)'));
end

% Now, to get all the channels concatenated, we'll just vertically stack
% the matrix for each electrode.

waves = vertcat(waves{:});

