function [fileNameComplete, fileFolder, fileName] = matRad_generateFileName(fileFolder, pln, workspaceType)
% matRad_generateFileName - Generate consistent file names for matRad workspaces
%
% Syntax:  [fileNameComplete, fileFolder, fileName] = ...
%              matRad_generateFileName(fileFolder, pln, workspaceType)
%
% Inputs:
%   fileFolder     - Target save folder (string)
%   pln            - matRad plan structure (struct)
%   workspaceType  - Workspace type identifier ('Base' or 'Full') (string)
%
% Outputs:
%   fileNameComplete - Full path to generated file (string)
%   fileFolder       - Input folder path (string)
%   fileName         - Generated file name (string)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: findFileName

    if nargin < 3
        error('All inputs (fileFolder, pln, workspaceType) must be provided.');
    end
    if ~isfield(pln, 'propStf') || ~isfield(pln, 'propDoseCalc')
        error('Plan must contain propStf and propDoseCalc fields.');
    end

    % -- Gantry Angle Separation --
    gantryAngles = pln.propStf.gantryAngles;
    if numel(gantryAngles) >= 2
        gantrySep = abs(gantryAngles(2) - gantryAngles(1));
    else
        gantrySep = 0;
    end
    gantryStr = ['Gantry' num2str(round(gantrySep))];

    % -- Dose Resolution String --
    res = pln.propDoseCalc.doseGrid.resolution;
    resStr = ['Res' num2str(res.x) num2str(res.y) num2str(res.z)];

    % -- Timestamp --
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % -- File Name Construction --
    fileName = sprintf('%s_plnstfdij%s%s_%s.mat', workspaceType, gantryStr, resStr, timestamp);

    % -- Combine with Folder Path --
    fileNameComplete = fullfile(fileFolder, fileName);
end
