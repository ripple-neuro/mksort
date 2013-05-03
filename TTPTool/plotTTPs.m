function plotTTPs(TTPwaves, varargin)
% plotTTPs(TTPwaves)
% plotTTPs(TTPwaves, boundary)
% plotTTPs(TTPwaves, lowerThresh, upperThresh)
% plotTTPs(TTPwaves, lowerThresh, upperThresh, troughToPeakBins)
%
% Plot waveforms and colored histograms for the TTP tool.
%
% Default boundary is 200 us
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

% TODO: is it worth making the sampling rate here variable?

% Default dividing line between narrow-spiking and broad-spiking, in us
defaultBoundary = 200;

sampleRate = 30000;       % Sampling rate in Hz


switch length(varargin)
  case 0                            % No boundary specified
    lowerThresh = defaultBoundary;
    upperThresh = defaultBoundary;
  case 1                            % Using 'boundary'
    lowerThresh = varargin{1};
    upperThresh = varargin{1};
  otherwise                         % Using 'lowerThresh' and 'upperThresh'
    lowerThresh = varargin{1};
    upperThresh = varargin{2};
end

if length(varargin) == 3
  troughToPeakBinWidth = varargin{3};
else
  troughToPeakBinWidth = 15;
end

TTPwaves = TTPwaves(logical([TTPwaves.good]));


troughToPeak = [];

globalMax = 0;
for i = 1:length(TTPwaves)
  wave = TTPwaves(i).wave;
  wave = wave - TTPwaves(i).baseline;
  wave = wave/abs(min(wave));

  if max(wave) > globalMax, globalMax = max(wave); end;

  troughToPeak = [troughToPeak TTPwaves(i).TTP];
end

fprintf('%d analyzable neurons\n', length(TTPwaves));

interneurons = (troughToPeak <= lowerThresh);
nonInterneurons = (troughToPeak > upperThresh);
boundary = (troughToPeak > lowerThresh) & (troughToPeak <= upperThresh);

fprintf('%d narrow-spiking neurons\n', sum(interneurons));
fprintf('%d broad-spiking neurons\n', sum(nonInterneurons));
if sum(boundary) > 0
  fprintf('%d boundary-zone neurons\n', sum(boundary));
end


% Waveforms figure

blankFigure;
axis auto

for isInt = 0:1
  for i = 1:length(TTPwaves)
    if interneurons(i) == isInt
      if isfield(TTPwaves, 'valleyWave')
        wave = TTPwaves(i).valleyWave;
      else
        wave = TTPwaves(i).wave;
      end

      wave = wave - TTPwaves(i).baseline;
      wave = wave/abs(min(wave));

      if interneurons(i)
        color = 'r';
      elseif boundary(i)
        color = 'g';
      else
        color = 'b';
      end
      plot((1:length(wave))/sampleRate*100000, wave, color);
    end
  end
end

% Scale bar, 200 us
rectangle('Position', [400 -0.8 200 0.02*(1+globalMax)], 'FaceColor', 'k');
text(450, -0.72, '200 \mus');


% Trough to peak figure

bottomBin = lowerThresh - troughToPeakBinWidth * ceil(120/troughToPeakBinWidth);
troughToPeakBins = (bottomBin:troughToPeakBinWidth:800) + 0.01;

nInt = histc(troughToPeak(interneurons), troughToPeakBins);
nBoundary = histc(troughToPeak(boundary), troughToPeakBins);
nNonInt = histc(troughToPeak(nonInterneurons), troughToPeakBins);
maxCount = max([nInt nBoundary nNonInt]);

blankFigure([70 800 -1 maxCount]);
barStacked(troughToPeakBins-0.01, [nNonInt', nBoundary', nInt'], {'b', 'g', 'r'});

params.tickLocations = 100:100:800;
params.axisLabel = 'Trough to peak (\mus)';
params.fontSize = 11;
AxisMMC(100, 800, params);
params.axisOrientation = 'v';
params.axisOffset = 80;
params.tickLocations = 0:2:maxCount;
params.axisLabel = '# of Neurons';
AxisMMC(0, params.tickLocations(end), params);
