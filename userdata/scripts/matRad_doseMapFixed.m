function doseColorMap = matRad_doseMapFixed()
% matRad_makeBinnedCmap - Discrete cmap with fixed base palette + plateau, and borders 0..21
%
% Syntax:
%   [cmap, borders] = matRad_makeBinnedCmap(nBins)

d = zeros(60, 3);

base = jet(9);
for i = 1:6, doseColorMap(i, :) = base(2, :); end;
for i = 7:12, doseColorMap(i, :) = base(3, :); end;
for i = 13:18, doseColorMap(i, :) = base(4, :); end;
for i = 19:24, doseColorMap(i, :) = base(5, :); end;
for i = 25:30, doseColorMap(i, :) = base(6, :); end;
for i = 31:36, doseColorMap(i, :) = base(7, :); end;
for i = 37:42, doseColorMap(i, :) = base(8, :); end;
for i = 43:48, doseColorMap(i, :) = base(9, :); end;
for i = 49:60, doseColorMap(i, :) = [0.667000000000000	0	0]; end;

end