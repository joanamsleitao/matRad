function [cst, pln, stf, doseCubeCurrent, wCurrent] = loadReplicatedData(patientFolderPath)
%loadReplicatedData Loads Replication files CT & CST from .mat or imports from DICOM
%
% Inputs:
%   patientFolderPath - path to the patient folder (e.g., '...\UHEI_005')
%
% Outputs:
%   ct, cst           - matRad-compatible CT and CST structures

fileOptions = dir(fullfile(patientFolderPath, '*DoseReproduction*.mat'));

if length(fileOptions) == 1
    load(fileOptions.name, 'ct', 'cst', 'doseCubePat', 'doseCubeCurrent', 'pln', 'stf', 'wCurrent');
else
    error('Multiple reference .mat files found. Please select one %s');
end
end