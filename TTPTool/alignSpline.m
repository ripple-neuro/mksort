function awaves = alignSpline(waves, troughPoint, varargin)
% awaves = alignSpline(waves, trough)
% awaves = alignSpline(waves, trough, interpTroughThresh)
% awaves = alignSpline(waves, trough, interpTroughThresh, alignMethod)
%
% This function is not particularly fast, and could probably be optimized.
%
% waves is a matrix where each row is a waveform
%
% trough is the approximate point at which the trough occurs, in samples.
%
% alignMethod is:
% 1 for downward slope
% 2 for trough
% 3 for upward slope
% 4 first aligns by trough. Aligns by upward slope unless downward slope is
%   > 1.5 x upward slope. If so, uses downward.
% 5 for center of mass
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

interpTroughThresh = [];

if ~isempty(varargin)
  interpTroughThresh = varargin{1};
end

if length(varargin) == 2
  alignMethod = varargin{2};
else
  alignMethod = 4;
end

upFactor = 1.5;
alignpt = 30;
waveLen = size(waves,2);
nwaves = size(waves,1);
trough = troughPoint * 10;

xs = 1:waveLen;
xis = 1:0.1:waveLen;


% If interpTroughThresh is specified, clip off all points for each wave
% with values below interpTroughThresh, and spline interpolate so that we
% get a decent estimate of the trough location. If interpTroughThresh is
% >0, do the same for the post-peak.
if ~isempty(interpTroughThresh)
  for i = 1:nwaves
    if interpTroughThresh < 0
      good = waves(i, :) > interpTroughThresh;
    else
      good = waves(i, :) < interpTroughThresh;
    end
    waves(i, :) = interp1(find(good), waves(i, good), 1:waveLen, 'spline');
  end
end


% Interpolate everybody
iwaves = zeros(nwaves, length(xis));
bases = zeros(1, nwaves);
for w = 1:nwaves
  bases(w) = mean(waves(w, 1:3));
  iwaves(w, :) = interp1(xs,waves(w,:),xis,'spline');
end

% Align. Wackiness for method 4.
if ismember(alignMethod, [1 2 3 5])
  awaves = alignWaves(iwaves, trough, bases, alignpt, alignMethod);
elseif alignMethod == 4
  % Align on trough
  awaves = alignWaves(iwaves, trough, bases, alignpt, 2);
  cwaves = cleanWaveforms(awaves);
  meanWave = mean(cwaves, 1);
  
  [wmin, mini] = min(meanWave);
  base = mean(bases);
  % Downward slope
  down = find(meanWave(1:mini) > 0.5*(wmin-base)+base, 1, 'last');
  try
    downSlope = meanWave(down-1) - meanWave(down+1);
  catch
    downSlope = -Inf;
  end
  % Upward slope
  up = mini - 1 + find(meanWave(mini:end) > 0.5*(max(meanWave)-wmin) + wmin, 1);
  upSlope = meanWave(up+1) - meanWave(up-1);

  if downSlope > upFactor*upSlope
    awaves = alignWaves(iwaves, trough, bases, alignpt, 1);
  else
    awaves = alignWaves(iwaves, trough, bases, alignpt, 3);
  end
end






function awaves = alignWaves(waves, trough, bases, alignpt, alignMethod)

nwaves = size(waves,1);
waveLen = size(waves,2);
awaves = zeros(1, waveLen);

if alignMethod == 2
  alignpt = alignpt * 1.5;
elseif alignMethod == 3
  alignpt = alignpt * 3;
elseif alignMethod == 5
  alignpt = alignpt * 2;
end

for w = 1:nwaves
  [wmin, mini] = min(waves(w, trough-50:trough+50));
  mini = mini + trough - 50 - 1;
  
  if alignMethod == 1  % Down
    pre = find(waves(w, 1:mini) > 0.5*(wmin-bases(w))+bases(w), 1, 'last');
  elseif alignMethod == 2  % trough
    pre = mini;
  elseif alignMethod == 3  % Up
    pre = mini - 1 + find(waves(w, mini:end) > 0.5*(max(waves(w,:))-wmin) + wmin, 1);
  elseif alignMethod == 5
    threshold = 0.3 * wmin;  % COM
    pre = 1 + find(waves(w, 1:trough) > threshold, 1, 'last');
    post = trough - 2 + find(waves(w, trough:end) > threshold, 1);
    if isempty(post) || isempty(pre) || pre > post
      pre = mini;
    else
      cums = cumsum(waves(w, pre:post) .* (pre:post));
      pre = pre - 1 + find(cums > cums(end)/2, 1, 'last');
    end
  end
  
  if pre < alignpt
    awaves(w, 1:(alignpt-pre)) = 0;
    awaves(w, alignpt-pre+1:end) = waves(w, 1:end-(alignpt-pre));
  else
    awaves(w, 1:(end-pre+alignpt)) = waves(w, (1+pre-alignpt):end);
  end
end
