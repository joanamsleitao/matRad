function [stf, dij, doseCubeInit, wInit, qiInit] = createReplicatedPlan(patientName, ct, cst, pln)
%CREATEREPLICATEDPLAN Creates stf and dij for a plan or loads from cache if available.
%   This function looks for a previously saved struct named 'basePlnStfDij_<date>.mat' inside the
%   same patient folder. If a match is found (based on matching fields in the plan), it loads the
%   corresponding stf and dij. Otherwise, it computes them and saves to a new struct.

    %%
    VOINames = parseStructureFile('VOINames.txt');

    % Determine patient folder based on ct path
    patientFolder = append('C:\Users\joana\MATLAB_ALL\KIT_STAR\Data\', patientName);

    % Look for existing basePlnStfDij files
    fileList = dir(fullfile(patientFolder, 'basePlnStfDij_*.mat'));
    loadedFromCache = false;

    for k = 1:numel(fileList)
        data = load(fullfile(fileList(k).folder, fileList(k).name));
        if isfield(data, 'pln') && isequaln(data.pln, pln)
            fprintf('Loaded cached STF and DIJ from %s\n', fileList(k).name);
            stf = data.stf;
            dij = data.dij;
            loadedFromCache = true;
            break;
        end
    end

    if ~loadedFromCache
        fprintf('No matching STF/DIJ found. Generating and saving new basePlnStfDij...\n');
        stf = matRad_generateStf(ct, cst, pln);
        dij = matRad_calcDoseInfluence(ct, cst, stf, pln);

        saveName = ['basePlnStfDij_', datestr(now, 'yyyymmdd_HHMMSS'), '.mat'];
        save(fullfile(patientFolder, saveName), 'pln', 'stf', 'dij');
    end

    %%
    % Initial fluence optimization using only EXTERNAL and PTV

    ixPTV = find(contains(cst(:,2), VOINames.PTV), 1);
    ixExternal = find(contains(cst(:,2), VOINames.External), 1);
    resultInit = matRad_fluenceOptimization(dij, [cst(ixExternal, :); cst(ixPTV, :)], pln);
    doseCubeInit = resultInit.physicalDose;
    wInit = resultInit.w;
    qiInit = matRadJoana_calcQualityIndicators(cst, pln, doseCubeInit);
end