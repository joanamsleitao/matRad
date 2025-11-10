function [ct, cst, pln, stf, resultGUI] = matRad_dicomImportFolder(primaryPath, fallbackPath)
% Import DICOM data from a primary folder, optionally using fallback CT/RTStruct

ct = []; cst = []; pln = []; stf = []; resultGUI = [];

fprintf('→ Importing primary DICOM folder...\n');
dcmImpObj = matRad_DicomImporter(primaryPath);

hasCT = isfield(dcmImpObj.importFiles, 'ct') && ~isempty(dcmImpObj.importFiles.ct);
hasRTStruct = isfield(dcmImpObj.importFiles, 'rtss') && ~isempty(dcmImpObj.importFiles.rtss);

if (~hasCT || ~hasRTStruct) && nargin > 1 && ~isempty(fallbackPath)
    fprintf('→ Loading fallback RTFiles folder...\n');
    tmpObj = matRad_DicomImporter(fallbackPath);

    % Transfer grid info
    dcmImpObj.importFiles.resx = tmpObj.importFiles.resx;
    dcmImpObj.importFiles.resy = tmpObj.importFiles.resy;
    dcmImpObj.importFiles.resz = tmpObj.importFiles.resz;
    dcmImpObj.importFiles.useImportGrid = tmpObj.importFiles.useImportGrid;

    % Add missing CT and RTSTRUCT
    if ~hasCT
        dcmImpObj.importFiles.ct = tmpObj.importFiles.ct;
    end
    if ~hasRTStruct
        dcmImpObj.importFiles.rtss = tmpObj.importFiles.rtss;
    end
end

matRad_importDicom(dcmImpObj);
ct = dcmImpObj.ct;
cst = dcmImpObj.cst;
pln = dcmImpObj.pln;
stf = dcmImpObj.stf;
resultGUI = dcmImpObj.resultGUI;

fprintf('✓ DICOM import completed successfully.\n');
end
