function [preview, sorts] = generateSortsAndPreviews(waveforms, maxUnits, lockout)
% [preview, sorts] = generateSortsAndPreviews(waveforms, maxUnits, lockout)
%
% This function generates the previews and sorts structures for one
% waveforms structure. These should be inserted into the array of previews
% and sorts structures in a file extraction function. lockout should be in
% ms.
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


previewSamplesPerChannel = 500;

autocorrMaxBin = 10;


nWaves = size(waveforms.waves, 2);

preview.electrode = waveforms.electrode;
preview.array = waveforms.array;

sorts.electrode = waveforms.electrode;
sorts.array = waveforms.array;

% Handle case of very few waveforms
if nWaves < previewSamplesPerChannel
  preview.throughDay = waveforms.waves;
  preview.throughDayAligned = [];
  preview.throughDayUnits = waveforms.units;
  preview.throughDaySpikeNums = 1:length(waveforms.units);

% Normal case
else
  spacing = floor(size(waveforms.waves, 2)/previewSamplesPerChannel);
  spikeNums = 1 + spacing*(0:previewSamplesPerChannel-1);
  preview.throughDay = waveforms.waves(:, spikeNums);
  preview.throughDayAligned = [];
  preview.throughDayUnits = waveforms.units(spikeNums);
  preview.throughDaySpikeNums = spikeNums;
end
preview.PCAPts = [];

uniqueUnits = unique(waveforms.units);
uniqueUnits = uniqueUnits(~ismember(uniqueUnits, 0));

% Initialize autocorrs for all possible units
for unit = 1:maxUnits
  sorts.autocorrs(unit).lags = 0:autocorrMaxBin;
  sorts.autocorrs(unit).lockout = lockout;
  sorts.autocorrs(unit).values = [];
  sorts.autocorrs(unit).percRefractoryViolations = NaN;
end
% Get actual autocorrs
for unit = uniqueUnits
  % ELB_EDIT: in the case where no spikes are found, the below loop will break
  if ~isempty(unit)
    autocorr = ISIOneMS(waveforms.spikeTimes(waveforms.units == unit), autocorrMaxBin, lockout);
    sorts.autocorrs(unit) = autocorr;
  end
end

% Calculate waveform envelopes
sorts.waveEnvelope = calculateWaveEnvelopes(waveforms.waves, waveforms.units, maxUnits);

sorts.nPCADims = 0;
sorts.onlineSorted = any(waveforms.units);
sorts.userSorted = 0;
sorts.fullySorted = 1;
sorts.rated = 0;
sorts.maxRatings = zeros(1, maxUnits);
sorts.viewMode = 'Waveform';
sorts.differentiated = 0;
sorts.sorts = [];
