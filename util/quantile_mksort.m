function q = quantile_mksort(x, p, d)
% QUANTILE_MKSORT Produce quantiles for mksort.
%    Q = QUANTILE_MKSORT(X, P[, D]) returns the quantiles, Q of the
%    observations, X for the requested probabilities, P.  Optional
%    argument, D, allows the choice of dimension.
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

if any(p < 0) || any(p > 1.0) || ~isreal(p)
  error('probabilities must be between 0 and 1');
end
xsize = size(x);

% if dimension is not specified use the first nonsingleton.
if nargin < 3
  d = find(xsize ~= 1, 1);
  % in case x is scalar
  if isempty(d)
    d = 1;
  end
end
n = size(x, d);
% reshape the data so that the first nonsingleton dimension is first
ncols = numel(x) / n;
x = reshape(x, n, ncols);
% sort based off this first dimension
x = sort(x, 1);
% total possible number of quantiles for this data including 0 and 1
bins = [0 (0.5:(n-0.5))./n 1]'; 
% pad x by doubling the first and last entries so that it has the same number 
% of elements as bins
xp = [x(1,:); x(1:n,:); x(n,:)];
% interpolate between the quanitle bins for the requested quantiles
q = interp1q(bins, xp, p(:));
