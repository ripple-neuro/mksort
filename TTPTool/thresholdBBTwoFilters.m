function [bbWaves, bbFiltWaves, spikeTimes] = thresholdBBTwoFilters(data, thresh, threshT, waveLen, filt)
% [bbWaves, bbFiltWaves, spikeTimes] = thresholdBBTwoFilters(data, thresh, threshT, waveLen, filt)
%
% This function extracts waveforms from broadband data. Copies of the data
% are first filtered in two different ways: one copy is filtered with the
% SOS filter passed as the filt argument; filt should match the filters
% used to collect the main portion of the data, and this copy of the data
% will be used for sorting. The other copy is filtered with a 150 Hz 1-pole
% high-pass filter, and will be used for producing the less-filtered
% waveforms for use with determining TTPs.
%
% The copy processed with filt is then thresholded at the thresh value, and
% waveforms of length waveLen are extracted. Waveforms have their threshold
% crossing at time point threshT. These waveforms are returned as
% bbFiltWaves. The other copy has waveforms extracted at the same time
% points. These waveforms are returned as bbFiltWaves. The 'times' of the
% start of each waveform is returned as spikeTimes, in units of data
% points.
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

unfilt = load('hp150_1p');

% Filter signal
% 'filtered' is filtered according to Cerebus filters, 'unfiltered' is
% still actually filtered, but only mildly.
filtered = round(sosfilt(filt.SOS, data));
data = round(sosfilt(unfilt.SOS, data));

% Pre-calculate some handy values
blackoutLen = waveLen - 1;
preThresh = threshT - 1;
postThresh = waveLen - threshT;
maxT = length(data) - postThresh + 1;

% Find all points below threshold, then clip out ones that are too close.

subThresh = filtered <= thresh;
subThresh(1:preThresh) = 0;

t = preThresh + 1;
while t < maxT
  if subThresh(t)
    subThresh(t+1:t+blackoutLen) = 0;
    t = t + waveLen;
  else
    t = t + 1;
  end
end
subThresh(maxT+1:end) = 0;

% Find the spike times, pre-allocate waves arrays
spikeTimes = find(subThresh) - preThresh;
bbWaves = zeros(waveLen, length(spikeTimes));
bbFiltWaves = zeros(waveLen, length(spikeTimes));

% Collect the snippets
for w = 1:length(spikeTimes)
  t = spikeTimes(w);
  bbWaves(:, w) = data(t : t + blackoutLen);
  bbFiltWaves(:, w) = filtered(t : t + blackoutLen);
end

