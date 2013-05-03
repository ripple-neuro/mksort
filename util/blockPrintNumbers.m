function blockPrintNumbers(v, nPerRow)
% blockPrintNumbers(v, nPerRow)
%
% Print the numbers in vector v using fprintf, with spaces between them
% and a newline after every nPerRow values. Also prints a newline at the
% end. Floats are printed with 3 decimal places.
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

isInt = isinteger(v) || all((floor(v) - v) == 0);

i = 1;
while i < length(v)
  endi = min(i + nPerRow - 1, length(v));
  if isInt
    fprintf('%d ', v(i:endi));
  else
    fprintf('%0.3f ', v(i:endi));
  end
  fprintf('\n');
  i = i + nPerRow;
end
