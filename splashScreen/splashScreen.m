function splashScreen(imageFile, time)
% SPLASHSCREEN Produces splash screen using Swing JLabels.
%
% This file is part of the spike sorting software package MKsort, licensed
% under GPL version 2.

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

splashImage = imread(imageFile);
javaImage = im2java(splashImage);

label = javax.swing.JLabel(javax.swing.ImageIcon(javaImage));

swingWindow = javax.swing.JWindow;
swingWindow.getContentPane().add(label);
swingWindow.setAlwaysOnTop(1);
swingWindow.pack;

screenSize = get(0, 'screensize');
width = screenSize(3);
height = screenSize(4);
swingWindow.setLocation((width - javaImage.getWidth()) / 2, ...
    (height - javaImage.getHeight()) / 2);

swingWindow.show();
tic;
while toc < time; end

swingWindow.dispose();



