function matRad_plotELCompare(ct, cst, doseAllEL, doseELorig, doseELOpt, doseRangeGy, ELName)
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

fig = figure('Color','w', 'Units', 'normalized', 'OuterPosition', [0 0 1 1], ...
       'Name', ['Dose Distribution Comparison of ', ELName]);
t = tiledlayout(1, 3);
title(t, regexprep(regexprep(ELName, 'EL_', 'EL '), '_', '.'), 'FontWeight', 'bold', 'FontSize', 16);

nexttile;
matRad_showSliceFast(ct, cst, doseAllEL, [], doseRangeGy, 0, 1);
title('Dose: all ELs');

nexttile;
matRad_showSliceFast(ct, cst, doseELorig, [], doseRangeGy, 0, 1);
title('Dose: pre-spot opt 97.5 MeV EL');

nexttile;
matRad_showSliceFast(ct, cst, doseELOpt, [], doseRangeGy, 0, 1);
title('Dose: spot and dose opt single-EL');

fontsize(14, 'points')
end