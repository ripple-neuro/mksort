function [conditions, trStarts, trEnds] = condsByTrialSimple(R, array)
% [conditions, trStarts, trEnds] = condsByTrialSimple(R, array)
%
% For use with trialInfoFromR. Parses an R struct from the maze paradigm.
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

startRelToMove = -100;
endRelToMove = 300;

% Figure out starts and ends for each trial
trStarts = NaN * zeros(1, length(R));
trEnds = NaN * zeros(1, length(R));

for tr = 1:length(R)
  if ~isempty(R(tr).CerebusInfo) && R(tr).success
    moveOnset = R(tr).moveOnsetTime;
    trStarts(tr) = R(tr).CerebusInfo.startTime * 1000 + moveOnset + startRelToMove;
    trEnds(tr) = R(tr).CerebusInfo.startTime * 1000 + moveOnset + endRelToMove;
  end
end

conditions = [R.condition];
