function fn = makeWaveFilename(lett, electrode)
% fn = makeWaveFilename(lett, electrode)
%
% Takes an array letter (empty string for no array letter because user has
% only one array) and an electrode number, and produces the appropriate
% waveforms file name. Examples:
%
% makeWaveFilename('A', 3) yields 'waveforms_A_003.mat'
% makeWaveFilename('', 3) yields 'waveforms_003.mat'
%
% Also handles n-trodes. Examples:
%
% makeWaveFilename('A', [1 3]) yields 'waveforms_A_001_003.mat'
% makeWaveFilename('', [1 3]) yields 'waveforms_001_003.mat'
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

elecStrs = arrayfun(@(x) sprintf('%03d', x), electrode, 'UniformOutput', false);
elecStr = strJoin(elecStrs, '_');

if ~isempty(lett)
  fn = sprintf('waveforms_%s_%s.mat', lett, elecStr);
else
  fn = sprintf('waveforms_%s.mat', elecStr);
end

