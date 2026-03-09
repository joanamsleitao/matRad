function cst = matRad_cstAddDoseObjectives(cst, VOIs, metrics, keepExistingObjectives)
% matRad_cstAddDoseObjectives
% -------------------------------------------------------------------------
% Adds dose objectives to selected VOIs in the CST from manually defined
% metric strings. Designed to support the DVH-based plan emulation workflow.
%
% This function interprets human-readable metric strings (e.g.,
% 'D_98 minDVH 10Gy 100', 'sqDev 30Gy 200', 'mean 300') and appends the
% corresponding matRad DoseObjective objects to CST entries.
%
% Automatically assigns stronger penalties for target structures
% (based on cst{:,3} flag) to prioritize dose conformity.
%
% -------------------------------------------------------------------------
% Syntax:
%   cst = matRad_cstAddDoseObjectives(cst, VOIs, metrics, keepExistingObjectives)
%
% Inputs:
%   cst                    - Current CST (cell array)
%   VOIs                   - Indices of VOIs to modify (numeric array)
%   metrics                - Cell array of metric strings, e.g.:
%                             {'D_98 minDVH 10Gy 100', 'D_2 maxDVH 50Gy 100'}
%   keepExistingObjectives - (optional) true to preserve existing objectives
%
% Output:
%   cst - Updated CST with new objectives for the specified VOIs
%
% -------------------------------------------------------------------------
% Supported metric formats:
%   'D_98 minDVH 10Gy 100'     -> MinDVH objective (98% volume, 10 Gy, penalty 100)
%   'D_2 maxDVH 50Gy 100'      -> MaxDVH objective (2% volume, 50 Gy, penalty 100)
%   'mean 200'                 -> Mean dose objective (penalty 200)
%   'sqDev 30Gy 300'           -> Squared deviation objective (30 Gy, penalty 300)
%   'sqOver 60Gy 500'          -> Overdose objective (threshold 60 Gy, penalty 500)
%   'sqUnder 10Gy 500'         -> Underdose objective (threshold 10 Gy, penalty 500)
%   'EUD 2.5 5Gy 150'          -> EUD objective (a=2.5, 5 Gy, penalty 150)
%
% Example:
%   metrics = {'D_98 minDVH 30Gy 100', 'D_2 maxDVH 50Gy 100', 'mean 200'};
%   cst = matRad_cstAddDoseObjectives(cst, [3 5], metrics, true);
%
% -------------------------------------------------------------------------
% Author: Joana Leitão (STAR Project)
% Updated: Oct 2025
% -------------------------------------------------------------------------

if nargin < 3 || isempty(metrics)
    error('Metrics must be provided.');
end
if ~iscell(metrics)
    metrics = {metrics};
end
if nargin < 4
    keepExistingObjectives = false;
end

fprintf('\n=== Adding dose objectives to CST ===\n');

for j = 1:numel(VOIs)
    ixVOI = VOIs(j);
    structName = cst{ixVOI, 2};
    isTarget = contains(cst{ixVOI, 3}, 'TARGET');
    objList = {};

    fprintf('\n>> VOI: %-20s (index %d) [%s]\n', ...
        structName, ixVOI, ternary(isTarget, 'Target', 'OAR'));

    % Adjust penalties dynamically
    penaltyScale = (isTarget * 5 + ~isTarget * 1); % 5× stronger for targets

    for m = 1:numel(metrics)
        metricStr = strtrim(metrics{m});
        parts = strsplit(metricStr);

        try
            switch true
                case strcmpi(parts{1}, 'mean') && numel(parts) == 2
                    obj.className = 'DoseObjectives.matRad_Mean';
                    obj.parameters = {};
                    obj.penalty = str2double(parts{2}) * penaltyScale;

                case strcmpi(parts{1}, 'sqDev') && numel(parts) == 3
                    dose = parseGy(parts{2});
                    obj.className = 'DoseObjectives.matRad_SquaredDeviation';
                    obj.parameters = {dose};
                    obj.penalty = str2double(parts{3}) * penaltyScale;

                case strcmpi(parts{1}, 'sqOver') && numel(parts) == 3
                    dose = parseGy(parts{2});
                    obj.className = 'DoseObjectives.matRad_SquaredOverdosing';
                    obj.parameters = {dose};
                    obj.penalty = str2double(parts{3}) * penaltyScale;

                case strcmpi(parts{1}, 'sqUnder') && numel(parts) == 3
                    dose = parseGy(parts{2});
                    obj.className = 'DoseObjectives.matRad_SquaredUnderdosing';
                    obj.parameters = {dose};
                    obj.penalty = str2double(parts{3}) * penaltyScale;

                case strcmpi(parts{1}, 'EUD') && numel(parts) == 4
                    a = str2double(parts{2});
                    dose = parseGy(parts{3});
                    obj.className = 'DoseObjectives.matRad_EUD';
                    obj.parameters = {a, dose};
                    obj.penalty = str2double(parts{4}) * penaltyScale;

                case contains(parts{1}, 'D_') && any(strcmpi(parts{2}, {'minDVH','maxDVH'})) && numel(parts) == 4
                    vol = str2double(extractAfter(parts{1}, 'D_'));
                    dose = parseGy(parts{3});
                    obj.penalty = str2double(parts{4}) * penaltyScale;
                    if strcmpi(parts{2}, 'minDVH')
                        obj.className = 'DoseObjectives.matRad_MinDVH';
                    else
                        obj.className = 'DoseObjectives.matRad_MaxDVH';
                    end
                    obj.parameters = {dose, vol};

                otherwise
                    warning('Invalid or unsupported metric: %s', metricStr);
                    continue;
            end

            objList{end+1} = obj;

        catch ME
            warning('Failed to parse metric: %s | Error: %s', metricStr, ME.message);
        end
    end

    % === Handle existing objectives ===
    if keepExistingObjectives && iscell(cst{ixVOI, 6})
        existingObjs = cst{ixVOI, 6};
    else
        existingObjs = {};
    end

    % Merge objectives, avoid duplicates
    for newObj = objList
        found = false;
        for i = 1:numel(existingObjs)
            if strcmp(existingObjs{i}.className, newObj{1}.className) && ...
               isequal(existingObjs{i}.parameters, newObj{1}.parameters)
                existingObjs{i}.penalty = newObj{1}.penalty; % update penalty
                found = true;
                break;
            end
        end
        if ~found
            existingObjs{end+1} = newObj{1};
        end
    end

    cst{ixVOI,6} = existingObjs;
    fprintf('   Added %d objectives to %s (now %d total)\n', ...
        numel(objList), structName, numel(existingObjs));
end

fprintf('\n=== Done adding objectives ===\n');
end

% -------------------------------------------------------------------------
function dose = parseGy(doseStr)
% PARSEGY - Converts '10Gy' or '10' to numeric value
    if endsWith(doseStr, 'Gy', 'IgnoreCase', true)
        doseStr = extractBefore(doseStr, 'Gy');
    end
    dose = str2double(doseStr);
    if isnan(dose)
        error('Invalid dose string: %s', doseStr);
    end
end

% -------------------------------------------------------------------------
function out = ternary(cond, a, b)
% Simple ternary operator
if cond, out = a; else, out = b; end
end