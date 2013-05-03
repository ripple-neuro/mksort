function alignedWaves = alignOnRiseLinExact(waves)
% alignedWaves = alignOnRiseLinExact(waves)
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

%% Preallocation and threshold computation

% Compute for subsequent ease
nSamples = size(waves, 1);
nSpikes = size(waves, 2);

[mins, minsI] = min(waves);   % find the minima (and the indices for the minima)
thresh = max(mins);  % threshold is about this (the biggest you could have been and still triggered).

% This method for finding the threshold sample may seem like overkill, but
% it's done this way to not expose a bug in some versions of the Cerebus
% software
[~, threshSamp] = max(sum(waves <= thresh, 2));  % the sum gives the the total number of samples below threshold across all spikes.
% The sample with the most values below threshold is the sample where the threshold must have been.
% We add 4 samples to let the wave come back up, since we're aligning on the upswing.
threshSamp = threshSamp + 4;

alignedWaves = zeros(size(waves));



%% Shift waveforms by integer numbers of samples
% We do this so that the new alignment point is not the first threshold
% crossing, but the threshold crossing that occurred before the deepest
% point.

greaterThanThresh = waves > thresh;  % all points that are above threshold
% For each time, get rid of the ones that come too early (minsI contains
% this info across all spikes)
for s = 1:nSamples
  greaterThanThresh(s,:) = greaterThanThresh(s,:) .* (s >= minsI);
end

% These are just indices that count from one to the number of samples.
% They will help define the qualifying times for the first post-thresh
% sample.
justCounting = (1:nSamples)';

% Get rid of those indices that do not qualify because they are below
% threshold or come too early
goodInds = bsxfun(@times, greaterThanThresh, justCounting);
% We'll want to find the min index for each waveform that's non-zero. We
% can make this easier by making the 0s Inf's.
goodInds(goodInds == 0) = Inf;
firstPostThreshAll = min(goodInds);

% Find first and last point in old waveform (may be out of bounds)
firstPointAll = firstPostThreshAll - threshSamp + 1;
% Clean up non-alignable waveforms
firstPointAll(isinf(firstPointAll)) = nSamples;
lastPointAll = firstPointAll + nSamples - 1;

% Do actual re-alignment
for w = 1:nSpikes
  
  firstSample = max(0, -firstPointAll(w)+1) + 1;  % first sample of new waveform could be < 1
  firstPt = firstPointAll(w) + (firstSample-1);   % if the above was adjusted, adjust this too
  
  lastSample = nSamples - max(0, lastPointAll(w) - nSamples);  % last sample in new waveform can be off the end
  lastPt = lastPointAll(w) - (nSamples - lastSample);          % if the above was adjusted, adjust this too
  
  alignedWaves(firstSample:lastSample, w) = waves(firstPt:lastPt, w);
  
end



%% Now we remove the small amount of remaining jitter due to sampling

prePoints = alignedWaves(threshSamp-1, :);    % last point before threshold crossing
threshPoints = alignedWaves(threshSamp, :);   % threshold has been crossed (so these are all ABOVE threshold)
slopes = threshPoints - prePoints;            % slope local to the threshold crossing
slopes(slopes == 0) = 1;                      % deal with bogus slopes due to bogus alignments
shiftTimes = (thresh - prePoints) ./ slopes;  % shift so that the interpolated line crosses exactly at threshold

% uses linear interpolation to align perfectly on threshold
alignedWaves = bsxfun(@times, alignedWaves(1:end-1,:), (1-shiftTimes)) + bsxfun(@times, alignedWaves(2:end,:), shiftTimes);

% trim off one timepoint from the front to remove junk due to forced
% alignments
alignedWaves = alignedWaves(2:end,:);

