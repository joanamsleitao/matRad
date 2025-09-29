function cst = matRad_cstAddDoseObjectives(cst, VOIs, metrics, prescribedDoseOverride, keepExistingObjectives)
% matRad_cstAddDoseObjectives - Adds dose objectives to CST from manually defined metrics
%
% Syntax: cst = matRad_cstAddDoseObjectives(cst, VOIs, basePenalty, metrics, prescribedDoseOverride, keepExistingObjectives)
%
% Inputs:
%   cst                    - CST table (cell array)
%   VOIs                   - Indices of VOIs to update (numeric array)
%   basePenalty            - Default penalty value (double)
%   metrics                - Cell array of strings (e.g., 'D_98 minDVH 10Gy 100', 'PD 1000')
%   prescribedDoseOverride - Scalar or array of prescribed doses (optional)
%   keepExistingObjectives - Logical flag to preserve existing objectives (optional)
%
% Output:
%   cst - Updated CST with new objectives
%
% Possible metrics
% metrics = {
% 'D_98 minDVH 10Gy 100'
% 'D_2 maxDVH 50Gy 100'
% 'PD 1000'
% 'sqDev 30Gy 300'
% 'mean 200'
% 'sqOver 60Gy 500'
% 'sqUnder 10Gy 500'
% 'EUD 2.5 5Gy 150'
% };

if ~iscell(metrics)
    metrics = {metrics};
end
if nargin < 4
    prescribedDoseOverride = [];
end
if nargin < 5
    keepExistingObjectives = false;
end

for j = 1:numel(VOIs)
    ixVOI = VOIs(j);
    structName = cst{ixVOI, 2};
    objList = {};

    % Determine goal dose
    if isempty(prescribedDoseOverride)
        goalDose = [];
    elseif isscalar(prescribedDoseOverride)
        goalDose = prescribedDoseOverride;
    elseif numel(prescribedDoseOverride) == numel(VOIs)
        goalDose = prescribedDoseOverride(j);
    else
        error('prescribedDoseOverride length mismatch with VOIs');
    end

    fprintf('\n>> Adding manual objectives for VOI: %s (index %d)\n', structName, ixVOI);

    for m = 1:numel(metrics)
        metricStr = strtrim(metrics{m});
        parts = strsplit(metricStr);

        try
            if strcmpi(parts{1}, 'PD') && numel(parts) == 2
                % Prescribed dose objective (squared deviation)
                dose = str2double(parts{2});
                obj.className = 'DoseObjectives.matRad_SquaredDeviation';
                obj.parameters = {dose};
                obj.penalty = str2double(parts{2});

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
                warning('Invalid or unsupported metric: %s', metricStr);
                continue;
            end

            objList{end+1} = obj;

        catch ME
            warning('Failed to parse metric: %s | Error: %s', metricStr, ME.message);
            continue;
        end
    end

    % === Handle existing objectives ===
    if keepExistingObjectives && iscell(cst{ixVOI,6})
        existingObjs = cst{ixVOI,6};
    else
        existingObjs = {};
    end

    % Merge objectives, avoid duplication
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

    fprintf('   Added %d objectives to VOI %s\n', numel(objList), structName);
end
end

function dose = parseGy(doseStr)
% PARSEGY - Converts '10Gy' or '10' to numeric value
    if endsWith(doseStr, 'Gy')
        doseStr = extractBefore(doseStr, 'Gy');
    end
    dose = str2double(doseStr);
    if isnan(dose)
        error('Invalid dose string: %s', doseStr);
    end
end
