function joined = strJoin(strs, sep)
% joined = strJoin(strs, sep)
%
% Takes a cell array of strings strs and a string sep to act as a
% separator, and returns a string with the members of strs joined by sep.
% There is not an extra sep at the end.
% E.g.,
%
% strJoin({'Matlab', 'should', 'handles', 'strings', 'better'}, '! ')
% returns
% 'Matlab! should! handle! strings! better!'
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

if nargin < 2, error('strJoin:tooManyArgs', 'strJoin takes exactly two arguments'); end;
if ~iscell(strs) || ~ischar(sep), error('strJoin:nonStringArgs', 'strJoin takes a cell array of strings and a string as arguments'); end;

if isempty(strs)
  joined = '';
  return;
end

newStrs = cellfun(@(x) [x sep], strs, 'UniformOutput', false);
newStrs{end} = strs{end};
joined = [newStrs{:}];