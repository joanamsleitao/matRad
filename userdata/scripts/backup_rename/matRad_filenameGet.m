function [fileNameComplete, fileFolder, fileName, foundMatches] = matRad_filenameGet(fileFolder, gantrySep, res, workspaceType)
% FINDFILENAME - Find matRad workspace file based on gantry angle and resolution
%
% Syntax:  [fileNameComplete, fileFolder, fileName, foundMatches] = ...
%              matRad_findFileName(fileFolder, gantrySep, res, workspaceType)
%
% Inputs:
%   fileFolder     - Path to search folder (string)
%   gantrySep      - Gantry separation angle [degrees] (double)
%   res            - Dose grid resolution [x y z] (double array)
%   workspaceType  - File prefix filter ('Base' or 'Full') (string, optional)
%
% Outputs:
%   fileNameComplete - Full path to first matching file (string)
%   fileFolder       - Input folder path (string)
%   fileName         - Name of first matching file (string)
%   foundMatches     - Cell array of all matching files (cell array)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: generateFileName

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