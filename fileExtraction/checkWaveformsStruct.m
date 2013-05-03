function success = checkWaveformsStruct(w)
% success = checkWaveformsStruct(w)
%
% Check for validity of waveforms struct. Basic checks, mostly.
% If the struct is invalid, this function will produce a msgbox with useful
% info about what went wrong, then throw an error. The success variable is
% redundant, really, but will be 1 if the function completes.
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


%% Fields to check for
requiredFields = {'electrode', 'spikeTimes', 'waves', 'alignedWaves', 'alignMethodFcn', ...
  'units', 'sorted', 'array', 'ratings', 'trialInfo'};
% Fields within .ratings
ratingsFields = {'ratings', 'epoch'};



%% Classes for each field.
% Note that below trialInfo is intentionally omitted. If new fields are
% added to check, trialInfo should still come at the end. This is because
% it can be either a struct or [], so it's trickier to test for.
fieldClasses = {'double', 'double', 'double', 'double', 'char', ...
  'double', 'double', 'double', 'struct'};
ratingsClasses = {'double', 'double'};



%% Check main level required fields
fields = fieldnames(w);
missingFields = find(~ismember(requiredFields, fields));

% Check for structure
if ~isempty(missingFields)
  strs = cellfun(@(x) [x ', '], requiredFields(missingFields), 'UniformOutput', false);
  strs{end} = strs{end}(1:end-2);
  uiwait(msgbox(sprintf('Bad waveforms file. Missing field(s) %s', [strs{:}])));
  error('checkWaveformsStruct:badStructure', 'Bad waveforms file');
end

% Check for class
for f = 1:length(fieldClasses)
  if ~strcmp(class(w.(requiredFields{f})), fieldClasses{f})
    uiwait(msgbox(sprintf('Field .%s is of incorrect class. Should be %s.', requiredFields{f}, fieldClasses{f})));
    error('checkWaveformsStruct:badFieldClass', 'Bad waveforms file');
  end
end



%% Check fields for ratings sub-struct
if ~isstruct(w.ratings)
  uiwait(msgbox('Bad waveforms file. .ratings must be a struct'));
  error('checkWaveformsStruct:badStructure', 'Bad waveforms file');
end

fields = fieldnames(w.ratings);
missingFields = find(~ismember(ratingsFields, fields));

% Check for structure
if ~isempty(missingFields)
  strs = cellfun(@(x) [x ', '], ratingsFields(missingFields), 'UniformOutput', false);
  strs{end} = strs{end}(1:end-2);
  uiwait(msgbox(sprintf('Bad waveforms file. Missing field(s) from .ratings sub-struct: %s', [strs{:}])));
  error('checkWaveformsStruct:badStructure', 'Bad waveforms file');
end

% Check for class
for f = 1:length(ratingsClasses)
  if ~strcmp(class(w.ratings(1).(ratingsFields{f})), ratingsClasses{f})
    uiwait(msgbox(sprintf('Field .%s is of incorrect class. Should be %s.', requiredFields{f}, fieldClasses{f})));
    error('checkWaveformsStruct:badFieldClass', 'Bad waveforms file');
  end
end



%% Check lengths of arrays
nWaves = length(w.spikeTimes);

if size(w.waves, 2) ~= nWaves
  uiwait(msgbox('Bad waveforms file. .waves must be size nPts x nWaves'));
  error('checkWaveformsStruct:badArrayLengths', 'Bad waveforms file');
end

if ~isempty(w.alignedWaves) && size(w.alignedWaves, 2) ~= nWaves
  uiwait(msgbox('Bad waveforms file. .alignedWaves must be either empty or size (nPts or less) x nWaves'));
  error('checkWaveformsStruct:badArrayLengths', 'Bad waveforms file');
end

if length(w.units) ~= nWaves
  uiwait(msgbox('Bad waveforms file. .units must be length nWaves'));
  error('checkWaveformsStruct:badArrayLengths', 'Bad waveforms file');
end



%% Why not.
success = 1;
