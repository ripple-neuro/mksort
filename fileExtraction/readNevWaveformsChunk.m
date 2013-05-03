function [waveforms, complete] = readNevWaveformsChunk(fid, header, waveBytesPerSample, scaleFactor, nPacketsToRead, snippetLen, firstSnippetPt)
%
%  [waveforms, complete] = readNevWaveformsChunk(fid, header, waveBytesPerSample, scaleFactor, nPacketsToRead, snippetLen, firstSnippetPt);
%
%  This function converts a chunk of a NEV file into matlab using only
%  script commands. Includes waveforms.
%  
%  Inputs:
%
%     fid        - a file handle to an open .nev file (read-only, binary).
%                  Should be open to the start of a data packet.
%
%     header     - header from the .nev file
%
%     waveBytesPerSample - how many bytes in each sample of the waveform.
%                          Should be gotten from the spikeheaders.
%
%     scaleFactor - conversion factor between values stored in .nev file
%                   and uV (note: this is 1000 x what is in the
%                   spikeheaders)
%
%     nPacketsToRead - number of packets to read from the file. Will
%                      probably return fewer waveforms, since some packets
%                      are digital I/O!
%
%     snippetLen - length of each snippet. Probably 32. Will yield a
%                  snippet from point firstSnippetPt to firstSnippetPt +
%                  snippetLen - 1.
%
%     firstSnippetPt - first point of each snippet to use.
%
%  Outputs:
%
%     waveforms - A nPts by W array of waveforms data, matched up with the
%                 spikes data. W will be <= nPacketsToRead.
%
%     complete  - 1 if this was the last chunk of the file, 0 otherwise
%
%
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

% Make sure that the output exists
waveforms = [];

% Check input arguments
if nargin ~= 7, warning('7 inputs required'); return; end;

if fid == -1
  warning('.nev file not open!');
  return;
end;

% Calculate skip factors based on data size
wavesize = header.datasize - 8;
idskipsize = header.datasize - 2;
nonWaveSize = 8;

% Figure out how many packets are left
startPos = ftell(fid);
fseek(fid, 0, 'eof');
endPos = ftell(fid);
nPacketsLeft = (endPos - startPos) / header.datasize;
nPacketsToRead = min(nPacketsLeft, nPacketsToRead);
if nPacketsToRead == nPacketsLeft
  complete = 1;
else
  complete = 0;
end

% Read appropriate number of electrode IDs, to exclude non-waveform entries
if fseek(fid, startPos+4, 'bof') == -1
   warning( ['Unable to position file, error code ' ferror(fid) ] );
   fclose(fid);
   return;
end;
electrodeIDs = fread(fid, nPacketsToRead, 'uint16', idskipsize);

% Grab waveforms
if fseek(fid, startPos+8, 'bof') == -1
   warning(['Unable to position file, error code ' ferror(fid)]);
   fclose(fid);
   return;
end;
if waveBytesPerSample == 2
  waveSamples = wavesize/waveBytesPerSample;
  waveforms = fread(fid, [waveSamples, nPacketsToRead], sprintf('%d*int16', waveSamples), nonWaveSize);
  if scaleFactor ~= 1
    waveforms = waveforms * scaleFactor;
  end
else
  fclose(fid);
  error('readNevWaveformsChunk: waveforms samples are not 2 bytes wide');
end

% Now, when we use fread with a 'count' value (2nd argument) of the form
% [m, n], the byte-skipping is done not only between entries but also an
% extra one is done at the end. So, we need to back up by one skip value so
% that we'll be in the right place for the next chunk (if applicable).
fseek(fid, -nonWaveSize, 'cof');

% Toss non-waveform entries, which will contain junk, and clip ends of
% waveforms.
% Use logical indexing for speed
if firstSnippetPt < 1
  firstSnippetPt = 1;
end
waveLen = size(waveforms, 1);
firstSnippetPt = min([firstSnippetPt waveLen]);
snippetLen = min([snippetLen, waveLen-firstSnippetPt+1]);

snippetPts = logical([zeros(1, firstSnippetPt - 1) ones(1, snippetLen) zeros(1, waveLen - snippetLen)]);
waveforms = waveforms(snippetPts, logical(electrodeIDs));
