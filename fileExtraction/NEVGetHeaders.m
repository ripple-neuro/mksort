function [ NEVbasicHeader, NEVwaveformHeader, NEVexternalIOHeader, NEVarrayHeader, NEVcommentsText ] = NEVGetHeaders( fid )
%
%	[ NEVbasicHeader, NEVwaveformHeader, NEVexternalIOHeader, NEVarrayHeader, NEVcommentsText ] = NEVGetHeaders( fid );
%
%  Reads the header data from a nev file - see the nev spec for interpretation
%
%   Inputs
%
%       fid                 -   File ID of previously opened NEV file. 
%
%                               Although not necessary in all cases, it is
%                               recommended that the file be opened with
%                               'rb' permissions, for read only and binary
%                               format(binary format is default, anyway).
%                           	Althoughnot necessary in all cases, it is
%                               recommended that the file be opened with
%                               'ieee-le' machine format, for little-end
%                               byte ordering that is typically the case
%                               for Windows machines. Although not
%                               necessary in all cases, it is recommended
%                               that the file be opened with 'windows-1252'
%                               encoding so that the extended characters in
%                               text strings are properly interpreted. This
%                               later item is very important for Unix
%                               machines.
%
%   Outputs (See most recent NEV specificiation for details
%
%       NEVbasicHeader      -	Header data implemented as structure scalar
%                               detailing information common to entire NEV
%                               file.
%
%       NEVwaveformHeader   -	Header data implemented as structure vector
%                               detailing information unique to particular
%                               electrode channels, including input channel
%                               information, label information, and
%                               filtering information.
%
%       NEVexternalIOHeader -	Header data implemented as structure scalar
%                               detailing information unique to external
%                               experimental data, including input channel
%                               information and label information.
%
%       NEVarrayHeader      -	Header data implemented as structure scalar
%                               detailing information unique to particular
%                               array used, including array name and map
%                               file used in creation of data.
%
%       NEVcommentsText     -	Header data implemented as structure vector
%                               with the text from any comments in the
%                               headers.
%
%
%   David J. Warren, University of Utah
%   22-Dec-2010
%
% This file is included as part of the spike sorting software package MKsort, 
% licensed under GPL version 2.
% 
% Please see mksort.m for full license and contact details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Magic Numbers
% ELB_EDIT changing the maximumChannel number to 512.  This will be used to
% pre-allocate data.  Later, we will remove channels where no data was
% found
% maximumChannelNumber = 255;
maximumChannelNumber = 512;
basicHeaderPacketSize = 8 + 2 + 2 + 4 + 4 + 4 + 4 + 8*2 + 32 + 256 + 4;
extentedHeaderPacketSize = 32;

%% Assure some output
NEVbasicHeader =[];
NEVwaveformHeader= [];
NEVexternalIOHeader= [];
NEVarrayHeader = [];
NEVcommentsText = [];

%% extensive checking of inputs
if( nargin ~= 1 );
    warning( 'NEVGetHeaders:InputArgumentCountError', ...
        'Incorrect number of input arguments\n' );
    return;
end;

if( nargout < 1 );
    warning( 'NEVGetHeaders:OutputArgumentCountError', ...
        'Incorrect number of output arguments\n' );
    return;
end;

if( fid < 0 )
    warning( 'NEVGetHeaders:InputValueError', ...
        'Invalid file handle\n' );
    return;
end;

%%	Get details of file
[ filename, permissions, machineformat, encoding ] = fopen(fid); 
if( isempty( filename ) )
    warning( 'NEVGetHeaders:FileNameError', ...
        'Unable to get filename of open file\n' );
    return;
end;
if( ~isempty( strfind( lower( permissions ), 't' ) ) )
    warning( 'NEVGetHeaders:FilePermissionsError', ...
        'File %s opened in text mode, may result in problems interpreting strings\n', filename );
end;
if( ~isempty( strfind( lower( permissions ), 'w' ) ) )
    warning( 'NEVGetHeaders:FilePermissionsError', ...
        'File %s opened for writing, may result in problems\n', filename );
end;
if( ~isempty( strfind( lower( permissions ), 'a' ) ) )
    warning( 'NEVGetHeaders:FilePermissionsError', ...
        'File %s opened for appending, may result in problems\n', filename );
end;
if( ~strcmpi( machineformat(1:7), 'ieee-le' ) )
    warning( 'NEVGetHeaders:FileFormatError', ...
        'File %s not opened in little-endian mode, may result in problems interpreting numbers\n', filename );
end;
% if( ~strcmpi( encoding, 'windows-1254' ) )
%     warning( 'NEVGetHeaders:FileEncodingError', ...
%         'File %s not opened with correct text encoding, may result in problems interpreting strings\n', filename );
% end;
clear permissions machineformat encoding

%%	Get details of file
fileDir = dir( filename ); 
if( isempty( fileDir ) )
    warning( 'NEVGetHeaders:FileNameError', ...
        'Unable to get details of open file\n' );
    return;
end;

%%	Position file to beginning
if( fseek( fid, 0, 'bof' ) == -1 )
    warning( 'NEVGetHeaders:FilePositioningError', ...
        'Invalid file positioning with message %s\n', ferror(fid,'clear') );
    return;
end;

%% Precreate basic header
NEVbasicHeader = struct( ...
    'id', blanks(8), ...
    'filespecMajor', 0, ...
    'filespecMinor', 0, ...
    'fileformat', 0, ...
    'dataptr', 0, ...
    'datasize', 0, ...
    'TimeRes', 0, ...
    'SampleRes', 0, ...
    'FileTime', zeros( 8, 1), ...
    'AppName', blanks(32), ...
    'Comment', blanks(256), ...
    'NumHeaders', 0, ...
    'filespecDouble', 0, ...
    'fileformat16Bit', 0, ...
    'NumPackets', 0, ...
    'SerialDateNumber', 0, ...
    'Filename', blanks(1) ...
    );

%%	Read Basic Headers
ncountTest = 8;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
else
    NEVbasicHeader.id = char( temp );
end

ncountTest = 1;[ NEVbasicHeader.filespecMajor, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 1;[ NEVbasicHeader.filespecMinor, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 1;[ NEVbasicHeader.fileformat, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 1;[ NEVbasicHeader.dataptr, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 1;[ NEVbasicHeader.datasize, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 1;[ NEVbasicHeader.TimeRes, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 1;[ NEVbasicHeader.SampleRes, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 8;[ NEVbasicHeader.FileTime, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

ncountTest = 32;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
else
    NEVbasicHeader.AppName = char( temp );
end

ncountTest = 256;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
else
    NEVbasicHeader.Comment = char( temp );
end

ncountTest = 1;[ NEVbasicHeader.NumHeaders, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

NEVbasicHeader.filespecDouble = fix( NEVbasicHeader.filespecMajor ) + ...
    fix( NEVbasicHeader.filespecMinor ) / 10;
if( NEVbasicHeader.filespecDouble < 1 ) % handle really old NSAS files
    NEVbasicHeader.filespecDouble = 10 * ...
        NEVbasicHeader.filespecDouble;
end
NEVbasicHeader.fileformat16Bit = mod( NEVbasicHeader.fileformat, 2 );
NEVbasicHeader.NumPackets = ( fileDir.bytes - NEVbasicHeader.dataptr ) ...
    / ( NEVbasicHeader.datasize );
if( mod( NEVbasicHeader.NumPackets, 1 ) ~= 0 )
    warning( 'NEVGetHeaders:PacketCountError', ...
        'Non-integer number of data packet at %f\n', NEVbasicHeader.NumPackets );
    return;
end;
dateVector = NEVbasicHeader.FileTime( [1 2 4 5 6 7] );
if( dateVector(1) < 50 )
    dateVector(1) = dateVector(1) + 2000;
else
    if( dateVector(1) < 100 )
        dateVector(1) = dateVector(1) + 1900;
    end
end
NEVbasicHeader.SerialDateNumber = datenum( dateVector );
NEVbasicHeader.Filename = filename;
clear filename fileDir dateVector

%% Precreate waveform header
NEVwaveformHeader = struct( ...
    'id', num2cell( (1:maximumChannelNumber)' ), ...
    'existNEUEVWAV', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'existNEUEVLBL', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'existNEUEVFLT', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'pinch', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'pinnum', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'sf', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'energythreshold', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'highthreshold', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'lowthreshold', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'numberunits', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'numberbytes', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'dummy', num2cell( zeros( maximumChannelNumber, 10 ), 2 ), ...
    'label', num2cell( zeros( maximumChannelNumber, 17 ), 2 ), ...
    'dummy1', num2cell( zeros( maximumChannelNumber, 6 ), 2 ), ...
    'highfreqcorner', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'highfreqorder', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'highfreqtype', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'lowfreqcorner', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'lowfreqorder', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'lowfreqtype', num2cell( zeros( maximumChannelNumber, 1) ), ...
    'dummy2', num2cell( zeros( maximumChannelNumber, 2 ), 2 ) ...
    );

%% Precreate external header
NEVexternalIOHeader.existNSASEXEV = 0;
NEVexternalIOHeader.existSTIMINFO = 0;
NEVexternalIOHeader.existDIGLABELSerial = 0;
NEVexternalIOHeader.existDIGLABELParallel = 0;
NEVexternalIOHeader.PeriodicRes = 0;
NEVexternalIOHeader.DigitalConfig = 0;
for m=1:5;
    NEVexternalIOHeader.AnalogConfig(m).Config = 0;
    NEVexternalIOHeader.AnalogConfig(m).Level = 0;
end;clear m
NEVexternalIOHeader.dummy = zeros(6,1);
NEVexternalIOHeader.SerialLabel = blanks( 16 );
NEVexternalIOHeader.SerialDummy = zeros(7,1);
NEVexternalIOHeader.ParallelLabel = blanks( 16 );
NEVexternalIOHeader.ParallelDummy = zeros(7,1);

%% Precreate array header
NEVarrayHeader.existARRAYNME = 0;
NEVarrayHeader.existMAPFILE = 0;
NEVarrayHeader.arrayName = blanks(24);
NEVarrayHeader.mapfile = blanks(24);

%%	Read Extended Headers
maximumChannelNumberObserved = 0;
% Produce warnings if stim markers are found, but will produce warning on
% the first stim marker found
foundStimMarkers = 0;
for n=1:NEVbasicHeader.NumHeaders;
    if( ftell( fid ) ~= basicHeaderPacketSize + (n-1) * extentedHeaderPacketSize )
        warning( 'NEVGetHeaders:badFilePosition', ...
            'Invalid file positioning\n' );
        return
    end
    ncountTest = 8;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
    else
        HeaderName = upper( char( temp ) );
    end
    switch HeaderName
        case { 'NEUEVWAV', 'NEUEVLBL', 'NEUEVFLT' } % Neural event waveform data
            
            ncountTest = 1;[ id, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
            if(  id < 1 )
                warning( 'NEVGetHeaders:badChannelID', ...
                    'Invalid packet ID value (%d) found\n', id );
                % skip to the next NEV header
                fseek(fid, basicHeaderPacketSize + n * extentedHeaderPacketSize, 'bof');
                continue;
            elseif ( id > maximumChannelNumber )
                if ( ~foundStimMarkers )
                    warning( 'NEVGetHeaders:stimMarkersFound', 'Stim markers found');
                    % skip to the next NEV header
                    fseek(fid, basicHeaderPacketSize + n * extentedHeaderPacketSize, 'bof');
                    foundStimMarkers = 1;
                    continue;
                end
            end
            maximumChannelNumberObserved = ...
                max( maximumChannelNumberObserved, id );
            NEVwaveformHeader(id).id = id;
            
            switch HeaderName
                case 'NEUEVWAV' % Basic neural event waveform data
                    
                    NEVwaveformHeader(id).existNEUEVWAV = 1;
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).pinch, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).pinnum, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).sf, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).energythreshold, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).highthreshold, ncount ] = fread( fid, [1,ncountTest], 'int16' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).lowthreshold, ncount ] = fread( fid, [1,ncountTest], 'int16' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).numberunits, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).numberbytes, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    if( NEVbasicHeader.fileformat16Bit == 1 )
                        NEVwaveformHeader(id).numberbytes = 2;
                    else
                        if( NEVwaveformHeader(id).numberbytes == 0 )
                            NEVwaveformHeader(id).numberbytes = 1;
                        end
                    end
                    
                    ncountTest = 10;[ NEVwaveformHeader(id).dummy, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

                case 'NEUEVLBL' % Neural event channel label
                    
                    NEVwaveformHeader(id).existNEUEVLBL = 1;
                    
                    ncountTest = 16;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
                    else
                        NEVwaveformHeader(id).label = char( temp );
                    end
                    
                    ncountTest = 6;[ NEVwaveformHeader(id).dummy1, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

                case 'NEUEVFLT' % Neural event channel filtering

                    NEVwaveformHeader(id).existNEUEVFLT = 1;

                    ncountTest = 1;[ NEVwaveformHeader(id).highfreqcorner, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).highfreqorder, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).highfreqtype, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).lowfreqcorner, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).lowfreqorder, ncount ] = fread( fid, [1,ncountTest], 'uint32' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 1;[ NEVwaveformHeader(id).lowfreqtype, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                    
                    ncountTest = 2;[ NEVwaveformHeader(id).dummy2, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                    if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

            end;clear id
            
        case { 'STIMINFO', 'NSASEXEV' } % External I/O info
            
            switch HeaderName % External I/O info, note goes back to NSAS
                case 'STIMINFO'
                    NEVexternalIOHeader.existSTIMINFO = 1;
                case 'NSASEXEV' % External I/O info
                    NEVexternalIOHeader.existNSASEXEV = 1;
            end

            ncountTest = 1;[ NEVexternalIOHeader.PeriodicRes, ncount ] = fread( fid, [1,ncountTest], 'uint16' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
            
            ncountTest = 1;[ NEVexternalIOHeader.DigitalConfig, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
            
            for m=1:5;
                
                ncountTest = 1;[ NEVexternalIOHeader.AnalogConfig(m).Config, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
                if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                
                ncountTest = 1;[ NEVexternalIOHeader.AnalogConfig(m).Level, ncount ] = fread( fid, [1,ncountTest], 'int16' );
                if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
                
            end;clear m
            
            ncountTest = 6;[ NEVexternalIOHeader.dummy, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end
            
        case 'DIGLABEL' % External I/O label
            
            ncountTest = 16;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
            else
                tempLabel = char( temp );
            end
            
            ncountTest = 1;[ tempMode, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

            ncountTest = 7;[ tempDummy, ncount ] = fread( fid, [1,ncountTest], 'uint8' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;end

            switch tempMode
                case 0
                    NEVexternalIOHeader.existDIGLABELSerial = 1;
                    NEVexternalIOHeader.SerialLabel = tempLabel;
                    NEVexternalIOHeader.SerialDummy = tempDummy;
                case 1
                    NEVexternalIOHeader.existDIGLABELParallel = 1;
                    NEVexternalIOHeader.ParallelLabel = tempLabel;
                    NEVexternalIOHeader.ParallelDummy = tempDummy;
                otherwise
            end;clear tempLabel tempMode tempDummy % Digital mode
        
        case 'ARRAYNME' % name of array

            NEVarrayHeader.existARRAYNME = 1;
            
            ncountTest = 24;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
            else
                NEVarrayHeader.arrayName = char( temp );
            end
            
        case 'MAPFILE' % name of array

            NEVarrayHeader.existMAPFILE = 1;
            ncountTest = 24;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
            else
                NEVarrayHeader.mapfile = char( temp );
            end
            
        case { 'ECOMMENT', 'CCOMMENT' } % name of array
            
            NEVcommentsText(end+1,1).existECOMMENT = 0; %#ok<AGROW>
            NEVcommentsText(end,1).existCCOMMENT = 0; %#ok<AGROW>
            
            switch HeaderName
                case 'ECOMMENT'
                    NEVcommentsText(end,1).existECOMMENT = 1; %#ok<AGROW>
                case 'CCOMMENT'
                    NEVcommentsText(end,1).existCCOMMENT = 1; %#ok<AGROW>
            end;
            
            ncountTest = 24;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' );
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
            else
                NEVcommentsText(end,1).Comment = char( temp ); %#ok<AGROW>
            end
            
        otherwise
            
            fprintf( 'Unhandled header packet type with code %s\n', HeaderName );
            ncountTest = 24;[ temp, ncount ] = fread( fid, [1,ncountTest], 'uint8=>char' ); %#ok<ASGLU>
            if( ncount ~= ncountTest );warning( 'NEVGetHeaders:readCountError', 'Unable to read correct number of elements' );return;
            else
            end;clear temp
            
    end;clear HeaderName% switch on packet id
end;clear n

%% Resize NEVwaveformHeader based on data available
if( maximumChannelNumberObserved == 0 )
    NEVwaveformHeader = [];
else
    % Instead of removing channels smaller than the number observed, we will 
    % remove channels that don't have NEUEVWAV headers.
    NEVwaveformHeader = NEVwaveformHeader([NEVwaveformHeader.existNEUEVWAV]==1);
    % Because Cerebus always has consecutive electrodes IDs headers could
    % be chosen by the maximum channel number.
    % if( maximumChannelNumberObserved < maximumChannelNumber )
    %   NEVwaveformHeader = NEVwaveformHeader(1:maximumChannelNumberObserved);
    % end
end

return;




