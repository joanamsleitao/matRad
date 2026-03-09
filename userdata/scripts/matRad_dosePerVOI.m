function [voiDoseByEL, qiByEL, qiMaxByELTarget] = matRad_dosePerVOI(cst, allELStruct, dij, wTotal, refGy, refVol)
% matRad_dosePerVOI - Compute per-VOI dose metrics for each energy layer
%
% Syntax:
%   [voiDoseByEL, qiByEL] = matRad_dosePerVOI(cst, allELStruct, dij, wTotal)
%   [voiDoseByEL, qiByEL, qiMaxByELTarget] = matRad_dosePerVOI(...)
%
% Description:
%   Computes per-VOI dose metrics for each energy layer. Returns a table of
%   mean / max / min dose per VOI and per EL, and a qiByEL struct with
%   detailed metrics (DX/VX etc.). Additionally, qiMaxByELTarget extracts
%   only the "max" value from qiByEL.(layer).(voiName).max for convenient
%   use (e.g. in slice selection / plotting).
%
% Inputs:
%   cst         - CST cell array (VOI definitions; VOI name in column 2,
%                 voxel indices in column 4)
%   allELStruct - struct of per-EL dose info (fields = EL names)
%   dij         - (unused in current implementation; kept for compatibility)
%   wTotal      - (unused in current implementation; kept for compatibility)
%   refGy       - (optional) vector of reference doses for VX calculation
%   refVol      - (optional) vector of reference volumes (percent) for DX
%
% Outputs:
%   voiDoseByEL    - table with columns:
%                       VOI, EL_Name, Energy_MeV, MeanDose, MaxDose, MinDose
%   qiByEL         - struct, EL-major, VOI-minor:
%                       qiByEL.(ELname).(voiName) = struct of metrics
%   qiMaxByELTarget- struct, EL-major, VOI-minor, containing only:
%                       qiMaxByELTarget.(ELname).(voiName) = qi.max
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 6 || isempty(refVol), refVol = [2 5 50 95 98]; end
if nargin < 5 || isempty(refGy),  refGy  = []; end

layerNames = fieldnames(allELStruct);
nEL = numel(layerNames);
nVOI = size(cst,1);

rows = {};
qiByEL = struct();          % EL-major, VOI-minor
qiMaxByELTarget = struct(); % EL-major, VOI-minor (only qi.max)

for v = 1:nVOI
    voiName = cst{v,2};
    indices = cst{v,4}{1};

    for i = 1:nEL
        ELname = layerNames{i};
        EL = allELStruct.(ELname);

        % Initialize substructs
        if ~isfield(qiByEL, ELname),         qiByEL.(ELname)         = struct(); end
        if ~isfield(qiMaxByELTarget, ELname), qiMaxByELTarget.(ELname) = struct(); end

        % Dose cube selection (physical or RBE-weighted)
        if isfield(EL,'physicalDose') && ~isempty(EL.physicalDose)
            doseCube = EL.physicalDose;
        elseif isfield(EL,'RBExDose') && ~isempty(EL.RBExDose)
            doseCube = EL.RBExDose;
        else
            error('Please run topELStruct = matRad_calcDoseCubePerEL(dij, resultGUI, topELStruct)')
        end

        if isempty(refGy)
            refGy_local = floor(linspace(0,max(doseCube(:)),6)*10)/10;
        else
            refGy_local = refGy;
        end

        doseInVoi = sort(doseCube(indices));
        nVox = numel(indices);

        qi = struct();
        qi.energy = EL.energy;

        if ~isempty(doseInVoi)
            qi.mean = mean(doseInVoi);
            qi.std  = std(doseInVoi);
            qi.max  = doseInVoi(end);
            qi.min  = doseInVoi(1);

            DX = @(x) interp1(linspace(0,1,nVox), doseInVoi, (100-x)/100, 'linear', 'extrap');
            VX = @(x) sum(doseInVoi>=x)/nVox;

            for runDX = 1:numel(refVol)
                qi.(sprintf('D_%d',refVol(runDX))) = DX(refVol(runDX));
            end
            for runVX = 1:numel(refGy_local)
                fieldname = ['V_' strrep(num2str(refGy_local(runVX),3),'.','_') 'Gy'];
                qi.(fieldname) = VX(refGy_local(runVX));
            end
        else
            qi.mean = 0; qi.std = 0; qi.max = 0; qi.min = 0;
            for runDX = 1:numel(refVol)
                qi.(sprintf('D_%d',refVol(runDX))) = 0;
            end
            for runVX = 1:numel(refGy_local)
                fieldname = ['V_' strrep(num2str(refGy_local(runVX),3),'.','_') 'Gy'];
                qi.(fieldname) = 0;
            end
        end

        % Store full qi
        qiByEL.(ELname).(voiName) = qi;

        % Store only max for convenience
        qiMaxByELTarget.(ELname).(voiName) = qi.max;

        % Append to table rows
        rows(end+1,:) = {voiName, ELname, EL.energy, qi.mean, qi.max, qi.min}; %#ok<AGROW>
    end
end

% Convert to table
voiDoseByEL = cell2table(rows, ...
    'VariableNames', {'VOI','EL_Name','Energy_MeV','MeanDose','MaxDose','MinDose'});

% Sort table: VOI-major, then Energy
[~, ~, voiIdx] = unique(voiDoseByEL.VOI, 'stable');      % get VOI indices
[~, sortIdx]   = sortrows([voiIdx, voiDoseByEL.Energy_MeV]); % sort by VOI index, then Energy
voiDoseByEL    = voiDoseByEL(sortIdx,:);

%% Show table in a figure
f = figure('Units','normalized','OuterPosition',[0 0 1 1]);
t = uitable(f, 'Data', table2cell(voiDoseByEL), ...
    'ColumnName', voiDoseByEL.Properties.VariableNames, ...
    'RowName', [], ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1]); %#ok<NASGU>

end