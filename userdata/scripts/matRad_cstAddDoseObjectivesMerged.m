function cst = matRad_cstAddDoseObjectivesMerged(cst, VOIs, sourceData, basePenalty, varargin)
% matRad_cstAddDoseObjectivesMerged - Add dose objectives to CST from various data sources
%
% Syntax:
%   cst = matRad_cstAddDoseObjectivesMerged(cst, VOIs, sourceData, basePenalty, 'sourceType', sourceType, ...)
%
% Inputs:
%   cst         - CST cell array to modify
%   VOIs        - Array of VOI indices to process
%   sourceData  - Data source:
%                 * For 'manual': cell array of metric strings (e.g., 'D_98 minDVH 10Gy 100')
%                 * For 'reference': struct array with reference DVH data
%                 * For 'qi': quality indicators struct array (clinical/reference plan)
%   basePenalty - Base penalty for dose objectives (double)
%
% Name-Value Pair Inputs:
%   'sourceType'            - One of {'manual','reference','qi'}, default 'manual'
%   'prescribedDoseOverride'- Scalar or array for prescribed dose override (optional)
%   'keepExistingObjectives'- Logical, whether to keep existing objectives (default false)
%
% Outputs:
%   cst - Updated CST with dose objectives added
%
% Description:
%   This unified function adds dose objectives to CST based on:
%   - Manual metric strings,
%   - Reference DVH data, or
%   - Clinical/reference quality indicators (QI).
%
% Examples:
%   cst = matRad_addDoseObjectivesMerged(cst, VOIs, metrics, 100, 'sourceType', 'manual');
%   cst = matRad_addDoseObjectivesMerged(cst, VOIs, dvhRef, 50, 'sourceType', 'reference');
%   cst = matRad_addDoseObjectivesMerged(cst, VOIs, qiPat, 200, 'sourceType', 'qi');
%

% Parse optional inputs
p = inputParser;
addParameter(p, 'sourceType', 'manual', @(x) any(validatestring(x, {'manual','reference','qi'})));
addParameter(p, 'prescribedDoseOverride', [], @(x) isnumeric(x) || isempty(x));
addParameter(p, 'keepExistingObjectives', false, @islogical);
parse(p, varargin{:});

sourceType = p.Results.sourceType;
prescribedDoseOverride = p.Results.prescribedDoseOverride;
keepExistingObjectives = p.Results.keepExistingObjectives;

if ~iscell(VOIs)
    VOIs = num2cell(VOIs);
end

switch lower(sourceType)
    case 'manual'
        % sourceData is metrics cell array or string
        if ~iscell(sourceData)
            metrics = {sourceData};
        else
            metrics = sourceData;
        end
        
        for j = 1:numel(VOIs)
            ixVOI = VOIs{j};
            structName = cst{ixVOI, 2};
            objList = {};
            
            % Determine goal dose if prescribedDoseOverride given
            goalDose = getGoalDose(j, prescribedDoseOverride, VOIs);

            fprintf('\n>> Adding manual objectives for VOI: %s (index %d)\n', structName, ixVOI);

            for m = 1:numel(metrics)
                metricStr = strtrim(metrics{m});
                parts = strsplit(metricStr);

                try
                    obj = parseMetricManual(parts);
                    if isempty(obj)
                        warning('Unsupported or invalid metric: %s', metricStr);
                        continue;
                    end
                    objList{end+1} = obj;
                catch ME
                    warning('Failed to parse metric: %s | Error: %s', metricStr, ME.message);
                end
            end

            cst = updateCSTwithObjectives(cst, ixVOI, objList, keepExistingObjectives);

            fprintf('   Added %d objectives to VOI %s\n', numel(objList), structName);
        end

    case 'reference'
        % sourceData is reference DVH struct array
        dvhBase = sourceData;
        if isempty(prescribedDoseOverride)
            prescribedDoseOverride = [];
        end

        if ~iscell(VOIs)
            VOIs = num2cell(VOIs);
        end

        for j = 1:numel(VOIs)
            ixVOI = VOIs{j};
            structName = cst{ixVOI, 2};
            objList = {};
            dvhData = dvhBase(ixVOI);

            goalDose = getGoalDose(j, prescribedDoseOverride, VOIs);

            fprintf('\n>> Adding objectives from reference DVH for VOI: %s (index %d)\n', structName, ixVOI);

            % Add mean objective if requested
            if any(strcmpi({'mean'}, dvhData.metrics)) && ~isempty(goalDose)
                obj.className = 'DoseObjectives.matRad_SquaredDeviation';
                obj.parameters = {goalDose};
                obj.penalty = basePenalty;
                objList{end+1} = obj;
            elseif any(strcmpi({'mean'}, dvhData.metrics)) && isempty(goalDose)
                fprintf('   Skipping sqDev dose objective: no goalDose provided.\n');
            end

            % Add min/max DVH objectives
            for m = 1:numel(dvhData.metrics)
                metricStr = dvhData.metrics{m};
                if strcmpi(metricStr, 'mean')
                    continue;
                elseif contains(metricStr, 'maxDVH') || contains(metricStr, 'minDVH')
                    parts = strsplit(metricStr, ' ');
                    if numel(parts) ~= 2
                        warning('Invalid metric format: %s', metricStr);
                        continue;
                    end
                    doseStr = parts{1}; % e.g. 'D_2'
                    modeStr = parts{2}; % 'maxDVH' or 'minDVH'

                    vol = str2double(extractAfter(doseStr, 'D_'));
                    if isnan(vol)
                        warning('Invalid DVH volume point in metric: %s', metricStr);
                        continue;
                    end

                    index = dsearchn(dvhData.volumePoints(:), vol);
                    if index < 1 || index > numel(dvhData.doseGrid)
                        warning('Volume %.2f%% is outside DVH volume points for VOI %s.', vol, structName);
                        continue;
                    end
                    dose = dvhData.doseGrid(index);

                    if strcmpi(modeStr, 'maxDVH')
                        obj.className = 'DoseObjectives.matRad_MaxDVH';
                    elseif strcmpi(modeStr, 'minDVH')
                        obj.className = 'DoseObjectives.matRad_MinDVH';
                    else
                        warning('Unknown DVH mode in metric: %s', metricStr);
                        continue;
                    end

                    obj.parameters = {dose, vol};
                    obj.penalty = basePenalty;
                    if vol > 80 && strcmpi(modeStr, 'maxDVH')
                        obj.penalty = basePenalty * 100;
                    end

                    objList{end+1} = obj;
                else
                    warning('Unsupported metric: %s', metricStr);
                end
            end

            % Fallback: add mean objective if none created but goalDose exists
            if isempty(objList) && ~isempty(goalDose)
                obj.className = 'DoseObjectives.matRad_SquaredDeviation';
                obj.parameters = {goalDose};
                obj.penalty = basePenalty;
                objList{end+1} = obj;
                fprintf('   No valid min/max DVH objectives found; added fallback mean objective.\n');
            elseif isempty(objList)
                fprintf('   No objectives added for VOI %s (no mean dose provided and no valid min/max DVH metrics).\n', structName);
            end

            cst = updateCSTwithObjectives(cst, ixVOI, objList, keepExistingObjectives);

            fprintf('   Final objectives for VOI %s (%d total)\n', structName, numel(objList));
        end

    case 'qi'
        % sourceData is QI struct array
        qiPat = sourceData;

        % Load VOINames for detection (assumes parseStructureFile exists)
        VOINames = parseStructureFile('VOINames.txt');

        for i = 1:numel(qiPat)
            voiName = qiPat(i).name;

            % Skip External
            if contains(voiName, VOINames.External)
                continue;
            end

            % Find VOI index in CST
            ixVOI = find(contains(cst(:,2), voiName), 1);
            if isempty(ixVOI)
                warning('VOI %s not found in CST, skipping...', voiName);
                continue;
            end

            isPTV = contains(voiName, VOINames.PTV);
            objList = {};

            % Mean dose objective
            obj.className = 'DoseObjectives.matRad_SquaredDeviation';
            obj.parameters{1} = qiPat(i).D_50;
            obj.penalty = basePenalty;
            objList{end+1} = obj;

            % For PTV, add volume-based VxGy objectives
            if isPTV
                vFields = fieldnames(qiPat(i));
                for v = 1:numel(vFields)
                    field = vFields{v};
                    if startsWith(field, 'V_') && endsWith(field, 'Gy')
                        numStr = extractBetween(field, 3, strlength(field)-2);
                        doseVal = str2double(strrep(numStr, '_', '.'));
                        if ~isnan(doseVal)
                            obj.className = 'DoseObjectives.matRad_MinDVH';
                            obj.parameters{1} = doseVal;
                            obj.parameters{2} = qiPat(i).(field);
                            obj.penalty = basePenalty;
                            objList{end+1} = obj;
                        end
                    end
                end
            end

            cst = updateCSTwithObjectives(cst, ixVOI, objList, keepExistingObjectives);

            fprintf('   Added %d objectives to VOI %s\n', numel(objList), voiName);
        end

    otherwise
        error('Unsupported sourceType: %s', sourceType);
end

end

%% Helper functions

function obj = parseMetricManual(parts)
% Parse manual metric strings to dose objectives
obj = [];
if strcmpi(parts{1}, 'PD') && numel(parts) == 2
    dose = str2double(parts{2});
    obj.className = 'DoseObjectives.matRad_SquaredDeviation';
    obj.parameters = {dose};
    obj.penalty = dose;

elseif strcmpi(parts{1}, 'mean') && numel(parts) == 2
    obj.className = 'DoseObjectives.matRad_Mean';
    obj.parameters = {};
    obj.penalty = str2double(parts{2});

elseif strcmpi(parts{1}, 'sqDev') && numel(parts) == 3
    dose = parseGy(parts{2});
    obj.className = 'DoseObjectives.matRad_SquaredDeviation';
    obj.parameters = {dose};
    obj.penalty = str2double(parts{3});

elseif strcmpi(parts{1}, 'sqOver') && numel(parts) == 3
    dose = parseGy(parts{2});
    obj.className = 'DoseObjectives.matRad_Overdosing';
    obj.parameters = {dose};
    obj.penalty = str2double(parts{3});

elseif strcmpi(parts{1}, 'sqUnder') && numel(parts) == 3
    dose = parseGy(parts{2});
    obj.className = 'DoseObjectives.matRad_Underdosing';
    obj.parameters = {dose};
    obj.penalty = str2double(parts{3});

elseif strcmpi(parts{1}, 'EUD') && numel(parts) == 4
    a = str2double(parts{2});
    dose = parseGy(parts{3});
    obj.className = 'DoseObjectives.matRad_EUD';
    obj.parameters = {a, dose};
    obj.penalty = str2double(parts{4});

elseif contains(parts{1}, 'D_') && any(strcmpi(parts{2}, {'minDVH','maxDVH'})) && numel(parts) == 4
    vol = str2double(extractAfter(parts{1}, 'D_'));
    dose = parseGy(parts{3});
    obj.penalty = str2double(parts{4});
    if strcmpi(parts{2}, 'minDVH')
        obj.className = 'DoseObjectives.matRad_MinDVH';
    else
        obj.className = 'DoseObjectives.matRad_MaxDVH';
    end
    obj.parameters = {dose, vol};

else
    obj = [];
end
end

function dose = parseGy(doseStr)
% Parse string like '10Gy' or '10' to numeric dose value
if endsWith(doseStr, 'Gy')
    doseStr = extractBefore(doseStr, 'Gy');
end
dose = str2double(doseStr);
if isnan(dose)
    error('Invalid dose string: %s', doseStr);
end
end

function cst = updateCSTwithObjectives(cst, ixVOI, objList, keepExistingObjectives)
% Merge new objectives into CST VOI objectives, optionally preserving existing
if keepExistingObjectives && iscell(cst{ixVOI,6})
    existingObjs = cst{ixVOI,6};
else
    existingObjs = {};
end

for newObj = objList
    found = false;
    for i = 1:numel(existingObjs)
        if strcmp(existingObjs{i}.className, newObj{1}.className) && ...
           isequal(existingObjs{i}.parameters, newObj{1}.parameters)
            existingObjs{i}.penalty = newObj{1}.penalty;
            found = true;
            break;
        end
    end
    if ~found
        existingObjs{end+1} = newObj{1};
    end
end

cst{ixVOI,6} = existingObjs;
end

function goalDose = getGoalDose(j, prescribedDoseOverride, VOIs)
% Determine the goal dose for VOI index j from override or empty
if isempty(prescribedDoseOverride)
    goalDose = [];
elseif isscalar(prescribedDoseOverride)
    goalDose = prescribedDoseOverride;
elseif numel(prescribedDoseOverride) == numel(VOIs)
    goalDose = prescribedDoseOverride(j);
else
    error('prescribedDoseOverride length mismatch with VOIs');
end
end
