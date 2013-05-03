function nTrodes = CCFFilenamesToNTrodeStructs(inDir, ccfNames)
% Take a directory and a cell array of .ccf filenames, turn it into a
% struct array of nTrode structs for use with combineWaveformsForNTrodes or
% nsx2MatWaveforms
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

nTrodes = [];

if ~isempty(ccfNames)
  for array = 1:length(ccfNames)
    if length(ccfNames) == 1
      arrayName = NaN;
    else
      arrayName = array;
    end
    infoPackets = CCF_read(fullfile(inDir, ccfNames{array}));
    nTrodes = [nTrodes infoPacketsToSpikegroups(infoPackets, arrayName)]; %#ok<AGROW>
  end
end
