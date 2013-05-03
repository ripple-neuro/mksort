function axLims(limits)
% Use instead of axis(axLim) to set axis limits. Skips whatever else axis
% does, runs *much* faster (>1000x).
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

ha = gca;
try
  set(ha, 'XLim', limits(1:2));
  set(ha, 'YLim', limits(3:4));
catch
  axis(limits);
end
