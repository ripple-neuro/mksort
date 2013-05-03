function [r, c] = ind2subFast(siz, inds)
% [r, c] = ind2subFast(siz, inds)
%
% Like ind2sub, but fast
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

c = 1 + floor(inds/siz(1));
r = rem(inds, siz(1));
