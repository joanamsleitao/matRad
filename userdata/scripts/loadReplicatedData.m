function [cst, pln, stf, doseCubeCurrent, wCurrent] = loadReplicatedData(patientFolderPath)
% loadReplicatedData - Load replication plan data from saved .mat file
%
% Syntax:
%   [cst, pln, stf, doseCubeCurrent, wCurrent] = loadReplicatedData(patientFolderPath)
%
% Inputs:
%   patientFolderPath - Full path to the patient folder (e.g., '...\UHEI_005')
%
% Outputs:
%   cst              - matRad structure table
%   pln              - Plan struct
%   stf              - Beam geometry struct
%   doseCubeCurrent  - Physical dose cube from current plan
%   wCurrent         - Beamlet weights for current plan
%
% Description:
%   Searches for a single *DoseReproduction*.mat file in the patient folder.
%   Loads all relevant data used for dose reproduction and comparison.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: *DoseReproduction*.mat
%
% See also: createReplicatedPlan, analyzePlanDose
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
warning('Using loadReplicatedData, maybe change?');

fileOptions = dir(fullfile(patientFolderPath, '*DoseReproduction*.mat'));

if length(fileOptions) == 1
    fileFullnName = fullfile(patientFolderPath, fileOptions.name);
    load(fileFullnName, 'ct', 'cst', 'doseCubePat', 'doseCubeCurrent', 'pln', 'stf', 'wCurrent');
else
    error('Multiple reference .mat files found. Please select one %s');
end
end