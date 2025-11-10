function [ct, cst, pln, stf, resultGUI] = matRad_loadFolderMat(folderPath, matFiles, matchPattern, fallbackMat, fallbackPath)
fprintf('→ Folder contains MAT files. Searching for pattern: "%s"\n', matchPattern);

% Find matches
matchedFiles = {};
if ~isempty(matchPattern)
    matches = contains({matFiles.name}, matchPattern, 'IgnoreCase', true);
    matchedFiles = {matFiles(matches).name};
end

% Determine selected file
if isempty(matchedFiles)
    warning('No .mat file matches pattern "%s". Using newest available .mat file.', matchPattern);
    [~, newestIdx] = max([matFiles.datenum]);
    selectedFile = fullfile(folderPath, matFiles(newestIdx).name);
elseif numel(matchedFiles) > 1
    warning('Multiple .mat files match pattern "%s":', matchPattern);
    disp(strjoin(matchedFiles, newline));
    matchedInfo = matFiles(ismember({matFiles.name}, matchedFiles));
    [~, newestIdx] = max([matchedInfo.datenum]);
    selectedFile = fullfile(folderPath, matchedInfo(newestIdx).name);
    fprintf('→ Using newest matching file: %s\n', matchedInfo(newestIdx).name);
else
    selectedFile = fullfile(folderPath, matchedFiles{1});
    fprintf('→ Matched file: %s\n', matchedFiles{1});
end

% Load selected MAT
[ct, cst, pln, stf, resultGUI] = matRad_dataLoadMat(selectedFile);

% Handle missing CT/CST
if (isempty(ct) || isempty(cst))
    if ~isempty(fallbackMat) && isfile(fallbackMat)
        fprintf('→ Using fallback MAT for missing CT/CST: %s\n', fallbackMat);
        [ct_fb, cst_fb, ~, ~, ~] = matRad_dataLoadMat(fallbackMat);
        if isempty(ct), ct = ct_fb; fprintf('  • CT replaced from fallback MAT.\n'); end
        if isempty(cst), cst = cst_fb; fprintf('  • CST replaced from fallback MAT.\n'); end
    elseif ~isempty(fallbackPath)
        fprintf('→ Using fallback DICOM folder for missing CT/CST: %s\n', fallbackPath);
        [ct, cst, pln, stf, resultGUI] = matRad_dicomImportFolder(folderPath, fallbackPath);
    else
        warning('CT or CST missing, no fallback provided.');
    end
end
end