function units = PCACluster2Nearest(PCAEllipses, PCAPts)
% units = PCACluster2Nearest(PCAEllipses, PCAPts)
%
%
% Input values:
%
% PCAEllipses -- the PCAEllipses sort structure from oneChannelSorter
%
% PCAPts      -- the PCA'd points to sort; it should be (nDims x nWaves)
%
%
% Output values:
%
% units        -- this is a (1 x nWaves) vector, where each value is the
%                 classification for that point.
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



thresh = 8;

unitsDefined = [];

nPts = size(PCAPts, 2);
units = zeros(1,nPts);

% Figure out which units are defined
for u = 1:length(PCAEllipses.params)
  if ~isempty(PCAEllipses.params(u).ellipses)
    unitsDefined(end+1) = u - 1;
  end
end

if isempty(unitsDefined) || isequal(unitsDefined, 0)
  return;
end

nDimsToUse = size(PCAPts, 1);
nDims = size(PCAEllipses.params(unitsDefined(1)+1).ellipses, 2) / 2;
ptsToUse = [1:nDimsToUse nDims+(1:nDimsToUse)];

dists = zeros(length(unitsDefined), nPts);

% Find distance from each point to each unit
for u = 1:length(unitsDefined)
  unit = unitsDefined(u);
  nEllipses = size(PCAEllipses.params(unit+1).ellipses, 1);
  % Get distance from each ellipse, take smallest
  eDists = zeros(nEllipses, nPts);
  for e = 1:nEllipses
    ellipse = PCAEllipses.params(unit+1).ellipses(e, ptsToUse)';
    lens = ellipse((nDimsToUse+1):end) / 2;
    c = ellipse(1:nDimsToUse) + lens;
    f = 1./lens.^2;
    eDists(e, :) = sqrt(sum(bsxfun(@times, bsxfun(@minus, PCAPts, c).^2, f), 1));
  end
  dists(u, :) = min(eDists, [], 1);
end

% Assign point to whichever unit is closest, as long as it's close enough
[minDist, minUnit] = min(dists, [], 1);
closeEnough = (minDist < thresh);
units(closeEnough) = unitsDefined(minUnit(closeEnough));
