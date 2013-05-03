function [waveforms, sorts, PCAPts, filename] = sortOneChannelWithoutCache(sorts, dataDir)
% [waveforms, sorts, PCAPts, filename] = sortOneChannelWithoutCache(sorts, dataDir)
%
% This function sorts one channel worth of data using the sorts structure
% passed to it and the corresponding waveforms file in dataDir. Note the
% the sorts structure should contain only one channel's worth of data.
% Intended for use with 'sort modified channels' button in the MKSORT main
% application, and for use with determining TTP durations from broadband
% (where waveforms from a broadband file must be sorted).
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

% Load waveforms file
alpha = alphabet();
if isnan(sorts.array)
  lett = '';
else
  lett = alpha(sorts.array);
end
filename = makeWaveFilename(lett, sorts.electrode);
try
  loadVar = load(fullfile(dataDir, filename));
catch
  uiwait(msgbox(sprintf('Failed to load file: %s', fullfile(dataDir, filename)), 'Load failed'));
  error('Could not load waveforms file');
end

waveforms = loadVar.waveforms;
clear loadVar

% Check whether waves are already correctly aligned. If not, align them.
if isempty(waveforms.alignedWaves) || ~(strcmp(sorts.sorts(1).alignMethodFcn, waveforms.alignMethodFcn) || ...
    (strcmp(sorts.sorts(1).alignMethodFcn, 'noAlign') && isempty(waveforms.alignMethodFcn)))
  waveforms.alignedWaves = feval(sorts.sorts(1).alignMethodFcn, waveforms.waves);
  waveforms.alignMethodFcn = sorts.sorts(1).alignMethodFcn;
end

% Set up method structure to pass in for sorting
method.classifyFcn = sorts.sorts(1).sortMethodFcn;
method.type = sorts.sorts(1).sortMethodType;

% If we're using PCA, convert the points. I wish this didn't have to be
% here, but I can't think of a better way to do this.
if strcmp(method.type, 'PCAEllipses');
  coeffs = sorts.sorts(1).PCAEllipses.PCACoeffs(1:sorts(1).nPCADims, :);
  if sorts.differentiated
    PCAPts = coeffs * zscore_mksort(diff(waveforms.alignedWaves), 2);
  else
    PCAPts = coeffs * zscore_mksort(waveforms.alignedWaves, 2);
  end
else
  PCAPts = [];
end

% Do the actual sorting
wLims = sorts.sorts(1).(method.type).waveLims;
if sorts.differentiated
  waveforms.units = sortWaveformsEngine(method, diff(waveforms.alignedWaves(wLims(1):wLims(2),:)), PCAPts, sorts.sorts);
else
  waveforms.units = sortWaveformsEngine(method, waveforms.alignedWaves(wLims(1):wLims(2),:), PCAPts, sorts.sorts);
end

% Update ratings and sorted fields in waveforms struct
for epoch = 1:length(sorts.sorts)
  waveforms.ratings(epoch).ratings = sorts.sorts(epoch).(method.type).ratings;
  waveforms.ratings(epoch).epoch = [sorts.sorts(epoch).epochStart sorts.sorts(epoch).epochEnd];
end
waveforms.sorted = 1;

% Note in sorts that we're now fully sorted
sorts.fullySorted = 1;
