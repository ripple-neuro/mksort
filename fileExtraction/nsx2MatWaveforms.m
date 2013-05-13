function nsx2MatWaveforms(inDir, outDir, nsxNames, thresh, filterName, snippetLenTime, preThreshTime, artifactThresh, nTrodes)
% nsx2MatWaveforms(inDir, outDir, nsxNames, thresh, filterName, snippetLenTime, preThreshTime)
% nsx2MatWaveforms(inDir, outDir, nsxNames, thresh, filterName, snippetLenTime, preThreshTime, artifactThresh)
% nsx2MatWaveforms(inDir, outDir, nsxNames, thresh, filterName, snippetLenTime, preThreshTime, artifactThresh, nTrodes)
%
% Files load from inDir and outputs saved to outDir
%
% nsxNames should be an nArrays-long cell array, with each cell containing
% an nFiles-long cell array of strings.
%
% thresh should be the RMS multiplier to use as the threshold. Should be
% negative.
%
% filterName should be a string, specifying which filter to run over the
% data before thresholding. Should work with cerebusFilter.
%
% snippetLenTime should be the (total) length of the snippet to extract, in
% ms.
%
% preThreshTime should be the total time desired in the snippet before
% threshold, in ms.
%
% artifactThresh (optional) specifies how big a point in a waveform is
% allowed to be before we consider it an artifact and throw it away. Sign
% does not matter, specify in mV. Default is Inf.
%
% nTrodes (optional) specifies n-trode groupings. Should be a struct array
% with as many elements as n-trodes to be defined (electrodes not in an
% n-trode do not need a member). Each struct should have three fields:
% spkGroup, which is the spkgroup value for that n-trode, members, which is
% an array of the channels that were members of that spike group, and
% array, which is the array number or NaN (if only using one array).
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

%% Optional arguments

if ~exist('artifactThresh', 'var')
  artifactThresh = Inf;
end

if ~exist('nTrodes', 'var')
  nTrodes = [];
end

%% Parameters

% channels for Cerebus hardware
channelsUsed = 1:128;

maxUnits = 4;

if ~exist('artifactThresh', 'var')
  artifactThresh = Inf;  % Max size in mV before we consider a waveform an artifact
end

alpha = alphabet();


%% Initialize flags and accumulator variables

nthFile = 0;

filt.SOS = cerebusFilter(filterName);


%% Figure out if we'll need to stitch files together at the end

needToStitch = any(cellfun(@(x) length(x) > 1, nsxNames));

if needToStitch
  chunkDir = tempname;
  status = mkdir(chunkDir);
  if ~status
    chunkDir = outDir;
  end
  
  allChunkFileInfo = {};
end



%% Main loop through files

if isempty(nsxNames)
  error('nsx2MatWaveforms:noFiles', 'No files specified');
end

% Go through each file, process it by channel and save down the data chunks.
% We'll combine these chunks (one per file per channel) at the end.
fprintf('Processing files\n');
nTotalFiles = sum(cellfun(@length, nsxNames));
for arr = 1:length(nsxNames)
  
  %% The initializaion of thresholds has been changed so that it is initialized
  % in each group.  This makes sense because the data is pulled from NSX file in
  % this order.
  % Initialize threshold repository for this array
  % thresholds = NaN(1, channelsUsed(end));

  %% Figure out which nTrodes are for this array
  if ~isempty(nTrodes)
    % If one array, all nTrodes belong to this array
    if length(nsxNames) == 1
      theseNTrodes = nTrodes;
    else
      theseNTrodes = nTrodes([nTrodes.array] == arr);
    end
  else
    theseNTrodes = [];
  end

  %% Loop through this array's files
  for fileNum = 1:length(nsxNames{arr})
    %% Bookkeeping related to this file
    if length(nsxNames) == 1
      lett = '';
    else
      lett = alpha(arr);
    end
    filename = nsxNames{arr}{fileNum};

    nthFile = nthFile + 1;
    fprintf('File %d/%d, channel:\n', nthFile, nTotalFiles);
    
    inFile = fullfile(inDir, filename);
    
    %% Open .nsx file
    NSX = [];
    try
      NSX = NSX_open(inFile);
    catch
      NSX = [];
    end
    if isempty(NSX) || NSX.FID < 0
      warning(['Unable to open file: ' filename ', error message ' message]); %#ok<WNTAG>
    end
    
    %% Convert snippetLenTime, preThreshTime to numbers of data points
    % NSX.Period is the number of 1/30,000 s ticks between data points
    snippetLen = round(snippetLenTime / NSX.Period / 1000);
    preThresh = round(preThreshTime / NSX.Period / 1000);
    
    if snippetLen == 0
      error('nsx2MatWaveforms:zeroSnippetLen', 'Snippet specified rounds to zero length');
    end
    
    
    %% Convert channels into cell groups, based on n-trodes
    
    channelGroups = channelsToGroupsByNTrodes(NSX.Channel_ID, theseNTrodes);
    
    
    %% Loop through groups
    
    nElectrodesProcessed = 0;
    for g = 1:length(channelGroups)
      
      % Clear data and spiketime accumulators
      data = {};
      times = {};
      
      % In the case of Ripple files, remove any analog channels.  I.e.,
      % channels aboved 10241.  With Grapevine, is no neural data with
      % channel counts about 512.  
      % Check for the comment field effectively handles NSX2.1
      % compatiblity.
      if isfield(NSX, 'Comment') && strfind(NSX.Comment, 'Trellis')
        if any(channelGroups{g} > 512)
          continue;
        end
      % if this is Cerebus data, analog channels start at 129.  TODO: This
      % code for Cerebus is not tested and should be updated to ensure that
      % this Cerebus compatibilty hasn't been broken.
      else
        if any(channelGroups{g} > 128)
          continue
        end
      end
      
      %% Loop through electrodes in this group (usually only one)
      for e = 1:length(channelGroups{g})
        nElectrodesProcessed = nElectrodesProcessed + 1;
        
        electrode = channelGroups{g}(e);

        % put place to hold thresholds
        thresholds = NaN(1, length(channelGroups{g}));

        %% Read electrode from file
        % TODO: Reading the entire channel could lead to running out of
        % memory for large data sets.
        [data{e}, times{e}] = NSX_read(NSX, electrode, 1);
        % convert the data into physical units
        index = find([NSX.Channel_ID] == electrode);
        adc2uV = (NSX.Channel_AnalogMax(index) - NSX.Channel_AnalogMin(index)) / ...
          (NSX.Channel_DigitalMax(index) - NSX.Channel_DigitalMin(index));
        % TODO: Some memory benifit could be had by leaving this as an
        % integer for the thresholding and only converting the thresholded
        % spikes to double.
        data{e} = double(data{e}) * double(adc2uV);
        % data{e} = data{e} * adc2uV;
        
        %% Filter
        data{e} = round(sosfilt(filt.SOS, data{e}));
        
        %% Get threshold if this is the first file
        if isnan(thresholds(e))
          % Including threshold removal from the calculation of rms.  This is
          % important as a few artifacts will greatly change the RMS.
          rms = std(data{e}(abs(data{e}) < artifactThresh * 1000));
          threshold = thresh(1) * rms;  % (1) is just in case numel(thresh) > 1 for some weird reason
          thresholds(e) = threshold;
        end
        % This version of output gives more debugging info but clobbers the
        % output a bit.
        % fprintf('%d:%4.2f; ', electrode, thresholds(e));
        % if ~mod(nElectrodesProcessed, 10), fprintf('\n'); end;
        fprintf('%03d, ', electrode);
        if ~mod(nElectrodesProcessed, 20), fprintf('\n'); end;
      end % nTrode group
      
      %% Extract snippets
      
      % Threshold broadband data to get snippets with and without filtering
      % [waves, pts] = thresholdBBMulti(data, thresholds(channelGroups{g}), preThresh, snippetLen);
      [waves, pts] = thresholdBBMulti(data, thresholds(1:length(channelGroups{g})), preThresh, snippetLen);

      % Convert spike point numbers to times in ms
      spikeTimes = times{e}(pts)' * 1000;
      
    
      %% Reject artifacts
      % Note that artifactThresh is specified in mV, need to convert to uV
      if ~isinf(artifactThresh)
        maxes = max(abs(waves));
        artifacts = (maxes > abs(artifactThresh) * 1000);
        
        waves = waves(:, ~artifacts);
        spikeTimes = spikeTimes(~artifacts);
      end
      
      
      %% Create waveforms data structure for this chunk
      if length(nsxNames) == 1
        array = NaN;
      else
        array = arr;
      end
      
      waveforms = createWaveformsStruct(double(channelGroups{g}), waves, zeros(1, length(spikeTimes)), spikeTimes, array, maxUnits);
      
      %% Depending on whether we'll have to stitch files together, either complete the waveforms struct or save 'chunk'
      
      if ~needToStitch
        %% This is the only file for this array, complete waveforms and save down
        
        waveforms.ratings.epoch = [1 length(waveforms.spikeTimes)];
        
        waveforms.sourceFiles.filenames{1} = filename;
        waveforms.sourceFiles.spikesByFile = [1 length(waveforms.spikeTimes)];
        
        %% Save channel
        waveFilename = makeWaveFilename(lett, channelGroups{g});
        save(fullfile(outDir, waveFilename), 'waveforms', '-v7');
        
        %% Generate this channel's worth of previews and sorts
        [previews(g), sorts(g)] = generateSortsAndPreviews(waveforms, maxUnits, snippetLenTime); %#ok<AGROW>


      else
        %% This is the more complicated situation, where there are multiple files per array.
        % Need to do bookkeeping about where things came from. The hard
        % work stitching things together comes later.
        
        % Keep track of where the chunk came from. This field will get
        % overwritten when chunks are stitched together.
        waveforms.sourceFiles = filename;
        
        %% Get chunk file filename
        chunkFilename = makeChunkFilename(chunkDir, lett, channelGroups{g}, fileNum);
        
        %% Save chunk file
        % Use -v6 to save uncompressed for speed (these files get deleted
        % later).
        save(chunkFilename, 'waveforms', '-v6');
        
        %% Chunk bookkeeping
        % If we don't have a list of fileNum's for this
        % array/electrode pair, initialize it with []
        if any(size(allChunkFileInfo) < [arr, channelGroups{g}(1)])
          allChunkFileInfo{arr, channelGroups{g}(1)} = []; %#ok<AGROW>
        end
        
        allChunkFileInfo{arr, channelGroups{g}(1)}(end+1) = fileNum; %#ok<AGROW>
      end
    end  % for channelGroup
    
    %% Clean up
    fclose(NSX.FID);
    fprintf('\n');
    
  end  % for fileNum
end  % for array



%% Stitch files together
if needToStitch
  fprintf('Stitching files together, generating previews\n');
  fprintf('Channel: ');
  
  usedChs = 0;
  for array = 1:size(allChunkFileInfo, 1)
    % Array letter if applicable
    if size(allChunkFileInfo, 1) > 1
      lett = alpha(array);
      fprintf('%s', lett);
    else
      lett = '';
    end
    
    % Loop through channel groups
    for g = 1:length(channelGroups)
      %% Figure out whether this was a used channel
      % Figure out how many files for this array/electrode
      chunkInfo = allChunkFileInfo{array, channelGroups{g}{1}};
      nFiles = length(chunkInfo);
      
      % If this channel was disabled, skip it
      if nFiles == 0
        continue;
      else
        usedChs = usedChs + 1;
      end
      
      fprintf('%d ', g);
      
      %% Load all files for this channel
      % elecWaveforms will hold all the file chunks to be combined in one
      % step at the end
      elecWaveforms = cell(1, nFiles);
      
      % Load file chunks, delete chunks files
      for chunk = 1:nFiles
        chunkFilename = makeChunkFilename(chunkDir, lett, channelGroups{g}, chunkInfo(chunk));
        loadVar = load(chunkFilename);
        elecWaveforms{chunk} = loadVar.waveforms;
        
        delete(chunkFilename);
      end
      
      %% Create full waveforms structure for this electrode/n-trode
      waveforms = elecWaveforms{1};
      waveforms.waves = cellfun(@(x)x.waves, elecWaveforms, 'UniformOutput', false);
      waveforms.waves = [waveforms.waves{:}];
      waveforms.units = cellfun(@(x)x.units, elecWaveforms, 'UniformOutput', false);
      waveforms.units = [waveforms.units{:}];
      waveforms.spikeTimes = cellfun(@(x)x.spikeTimes, elecWaveforms, 'UniformOutput', false);
      waveforms.spikeTimes = [waveforms.spikeTimes{:}];
      waveforms.ratings.epoch = [1 length(waveforms.spikeTimes)];
      waveforms.sourceFiles = chunkFilenamesToSourceFiles(elecWaveforms);
      
      %% Save channel
      waveFilename = makeWaveFilename(lett, channelGroups{g});
      save(fullfile(outDir, waveFilename), 'waveforms', '-v7');
      
      %% Generate this channel's worth of previews and sorts
      [previews(usedChs), sorts(usedChs)] = generateSortsAndPreviews(waveforms, maxUnits, snippetLenTime); %#ok<AGROW>
      
      if mod(g, 20) == 0, fprintf('\n'); end
    end
    fprintf('\n');

  end  % for array
end  % if needToStitch


%% Attempt to delete temp chunk directory

if needToStitch && ~strcmp(chunkDir, outDir)
  status = rmdir(chunkDir);
  
  if ~status
    fprintf('Warning: could not delete the temporary extraction directory.\n');
  end
end


%% Save previews and sorts
save(fullfile(outDir, 'previews.mat'), 'previews', '-v6');
save(fullfile(outDir, 'sorts.mat'), 'sorts', '-v6');

fprintf('Done.\n');






%%
function chunkFilename = makeChunkFilename(outDir, lett, electrode, fileNum)
name = makeWaveFilename(lett, electrode);
stem = name(1:end-4);
chunkFilename = fullfile(outDir, sprintf('%s_%d.mat', stem, fileNum));



%%
function sourceFiles = chunkFilenamesToSourceFiles(elecWaveforms)
% Take the elecWaveforms cell array, and use the spike arrays and
% fileSource info contained therein to produce a cell array of filenames
% and an nFile x 2 table of spike indices telling which file spikes came
% from.

sourceFiles.filenames{1} = elecWaveforms{1}.sourceFiles;
sourceFiles.spikesByFile = [1 length(elecWaveforms{1}.spikeTimes)];

if length(elecWaveforms) > 1
  for ch = 2:length(elecWaveforms)
    chunk = elecWaveforms{ch};
    
    sourceFiles.filenames{ch} = chunk.sourceFiles;
    sourceFiles.spikesByFile(ch, :) = sourceFiles.spikesByFile(ch - 1, 2) + [1, length(chunk.spikeTimes)];
  end
end



%%
function channelGroups = channelsToGroupsByNTrodes(channelIDs, nTrodes)
% Turn a list of possible channels and an nTrodes structure into a cell
% array, where each cell contains either a single channel number if that
% channel is not in an n-trode, or an array of channels in an n-trode.
% n-trodes will all be at the end.

if isempty(nTrodes)
  % No n-trodes, simple case
  channelGroups = num2cell(channelIDs);
else
  % n-trodes defined
  
  % which channels are involved in an n-trode
  nTrodeMembers = [nTrodes.members];
  % which channels are not involved in an n-trode (logical array)
  singleElec = ~ismember(channelIDs, nTrodeMembers);
  % turn the non-n-trode channels into a cell array
  channelGroups = num2cell(channelIDs(singleElec));
  % tack on a cell array of vectors for the n-trode channels
  channelGroups = [channelGroups {nTrodes.members}];
end
