function [fileNameComplete, fileFolder, fileName]  = generateFileName(fileFolder, pln, workspaceType)
% generateWorkspaceFileName - Generate consistent file names for saving matRad workspaces.
%
% Syntax:
%   fileNameComplete = generateWorkspaceFileName(fileFolder, pln, workspaceType)
%
% Inputs:
%   fileFolder      - Path to the folder where the file will be saved
%   pln             - matRad plan struct (must contain propStf and propDoseCalc)
%   workspaceType   - String: 'Base' (e.g., pln/stf/dij) or 'Full' (everything saved)
%
% Output:
%   fileNameComplete - Full path to the generated .mat file

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
