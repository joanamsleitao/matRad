function matRad_plotCompare3Doses(ct, cst, doseLeft, doseMiddle, doseRight, doseRangeGy, figName)
% matRad_plotELCompare - Compare full-plan dose vs single-EL vs optimized EL
%
% Syntax:
%   matRad_plotELCompare(ct, cst, doseAllEL, doseELorig, doseELOpt)
%   matRad_plotELCompare(ct, cst, doseAllEL, doseELorig, doseELOpt, doseRangeGy)
%
% Description:
%   Creates a 1x3 tiled figure showing:
%     1) Full plan dose (all ELs)
%     2) Dose from one original energy layer
%     3) Dose from optimized single energy layer
%
% Inputs:
%   ct          - CT struct
%   cst         - CST cell array
%   doseAllEL   - dose cube of full plan (e.g. doseCubeRBE)
%   doseELorig  - dose cube of original single EL
%   doseELOpt   - dose cube of optimized single EL
%   doseRangeGy - (optional) [min max] for color scale (default [0 12])
%
% Outputs:
%   (none) - figure is created
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_plotELCompare` | `matRad_plotELCompare` | 3-panel comparison of full vs single vs optimized EL dose | `matRad_plotELCompare(ct, cst, doseAllEL, doseELorig, doseELOpt, [0 12])` | 🟢 |
% -------------------------------------------------------------------------

if nargin < 6 || isempty(doseRangeGy)
    doseRangeGy = [ ];
end

figure('Color','w', 'Units', 'normalized', 'OuterPosition', [0 0 1 1], 'name', figName);

t = tiledlayout(1, 3);
title(t, figName, 'FontWeight', 'bold', 'FontSize', 16);

nexttile;
matRad_showSliceFast(ct, cst, doseLeft, [], [], 0, 1);
title(' ');

nexttile;
matRad_showSliceFast(ct, cst, doseMiddle, [], doseRangeGy, 0, 1);
title(' ');

nexttile;
matRad_showSliceFast(ct, cst, doseLeft, [], doseRangeGy, 0, 1);  % was: [], []
title(' ');
end