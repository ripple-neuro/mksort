function autocorr = autocorrSpikesOneMS(spikeTimes, maxLag, lockout)
% autocorr = autocorrSpikesOneMS(spikeTimes, maxLag, lockout)
%
% This file computes autocorrelations. Useful for determining refractory
% violations.
%
% THIS FILE IS NOT CURRENTLY USED.
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

% Anything before this time is a refractory violation. Should be a natural
% number.
refracMax = 2;

maxTimes = 1000000;  % in ms

% This value determines when small values will be attributed to FFT error
% and rounded to 0. If I understand correctly, anything up to about 0.99
% should actually be fine, if excessive.
noiseThresh = 0.0001;

autocorr.lags = 0:maxLag;
autocorr.lockout = lockout;


if isempty(spikeTimes)
  autocorr.values = zeros(1, length(autocorr.lags));
  autocorr.percRefractoryViolations = NaN;
  return;
end

% Calculate autocorr
spikeTimes = round(spikeTimes);
% Handles possible downward discontinuities in spikeTimes due to restarting
% recordings
nonMonoPts = find(spikeTimes(2:end) - spikeTimes(1:end-1) < 0);
if ~isempty(nonMonoPts)
  for pt = nonMonoPts
    spikeTimes(pt+1:end) = spikeTimes(pt+1:end) + spikeTimes(pt) + maxLag + 1;
  end
end

% We handle the point limit starting from the end since there may be a few
% spikes recorded right when recording is started, without any more
% recording for a while.
if spikeTimes(end) - spikeTimes(1) < maxTimes
  firstTime = 1;
else
  firstTime = find(spikeTimes > spikeTimes(end) - maxTimes, 1);
end

spikes = zeros(1, spikeTimes(end)-spikeTimes(firstTime) + 1);
spikes(spikeTimes(firstTime:end) - spikeTimes(firstTime) + 1) = 1;

acorr = xcorr(spikes, maxLag);

autocorr.values = acorr(maxLag+1:end);
autocorr.values(1) = 0;
autocorr.values(autocorr.values < noiseThresh) = 0;

% Calculate refractory violations. We'll use the mean count per bin after
% the lockout to estimate an 'expected' number of spikes per bin, then see
% how bad the bins before refracMax ms are.
% First, check that lockout is appropriate; if not, use NaN
if lockout >= refracMax
  autocorr.percRefractoryViolations = NaN;
else
  % Want first normalization bin to be halfway through.
  firstMeanBin = ceil(maxLag/2) + 1;
  lastMeanBin = maxLag + 1;
  meanCountPerBin = mean(autocorr.values(firstMeanBin:lastMeanBin));
  
  % If we happen to have no non-refractory spikes, give NaN
  if meanCountPerBin == 0
    autocorr.percRefractoryViolations = NaN;
  else
    refracBins = autocorr.values(floor(lockout)+2:refracMax+1);
    % Now, scale a partially locked-out bin to account for missing data
    refracBins(1) = refracBins(1) / (1-mod(lockout, 1));

    % Finally, look at refractory data relative to non-refractory data
    autocorr.percRefractoryViolations = 100 * sum(refracBins)/length(refracBins)/meanCountPerBin;
  end
end
