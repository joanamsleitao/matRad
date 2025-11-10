function [metricStrings, objStruct] = matRad_cstExtractDoseObjectives(cst, VOIs)
% matRad_cstExtractDoseObjectives
% -------------------------------------------------------------------------
% Extracts all dose objectives from a CST and converts them into
% human-readable metric strings and structured summaries.
%
% This is the inverse of matRad_cstAddDoseObjectives.
%
% -------------------------------------------------------------------------
% Syntax:
%   [metricStrings, objStruct] = matRad_cstExtractDoseObjectives(cst, VOIs)
%
% Inputs:
%   cst  - Constraint structure table (cell array)
%   VOIs - (optional) numeric indices of VOIs to extract from
%
% Outputs:
%   metricStrings - Cell array of metric strings for all VOIs
%   objStruct     - Struct with fields:
%       .VOIName     - Name of the VOI
%       .isTarget    - Whether it's a target structure (from cst{:,3})
%       .metrics     - Cell array of readable metric strings
%       .objectives  - The raw CST objective objects
%
% Example:
%   [strings, structOut] = matRad_cstExtractDoseObjectives(cst);
%
%   structOut(1)
%       .VOIName = 'PTV'
%       .isTarget = true
%       .metrics = {'D_98 minDVH 10Gy 100', 'D_2 maxDVH 50Gy 100'}
%       .objectives = { [1x1 struct], [1x1 struct] }
%
% -------------------------------------------------------------------------
% Author: Joana Leitão (STAR Project)
% Updated: Oct 2025
% -------------------------------------------------------------------------

if nargin < 2 || isempty(VOIs)
    VOIs = 1:size(cst,1);
end

metricStrings = {};
objStruct = struct('VOIName', {}, 'isTarget', {}, 'metrics', {}, 'objectives', {});

% fprintf('\n=== Extracting dose objectives from CST ===\n');

for j = 1:numel(VOIs)
    ixVOI = VOIs(j);
    structName = cst{ixVOI, 2};
    isTarget = contains(upper(string(cst{ixVOI,3})), 'TARGET');
    objList = cst{ixVOI, 6};

    if isempty(objList)
        fprintf('>> %-20s : [no objectives]\n', structName);
        continue;
    end

    metricsForVOI = {};

    for k = 1:numel(objList)
        obj = objList{k};
        cls = string(obj.className);
        params = obj.parameters;
        pen = obj.penalty;

        % === Translate back to readable format ===
        switch cls
            case 'DoseObjectives.matRad_Mean'
                metricStr = sprintf('mean %.1f', pen);

            case 'DoseObjectives.matRad_SquaredDeviation'
                metricStr = sprintf('sqDev %.2fGy %.1f', params{1}, pen);

            case 'DoseObjectives.matRad_Overdosing'
                metricStr = sprintf('sqOver %.2fGy %.1f', params{1}, pen);

            case 'DoseObjectives.matRad_Underdosing'
                metricStr = sprintf('sqUnder %.2fGy %.1f', params{1}, pen);

            case 'DoseObjectives.matRad_EUD'
                metricStr = sprintf('EUD %.2f %.2fGy %.1f', params{1}, params{2}, pen);

            case 'DoseObjectives.matRad_MinDVH'
                metricStr = sprintf('D_%.0f minDVH %.2fGy %.1f', params{2}, params{1}, pen);

            case 'DoseObjectives.matRad_MaxDVH'
                metricStr = sprintf('D_%.0f maxDVH %.2fGy %.1f', params{2}, params{1}, pen);

            otherwise
                metricStr = sprintf('[unknown objective: %s]', cls);
        end

        metricsForVOI{end+1} = metricStr;
        metricStrings{end+1} = sprintf('%s: %s', structName, metricStr);
    end

    % Store summary in structured form
    objStruct(end+1).VOIName = structName;
    objStruct(end).isTarget = isTarget;
    objStruct(end).metrics = metricsForVOI;
    objStruct(end).objectives = objList;

    % fprintf('>> %-20s : %d objectives extracted\n', structName, numel(metricsForVOI));
end

% fprintf('\n=== Done extracting objectives ===\n');
end
