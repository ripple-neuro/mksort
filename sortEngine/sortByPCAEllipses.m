function units = sortByPCAEllipses(method, waveforms, PCAPts, sorts, varargin)
% The master sort function for the PCAEllipses sort type.
%
% See sortWaveforms() above for an explanation of the optional argument.
%
% To specify a PCAEllipses-type 2D-PCA sorting function, it should have the
% prototype:
% units = fcnName(PCAEllipses, PCAPts)
%
% PCAPts should either contain the correct points in PCA space (nDims x
% nWaves), or be empty, in which case the PCAPts will be regenerated from
% the coefficients stored in sorts
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

if isempty(waveforms)
  units = [];
  return;
end

% If needed, regenerate PCAPts from stored PCA coefficients
if isempty(PCAPts)
  coeffs = sorts(1).PCAEllipses.PCACoeffs(1:sorts(1).nPCADims, :);
  PCAPts = coeffs * zscore_mksort(waveforms, 0, 2);
end

units = zeros(1, size(waveforms, 2));
% Figure out indices of waves so that we sort using values from the right
% epoch, and so that we can just use the cached PCAPts.
if ~isempty(varargin)
  waveIndices = varargin{1};
else
  waveIndices = [];
end
for epoch = 1:length(sorts)
  if isempty(waveIndices)
    thesePts = sorts(epoch).epochStart:sorts(epoch).epochEnd;
    thisEpoch = false(1, size(waveforms, 2));
    thisEpoch(thesePts) = 1;
    thesePCAPts = PCAPts(:, thesePts);
  else
    thisEpoch = (waveIndices >= sorts(epoch).epochStart & waveIndices <= sorts(epoch).epochEnd);
    thesePCAPts = PCAPts(:, waveIndices(thisEpoch));
  end
  units(thisEpoch) = feval(method.classifyFcn, sorts(epoch).PCAEllipses, thesePCAPts);
end
