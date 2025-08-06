function [stf, dij, doseCubeInit, wInit, qiInit] = createReplicatedPlan(patientName, ct, cst, pln)
% CREATEREPLICATEDPLAN - Creates/loads stf and dij for plan replication
%
% Syntax:  [stf, dij, doseCubeInit, wInit, qiInit] = createReplicatedPlan(patientName, ct, cst, pln)
%
% Inputs:
%   patientName     - Name of patient folder (string)
%   ct              - CT data structure (struct)
%   cst             - CST cell array (cell array)
%   pln             - Plan structure (struct)
%
% Outputs:
%   stf             - Steering information (struct)
%   dij             - Dose influence matrix (struct)
%   doseCubeInit    - Initial dose cube [Gy] (double array)
%   wInit           - Initial spot weights (double array)
%   qiInit          - Initial quality indicators (struct)
%
% Other m-files required: matRad_generateStf.m, matRad_calcDoseInfluence.m,
%                         matRad_fluenceOptimization.m,
%                         matRadJoana_calcQualityIndicators.m
% Subfunctions: none
% MAT-files required: none
%
% See also: analyzePlanDose

    %%
    VOINames = parseStructureFile('VOINames.txt');

    % Determine patient folder based on ct path
    patientFolder = fullfile(pwd, 'Data', patientName);

    % Look for existing basePlnStfDij files
    fileList = dir(fullfile(patientFolder, ['*ase*', 'antry', gantrySep, '*', res, '*.mat']));
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

        gantrySep = num2str(abs(pln.propStf.gantryAngles(1)-pln.propStf.gantryAngles(2)));
        res = pln.propDoseCalc.doseGrid.resolution;
        res = [num2str(res.x), num2str(res.y), num2str(res.z),'_' ];

        saveName = ['basePlnStfDij_gantry', gantrySep, '_res', res, datestr(now, 'yyyymmdd_HHMMSS'), '.mat'];
        save(fullfile(patientFolder, saveName), 'pln', 'stf', 'dij');
    end

    %%
    % Initial fluence optimization using only EXTERNAL and PTV

    ixPTV = find(contains(cst(:,2), VOINames.PTV.Aliases), 1);
    ixExternal = find(contains(cst(:,2), VOINames.External.Aliases), 1);
    resultInit = matRad_fluenceOptimization(dij, [cst(ixExternal, :); cst(ixPTV, :)], pln);
    doseCubeInit = resultInit.physicalDose;
    wInit = resultInit.w;
    qiInit = matRadJoana_calcQualityIndicators(cst, pln, doseCubeInit);
end