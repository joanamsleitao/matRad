function [fileNameComplete, fileFolder, fileName, foundMatches] = matRad_wsFileFind(fileFolder, gantrySep, res, workspaceType)
% matRad_wsFileFind - Find simulation/workspace MAT files by gantry & resolution
%
% Syntax:
%   [fileNameComplete, fileFolder, fileName, foundMatches] = ...
%       matRad_wsFileFind(fileFolder, gantrySep, res, workspaceType)
%
% Description:
%   Searches a folder for workspace/simulation MAT files named with the
%   pattern "<workspaceType>_...Gantry<gantrySep>Res<res>_*.mat".
%
% -------------------------------------------------------------------------

    if nargin < 3
        error('At least fileFolder, gantrySep, and res must be provided.');
    end

    % -- Build search pattern --
    gantryStr = ['Gantry' num2str(round(gantrySep))];
    resStr = ['Res' num2str(res(1)) num2str(res(2)) num2str(res(3))];

    if nargin >= 4 && ~isempty(workspaceType)
        pattern = sprintf('%s_%s%s_*.mat', workspaceType, gantryStr, resStr);
    else
        pattern = sprintf('*%s%s_*.mat', gantryStr, resStr);
    end

    % -- Search --
    fileList = dir(fullfile(fileFolder, pattern));
    
    % -- Extract matches --
    foundMatches = {fileList.name};

    if ~isempty(foundMatches)
        fileName = foundMatches{1};
        fileNameComplete = fullfile(fileFolder, fileName);
    else
        % Fallback: List all .mat files
        fprintf('[INFO] No match found for pattern "%s".\nListing all .mat files in: %s\n', ...
                pattern, fileFolder);
        allFiles = dir(fullfile(fileFolder, '*.mat'));
        foundMatches = {allFiles.name};
        if ~isempty(foundMatches)
            fileName = foundMatches{1};
            fileNameComplete = fullfile(fileFolder, fileName);
        else
            warning('No .mat files found in folder: %s', fileFolder);
            fileName = '';
            fileNameComplete = '';
        end
    end
end