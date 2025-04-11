function [matRadFileName, ct, cst, pln, stf, resultGUI] = matRadJoana_importDicom(pathToFolder)
% Function to import dicom files
%   Detailed explanation goes here

% % output = matRad_DicomImporter(path);
% pathToFolder = 'C:\Users\joana\OneDrive\Documentos\PhD\KIT_IBT\Ablation\PatientTrial_CAUG_002_FromKielh';
dcmImpObj = matRad_DicomImporter(pathToFolder);

matRad_importDicom(dcmImpObj);
% allfiles = dcmImpObj.allfiles;
patients = dcmImpObj.patients;

% [allfiles,patients] = matRad_scanDicomImportFolder("C:\Users\joana\OneDrive\Documentos\PhD\KIT_IBT\Ablation\PatientTrial_CAUG_002_FromKielh"); %MatRad will also be able to separate multiple patients, but this example will only work if there's only a single patient in the folder.

% ctFiles = strcmp(allfiles(:,2),'CT');
% rtssFiles = strcmpi(allfiles(:,2),'rtstruct'); %note we can have multiple RT structure sets, matRad will always import the first it finds
%
% importFiles.ct = allfiles(ctFiles,1);%All CT slice filepaths stored in a cell array like {'CTSlice1.dcm','CTSlice2.dcm'};
% importFiles.rtss = allfiles(rtssFiles,1); %will also be a cell array like {'RTStruct.dcm'};

% %Use the first ct file to get resolution
% dcmInfoCt = dicominfo(importFiles.ct{1});
% importFiles.resx = dcmInfoCt.PixelSpacing(1);
% importFiles.resy = dcmInfoCt.PixelSpacing(2);
% importFiles.resz = dcmInfoCt.SliceThickness; %some CT dicoms do not follow the standard and use SpacingBetweenSlices
%
% %We need to set one more variable I forgot to mention above
% importFiles.useDoseGrid = false;

dcmImpObj.patient = dcmImpObj.patient{1, 1};
% matRad_importDicom(dcmImpObj);

matRad_importDicom(dcmImpObj);
%Now, after starting the GUI / clicking Refresh, the important patient should show after some precomputations for display
% matRadGUI

% Save
matRadFileName = fullfile([pathToFolder, '\matRadPatient', patients{1} '.mat']); % use default from dicom

ct = dcmImpObj.ct;
cst = dcmImpObj.cst;
pln = dcmImpObj.pln;
stf = dcmImpObj.stf;
resultGUI = dcmImpObj.resultGUI;

%Optional saving, we tend to force v7 for compatibility. We use the patient name from the importScan here to identify
save('-v7',matRadFileName,'ct','cst', 'pln', 'stf', 'resultGUI');

end