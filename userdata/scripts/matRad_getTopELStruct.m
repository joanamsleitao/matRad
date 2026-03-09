function topELStruct_topN = matRad_getTopELStruct(voiDoseByEL, topELStruct, N)
% matRad_getTopELStruct - Extract and plot top N energy layers by dose
%
% Syntax:
%   matRad_getTopELStruct(voiDoseByEL, topELStruct, N, ct, cst, stf, qiByEL, nTarget)
%   matRad_getTopELStruct(voiDoseByEL, topELStruct, N, ct, cst, stf, qiByEL, nTarget, nRows, nCols)
%
% Description:
%   Sorts energy layers by MaxDose, extracts the top N layers, and plots
%   their dose distributions using matRad_plotDoseEL.
%
% Inputs:
%   voiDoseByEL  - table with columns: VOI, EL_Name, Energy_MeV, MeanDose, MaxDose, MinDose
%   topELStruct  - struct containing all energy layer data (RBExDose, w, etc.)
%   N            - number of top layers to plot
%   ct           - matRad CT struct
%   cst          - matRad CST (cell array of VOIs)
%   stf          - beam geometry struct
%   qiByEL       - struct of per-VOI quality indices by energy layer
%   nTarget      - string with name of target VOI (e.g. 'GTV')
%   nRows        - (optional) number of rows in subplot grid
%   nCols        - (optional) number of columns in subplot grid
%
% Outputs:
%   (none - generates plot)
%
% Example:
%   matRad_getTopELStruct(voiDoseByEL, topELStruct, 5, ct, cst, stf, qiByEL, 'GTV', 2, 3);
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------
% 1) Sort table by MaxDose (descending)
voiDoseByEL_sorted = sortrows(voiDoseByEL, 'MaxDose', 'descend');
voiDoseByEL_sorted = voiDoseByEL_sorted(1:N,:);

voiDoseByEL_sorted = sortrows(voiDoseByEL_sorted, 'Energy_MeV', 'ascend');

% 2) Build reduced topELStruct with top N layers
N = min(N, height(voiDoseByEL_sorted));
topELStruct_topN = struct();

for i = 1:N
    elName = voiDoseByEL_sorted.EL_Name{i};
    topELStruct_topN.(elName) = topELStruct.(elName);
end

% 3) Set default layout if not provided
if nargin < 9 || isempty(nRows) || isempty(nCols)
    nRows = [];
    nCols = [];
end

end