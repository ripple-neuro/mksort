% produces a blank figure with everything turned off
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

function hf = blankFigure(varargin)

hf = figure; hold on; 
set(gca,'visible', 'off');
set(hf, 'color', [1 1 1]);
if ~isempty(varargin)
  axis(varargin{1});
end
axis square;
