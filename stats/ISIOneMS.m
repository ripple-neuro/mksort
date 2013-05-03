function autocorr = ISIOneMS(spikeTimes, maxLag, lockout)
% autocorr = ISIOneMS(spikeTimes, maxLag, lockout)
%
% This file computes interspike intervals (ISIs), similar to
% autocorrelations but vastly faster. Useful for determining refractory
% violations.
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

autocorr.lags = 0.5:maxLag-0.5;
autocorr.lockout = lockout;


if isempty(spikeTimes)
  autocorr.values = zeros(1, length(autocorr.lags));
  autocorr.percRefractoryViolations = NaN;
  return;
end

ISIs = diff(spikeTimes);

ISIs = ISIs(ISIs <= maxLag & ISIs >= 0);

autocorr.values = hist(ISIs, autocorr.lags, maxLag);

% Calculate refractory violations. We'll use the mean count per bin after
% the lockout to estimate an 'expected' number of spikes per bin, then see
% how bad the bins before refracMax ms are.
% First, check that lockout is appropriate; if not, use NaN
if lockout >= refracMax
  autocorr.percRefractoryViolations = NaN;
else
  % Want first normalization bin to be halfway through.
  firstMeanBin = ceil(maxLag/2) + 1;
  lastMeanBin = maxLag;
  meanCountPerBin = mean(autocorr.values(firstMeanBin:lastMeanBin));
  
  % If we happen to have no non-refractory spikes, give NaN
  if meanCountPerBin == 0
    autocorr.percRefractoryViolations = NaN;
  else
    refracBins = autocorr.values(floor(lockout)+1:refracMax);
    % Now, scale a partially locked-out bin to account for missing data
    refracBins(1) = refracBins(1) / (1-mod(lockout, 1));

    % Finally, look at refractory data relative to non-refractory data
    autocorr.percRefractoryViolations = 100 * sum(refracBins)/length(refracBins)/meanCountPerBin;
  end
end
