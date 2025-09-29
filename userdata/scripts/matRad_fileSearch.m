function matFiles = matRad_fileSearch()
% First try sub-part in filename if given
if numel(wildcardParts) > 1 && ~isempty(wildcard)
    matFiles = dir(fullfile(targetFolder, ['*', wildcard, '*.mat']));
else
    matFiles = [];
end
% If not found, try main wildcard
if isempty(matFiles) && ~isempty(wildcard)
    matFiles = dir(fullfile(targetFolder, ['*', wildcard, '*.mat']));
end
% Fallback: any mat file
if isempty(matFiles)
    matFiles = dir(fullfile(targetFolder, '*.mat'));
end
end