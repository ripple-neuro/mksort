function units = sortByTemplate(method, waveforms, PCAPts, sorts, varargin)
% The master sort function for the Template sort type. Calls both the
% actual template sorting function selected and sorts by hoops, then
% combines the outputs.
%
% See sortWaveformsEngine() above for an explanation of the optional argument.
%
% To specify a Template-type template sorting function, it should have the
% prototype:
% [templateUnits, templateUnitsDefined] = fcnName(Template, waveforms, wavesStart)
%   where waveStart is the first point specified in the waveforms matrix
%   (needed to align the template with the waveforms).
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

if isempty(waveforms)
  units = [];
  return;
end

units = zeros(1, size(waveforms, 2));
% Figure out indices of waves so that we sort using values from the right
% epoch
if ~isempty(varargin)
  waveIndices = varargin{1};
else
  waveIndices = [];
end
for epoch = 1:length(sorts)
  if isempty(waveIndices)
    thisEpoch = false(1, size(waveforms, 2));
    thisEpoch(sorts(epoch).epochStart:sorts(epoch).epochEnd) = 1;
  else
    thisEpoch = (waveIndices >= sorts(epoch).epochStart & waveIndices <= sorts(epoch).epochEnd);
  end
  
  waveStart = sorts(epoch).Template.waveLims(1);
  
  % Sort by hoops
  [hoopsUnits, hoopsUnitsDefined] = sortHoops(sorts(epoch).Template, waveforms(:, thisEpoch), waveStart);
  % Sort by templates
  [templateScores, templateUnitsDefined] = feval(method.classifyFcn, sorts(epoch).Template, waveforms(:, thisEpoch), waveStart);

  % Combine output of hoops and templates
  units(thisEpoch) = combineSortSources(templateScores, hoopsUnits, templateUnitsDefined, hoopsUnitsDefined);
end



function units = combineSortSources(scores1, scores2, s1Units, s2Units)
% This lets us combine sorts from both hoops and templates. scores1 is
% sort scores from source 1, scores2 is sort scores from source 2, s1Units
% is which units are defined using sort method 1, etc.
%
% If a unit is only defined by one sort source, that's fine. Otherwise, we
% require that both sources agree about a waveform's identity. In this
% case, the score for a unit in scores1 takes precedence. If an event can
% be classified a unit using source 1 and a unit using only source 2, the
% unit with source 1 takes the event.

units = zeros(1, max(size(scores1, 2), size(scores2, 2)));

% Since an event that can be sorted into a unit using source 1 will always
% take precedence over a unit sorted by source 2 alone, we'll first apply
% sorting for units using source 2 alone, then overwrite those sorts as
% necessary.

s2OnlyUnits = find(~ismember(s2Units, s1Units));
if ~isempty(s2OnlyUnits)
  [maxes, unitsS2] = max(scores2(s2OnlyUnits, :), [], 1);
  classified = (maxes ~= 0);
  units(classified) = s2Units(s2OnlyUnits(unitsS2(classified)));
end


if ~isempty(s1Units)
  % Now we account for source 2's ability to veto when using both sources
  bothSourceUnits = s1Units(ismember(s1Units, s2Units));
  if ~isempty(bothSourceUnits)
    s1Indices = ismember(s1Units, bothSourceUnits);
    s2Indices = ismember(s2Units, bothSourceUnits);
    scores1(s1Indices, :) = scores1(s1Indices, :) .* (scores2(s2Indices, :) > 0);
  end

  [maxes, unitsS12] = max(scores1, [], 1);
  classified = (maxes ~= 0);
  unitsS12(~classified) = 0;
  unitsS12(classified) = s1Units(unitsS12(classified));

  % Finally, overwrite the sorts we can using the source 1 sorts (with source
  % 2's veto power already factored in)
  eventsToOverwrite = (unitsS12 > 0);
  units(eventsToOverwrite) = unitsS12(eventsToOverwrite);
end



function [units, unitsDefined] = sortHoops(Template, waves, waveStart)
% Sort by hoops.
%
% Output values:
%
% units        -- this is an (nUnitsDefined x nWaves) scores matrix, where
%                 each row corresponds to the unit in unitsDefined and each
%                 value is non-zero if that wave matched those hoops, and
%                 greater for lower-numbered units (i.e., they are scores).
%
% unitsDefined -- which units are defined by templates. Note that if values
%                 are skipped, there will be no row for the skipped value
%                 in units!

% Figure out which units are defined
unitsDefined = [];
% Start at 2 since we don't care about the 0-unit and params has an entry
% for it
for u = 2:length(Template.params)
  if ~isempty(Template.params(u).hoops)
    unitsDefined(end+1) = u - 1;
  end
end

units = true(length(unitsDefined), size(waves, 2));

for u = 1:length(unitsDefined)
  unit = unitsDefined(u);
  
  % In hoops, each row is a hoop, and the three columns are x and the
  % two y values. Don't rely on the y values being in the right order.
  for h = 1:size(Template.params(unit+1).hoops, 1)
    hoopX = Template.params(unit+1).hoops(h, 1);
    hoopY = Template.params(unit+1).hoops(h, 2:3);
    x = hoopX - waveStart + 1;
    yMin = min(hoopY);
    yMax = max(hoopY);

    if x <= size(waves, 1)
      units(u, :) = units(u, :) & (waves(x, :) >= yMin) & (waves(x, :) <= yMax);
    else
      uiwait(msgbox(sprintf('Hoop outside waveform window. Unit %d will not be sorted.', unit)));
    end
  end
end

if ~isempty(unitsDefined)
  unitScores = 1 ./ (1 + unitsDefined)';
  units = bsxfun(@times, units, unitScores);
end
