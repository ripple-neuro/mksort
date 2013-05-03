function activateAxes(hf, ha)
% Use instead of axes(ha). If the axes already exist, it skips bringing the
% plot to the front, giving focus, etc. and runs *much* faster (>1000x).
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

try
  set(hf, 'CurrentAxes', ha);
catch
  axes(ha);
end
