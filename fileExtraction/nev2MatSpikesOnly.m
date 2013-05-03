function [spikes, stimulus, units] = nev2MatSpikesOnly(filename)
%
%  function [spikes, stimulus, units] = nev2MatSpikesOnly(filename);
%
%  This function loads a NEV file into matlab using only script commands
%  
%  Inputs:
%
%     filename - a character string containing the entire path to the 
%                the NEV file. Is opened in read only mode.
%
%  Outputs:
%
%     spikes   - A N by 2 array of neural events. The unit number is in column 1
%                and the time, in seconds of the event, is in column 2. See units
%                field for description of the coding of units.
%
%     stimulus - A M by 8 array of stimulus events. The columns are as follows:
%                  1 - Time of event in seconds.
%                  2 - The 'why' field of the stimulus packet, indicating why this
%                      packet was saved.
%                  3 - Value on the digital port
%                  4 - Value on the 1st analog port in volts
%                  5 - Value on the 2nd analog port in volts
%                  6 - Value on the 3rd analog port in volts
%                  7 - Value on the 4th analog port in volts
%                  8 - Value on the 5th analog port in volts
%
%     units    - A L by 1 array of the units having neural events in the file.
%                The integer portion indicates the channel number and the fractional
%                portion indicates the unit on the channel. Unit 0 is typically 
%                defined as unclassified or noise and unit 255 is typically defined
%                as truly bad data.
%
%
%  Written by Dave Warren
%  Modified by Matt Kaufman
%
% This file is included as part of the spike sorting software package MKsort, 
% licensed under GPL version 2.
% 
% Please see mksort.m for full license and contact details.

% Make sure that the output exists
spikes = [];
stimulus = [];
units = [];

% Check input arguments
if( nargin ~= 1 ), warning( '1 input required' ); return; end;

[fid, message] = fopen( filename, 'rb', 'l');
if( fid == -1 ),
   warning( ['Unable to open file: ' filename ', error message ' message ] );
   return;
end;

% Read headers
[ header, spikeheaders, stimheader ] = NEVGetHeaders( fid );
if( isempty( header ) )
   warning( ['Unable to read headers in file: ' filename ', error message ' message ] );
   fclose(fid);
   return;
end;

% Calculate skip factors based on data size
wavesize = header.datasize - 8;
tsskipsize = header.datasize - 4;
idskipsize = header.datasize - 2;
unitskipsize = header.datasize - 1;

% Read time stamp
if( fseek( fid, header.dataptr+0, 'bof' ) == -1 ),
   warning( ['Unable to position file, error code ' ferror( fid ) ] );
   fclose(fid);
   return;
end;
timestamp = fread( fid, inf, 'uint32', tsskipsize ) / header.SampleRes;

% Read electrode but not unit
if( fseek( fid, header.dataptr+4, 'bof' ) == -1 ),
   warning( ['Unable to position file, error code ' ferror( fid ) ] );
   fclose(fid);
   return;
end;
electrode = fread( fid, inf, 'uint16', idskipsize );

% Read unit but not electrode
if( fseek( fid, (header.dataptr + 6), 'bof' ) == -1 ),
   warning( ['Unable to position file, error code ' ferror( fid ) ] );
   fclose(fid);
   return;
end;
unit = fread( fid, inf, 'uint8', unitskipsize );

% Extract stimulus events
z = find( electrode == 0 );
if( ~isempty(z) )
   stimulus = zeros( length(z), 8 );
   stimulus(:,1) = timestamp(z);
   for n=1:length(z)
      if( fseek( fid, header.dataptr+(z(n)-1)*header.datasize+6, 'bof' ) == -1 ),
         warning( ['Unable to position file, error code ' ferror( fid ) ] );
         fclose(fid);
         return;
      end;
      stimulus(n,2) = fread( fid, [1], 'uint8' );
      dummy = fread( fid, [1], 'uint8' );
      stimulus(n,3) = fread( fid, [1], 'uint16' );
      stimulus(n,4:8) = 1e-3*fread( fid, [1,5], 'int16' );
   end
end

% Extract neural events
z = find( electrode ~= 0 );
if( ~isempty(z) )
   spikes = [ round( 100 * electrode(z) + bitand( unit(z), 15 ) )/100, timestamp(z) ];
   units = unique( spikes(:,1) );
end

fclose(fid);
