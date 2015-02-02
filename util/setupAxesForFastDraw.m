function setupAxesForFastDraw(ha)
% setupAxesForFastDraw(ha)
%
% Based in part on Matlab's doc_perfex, this function sets up the
% properties of a set of axes to speed up drawing. A bunch of camera and
% tick modes get set to manual, and the DrawMode gets set to fast.
%
% ha is the handle to the axes object
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

% [ELB-2015/02/02] 'DrawMode' 'fast' is deprecated in 2014 and 'SortMode'
% is now recommended.  On my machine, I don't see any difference between
% 'DrawMode' 'fast' or changes in 'SortMode' property.  If this begins to
% cause trouble, a user could try to use 'SortMode' to 'depth' or submit an
% issue.
% set(ha, 'DrawMode', 'fast');
% set(ha, 'SortMode', 'depth');

% According to the original documentation for doc_perfex:
% Do not set CameraViewAngleMode, DataAspectRatioMode,
% and PlotBoxAspectRatioMode to avoid exposing a bug
%
% In addition, there appears to be a bug introduced when setting
% CameraPositionMode or CameraTargetMode to manual. Whatever.
pn = {'ALimMode', ...
  'CameraUpVectorMode','CLimMode',...
  'TickDirMode','XLimMode',...
  'YLimMode','ZLimMode',...
  'XTickMode','YTickMode',...
  'ZTickMode','XTickLabelMode',...
  'YTickLabelMode','ZTickLabelMode'};

% For reference, the list of properties set by doc_perfex:
% pn = {'ALimMode',...
%   'CameraPositionMode','CameraTargetMode',...
%   'CameraUpVectorMode','CLimMode',...
%   'TickDirMode','XLimMode',...
%   'YLimMode','ZLimMode',...
%   'XTickMode','YTickMode',...
%   'ZTickMode','XTickLabelMode',...
%   'YTickLabelMode','ZTickLabelMode'};

pv = repmat({'manual'}, 1, length(pn));
set(ha, pn, pv);
