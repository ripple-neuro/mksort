function [infoPackets, version] = CCF_read(filename)
% [infoPackets, version] = CCF_read(filename)
%
% Read a .ccf file. Reads only the (156) cbPKT_CHANINFO packets, not
% whatever is at the end. Note that only the first 128 packets will be for
% electrodes, the rest are for other things (aout, dout, audio, etc).
%
% Supports versions 3.6, 3.7, and 3.8 of the .ccf spec from Blackrock
% Microsystems.
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

% Which versions of .ccf's are supported
supportedVersions = {'3.6', '3.7', '3.8'};
% Number of cbPKT_CHANINFO packets to read in the file
nValidPKT_CHANINFO = 156;

if( nargin ~= 1 ), warning( '1 input required' ); return; end;

%% Open file
[fid, message] = fopen( filename, 'rb', 'l');
if( fid == -1 ),
   warning(['Unable to open file: ' filename ', error message ' message]);
   return;
end;

%% Read header incl. version
head = fread(fid, 16, '*char*1' )';

if ~strcmp(head(1:5), 'cbCCF')
  warning('Not a well-formed .ccf file');
  fclose(fid);
  return;
end

% Strip possible leading space and trailing nulls
version = deblank(strtrim(head(6:end)));

if ~ismember(version, supportedVersions)
  warning(sprintf('Unsupported file version: %s', version));
  fclose(fid);
  return;
end

%% Read packets
for p = 1:nValidPKT_CHANINFO
  infoPackets(p) = readInfoPacket(fid, version);
end

%% Close file
fclose(fid);



function p = readInfoPacket(fid, version)
% Read a cbPKT_CHANINFO packet

cbLEN_STR_LABEL = 16;
cbMAXUNITS = 5;
cbMAXHOOPS = 4;

p.time = fread(fid, 1, '*uint32');
p.chid = fread(fid, 1, '*uint16');
p.type = fread(fid, 1, '*uint8');
p.dlen = fread(fid, 1, '*uint8');
p.chan = fread(fid, 1, '*uint32');
p.proc = fread(fid, 1, '*uint32');
p.bank = fread(fid, 1, '*uint32');
p.term = fread(fid, 1, '*uint32');
p.chancaps = fread(fid, 1, '*uint32');
p.doutcaps = fread(fid, 1, '*uint32');
p.dinpcaps = fread(fid, 1, '*uint32');
p.aoutcaps = fread(fid, 1, '*uint32');
p.ainpcaps = fread(fid, 1, '*uint32');
p.spkcaps = fread(fid, 1, '*uint32');

p.physcalin = readCbScaling(fid);
p.phyfiltin = readFiltDesc(fid);
p.physcalout = readCbScaling(fid);
p.phyfiltout = readFiltDesc(fid);

p.label = fread(fid, cbLEN_STR_LABEL, '*char*1')';
p.userflags = fread(fid, 1, '*uint32');
p.position = fread(fid, 4, '*int32')';

p.scalin = readCbScaling(fid);
p.scalout = readCbScaling(fid);

p.doutopts = fread(fid, 1, '*uint32');
p.dinpopts = fread(fid, 1, '*uint32');
p.aoutopts = fread(fid, 1, '*uint32');
p.eopchar = fread(fid, 1, '*uint32');

% Below two lines are actually part of a union, not sure how to figure out
% which option is actually being used
p.monsource = fread(fid, 1, '*uint32');
p.outvalue = fread(fid, 1, '*int32');

p.ainpopts = fread(fid, 1, '*uint32');
p.lncrate = fread(fid, 1, '*uint32');
p.smpfilter = fread(fid, 1, '*uint32');
p.smpgroup = fread(fid, 1, '*uint32');
p.smpdispmin = fread(fid, 1, '*int32');
p.smpdispmax = fread(fid, 1, '*int32');
p.spkfilter = fread(fid, 1, '*uint32');
p.spkdispmax = fread(fid, 1, '*int32');
p.lncdispmax = fread(fid, 1, '*int32');
p.spkopts = fread(fid, 1, '*uint32');
p.spkthrlevel = fread(fid, 1, '*int32');
p.spkthrlimit = fread(fid, 1, '*int32');
p.spkgroup = fread(fid, 1, '*uint32');
p.amplrejpos = fread(fid, 1, '*int16');
p.amplrejneg = fread(fid, 1, '*int16');
p.refelecchan = fread(fid, 1, '*uint32');
p.unitmapping = readCbManualUnitMappings(fid, cbMAXUNITS, version);
p.spkhoops = readCbHoops(fid, cbMAXUNITS, cbMAXHOOPS);


%% Sub-struct readers
function sc = readCbScaling(fid)
% Read a cbSCALING struct

cbLEN_STR_UNIT = 8;

sc.digmin = fread(fid, 1, '*int16');
sc.digmax = fread(fid, 1, '*int16');
sc.anamin = fread(fid, 1, '*int32');
sc.anamax = fread(fid, 1, '*int32');
sc.anagain = fread(fid, 1, '*int32');
sc.anaunit = fread(fid, cbLEN_STR_UNIT, '*char*1')';



function fd = readFiltDesc(fid)
% Read a cbFILTDESC struct

cbLEN_STR_FILT_LABEL = 16;

fd.label = fread(fid, cbLEN_STR_FILT_LABEL, '*char*1')';
fd.hpfreq = fread(fid, 1, '*uint32');
fd.hporder = fread(fid, 1, '*uint32');
fd.hptype = fread(fid, 1, '*uint32');
fd.lpfreq = fread(fid, 1, '*uint32');
fd.lporder = fread(fid, 1, '*uint32');
fd.lptype = fread(fid, 1, '*uint32');



function ums = readCbManualUnitMappings(fid, maxUnits, version)
% Loop to read all the cbMANUALUNITMAPPING packets. Note that this requires
% knowing the file version: v3.6 is different from 3.7 and 3.8

% Loop growing is inefficient, but it's just not that much data.
if strcmp(version, '3.6')
  for i = 1:maxUnits
    ums(i) = readCbManualUnitMapping3_6(fid);
  end
else
  for i = 1:maxUnits
    ums(i) = readCbManualUnitMapping(fid);
  end
end  


function um = readCbManualUnitMapping(fid)
% Read a cbMANUALUNITMAPPING packet for a v3.7 or 3.8 file

um.nOverride = fread(fid, 1, '*int16');
um.afOrigin = fread(fid, 3, '*int16')';
um.afShape = fread(fid, [3 3], '*int16')';
um.aPhi = fread(fid, 1, '*int16')';
um.bValid = fread(fid, 1, '*uint32')';

function um = readCbManualUnitMapping3_6(fid)
% Read a cbMANUALUNITMAPPING packet for a v3.6 file

um.nOverride = fread(fid, 1, '*uint32');
um.afOrigin = fread(fid, 3, '*float32')';
um.afShape = fread(fid, [3 3], '*float32')';
um.aPhi = fread(fid, 1, '*float32')';
um.bValid = fread(fid, 1, '*uint32')';




function hs = readCbHoops(fid, maxUnits, maxHoops)
% Loop to read the cbHOOP packets

% Loop growing is inefficient, but it's just not that much data.
for u = 1:maxUnits
  for h = 1:maxHoops
    hs(u, h) = readCbHoop(fid);
  end
end


function h = readCbHoop(fid)
% Read a cbHOOP packet

h.valid = fread(fid, 1, '*uint16')';
h.time = fread(fid, 1, '*int16')';
h.min = fread(fid, 1, '*int16')';
h.max = fread(fid, 1, '*int16')';


