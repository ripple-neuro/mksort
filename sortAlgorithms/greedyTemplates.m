function [units, unitsDefined] = greedyTemplates(Template, waves, waveStart)
% [units, unitsDefined] = greedyTemplates(Template, waves, waveStart)
%
%
% Input values:
%
% Template  -- the Template sort structure from oneChannelSorter
%
% waves     -- the waveforms array to sort; it should be (nPts x nWaves)
%
% waveStart -- the index of the first point in waves. This is needed so
%              that we can line up the start of the template with the
%              waveforms
%
%
% Output values:
%
% units        -- this is an (nUnitsDefined x nWaves) logical matrix, where
%                 each row corresponds to the unit in unitsDefined and each
%                 value is the score for that wave on that template (higher
%                 is better).
%
% unitsDefined -- which units are defined by templates. Note that if values
%                 are skipped, there will be no row for the skipped value
%                 in units!
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

acceptanceFactor = 0.001;

unitsDefined = [];

% Figure out which units are defined
% Start at 2 since we don't care about the 0-unit and params has an entry
% for it
for u = 2:length(Template.params)
  if ~isempty(Template.params(u).inTemplate)
    unitsDefined(end+1) = u - 1;
  end
end


origWaves = waves;
units = zeros(length(unitsDefined), size(waves, 2));

for u = 1:length(unitsDefined)
  unit = unitsDefined(u);
  
  means = Template.params(unit+1).inTemplate.means;
  stds = Template.params(unit+1).inTemplate.stds;
  
  % Determine alignment
  templateStart = Template.params(unit+1).templateStart;
  
  if waveStart < templateStart
    firstPt = templateStart-waveStart+1;
    waves = origWaves(firstPt:end, :);
  elseif waveStart > templateStart
    firstPt = waveStart - templateStart + 1;
    means = means(firstPt:end);
    stds = stds(firstPt:end);
    waves = origWaves;
  else
    waves = origWaves;
  end
  
  lastPt = min(length(means), size(waves, 1));
  waves = waves(1:lastPt, :);
  means = means(1:lastPt, :);
  stds = stds(1:lastPt, :);
  
  % Exclude rows with little variation, since they'll mess up normalization
  % and don't actually contain any information. Use > 1.5 because in
  % practice this also captures the alignment point.
  goodRows = (stds > 1.5);
  
  templateMeans = repmat(means, [1 size(waves, 2)]);
  templateStds = repmat(stds, [1 size(waves, 2)]);
  allScores = (waves - templateMeans) ./ templateStds;
  scores = mean(abs(allScores(goodRows, :))) / sum(goodRows);
  units(u, :) = (1 / u) .* (scores <= Template.params(unit+1).acceptance * acceptanceFactor);
end
