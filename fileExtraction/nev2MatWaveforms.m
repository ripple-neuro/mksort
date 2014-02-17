function nev2MatWaveforms(inDir, outDir, nevNames, artifactThresh, snippetLen, firstSnippetPt, conserveMemory)
% nev2MatWaveforms(inDir, outDir, nevNames)
% nev2MatWaveforms(inDir, outDir, nevNames, artifactThresh)
% nev2MatWaveforms(inDir, outDir, nevNames, artifactThresh, snippetLen)
% nev2MatWaveforms(inDir, outDir, nevNames, artifactThresh, snippetLen, firstSnippetPt)
% nev2MatWaveforms(inDir, outDir, nevNames, artifactThresh, snippetLen, firstSnippetPt, conserveMemory)
%
% Files load from inDir and outputs saved to outDir
%
% nevNames should be an nArrays-long cell array, with each cell containing
% an nFiles-long cell array of strings.
%
% artifactThresh (optional) specifies how big a point in a waveform is
% allowed to be before we consider it an artifact and throw it away. Sign
% does not matter, specify in mV. Default is Inf.
%
% snippetLen is an optional argument specifying the maximum length of
% snippets to extract. Default 32.
%
% firstSnippetPt is an optional argument specifying the first point of the
% snippet within the .nev file to save (i.e., it will save points
% firstSnippetPt : firstSnippetPt+snippetLen-1). Default 1.
%
% conserveMemory is an optional argument which, if set to non-zero, will
% read smaller chunks of the file at a time and thereby help prevent
% running out of memory. Makes the extract go slower and creates/deletes
% many more files, though. Default 0.
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


%% Parameters

maxUnits = 4;

RRRlockout = 0.5; % the lockout period used in online RRR sorting

if ~exist('artifactThresh', 'var')
  artifactThresh = Inf;  % Max size in mV before we consider a waveform an artifact
end
if ~exist('snippetLen', 'var')
  snippetLen = 32;  % samples per waveform to save down
end
if ~exist('firstSnippetPt', 'var')
  firstSnippetPt = 1;
end
% Controls how many packets are read in a chunk.
% Make this number bigger and the program will do fewer loads/saves, but
% you may run out of memory.
if ~exist('conserveMemory', 'var') || conserveMemory == 0
  nPacketsToRead = 1000000;
else
  nPacketsToRead = 200000;
end



alpha = alphabet();

%% Initialize flags and accumulator variables

allChunkFileInfo = {};
lockoutViolations = 0;
flagrantLockoutViolations = 0;
fracNonCrossers = [];
remLockoutViol = [];
nthFile = 0;

chunkDir = tempname;
status = mkdir(chunkDir);
if ~status
  chunkDir = outDir;
end



%% Main loop through files

if isempty(nevNames)
  error('nev2MatWaveforms:noFiles', 'No files specified');
end

% Go through each file, process it in chunks and save down the data chunks.
% We'll combine these chunks at the end.
fprintf('Processing files\n');
nTotalFiles = sum(cellfun(@length, nevNames));
for arr = 1:length(nevNames)
  for fileNum = 1:length(nevNames{arr})
    %% Bookkeeping related to this file
    if length(nevNames) == 1
      lett = '';
    else
      lett = alpha(arr);
    end
    filename = nevNames{arr}{fileNum};

    nthFile = nthFile + 1;
    fprintf('File %d/%d: ', nthFile, nTotalFiles);
    
    inFile = fullfile(inDir, filename);
    
    
    %% Get spikeTimes and units (once per file)
    fprintf('spike times; ');
    spikes = nev2MatSpikesOnly(inFile);
    spikeTimes = spikes(:, 2)' * 1000;
    
    
    %% Open .nev file
    [fid, message] = fopen(inFile, 'rb', 'l');
    if fid == -1
      warning(['Unable to open file: ' filename ', error message ' message]); %#ok<WNTAG>
      return;
    end
    
    
    %% Read headers
    [header, spikeheaders] = NEVGetHeaders(fid);
    if isempty(header)
      warning(['Unable to read headers in file: ' filename ', error message ' message]); %#ok<WNTAG>
      fclose(fid);
      return;
    end
    
    
    %% Figure out how many bytes per sample in waveforms
    waveBytesPerSample = unique([spikeheaders.numberbytes]);
    if length(waveBytesPerSample) ~= 1
      error('nev2MatWaveforms: Different units have different sampling of waveforms');
    end
    
    
    %% Figure out scaling factors
    % Doesn't deeply need to be unique, but let's hope it is and not write
    % the code to handle if it isn't unless we have to.
    
    %   spikeHeaderIDs = [spikeheaders.id];
    allScaleFactors = [spikeheaders.sf];
    % If Ripple data is found use the valid NEUEVWAV headers to identify
    % good channels.
    if ~isempty(strfind(header.AppName, 'Trellis'))
        channelsUsed = find([spikeheaders(:).existNEUEVWAV]==1);  
    % In the case of Black Rock data, the channel counts should always be 1
    % through 128.
    else 
        channelsUsed = 1:128;
    end
    % Convert scaling to uV
    scaleFactor = unique(allScaleFactors(channelsUsed)) / 1000;
    if length(scaleFactor) ~= 1
      error('nev2MatWaveforms: Different units have different scale factors');
    end

    
    %% Find which electrodes/units are recorded in the file
    allElectrodeNums = floor(spikes(:, 1))';
    allUnits = round(mod(spikes(:, 1)', 1) * 100);
    
    
    %% Figure out lockout period
    % This is the number of waveform samples divided by the sampling rate,
    % converted into ms. This may be overridden at the end if lockout
    % violations are found. Violations imply either that RRR was used, which
    % has a shorter lockout, or that a buggy version of the Cerebus software
    % was used, which can add extraneous events.
    snippetLockout = 1000 * ((header.datasize - 8) / waveBytesPerSample) / header.SampleRes;
    
    
    %% Check for lockout violations
    [lockout, lockoutViolations, flagrantLockoutViolations] = ...
      checkForLockoutViolations(spikeTimes, allElectrodeNums, snippetLockout, lockoutViolations, flagrantLockoutViolations, RRRlockout);
    
    
    %% Read/save every chunk until finished
    % Each will be saved down separately, then recombined at the end
    complete = 0;
    firstSpike = 1;
    chunki = 0;
    fprintf('waveforms chunk ');
    
    while (~complete)
      chunki = chunki + 1;
      fprintf('%d ', chunki);
      
      % Read the chunk
      [waves, complete] = readNevWaveformsChunk(fid, header, waveBytesPerSample, scaleFactor, nPacketsToRead, snippetLen, firstSnippetPt);
      
      nWavesRead = size(waves, 2);
      
      %% Parcel out waveforms to appropriate waveform chunk files
      
      % Values corresponding to this data chunk
      indices = firstSpike:firstSpike+nWavesRead-1;
      electrodeNums = allElectrodeNums(indices);
%      electrodesInChunk = unique(electrodeNums);
      % current Ripple data may contain spike markers which are delivered
      % in NEV packets but with an electrode ID of 5120 + the electrode ID.
      % Here we require that electrode IDs are less than 512.
      electrodeNums = electrodeNums(electrodeNums <= 512);
      electrodesInChunk = unique(electrodeNums);
      unitNums = allUnits(indices);
      chunkSpikeTimes = spikeTimes(indices);
      
      for electrode = electrodesInChunk
        %% Data for this electrode
        thisElectrode = (electrodeNums == electrode);
        theseWaves = waves(:, thisElectrode);
        theseUnits = unitNums(thisElectrode);
        
        %% Handle chunk file basics
        % Get chunk file filename
        chunkFilename = makeChunkFilename(chunkDir, lett, electrode, fileNum, chunki);
        
        
        %% Chunk bookkeeping
        % If we don't have a list of fileNum's and chunki's for this
        % array/electrode pair, initialize it with []
        if any(size(allChunkFileInfo) < [arr, electrode])
          allChunkFileInfo{arr, electrode} = []; %#ok<AGROW>
        end
        
        allChunkFileInfo{arr, electrode}(end+1, :) = [fileNum, chunki]; %#ok<AGROW>
        
         
        %% Create waveforms data structure for this chunk
        if length(nevNames) == 1
          array = NaN;
        else
          array = arr;
        end
      
        waveforms = createWaveformsStruct(electrode, theseWaves, theseUnits, chunkSpikeTimes(thisElectrode), array, maxUnits); 
        
        % Keep track of where the chunk came from. This field will get
        % overwritten when chunks are stitched together.
        waveforms.sourceFiles = filename;
        
        
        %% Save chunk file
        % Use -v6 to save uncompressed for speed (these files get deleted
        % later).
        save(chunkFilename, 'waveforms', '-v6');
      end

      firstSpike = firstSpike + nWavesRead;
    end
    
    %% Clean up
    fprintf('\n');
    fclose(fid);
  end
end


%% Stitch together chunks into whole channels and generate previews
fprintf('Stitching chunks together, generating previews\n');
fprintf('Channel: ');

% Loop through arrays
usedChs = 0;
for array = 1:size(allChunkFileInfo, 1)
  % Array letter if applicable
  if size(allChunkFileInfo, 1) > 1
    lett = alpha(array);
    fprintf('%s', lett);
  else
    lett = '';
  end
  
  % Loop through electrodes
  for electrode = 1:size(allChunkFileInfo, 2)
    %% Figure out whether this was a used channel
    % Figure out how many chunks for this array/electrode
    chunkInfo = allChunkFileInfo{array, electrode};
    nChunks = size(chunkInfo, 1);
    
    % If this channel was disabled, skip it
    if nChunks == 0
      continue;
    end
    
    fprintf('%d ', electrode);
    
    %% Load all chunks for this channel
    % elecWaveforms will hold all the chunks to be combined in one step at
    % the end
    elecWaveforms = cell(1, nChunks);
    
    % Load chunks, delete chunks files
    for chunk = 1:nChunks
      chunkFilename = makeChunkFilename(chunkDir, lett, electrode, chunkInfo(chunk, 1), chunkInfo(chunk, 2));
      loadVar = load(chunkFilename);
      elecWaveforms{chunk} = loadVar.waveforms;
      
      delete(chunkFilename);
    end
    
    %% Create full waveforms structure for this electrode
    waveforms = elecWaveforms{1};
    waveforms.waves = cellfun(@(x)x.waves, elecWaveforms, 'UniformOutput', false);
    waveforms.waves = [waveforms.waves{:}];
    waveforms.units = cellfun(@(x)x.units, elecWaveforms, 'UniformOutput', false);
    waveforms.units = [waveforms.units{:}];
    waveforms.spikeTimes = cellfun(@(x)x.spikeTimes, elecWaveforms, 'UniformOutput', false);
    waveforms.spikeTimes = [waveforms.spikeTimes{:}];
    waveforms.ratings.epoch = [1 length(waveforms.spikeTimes)];
    waveforms.sourceFiles = chunkFilenamesToSourceFiles(elecWaveforms);
    
    %% Remove artifacts
    % Note that artifactThresh is specified in mV, need to convert to uV
    if ~isinf(artifactThresh)
      maxes = max(abs(waveforms.waves));
      artifacts = (maxes > abs(artifactThresh) * 1000);
      
      waveforms = removeBadSpikes(waveforms, artifacts);
    end
    
    %% If there were refractory violations caused by a Cerebus bug, fix
    % We need to do a two-pass repair: first we'll remove all waveforms
    % that don't cross threshold at the right time, then we'll remove the
    % small number of potentially remaining lockout violators.
    if flagrantLockoutViolations
      %% Find threshold value and sample
      [thresh, threshi] = findThreshold(waveforms.waves);
      
      %% Remove spikes that don't cross threshold at the right time
      if ~isempty(waveforms.waves)
        nonCrossers = (waveforms.waves(threshi-1, :) <= thresh | waveforms.waves(threshi, :) > thresh);
        fracNonCrossers(end+1) = sum(nonCrossers) / size(waveforms.waves, 2); %#ok<AGROW>
        
        waveforms = removeBadSpikes(waveforms, nonCrossers);
      end
      
      %% Find remaining lockout violations
      if ~isempty(waveforms.waves)
        diffs = diff(waveforms.spikeTimes);
        violations = [false (diffs > 0 & diffs < lockout)];
        
        waveforms = removeBadSpikes(waveforms, violations);
        
        remLockoutViol(end+1) = sum(violations); %#ok<AGROW>
      else
        remLockoutViol(end+1) = 0; %#ok<AGROW>
      end
    end
    
    
    % Check that the channel didn't end up with absolutely nothing in it
    if ~isempty(waveforms.waves)
      %% Save channel
      waveFilename = makeWaveFilename(lett, electrode);
      save(fullfile(outDir, waveFilename), 'waveforms', '-v7');
      
      %% Generate this channel's worth of previews and sorts
      usedChs = usedChs + 1;
      [previews(usedChs), sorts(usedChs)] = generateSortsAndPreviews(waveforms, maxUnits, lockout); %#ok<AGROW,NASGU>
    end
      
    if mod(electrode, 20) == 0, fprintf('\n'); end
  end
  fprintf('\n');
end


%% Attempt to delete temp chunk directory

if ~strcmp(chunkDir, outDir)
  status = rmdir(chunkDir);
  
  if ~status
    fprintf('Warning: could not delete the temporary extraction directory.\n');
  end
end


%% If relevant, report .nev bug repairs
if flagrantLockoutViolations
  fprintf('\nPercent of waveforms that failed to cross threshold at the right time, by channel:\n');
  blockPrintNumbers(100 * fracNonCrossers, 20);
  fprintf('Mean: %0.3f\n', mean(100 * fracNonCrossers));
  fprintf('Total number of remaining waveforms involved in a residual lockout violation, by channel:\n');
  blockPrintNumbers(remLockoutViol, 20);
  fprintf('Mean: %0.3f%%\n', mean(remLockoutViol));
end
  

%% Save previews and sorts
save(fullfile(outDir, 'previews.mat'), 'previews', '-v6');
save(fullfile(outDir, 'sorts.mat'), 'sorts', '-v6');

fprintf('Done.\n');





%%
function chunkFilename = makeChunkFilename(outDir, lett, electrode, fileNum, chunki)
name = makeWaveFilename(lett, electrode);
stem = name(1:end-4);
chunkFilename = fullfile(outDir, sprintf('%s_%d_%d.mat', stem, fileNum, chunki));



%%
function [lockout, lockoutViolations, flagrantLockoutViolations] = ...
  checkForLockoutViolations(spikeTimes, allElectrodeNums, snippetLockout, lockoutViolations, flagrantLockoutViolations, RRRlockout)
% There are three possibilities. One is that the lockout period is
% determined normally by the snippet length. A second is that data was
% recorded with a buggy version of the Cerebus software, which will cause
% flagrant lockout violations (e.g., 100 us ISIs). A third is that the data
% was recorded with RRR, which has a shorter lockout than normal Cerebus.

% ELB_NOTE: Lockout -- Deadtime

if ~flagrantLockoutViolations
  % Check for violations of the lockout period calculated by snippet
  % length. If we find any, assume the data was collected with RRR,
  % which uses a lockout shorter than the snippet length.
  lockout = snippetLockout;
  
  electrodes = unique(allElectrodeNums);
  
  for electrode = electrodes
    diffs = diff(spikeTimes(allElectrodeNums == electrode));
    
    if any(diffs >= 0 & diffs < RRRlockout)
      fprintf('Found violations of lockout period; assuming lockout period is snippet length\n');
      flagrantLockoutViolations = 1;
      lockout = snippetLockout;
      break;
    elseif lockoutViolations || any(diffs >= 0 & diffs < snippetLockout)
      lockoutViolations = 1;
      lockout = RRRlockout;
    else
      lockout = snippetLockout;
    end
  end
end

if flagrantLockoutViolations
  lockout = snippetLockout;
end



%%
function [thresh, threshi] = findThreshold(waves)
% Find threshold value and time. We can't use the value in the spike
% headers, because Blackrock changed between 0 and 1 indexing for the
% number of pre-threshold samples between version 4 and 6 of the
% software/firmware (and possibly introduced another weird offset).

% Note - This only returns the negative threshold.  There may be different
% negative and positive thresholds

% The hack we'll use to find the threshold-crossing sample is to find the
% sample at which the most waveforms have just gone negatively
diffs = diff(waves);
nNegs = sum(diffs < 0, 2);
[junk, threshi] = max(nNegs); %#ok<ASGLU>
threshi = threshi + 1;        % Need to correct for off-by-1 of diff

% We'll try different strategies depending on how many waveforms are
% present
nWaves = size(waves, 2);
if nWaves < 20
  thresh = -1e-9;
  quantiles = NaN;
else
  % To find the actual threshold value, we'll take the percentiles of
  % post-threshold values from 95th to 99.9th (to exclude the few
  % violators). We'll try to find two percentiles 0.2% apart that agree,
  % and take the highest ones that do. May have to use coarser-grained
  % quantiles if the number of waveforms is small.
  if nWaves < 100
    quantiles = 0.999:-1/nWaves:0.5;
    criterion = 5;
  elseif nWaves < 1000
    quantiles = 0.999:-1/nWaves:0.5;
    criterion = 1;
  else
    quantiles = (0.999:-0.001:0.950);
    criterion = 1e-9;
  end
  wavesQ = quantile_mksort(waves(threshi, :), quantiles);
  thresh = NaN;
  for q = 1:length(quantiles) - 2
    if abs(wavesQ(q) - wavesQ(q + 2)) < criterion
      thresh = wavesQ(q);
      break;
    end
  end
end

if ~isnan(thresh)
  if ~isnan(quantiles)
    fprintf('Using threshold at %0.1f percentile\n', quantiles(q) * 100);
  else
    fprintf('So few threshold crossings present that the cleaning threshold was chosen arbitrarily at -1e-9\n');
  end
else
  fprintf('WARNING: Could not find a valid threshold between 95th and 99.9th percentile of post-threshold values\n');
  fprintf('Since a consistent threshold could not be found, arbitrarily using -1e-9. Invalid waveforms likely remain.\n');
  thresh = -1e-9;
end



%%
function sourceFiles = chunkFilenamesToSourceFiles(elecWaveforms)
% Take the elecWaveforms cell array, and use the spike arrays and
% fileSource info contained therein to produce a cell array of filenames
% and an nFile x 2 table of spike indices telling which file spikes came
% from.

sourceFiles.filenames{1} = elecWaveforms{1}.sourceFiles;
sourceFiles.spikesByFile = [1 0];

filei = 1;

for ch = 1:length(elecWaveforms)
  chunk = elecWaveforms{ch};
  
  if ~strcmp(chunk.sourceFiles, sourceFiles.filenames{filei})
    filei = filei + 1;
    sourceFiles.filenames{filei} = chunk.sourceFiles;
    sourceFiles.spikesByFile(filei, :) = sourceFiles.spikesByFile(filei - 1, 2) + [1, length(chunk.spikeTimes)];
  else
    sourceFiles.spikesByFile(filei, 2) = sourceFiles.spikesByFile(filei, 2) + length(chunk.spikeTimes);
  end
end

% Now, check for rows where no spikes were present. They will have a last
% spike less than their first spike, but subsequent rows will be ok.
% Replace those bad rows with NaNs.
badRows = find(diff(sourceFiles.spikesByFile, 1, 2) < 0);
if ~isempty(badRows)
  sourceFiles.spikesByFile(badRows, :) = [NaN NaN];
end


%%
function waveforms = removeBadSpikes(waveforms, badSpikes)

waveforms.waves(:, badSpikes) = [];
waveforms.units(:, badSpikes) = [];
waveforms.spikeTimes(:, badSpikes) = [];
waveforms.ratings.epoch = [1 length(waveforms.spikeTimes)];
waveforms.sourceFiles = correctSourceFilesTable(waveforms.sourceFiles, badSpikes);




%%
function sourceFiles = correctSourceFilesTable(sourceFiles, badSpikes)
% Take a sourceFiles struct and a logical array of bad spikes that will be
% removed, and fix the table values.

badAtGivenPos = cumsum(badSpikes);
for filei = 1:size(sourceFiles.spikesByFile, 1)
  val1 = sourceFiles.spikesByFile(filei, 1);
  if ~isnan(val1)
    % Have to add back the badSpikes value at first element, since
    % otherwise we may decrement it (and we never should, or else it will
    % be on top of the last spike of the previous file)
    sourceFiles.spikesByFile(filei, 1) = val1 - badAtGivenPos(val1) + badSpikes(val1);
    val2 = sourceFiles.spikesByFile(filei, 2);
    sourceFiles.spikesByFile(filei, 2) = val2 - badAtGivenPos(val2);
  end
end
