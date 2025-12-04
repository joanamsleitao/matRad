function logFileName = matRad_flashLog(cstFLASH, DMF, doseThreshold, finalMask)
% matRad_flashLog - Print FLASH preprocessing results and optionally return log filename
%
% Syntax:
%   logFileName = matRad_flashLog(cstFLASH, DMF, doseThreshold, finalMask)
%
% Inputs:
%   cstFLASH      - CST rows of affected VOIs (from matRad_flashVoxels)
%   DMF           - scalar Dose Modifying Factor applied
%   doseThreshold - scalar threshold in Gy
%   finalMask     - logical mask of voxels modified (flashMask)
%
% Output:
%   logFileName   - optional output string of log file name (formatted), not saved
%
% Notes:
%   - Always prints summary to command window
%   - Determines if healthy tissue is included from CST names
%   - No file is written; output is only the suggested filename
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------

% Determine if healthy tissue is included
includeHealthy = any(contains(lower(cstFLASH(:,2)), 'healthy'));

% Build log content
logLines = {};
logLines{end+1} = sprintf('DMF applied: %.3f | Dose threshold: %.1f Gy | Healthy included: %s', ...
    DMF, doseThreshold, mat2str(includeHealthy));
logLines{end+1} = sprintf('Total voxels modified: %d', nnz(finalMask));
logLines{end+1} = 'VOIs affected:';

% Add VOI names and voxel counts
for i = 1:size(cstFLASH,1)
    voiName = cstFLASH{i,2};
    if isempty(cstFLASH{i,4}) || isempty(cstFLASH{i,4}{1})
        numVox = 0;
    else
        numVox = numel(cstFLASH{i,4}{1});
    end
    logLines{end+1} = sprintf('  %-25s -> %d voxels', voiName, numVox);
end

logLines{end+1} = '-------------------------------------------';

% Print to command window
for i = 1:numel(logLines)
    fprintf('%s\n', logLines{i});
end

% Generate suggested log filename (optional output)
if nargout > 0
    dtStr = datestr(now,'dd-mm-yyyy_HHMM');
    logFileName = sprintf('flash_DMF%.2f_from%.1f_%s.txt', DMF, doseThreshold, dtStr);
end

end
