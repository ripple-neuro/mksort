function [conditions, trStarts, trEnds] = condsByTrialSlider(R, array)
% [conditions, trStarts, trEnds] = condsByTrialSlider(R, array)
%
% For use with trialInfoFromR. Parses an R struct from the slider-maze
% paradigm.
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

answer = inputdlg('saveTags to use, leave blank for all:', 'saveTags');
saveTags = [];
try
  saveTags = eval(answer{1});
catch
  warning('Could not evaluate user response, using all saveTags');
end
if isempty(saveTags)
  saveTags = unique([R.saveTag]);
end

maxMoveDur = 600;

startRelToMove = -100;
endRelToMove = 300;


AB = 'AB';
if isnan(array), array = 1; end;
cerField = ['CerebusInfo' AB(array)];


% Figure out starts and ends for each trial
trStarts = NaN * zeros(1, length(R));
trEnds = NaN * zeros(1, length(R));

for tr = 1:length(R)
  if ~isempty(R(tr).(cerField)) && R(tr).success && ismember(R(tr).saveTag, saveTags) && R(tr).onlineMoveDur <= maxMoveDur
    moveOnset = R(tr).offlineMoveOnsetTime;
    trStarts(tr) = R(tr).(cerField).startTime * 1000 + moveOnset + startRelToMove;
    trEnds(tr) = R(tr).(cerField).startTime * 1000 + moveOnset + endRelToMove;
  end
end

mazes = zeros(length(R), 2);

for tr = 1:length(R)
  mazes(tr, 1) = R(tr).mazeID;
  mazes(tr, 2) = R(tr).whichFly;
end

uniqueMazes = unique(mazes, 'rows');

% Remove failures
uniqueMazes(uniqueMazes(:, 2) == 0, :) = [];

conditions = NaN * zeros(1, length(R));
for tr = 1:length(R)
  match = find(mazes(tr, 1) == uniqueMazes(:, 1) & mazes(tr, 2) == uniqueMazes(:, 2));
  if ~isempty(match)
    conditions(tr) = match;
  end
end
