function [patientFolder, clinicalFile, planningFile336, doseReproductionFile, structsPhasePath, dosePerPhasePath, planningDataSepFile] = STAR_getPatientPaths(patientName)
% STAR_getPatientPaths
% ---------------------------------------------------------
% Find key file paths for a given STAR patient.
%
% INPUT:
%   patientName (string or char) - name of patient subfolder (e.g., 'CAUG_002')
%
% OUTPUTS:
%   clinicalFile       - full path to <patientName>_PlanningCTandRTDose.mat
%   planningFile            - full path to the stf file (contains 'stfpln')
%   structsPhasePath   - full path to the StructsPhase_Sep folder
%   dosePerPhasePath   - full path to the DosePerPhase folder (handles variants)
%
% EXAMPLE:
%   [clinicalFile, planningFile, structsPath, dosePath] = getPatientDataPaths('UHEI_005');
%
%   % clinicalFile -> '...\Data\UHEI_005\UHEI_005_PlanningCTandRTDose.mat'
%   % planningFile  -> '...\Data\UHEI_005\UHEI_005_stfplnRes336_Beam72_5deg.mat'
%   % structsPath -> '...\Data\UHEI_005\StructsPhase_Sep'
%   % dosePath -> '...\Data\UHEI_005\DosePerPhase (September)'

% ---------------------------------------------------------
% Author: Joana Leitão (STAR project)
% Created: Oct 2025
% ---------------------------------------------------------

patientFolder = [];
clinicalFile = [];
planningFile336 = [];
doseReproductionFile = [];
structsPhasePath = [];
dosePerPhasePath = [];
planningDataSepFile = [];
%%

% Base path for STAR data
baseDir = fullfile(pwd, 'Data', patientName);

if ~isfolder(baseDir)
    error('Folder for patient "%s" not found in Data directory.', patientName);
end

% 1) Planning file
planPattern = fullfile(baseDir, [patientName, '_ClinicalCTandRTDose.mat']);
planList = dir(planPattern);
if isempty(planList)
    error('Planning file not found for %s in %s.', patientName, baseDir);
else
    clinicalFile = fullfile(planList(1).folder, planList(1).name);
end

patientFolder = planList(1).folder;

% 2) planning file (pattern-based search)
planningList = dir(fullfile(baseDir, [patientName, '*pln*stf*dij*.mat']));
if isempty(planningList)
    warning('No planning file found for %s.', patientName);
else
    [~, newestIdx] = max([planningList.datenum]);
    planningFile = fullfile(planningList(newestIdx).folder, planningList(newestIdx).name);
end

% 3) doseReproductionPath (pattern-based search)
doseReproductionList = dir(fullfile(baseDir, [patientName, '*ose*tion*.mat']));
if isempty(doseReproductionList)
    warning('No doseReproductionReplica file found for %s.', patientName);
else
    [~, newestIdx] = max([doseReproductionList.datenum]);
    doseReproductionFile = fullfile(planningList(newestIdx).folder, doseReproductionList(newestIdx).name);
end

% 3) StructsPhase_Sep folder
structsPhasePath = fullfile(baseDir, 'StructsPhase_Sep');
if ~isfolder(structsPhasePath)
    warning('StructsPhase_Sep folder not found for %s.', patientName);
    structsPhasePath = '';
end

% 4) DosePerPhase folder (handles variations like "DosePerPhase (September)")
doseList = dir(fullfile(baseDir, 'DosePerPhase*'));
doseList = doseList([doseList.isdir]); % keep only folders
if isempty(doseList)
    warning('DosePerPhase folder not found for %s.', patientName);
    dosePerPhasePath = '';
else
    % Pick the most recently modified one
    [~, newestIdx] = max([doseList.datenum]);
    dosePerPhasePath = fullfile(doseList(newestIdx).folder, doseList(newestIdx).name);
end

% 5) Sep Planning File with new cst
planningDataSepList = dir(fullfile(structsPhasePath, ['*', patientName, '*lanning*.mat']));
if isempty(planningDataSepList)
    warning('No Sep planning file found for %s.', patientName);
else
    [~, newestIdx] = max([planningDataSepList.datenum]);
    planningDataSepFile = fullfile(planningDataSepList(newestIdx).folder, planningDataSepList(newestIdx).name);
end
end
