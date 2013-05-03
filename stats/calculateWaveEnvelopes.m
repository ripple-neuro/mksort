function envelopes = calculateWaveEnvelopes(waves, units, maxUnits)
% envelopes = calculateWaveEnvelopes(waves, units, maxUnits)
%
% Calculate the 5% and 95% quantiles of the waveforms for each unit.
%
% NOTE: This file requires the statistics toolbox. It would be nice to
% remove this dependence.
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

uniqueUnits = unique(units);
for unit = 1:maxUnits
  if ismember(unit, uniqueUnits)
    unitWaves = waves(:, units == unit)';
    quantiles = quantile_mksort(unitWaves, [0.05 0.95], 1);
    envelopes(unit).bottom = quantiles(1, :);
    envelopes(unit).top = quantiles(2, :);
  else
    envelopes(unit).bottom = [];
    envelopes(unit).top = [];
  end
end
