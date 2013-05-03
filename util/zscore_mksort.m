function [z,mu,sigma] = zscore_mksort(x, dim)
%ZSCORE_MKSORT Produce Z-Scores of x.
%  [Z, MU, SIGMA] = ZSCORE_MKSORT(X)
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

if nargin < 2
  % find first non-singleton dimension
  dim = find(size(x) ~= 1, 1);
  % in the case that x is scalar
  if isempty(dim)
    dim = 1;
  end
end
% first find mean and RMS
mu = mean(x, dim);
% '0' flags indicates (N-1) normalization
sigma = std(x, 0, dim);

% As this is divided out, remove zeros.
sigma(sigma==0) = 1;

% get mean subtracted version of x.
z = bsxfun(@minus, x, mu);
% rescale x to multiples of RMS.
z = bsxfun(@rdivide, z, sigma);
