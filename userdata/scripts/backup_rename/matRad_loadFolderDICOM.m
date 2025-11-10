function [ct, cst, pln, stf, resultGUI] = matRad_loadFolderDICOM(folderPath, matchPattern, fallbackPath)
fprintf('→ Folder contains DICOMs. Importing...\n');
dcmImpObj = matRad_DicomImporter(folderPath);
if ~isempty(matchPattern)
    dcmImpObj = matRad_dicomMatchFiles(dcmImpObj, matchPattern);
end

hasCT = isfield(dcmImpObj.importFiles,'ct') && ~isempty(dcmImpObj.importFiles.ct);
hasRTStruct = isfield(dcmImpObj.importFiles,'rtss') && ~isempty(dcmImpObj.importFiles.rtss);

if ~(hasCT && hasRTStruct)
    warning('Missing CT or RTSTRUCT detected.');
    if ~isempty(fallbackPath)
        fprintf('→ Using fallback DICOM folder: %s\n', fallbackPath);
        [ct, cst, pln, stf, resultGUI] = matRad_dicomImportFolder(folderPath, fallbackPath);
        return;
    end
end

% Direct import
matRad_importDicom(dcmImpObj);
ct = dcmImpObj.ct;
cst = dcmImpObj.cst;
pln = dcmImpObj.pln;
stf = dcmImpObj.stf;
resultGUI = dcmImpObj.resultGUI;
end