function plotAutocorrsInAxes(autocorrs, nAutocorrs, nUnits, has, color, redRefracViolThresh)
% Plots autocorrelation/ISI plots in specified axes. nUnits is the maximum
% number of possible units, has is a vector of handles to the axis objects,
% color is a (nUnits x 3) matrix specifying the colors for each unit
% (excluding zero-unit).
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

for u = 1:nUnits
  activateAxes(gcbf, has(u));
  hold on;
  cla;
  
  % If there is a unit, display it; if not, gray the plot
  if nAutocorrs >= u && ~isempty(autocorrs(u).values)
    % Make plot background white
    set(gca, 'color', [1 1 1]);
    
    % Find max; if no values, arbitrary scaling
    theMax = max(autocorrs(u).values);
    if theMax == 0, theMax = 1; end;
    
    % Calculate a rescaled tick for the bin that is partially locked out, if any
    lockBin = ceil(autocorrs(u).lockout);
    if lockBin ~= autocorrs(u).lockout
      rescale = autocorrs(u).values(lockBin) / (lockBin - autocorrs(u).lockout);
      theMax = max(theMax, rescale);
    end
    
    % Plot gray lockout rectangle
    rectangle('Position', [0 0 autocorrs(u).lockout theMax*1.2], 'EdgeColor', 'w', 'FaceColor', [0.8 0.8 0.8]);

    % Plot rescaled tick
    if lockBin ~= autocorrs(u).lockout && rescale > 0
      plot([lockBin-1 lockBin], rescale*[1 1], '-', 'LineWidth', 2, 'color', color(u,:));
    end

    
    % Plot autocorr/ISI values. Line plot for autocorrs, histogram for
    % ISIs. We know which it is because autocorrs have 11 points for 10 ms
    % while ISIs have 10.
    if length(autocorrs(u).lags) == 11
      plot(autocorrs(u).lags, autocorrs(u).values, 'color', color(u,:), 'LineWidth', 1.5);
    else
      bh = bar(autocorrs(u).lags, autocorrs(u).values);
      set(bh, 'EdgeColor', color(u,:), 'FaceColor', color(u,:), 'BarWidth', 1);
    end
    
    % Figure out whether refractory violation text should be gray (OK) or
    % red (too many)
    if autocorrs(u).percRefractoryViolations > redRefracViolThresh
      refracColor = [1 0 0];
    else
      refracColor = [0.5 0.5 0.5];
    end
    % abs() below is to get rid of tiny tiny negative values due to
    % rounding error with 0 in xcorr.
    refrac = abs(autocorrs(u).percRefractoryViolations);
    % If == 0, plot 0 not 0.0
    if refrac < 0.00001
      text(0.1, 1.1*theMax, '0', 'color', refracColor);
    else
      text(0.1, 1.1*theMax, sprintf('%0.1f', refrac), 'color', refracColor);
    end
    
    % Choose nice scaling
    axLims([0 autocorrs(u).lags(end) 0 theMax*1.2]);
  else
    % Make plot background gray if no values
    set(gca, 'color', [0.9 0.9 0.9]);
  end
end
