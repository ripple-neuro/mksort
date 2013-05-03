function waveforms = createWaveformsStruct(electrode, theseWaves, theseUnits, spikeTimes, array, maxUnits)
% waveforms = createWaveformsStruct(electrode, theseWaves, theseUnits, spikeTimes, array, maxUnits)
%
% This function takes parameters for a channel and creates a waveforms
% structure, as used to store sorting data for each channel.
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

waveforms.electrode = electrode;
waveforms.waves = theseWaves;
waveforms.alignedWaves = [];
waveforms.alignMethodFcn = '';
waveforms.units = theseUnits;
waveforms.sorted = 0;
waveforms.array = array;
waveforms.ratings.ratings = zeros(1, maxUnits);
waveforms.ratings.epoch = [];
waveforms.trialInfo = [];
waveforms.spikeTimes = spikeTimes;
