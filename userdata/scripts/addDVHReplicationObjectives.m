function cst = addDVHReplicationObjectives(cst, VOIs, dvh, meanDose, basePenalty)
%ADDDVHREPLICATIONOBJECTIVES Create objectives to replicate a clinical DVH.
%
% INPUTS:
%   cstIn       - CST table
%   ixVOI       - Index of the VOI (e.g. ixPTV)
%   dvh         - DVH struct with fields: dose [Gy] and volume [%]
%   meanDose    - Mean dose of the VOI in the clinical plan
%   basePenalty - Base penalty factor for all objectives
%
% OUTPUT:
%   cstOut      - Modified CST with replication objectives for the selected VOI

% if ~exist('basePenalty', 'var') || isempty(basePenalty)
%     basePenalty = 10;
% end

% if ~exist('meanDose', 'var') || isempty(meanDose)
%     meanDose = 10;
% end

% Volume percentages to use (sorted low to high)
vPoints = [2, 30, 98];

for j = 1:numel(VOIs)
    ixVOI = VOIs(j);
    % % Interpolate clinical DVH to get dose at specific volume percentages
    % doseAtV = interp1(dvh.volumePoints, dvh.doseGrid, vPoints, 'linear', 'extrap');

    objList = {};

    %% Add mean dose match
    obj.className = 'DoseObjectives.matRad_SquaredDeviation';
    obj.parameters{1} = meanDose;
    obj.penalty = basePenalty;
    objList{end+1} = obj;

    % %% Add MinDVH (dose >= clinical at X% vol)
    % for i = 1:numel(vPoints)
    %     obj.className = 'DoseObjectives.matRad_MinDVH';
    %     index = dsearchn(dvh(ixVOI).volumePoints(:),vPoints(i));
    %     dose = dvh(ixVOI).doseGrid(index)*1.;
    %     obj.parameters = {dose, vPoints(i)}; % Type 1 = absolute dose
    %     obj.penalty = basePenalty;
    %    objList{end+1} = obj;
    % end

    %% Add MaxDVH (dose <= clinical at X% vol)
    for i = 1:numel(vPoints)
        obj.className = 'DoseObjectives.matRad_MaxDVH';
        index = dsearchn(dvh(ixVOI).volumePoints(:),vPoints(i));
        dose = dvh(ixVOI).doseGrid(index);
        obj.parameters = {dose, vPoints(i)}; % Type 1 = absolute dose
        obj.penalty = basePenalty;
        if vPoints(i) > 80
            obj.penalty = basePenalty*100;
        end
        objList{end+1} = obj;
    end

    %% Set objectives in CST
    cst{ixVOI, 6} = objList;
end
end