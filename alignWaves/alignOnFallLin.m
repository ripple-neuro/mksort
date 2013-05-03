function alignedWaves = alignOnFallLin(waves)
% This function is deprecated. alignOnFallLinExact should now always be
% used instead. This exists solely to provide legacy compatibility.
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

interpFactor = 10;

% First, get an approximation of the original threshold. We'll take the
% deepest point in every snippet, then take the least deep one of those.
[mins, minsI] = min(waves);
minsI = 1 + interpFactor * (minsI - 1);
thresh = max(mins);

% Now, find at which sample snippets crossed threshold. This will be the
% point at which the most waveforms are < threshold.
[junk, threshSamp] = max(sum(waves <= thresh, 2));

% Linearly interpolate waveforms by 10x. Use linear for speed. I <3 speed.
iWaves = interp1(1:size(waves, 1), waves, 1:1/interpFactor:size(waves, 1));

alignedWaves = zeros(size(waves, 1), size(waves, 2));

for w = 1:size(iWaves, 2)
  firstPostThresh = find(iWaves(1:minsI(w), w) > thresh, 1, 'last') + 1;
  
  firstPt = firstPostThresh - interpFactor * (threshSamp - 1); % This value may be negative
  firstSample = max(0, ceil(-(firstPt-1)/interpFactor)) + 1;   % If there are negative values, clip pts not samples
  firstPt = firstPt + interpFactor * (firstSample - 1);        % Toss the negative values

  lastPt = firstPostThresh + interpFactor * (size(waves, 1) - threshSamp); % This value may be too big
  lastSample = size(waves, 1) - max(0, ceil((lastPt - size(iWaves, 1)) / interpFactor)); % Make sure we have enough values to get through samples
  lastPt = lastPt - interpFactor * (size(waves, 1) - lastSample);          % Toss extra points

  alignedWaves(firstSample:lastSample, w) = iWaves(firstPt:interpFactor:lastPt, w);
end

% Clip off one point at both the front and end
alignedWaves = alignedWaves(2:end-1, :);
