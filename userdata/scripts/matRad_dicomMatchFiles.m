function dcmImpObj = matRad_dicomMatchFiles(dcmImpObj, matchPattern)
% matRad_dicomMatchFiles
% -------------------------------------------------------------------------
% Filter DICOM import object to only include files whose names or DICOM
% metadata contain a given substring.
%
% Usage:
%   dcmImpObj = matRad_matchDicomFiles(dcmImpObj, 'PlanA')
%
% Input:
%   dcmImpObj    - object from matRad_DicomImporter()
%   matchPattern - string or pattern to filter (case-insensitive)
%
% Output:
%   dcmImpObj    - filtered DICOM importer object
%
% Notes:
% - Non-matching RTPlan/RTDose/RTStruct files are excluded.
% - CT files are kept unless explicitly filtered out (to keep geometry intact).
%
% Author: Joana Leitão + GPT-5 assistant
% -------------------------------------------------------------------------

if nargin < 2 || isempty(matchPattern)
    return;
end

fprintf('→ Filtering DICOM data for match: "%s"\n', matchPattern);

% Helper: safe match function
containsMatch = @(str) ischar(str) && contains(str, matchPattern, 'IgnoreCase', true);

% --- Filter each DICOM category if it exists ---
fieldsToCheck = {'rtdose', 'rtplan', 'rtss'};

for f = 1:numel(fieldsToCheck)
    fn = fieldsToCheck{f};

    if isfield(dcmImpObj.importFiles, fn)
        fileList = dcmImpObj.importFiles.(fn);

        if isempty(fileList)
            continue;
        end

        % fileList can be cell array or struct array depending on matRad version
        if iscell(fileList)
            keepMask = cellfun(@(x) containsMatch(x), fileList);
            keptFiles = fileList(keepMask);
        elseif isstruct(fileList)
            if isfield(fileList, 'fileName')
                names = {fileList.fileName};
            elseif isfield(fileList, 'name')
                names = {fileList.name};
            else
                names = repmat({''}, size(fileList));
            end
            keepMask = cellfun(@(x) containsMatch(x), names);
            keptFiles = fileList(keepMask);
        else
            keptFiles = fileList;
            warning('Unknown format for dcmImpObj.importFiles.%s', fn);
        end

        dcmImpObj.importFiles.(fn) = keptFiles;

        fprintf('   • %s: kept %d of %d files\n', fn, numel(keptFiles), numel(fileList));
    end
end

% --- Optional: Filter allfiles field if present ---
if isfield(dcmImpObj, 'allfiles') && ~isempty(dcmImpObj.allfiles)
    mask = contains(dcmImpObj.allfiles(:,1), matchPattern, 'IgnoreCase', true);
    dcmImpObj.allfiles = dcmImpObj.allfiles(mask,:);
    fprintf('   • allfiles: kept %d entries\n', sum(mask));
end

% --- If nothing left, warn user ---
if (~isfield(dcmImpObj.importFiles, 'rtdose') || isempty(dcmImpObj.importFiles.rtdose)) && ...
   (~isfield(dcmImpObj.importFiles, 'rtplan') || isempty(dcmImpObj.importFiles.rtplan))
    warning('No RTPLAN or RTDOSE files matched "%s". You may need to adjust matchPattern.', matchPattern);
else
    fprintf('✓ DICOM files successfully filtered by "%s".\n', matchPattern);
end

end
