function units = sortWaveformsEngine(method, waveforms, PCAPts, sorts, varargin)
% This is the master waveform-sorting function.
%
% waveforms should be a matrix of waveforms, nPts x nWaveforms
%
% Note: all points supplied should be relevant. Thus, if using a
% Template-type sort that starts at point 6 and ends at point 24, waveforms
% should be size (19 x nWaveforms).
%
% Optional argument is a vector of indices for these waves. This is needed
% to make sorting selected waveforms work with epochs, since we need to
% know which epoch each spike is in. Kind of a hack, but if you're not
% sorting all the waveforms, use this.
%
% units is a vector nWaveforms long of which unit each waveform belongs to.
%
% Calls appropriate sort-method-type sort function.
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

if isempty(varargin)
  units = feval(['sortBy' method.type], method, waveforms, PCAPts, sorts);
else
  units = feval(['sortBy' method.type], method, waveforms, PCAPts, sorts, varargin{1});
end
