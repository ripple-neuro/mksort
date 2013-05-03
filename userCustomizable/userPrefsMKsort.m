%% ================ User-customizable functionality ===================
% This file allows the user to add in their own functionality in two
% places (and also change their default directory).
%
% First, you can add in their own functions for reading behavioral data and
% adding relevant timing events. This permits use of the tuning consistency
% tool.
%
% Second, you can add your own merge functions, so that you can fold the
% spike sorts back into your own data using the menus.
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


%% Default path

handles.defaultDataDir = '/data/SS';





%% Add trial/condition info into sorts
% To add a new function, follow the model of the below 3 lines. '.label' is
% what will appear in the options menu. '.fcn' should be the name of your
% function.

% --- Copy the 3 lines below to add a new trial/condition info function ---
trialInfoFcn.label = 'R structure';
trialInfoFcn.fcn = 'trialInfoFromR';
handles.trialInfoFcns{end+1} = trialInfoFcn;

% --- Paste those 3 lines here, then customize them, to add your new trial/condition info function ---




% The following line sets the default trial/condition info function. Change
% it to your own function's name.
defaultTrialInfoFcn = 'trialInfoFromR';









%% Add merge functions
% To add a new merge function, follow the model of the below 3 lines. As
% above, '.label' is what will appear in the options menu. '.fcn' should be
% the name of your function.

% --- Copy the 3 lines below to add a new merge function ---
mergeSortsIntoDataFcn.label = 'R structure';
mergeSortsIntoDataFcn.fcn = 'mergeHandsortsIntoR';
handles.mergeSortsIntoDataFcns{end+1} = mergeSortsIntoDataFcn;

% --- Paste those 3 lines here, then customize them, to add your new merge function ---




% The following line sets the default merge function. Change it to your own
% function's name.
defaultMergeSortsIntoDataFcn = 'mergeHandsortsIntoR';

