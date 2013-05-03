function varargout = aboutDialog(varargin)
% ABOUTDIALOG MATLAB code for aboutDialog.fig
%      ABOUTDIALOG, by itself, creates a new ABOUTDIALOG or raises the existing
%      singleton*.
%
%      H = ABOUTDIALOG returns the handle to a new ABOUTDIALOG or the handle to
%      the existing singleton*.
%
%      ABOUTDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ABOUTDIALOG.M with the given input arguments.
%
%      ABOUTDIALOG('Property','Value',...) creates a new ABOUTDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before aboutDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to aboutDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% This file is part of the spike sorting software package MKsort, licensed
% under GPL version 2.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; version 2 of the License.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

% Edit the above text to modify the response to help aboutDialog

% Last Modified by GUIDE v2.5 25-Apr-2013 16:14:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @aboutDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @aboutDialog_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before aboutDialog is made visible.
function aboutDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to aboutDialog (see VARARGIN)

% Choose default command line output for aboutDialog
handles.output = hObject;

DIALOG_IMAGE = 'about_dialog_with_link.png';
mksortPath = fileparts(which('mksort'));

imageFilePath = fullfile(mksortPath, 'aboutDialog', DIALOG_IMAGE);

i = imread(imageFilePath);

% 
set(handles.figure1, 'units', 'pixels');
pos = getpixelposition(handles.figure1);

set(handles.figure1, 'position', [pos(1), pos(2), size(i, 2), size(i, 1)]);
javaImage = im2java(i);
label = javacomponent('javax.swing.JLabel', [1, 1, 550, 700]);
label.setIcon(javax.swing.ImageIcon(javaImage));
label.show();

% Create link to full GPL license
% Using swing Label for for GPL link so that we can use HTML to render text, as
% well change the cursor into a hand when the cursor is hovering over the
% link.
label = javacomponent('javax.swing.JLabel', [140, 270, 300, 20]);
% The color provided here matches the RBG of the background image that
% Christine has provided.  This way the link text appears seemlessly on the
% dialog.
label.setBackground(java.awt.Color(230/255, 230/255, 230/255));
% Create a link to the full gpl v2.
gnuLink = 'http://www.gnu.org/licenses/gpl-2.0.html';
label.setText(sprintf('<html> <a href="%s"> %s </a></html>', gnuLink, gnuLink));
% Set the callback to open the link with the Matlab browser.
label.mouseClickedCallback = sprintf('web(''%s'')', gnuLink);
% It's not a hyperlink unless the cursor turns into a pointing finger.
label.setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));
label.show();

guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = aboutDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
