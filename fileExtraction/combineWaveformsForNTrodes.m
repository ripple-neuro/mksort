function combineWaveformsForNTrodes(inDir, nTrodes)
% combineWaveformsForNTrodes(inDir, nTrodes)
%
% Called by dataImportWizard. Takes the directory of extracted waveforms
% files and the output of CCFFilenamesToNTrodeStructs. Loads the waveforms
% files from those electrodes involved in n-trodes, and replaces them with
% new waveforms files with concatenated waveforms and appropriate metadata.
% Also alters previews.mat and sorts.mat as appropriate.
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


if isempty(nTrodes)
  return;
end


%% Load sorts and previews

try
  sorts = loadOneStruct(fullfile(inDir, 'sorts.mat'));
catch
  error('combineWaveformsForNTrodes:sortsLoadFailed', 'Failed to load sorts.mat');
end

try
  previews = loadOneStruct(fullfile(inDir, 'previews.mat'));
catch
  error('combineWaveformsForNTrodes:previewsLoadFailed', 'Failed to load previews.mat');
end


%% Other setup

alpha = alphabet();
waveformsFilesToDelete = {};
sortsToDelete = false(1, length(sorts));



%% Loop through nTrodes
for nt = 1:length(nTrodes)
  
  %% Set up
  members = nTrodes(nt).members;
  
  % Check for degenerate case, just in case
  if length(members) == 1
    continue;
  end
  
  % Get array letter
  if isnan(nTrodes(nt).array)
    lett = '';
  else
    lett = alpha(nTrodes(nt).array);
  end
  
  
  %% Loop through nTrode members, load all waveforms files
  for m = 1:length(members)
    % Load this waveforms file
    filename = fullfile(inDir, makeWaveFilename(lett, members(m)));
    try
      loadVar = load(filename);
    catch
      error('combineWaveformsForNTrodes:waveformsLoadFailed', 'Failed to load %s', filename);
    end
    waveformsFilesToDelete{end+1} = filename;
    
    % Add to struct array ('aw' is 'all waveforms')
    aw(m) = loadVar.waveforms; %#ok<AGROW>
  end
  clear loadVar
  
  
  
  %% Combine waveforms files
  
  % Use array of electrode numbers
  electrode = [aw.electrode];
  % vertcat of waves strings times end to end
  waves = vertcat(aw.waves);
  
  % Everything else comes from first member
  units = aw(1).units;
  spikeTimes = aw(1).spikeTimes;
  array = aw(1).array;
  maxUnits = length(aw(1).ratings(1).ratings);
  
  % Create the basic waveforms struct
  waveforms = createWaveformsStruct(electrode, waves, units, spikeTimes, array, maxUnits);
  
  % Add back trialInfo
  waveforms.trialInfo = aw(1).trialInfo;
  
  % If sourceFiles was present, add it back
  if isfield(aw(1), 'sourceFiles')
    waveforms.sourceFiles = aw(1).sourceFiles;
  end
  
  %% Save combined waveforms file
  
  waveFilename = makeWaveFilename(lett, electrode);
  save(fullfile(inDir, waveFilename), 'waveforms', '-v7');
  
  
  
  %% Identify old sorts and previews entries
  
  if isnan(nTrodes(nt).array)
    rightArray = true(1, length(sorts));
  else
    rightArray = ([sorts.array] == nTrodes(nt).array);
  end
  
  memberElectrode = ismember([sorts.electrode], members);
  
  sortsToDelete = (sortsToDelete | (rightArray & memberElectrode));
  sortsInds = find(rightArray & memberElectrode);
  
  
  %% Generate new sorts and previews entries
  
  lockout = sorts(sortsInds(1)).autocorrs(1).lockout;
  
  [newPreviews(nt), newSorts(nt)] = generateSortsAndPreviews(waveforms, maxUnits, lockout);
  
  newSorts(nt).onlineSorted = sorts(sortsInds(1)).onlineSorted || sorts(sortsInds(1)).userSorted;
%   newSorts(nt).viewMode = 'PCA';
end




%% Remove outdated entries in previews, add new at end, save
previews = previews(~sortsToDelete);
previews = [previews newPreviews];
save(fullfile(inDir, 'previews.mat'), 'previews', '-v6');


%% Remove outdated entries in sorts, add new at end, save
sorts = sorts(~sortsToDelete);
sorts = [sorts newSorts];
save(fullfile(inDir, 'sorts.mat'), 'sorts', '-v6');


%% Delete old waveforms files
for w = 1:length(waveformsFilesToDelete)
  delete(waveformsFilesToDelete{w});
end


