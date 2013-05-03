function alignedWaves = alignOnMin(waves)
% alignedWaves = alignOnMin(waves)
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

% First, get an approximation of the original threshold. We'll take the
% deepest point in every snippet, then take the least deep one of those.
[mins, minsI] = min(waves);
thresh = max(mins);

% Now, find at which sample snippets crossed threshold. This will be the
% point at which the most waveforms are < threshold. We add 2 samples to
% let the wave reach minimum.
[junk, threshSamp] = max(sum(waves <= thresh, 2));
threshSamp = threshSamp + 2;

alignedWaves = zeros(size(waves, 1), size(waves, 2));

for w = 1:size(waves, 2)
  firstPostThresh = minsI(w);
  
  firstPt = firstPostThresh - (threshSamp - 1); % This value may be negative
  firstSample = max(0, ceil(-firstPt+1)) + 1;   % If there are negative values, clip pts not samples
  firstPt = firstPt + firstSample - 1;          % Toss the negative values

  lastPt = firstPostThresh + size(waves, 1) - threshSamp; % This value may be too big
  lastSample = size(waves, 1) - max(0, ceil(lastPt - size(waves, 1))); % Make sure we have enough values to get through samples
  lastPt = lastPt - size(waves, 1) + lastSample;          % Toss extra points

  alignedWaves(firstSample:lastSample, w) = waves(firstPt:lastPt, w);
end

% Clip off one point at both the front and end
alignedWaves = alignedWaves(2:end-1, :);
