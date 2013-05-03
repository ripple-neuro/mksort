function [ data, time ] = NSX_read( NSX, channelStart, numberChannels, timeStart, timeWindow, transposeFlag )
%
%   [ data, time ] = NSX_read( NSX, channelStart, numberChannels,, timeStart, timeWindow, transposeFlag )
%
%   This file reads one or more channels from a NSx file.
%
%   This version currently works for both NEV File Specification 2.1 and 2.2.
%
%   Inputs
%
%       NSX             -   Structure from NSX_open call
%
%       channelStart    -   First channel to read (default is first in file)
%
%       numberChannels  -   Number of channels to read (default is all)
%
%       timeStart       -   Time to start reading in seconds (default = 0)
%
%       timeWindow      -   Amount of time to read in seconds (default all)
%
%       transposeFlag   -   <=0 (default) do not transpose
%                           >0  do transpose
%
%   Outputs
%
%       data            -   the data as int16 vector
%
%       time            -   vector of times associated with data
%
%   Written by David J. Warren, University of Utah
%   2009-Nov-21
%
% This file is included as part of the spike sorting software package MKsort, 
% licensed under GPL version 2.
% 
% Please see mksort.m for full license and contact details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: Should this function be modified to return doubles and do the
% conversion here?

%%   magic numbers
%
BytesPerSample = 2;
% readBufferCount = 1024;

%%  Assure have outputs
%
data = [];
time = [];

%%  Check inputs and handle defaults
%
if( nargin < 6 );transposeFlag = [];end
if( nargin < 5 );timeWindow = [];end
if( nargin < 4 );timeStart = [];end
if( nargin < 3 );numberChannels = [];end
if( nargin < 2 );channelStart = [];end
if( nargin < 1 );warning( 'NSX_read:IncorrectNumberofArguments', 'At least one argument required' );end

if( NSX.FID < 0 )
    warning( 'NSX_read:BadFIDValue', 'Bad file open' );
    return;
end

if( isempty( transposeFlag ) )
    transposeFlag = -1;
end
if( isempty( timeWindow ) )
    timeWindow = NSX.TimeRange(1);
end
if( isempty( timeStart ) )
    timeStart = NSX.TimeStart(1);
end
if( isempty( numberChannels ) )
    numberChannels = length( NSX.Channel_ID );
end
if( isempty( channelStart ) )
    channelStart = NSX.Channel_ID(1);
end

%%  Useful parameters
%
nHeaders = length( NSX.header );
nChannels = NSX.Channel_Count;
availableChannels = [ NSX.Channel_ID ];availableChannels = availableChannels(:);


%% Figure out where to start in time
%
timeEnd = timeStart + timeWindow;
header = -1;
for n = 1:nHeaders
    if( ( timeStart >= NSX.TimeStart(n) ) && ( timeStart <= NSX.TimeEnd(n)) )
        header = NSX.header(n);
        headerOffset = ( ( timeStart - NSX.TimeStart(n) ) / NSX.Period ) * BytesPerSample;
        timeEnd = min( timeEnd, NSX.TimeEnd(n) ); % Will not cross data packet boundary
        numberSamples = 1 + ( timeEnd - timeStart ) / NSX.Period;
        break;
    end
end
if( header < 0 )
    warning( 'NSX_read:StartTimeOutOfRange', 'Starting point of time is outside of range of file' );
    return
end

%%  Figure out where to start in data
%
z = find( availableChannels == channelStart );
if( isempty( z ) )
    warning( 'NSX_read:StartChannelNotInFile', 'Starting channel not in file' );
    return;
end
dataOffset = ( z(1) - 1 ) * BytesPerSample;
readSkip = ( nChannels - numberChannels ) * BytesPerSample;
if( readSkip < 0 )
    error( 'NSX_read:TooManyChannels', 'Asking for more channels then there are' );
end

%% Position file
if ( fseek( NSX.FID, header + headerOffset + dataOffset, 'bof' ) == -1 )
    warning( 'NSX_read:PositioningError', 'Unable to position file to start of data' );
    ferror( NSX.FID )
    data = 'NaN';
    return
end;

%%  Go read the data
%
[ data, ncount ] = fread( NSX.FID, [ numberChannels numberSamples ], [ int2str(numberChannels) '*int16=>int16' ], readSkip );
if( ncount ~= fix( numberChannels * numberSamples ) )
    warning( 'NSX_read:BadRead', 'Did not read all the data' );
end

%%  Transpose data
%
if( transposeFlag > 0 )
    data = data';
end

time = timeStart + ((1:numberSamples)'-1)*NSX.Period;

return