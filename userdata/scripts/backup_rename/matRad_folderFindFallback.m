function fallbackPath = matRad_folderFindFallback(basePath)
% Locate fallback RTFiles_CTandRTStruct folder

candidate = fullfile(fileparts(basePath), 'RTFiles_CTandRTStruct');
if isfolder(candidate)
    fallbackPath = candidate;
else
    warning('Fallback folder not found near %s', basePath);
    fallbackPath = '';
end
end
