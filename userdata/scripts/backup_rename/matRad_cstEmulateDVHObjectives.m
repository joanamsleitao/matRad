function cst = matRad_cstEmulateDVHObjectives(cst, VOIs, dvhBase, basePenalty, metrics, keepExistingObjectives)
% matRad_cstEmulateDVHObjectives
% -------------------------------------------------------------------------
% Generate dose objectives for plan emulation based on reference DVH data.
% This function creates one objective per requested metric, aiming to 
% reproduce an existing DVH shape from a base plan.
%
% Target structures (cst{:,3} == true) automatically receive higher
% penalties to prioritize conformity.
%
% -------------------------------------------------------------------------
% Syntax:
%   cst = matRad_cstEmulateDVHObjectives(cst, VOIs, dvhBase, basePenalty, metrics, keepExistingObjectives)
%
% Inputs:
%   cst                    - Original CST (cell array)
%   VOIs                   - Indices of VOIs to process (numeric array)
%   dvhBase                - Reference DVH struct array with fields:
%                              .doseGrid (Gy)
%                              .volumePoints (fraction or %)
%   basePenalty            - Base penalty factor (double)
%   metrics                - Cell array of metric names (e.g.:
%                            {'mean','D_2 maxDVH','D_98 minDVH'})
%   keepExistingObjectives - Preserve existing objectives (logical, optional)
%
% Output:
%   cst - Updated CST with one new objective per requested metric per VOI
%
% Example:
%   metrics = {'mean','D_2 maxDVH','D_98 minDVH'};
%   cst = matRad_cstEmulateDVHObjectives(cst, [3 5], dvhBase, 100, metrics);
%
% -------------------------------------------------------------------------
% Author: Joana Leitão (STAR Project)
% Updated: Oct 2025
% -------------------------------------------------------------------------

if nargin < 5 || isempty(metrics)
    error('Metrics cell array must be provided.');
end
if ~iscell(metrics)
    metrics = {metrics};
end
if nargin < 6
    keepExistingObjectives = false;
end

fprintf('\n=== Generating DVH-based objectives for %d VOIs ===\n', numel(VOIs));

for j = 1:numel(VOIs)
    ixVOI = VOIs(j);
    structName = cst{ixVOI, 2};
    isTarget = contains(cst{ixVOI, 3}, 'TARGET');
    dvhData = dvhBase(ixVOI);

    fprintf('\n>> VOI: %-20s (index %d) [%s]\n', ...
        structName, ixVOI, ternary(isTarget, 'Target', 'OAR'));

        if contains(structName, 'ring') || contains(structName, 'Ring')
            isTarget = 0.5;
        end
    % Adjust penalty based on VOI type
    penaltyFactor = basePenalty * (isTarget * 5 + ~isTarget * 1);

        

    % Prepare one metric string per input metric
    metricStrings = cell(1, numel(metrics));

    for m = 1:numel(metrics)
        metric = strtrim(metrics{m});

        % === Case 1: Mean dose objective ===
        if strcmpi(metric, 'mean')
            meanDose = mean(dvhData.doseGrid);
            metricStrings{m} = sprintf('sqDev %.2fGy %.1f', meanDose, penaltyFactor);
            continue;
        end

        % === Case 2: DVH-type objective (e.g., 'D_2 maxDVH', 'D_98 minDVH') ===
        parts = split(metric);
        if numel(parts) ~= 2 || ~startsWith(parts{1}, 'D_')
            warning('Invalid metric format: %s. Skipping.', metric);
            metricStrings{m} = [];
            continue;
        end

        vol = str2double(extractAfter(parts{1}, 'D_'));
        mode = lower(parts{2});

        if isnan(vol) || ~ismember(mode, {'maxdvh','mindvh'})
            warning('Unsupported metric type: %s', metric);
            metricStrings{m} = [];
            continue;
        end

        % Interpolate dose at specified volume percentile
        [~, idx] = min(abs(dvhData.volumePoints - vol));
        if isempty(idx) || idx < 1 || idx > numel(dvhData.doseGrid)
            warning('Volume %.1f%% outside DVH range for %s', vol, structName);
            metricStrings{m} = [];
            continue;
        end

        dose = dvhData.doseGrid(idx);
        metricStrings{m} = sprintf('D_%.0f %s %.2fGy %.1f', vol, mode, dose, penaltyFactor);
    end

    % Remove empty entries
    metricStrings = metricStrings(~cellfun('isempty', metricStrings));

    % If no valid metrics found, add a fallback objective
    if isempty(metricStrings)
        fprintf('   No valid metrics; added fallback mean objective.\n');
        meanDose = mean(dvhData.doseGrid);
        metricStrings = {sprintf('sqDev %.2fGy %.1f', meanDose, penaltyFactor)};
    end

    % === Add exactly one objective per metric ===
        cst = matRad_cstAddDoseObjectives(cst, ixVOI, metricStrings, keepExistingObjectives);
end

fprintf('\n=== Done: one objective per metric added to CST ===\n');
end

% -------------------------------------------------------------------------
function out = ternary(cond, a, b)
% Simple ternary operator
if cond, out = a; else, out = b; end
end
