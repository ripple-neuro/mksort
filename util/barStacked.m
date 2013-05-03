function barStacked(binEdges, vals, colors)
% barStacked(binEdges, vals, colors)
%
% Produces a stacked bar graph.
% binEdges should be as in histc, vals should be bins x nStacks, and colors
% should be a cell array of colors (either letters or RGB triplets).
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

for b = 1:length(binEdges)-1
  for v = 1:size(vals, 2)
    vStart = sum(vals(b, 1:v-1));
    if vals(b,v) > 0
      rectangle('Position', ...
        [binEdges(b) vStart binEdges(b+1)-binEdges(b) vals(b,v)], ...
        'FaceColor', colors{v}, 'EdgeColor', colors{v});
    end
  end
end
