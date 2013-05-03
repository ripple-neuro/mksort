function sos = cerebusFilter(filtid)
% sos = cerebusFilter(filtid)
%
% This function returns the sos field of an SOS filter for use with
% sosfilt. Valid filtid specs are:
%
% 'HP 750 Hz'
% 'HP 250 Hz'
% 'HP 100 Hz'
% '"Spike Narrow" Cerebus v.4 or lower' or 'SpikeNarrowV4-'
% '"Spike Medium" Cerebus v.4 or lower' or 'SpikeMediumV4-'
% '"Spike Wide" Cerebus v.4 or lower' or 'SpikeWideV4-'
%
% This file is part of the spike sorting software package MKsort, licensed
% under GPL version 2.
% 
% Copyright (C) 2010, 2011, 2012, 2013 The Board of Trustees of The Leland
% Stanford Junior University
% 
% Written by Matt Kaufman
% This function partly based on rr_filter by Gopal Santhanam.
% 
% Please see mksort.m for full license and contact details.


% Use sosfilt in matlab.
% f1a0 is assumed to be 1.

% For the newer filters, gain is embedded into the b0 b1 b2 coeffs.

if ~ischar(filtid)
  error('cerebusFilter:filidNotString', 'Argument must be a string specifying filter spec');
end

switch (filtid)
 case {'HP 750 Hz'}, 
  sos = [...
      [1,-2.000000061951650,1.000000025329964] .* 0.814254556886247,...
      1,-1.725933395036931,0.747447371907782; ...
      1,-1.999999938048353,0.999999974670039,...
      1,-1.863800492075247,0.887032999652709];
 
 case {'HP 250 Hz'}, 
  sos = [... 
      [1,-2.000000061951650,1.000000025329964] .* 0.933867573636478,...
      1,-1.905141444109443,0.907755957344679; ...
      1,-1.999999938048353,0.999999974670039,...
      1,-1.958043178316561,0.960730291036509];

 case {'HP 100 Hz'}, 
  sos = [...
      [1,-2.000000057758566,1.000000007740578] .* 0.973005857545153,...
      1,-1.961607646536474,0.962037953881519; ...
      1,-1.999999942241435,0.999999992259421,...
      1,-1.983663657304700,0.984098802960298];
    
    
 case {'"Spike Narrow" Cerebus v.4 or lower', 'SpikeNarrowV4-'},
    sos = [...
      0.86834523027112,-1.73669045530405,0.86834522455810,...
      1, -1.72593339503694, 0.74744737190779; ...
      0.93770833131889,-1.87541666829439,0.93770833748826,...
      1, -1.86380049207524,0.88703299965269];

 case {'"Spike Medium" Cerebus v.4 or lower', 'SpikeMediumV4-'}, 
  sos = [...
      0.95321773445431,-1.90644870937033,0.95323097500802,...
      1, -1.90514144409761,0.90775595733389; ...
      0.97970016700443,-1.95938672569874,0.97968655878878,...
      1, -1.95804317832840,0.96073029104793];
 
 case {'"Spike Wide" Cerebus v.4 or lower', 'SpikeWideV4-'}, 
  sos = [...
      0.98091008834795,-1.96182280161008,0.98091271326564,...
      1, -1.96160764650672,0.96203795385298; ...
      0.99194194157376,-1.98388122871212,0.99193928714191,...
      1, -1.98366365733446,0.98409880298949];
    
  otherwise
    error('cerebusFilter:unknownFilter', 'Unknown filter spec: %s', filtid);
end
