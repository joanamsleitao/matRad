function [fileNameComplete, fileFolder, fileName, foundMatches] = findFileName(fileFolder, gantrySep, res, workspaceType)
% findWorkspaceFileName - Find a matRad workspace file based on gantry angle and resolution.
%
% Syntax:
%   [fileNameComplete, fileFolder, fileName, foundMatches] = ...
%       findWorkspaceFileName(fileFolder, gantrySep, res, workspaceType)
%
% Inputs:
%   fileFolder     - Path to the folder to search in
%   gantrySep      - Scalar: gantry separation (e.g., 5)
%   res            - Struct with [x y z]
%   workspaceType  - (Optional) 'Base' or 'Full' to restrict search by prefix
%
% Outputs:
%   fileNameComplete - Full path to the first matching file
%   fileFolder       - Same as input
%   fileName         - File name only (not full path)
%   foundMatches     - Cell array of all matching file names

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