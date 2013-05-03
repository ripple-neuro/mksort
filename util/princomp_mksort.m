function [v, y] = princomp_mksort(x)
% PRINCOMP_MKSORT A trimmed down version of princomp for mksort.
%   [V, Y] = PRINCOMP_MKSORT(X) Returns the principle component coefficients, V, 
%     and the representation of X in principal component space, Y.
% 
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
n = size(x, 2);
% mean-subtract the data
xx = bsxfun(@minus, x, mean(x, 1));
% Get SVD.  Always use the economy version, i.e. 0 option.  v is already
% the principal component values ordered largest first.
[u, s, v] = svd(xx, 0); 

% Get x in the component space.
if n == 1 
    s = s(1);
else
    s = diag(s);
end
y = bsxfun(@times, u, s');

