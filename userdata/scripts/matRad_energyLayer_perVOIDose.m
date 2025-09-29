function [voiDoseByEL, qiByEL] = matRad_energyLayer_perVOIDose(cst, allELStruct, dij, wTotal, refGy, refVol)
% Compute per-VOI dose metrics for each energy layer
% Output:
%   - voiDoseByEL: table (VOI × EL) with Mean, Max, Min, sorted by VOI then EL
%   - qiByEL: struct, EL-major, VOI-minor

if nargin < 6 || isempty(refVol), refVol = [2 5 50 95 98]; end
if nargin < 5 || isempty(refGy),  refGy  = []; end

layerNames = fieldnames(allELStruct);
nEL = numel(layerNames);
nVOI = size(cst,1);

rows = {};
qiByEL = struct();  % EL-major, VOI-minor

for v = 1:nVOI
    voiName = cst{v,2};
    indices = cst{v,4}{1};

    for i = 1:nEL
        ELname = layerNames{i};
        EL = allELStruct.(ELname);

        % Initialize substruct
        if ~isfield(qiByEL, ELname), qiByEL.(ELname) = struct(); end

        % Dose cube
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
            for runDX = 1:numel(refVol), qi.(sprintf('D_%d',refVol(runDX))) = 0; end
            for runVX = 1:numel(refGy_local), fieldname = ['V_' strrep(num2str(refGy_local(runVX),3),'.','_') 'Gy']; qi.(fieldname) = 0; end
        end

        qiByEL.(ELname).(voiName) = qi;

        % Append to rows
        rows(end+1,:) = {voiName, ELname, EL.energy, qi.mean, qi.max, qi.min}; %#ok<AGROW>
    end
end

% Convert to table
voiDoseByEL = cell2table(rows, 'VariableNames', {'VOI','EL_Name','Energy_MeV','MeanDose','MaxDose','MinDose'});

% Sort table: VOI-major, then EL
% Sort table: VOI-major, then EL
[~, ~, voiIdx] = unique(voiDoseByEL.VOI, 'stable');  % get VOI indices
[~, sortIdx] = sortrows([voiIdx, voiDoseByEL.Energy_MeV]);     % sort by VOI index, then Energy
voiDoseByEL = voiDoseByEL(sortIdx,:);

%% Show table in a figure
f = figure('Units','normalized','OuterPosition',[0 0 1 1]);
% I know it is dumb to use table2cell here
t = uitable(f, 'Data', table2cell(voiDoseByEL), ...
    'ColumnName', voiDoseByEL.Properties.VariableNames, ...
    'RowName', [], ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1]);


end