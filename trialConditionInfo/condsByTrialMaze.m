function [conditions, trStarts, trEnds] = condsByTrialMaze(R, array)
% [conditions, trStarts, trEnds] = condsByTrialMaze(R, array)
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

AB = 'AB';
if isnan(array), array = 1; end;
cerField = ['CerebusInfo' AB(array)];

for tr = 1:length(R)
  if ~isempty(R(tr).(cerField)) && R(tr).success && ~R(tr).possibleRTproblem
    moveOnset = R(tr).offlineMoveOnsetTime;
    trStarts(tr) = R(tr).(cerField).startTime * 1000 + moveOnset + startRelToMove;
    trEnds(tr) = R(tr).(cerField).startTime * 1000 + moveOnset + endRelToMove;
  end
end

mazes = zeros(length(R), 2);

for tr = 1:length(R)
  mazes(tr, 1) = R(tr).mazeID;
  mazes(tr, 2) = R(tr).trialVersion;
end

uniqueMazes = unique(mazes, 'rows');

% Throw away randomly generated mazes
uniqueMazes(uniqueMazes(:, 1) == 0, :) = [];
% Throw away novel variants
uniqueMazes(uniqueMazes(:, 2) > 9, :) = [];

conditions = NaN * zeros(1, length(R));
for tr = 1:length(R)
  match = find(mazes(tr, 1) == uniqueMazes(:, 1) & mazes(tr, 2) == uniqueMazes(:, 2));
  if ~isempty(match)
    conditions(tr) = match;
  end
end

