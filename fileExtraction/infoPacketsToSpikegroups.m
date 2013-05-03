function nTrodes = infoPacketsToSpikegroups(infoPackets, array)
% nTrodes = infoPacketsToSpikegroups(infoPackets, array)
%
% Takes an infoPackets struct array as returned from CCF_read, returns
% information about the spike groups ala n-trodes. Also needs to know which
% array we're using (NaN for one array only). nTrodes is a struct array
% with as many elements as spike groups ( [] if all spike groups were 0).
% nTrodes has three fields: spkGroup, which is the spkgroup value for that
% n-trode, members, which is an array of the channels that were members of
% that spike group, and array, which is just the array input regurgitated.
%
% Called by the top level function CCFFilenamesToNTrodeStructs.
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


%% Trim off packets from all the non-spike channels
if length(infoPackets) > 128
  infoPackets = infoPackets(1:128);
end

%% Find the unique spike group numbers, and membership
[spkGroups, ~, inds] = unique([infoPackets.spkgroup]);

%% If no real spike groups, return []
if isequal(spkGroups, 0)
  nTrodes = [];
  return;
end

%% Channel numbers, in case some were disabled
chans = [infoPackets.chan];


%% Loop through spike groups, gather data up
nt = 0;
for s = 1:length(spkGroups)
  % Toss the bogus 0 spike group, if present
  sg = spkGroups(s);
  if sg == 0, continue; end;
  
  % OK, it's a real spike group
  nt = nt + 1;
  
  nTrodes(nt).spkGroup = sg;
  nTrodes(nt).members = chans(inds == s);
  nTrodes(nt).array = array;
end
