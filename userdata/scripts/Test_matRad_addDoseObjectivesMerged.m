% Test script for matRad_addDoseObjectivesMerged

% --- Setup dummy CST ---
% Format: cst{VOI_index, col} with col 2 = VOI name, col 6 = objectives cell
cst = {
    1, 'PTV', [], [], [], {};
    2, 'Heart', [], [], [], {};
    3, 'Lung', [], [], [], {};
};

VOIs = [1 2 3];

% --- 1. Manual metrics test ---
fprintf('--- Manual metrics test ---\n');
manualMetrics = {
    'mean 50'
    'D_2 maxDVH 45Gy 100'
    'D_98 minDVH 20Gy 150'
};

cstManual = matRad_addDoseObjectivesMerged(cst, VOIs, manualMetrics, 100, 'sourceType', 'manual');

% Display results for PTV
disp('PTV objectives after manual metrics:');
disp(cstManual{1,6});

% --- 2. Reference DVH test ---
fprintf('\n--- Reference DVH test ---\n');

% Dummy dvhRef struct with metrics and doseGrid, volumePoints (must match VOIs size)
dvhRef(1).metrics = {'mean', 'D_2 maxDVH', 'D_98 minDVH'};
dvhRef(1).volumePoints = [0 2 5 10 20 50 80 100];
dvhRef(1).doseGrid = [0 44 46 47 48 40 38 30]; % dose at volume points

dvhRef(2).metrics = {'mean'};
dvhRef(2).volumePoints = [0 5 10 20 50 80 100];
dvhRef(2).doseGrid = [0 40 42 43 35 30 25];

dvhRef(3).metrics = {'mean', 'D_5 maxDVH'};
dvhRef(3).volumePoints = [0 5 10 20 50 80 100];
dvhRef(3).doseGrid = [0 38 40 41 33 28 24];

cstRef = matRad_addDoseObjectivesMerged(cst, VOIs, dvhRef, 50, 'sourceType', 'reference', 'prescribedDoseOverride', 60);

disp('Heart objectives after reference DVH:');
disp(cstRef{2,6});

% --- 3. Quality indicators (QI) test ---
fprintf('\n--- Quality Indicators (QI) test ---\n');

% Dummy QI struct array
qiPat(1).name = 'PTV';
qiPat(1).D_50 = 55;
qiPat(1).V_20_Gy = 95;
qiPat(1).V_30_Gy = 80;

qiPat(2).name = 'Heart';
qiPat(2).D_50 = 30;
qiPat(2).V_15_Gy = 50;

qiPat(3).name = 'Lung';
qiPat(3).D_50 = 25;
qiPat(3).V_10_Gy = 60;

% Dummy VOINames file replacement for testing
% Replace parseStructureFile call with a function handle returning fixed structure:
function VOINames = parseStructureFile(~)
    VOINames.External = 'External';
    VOINames.PTV = 'PTV';
end

cstQI = matRad_addDoseObjectivesMerged(cst, [], qiPat, 200, 'sourceType', 'qi', 'keepExistingObjectives', true);

disp('Lung objectives after QI:');
disp(cstQI{3,6});
