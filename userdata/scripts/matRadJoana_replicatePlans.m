function [cst] = matRadJoana_replicatePlans(cst,pln,doseCube, prescribedDose, refGy, refVol)
% MATRADJOANA_REPLICATEPLANS - Replicates plans from dose cube
%
% Syntax:  [cst] = matRadJoana_replicatePlans(cst,pln,doseCube, prescribedDose, refGy, refVol)
%
% Inputs:
%   cst             - CST cell array (cell array)
%   pln             - Plan structure (struct)
%   doseCube        - Dose cube (3D array)
%   prescribedDose  - Prescribed dose [Gy] (double)
%   refGy           - Reference dose levels [Gy] (vector, optional)
%   refVol          - Reference volumes [%] (vector, optional)
%
% Outputs:
%   cst - Updated CST with objectives (cell array)
%
% Other m-files required: matRadJoana_calcQualityIndicators.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRadJoana_calcQualityIndicators
%%
if ~exist('refVol', 'var') || isempty(refVol)
    refVol = [2 5 50 95 98];
end

if ~exist('refGy', 'var') || isempty(refGy)
    refGy = floor(linspace(0,max(doseCube(:)),6)*10)/10;
end

qi = matRadJoana_calcQualityIndicators(cst,pln,doseCube,refGy,refVol);
meanDose = [qi.mean];
minDose = [qi.D_98]; % actually D_98 not max
maxDose = [qi.D_2];
% V20 = [qi.V_20Gy];
D = [qi.(strcat('D_',num2str(refVol(runDX))))];
% sRefGy = num2str(refGy(runVX),3); qi(runVoi).(['V_' strrep(sRefGy,'.','_') 'Gy'])
for runDX = 1:numel(refVol)
    qi(runVoi).(strcat('D_',num2str(refVol(runDX)))) = DX(refVol(runDX));
    %             voiPrint = sprintf('%sD%d%% = %5.2f Gy, ',voiPrint,refVol(runDX),DX(refVol(runDX)));
end

%% Sq Dev for Target
for StructNr = 1:size(cst,1)
    if strcmp(cst{StructNr,3}, 'TARGET')
        % To overwrite
        if ~isempty(cst{StructNr,6})
            FunctionNr = size(cst{StructNr,6},2);
        else
            FunctionNr = size(cst{StructNr,6},2)+1;
        end
        cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_SquaredDeviation(Penalty, prescribedDose));
        cst{StructNr,6}{1}.penalty = Penalty; % struct(DoseObjectives.matRad_MeanDose(penalty, MeanDose(g)));

        FunctionNr = size(cst{StructNr,6},2)+1;
        minDoseGoalStruct = floor(minDose(StructNr));
        maxDoseGoalStruct = ceil(maxDose(StructNr));

        cst{StructNr,6}{FunctionNr} = struct(DoseConstraints.matRad_MinMaxDose({[minDoseGoalStruct] [maxDoseGoalStruct] [1]}, 'dose'));
        % redundant?
        % cst{StructNr,6}{FunctionNr}.parameters{1} = floor(minDose(StructNr));
        % cst{StructNr,6}{FunctionNr}.parameters{2} = ceil(maxDose(StructNr));
    end
end

%% Constraint - MinMaxDose for OARs
for StructNr = 1:size(cst,1)
    if strcmp(cst{StructNr,3}, 'OAR')
        FunctionNr = size(cst{StructNr,6},2)+1;
        cst{StructNr,6}{FunctionNr} = struct(DoseConstraints.matRad_MinMaxDose({1 1 1}, 'dose'));
        cst{StructNr,6}{FunctionNr}.parameters{1} = minDose(StructNr)*1.04;
        cst{StructNr,6}{FunctionNr}.parameters{2} = maxDose(StructNr)*1.04;

        FunctionNr = size(cst{StructNr,6},2)+1;
        cst{StructNr,6}{FunctionNr} = struct(DoseConstraints.matRad_MinMaxMeanDose({1 1}));
        cst{StructNr,6}{FunctionNr}.parameters{1} = meanDose(StructNr)*0.95;
        cst{StructNr,6}{FunctionNr}.parameters{2} = meanDose(StructNr)*1.05;
    end
end

%% Objectives
% Vref
% V20 = [qi.V_20Gy];
% D = [qi.(strcat('D_',num2str(refVol(runDX))))];
% sRefGy = num2str(refGy(runVX),3); qi(runVoi).(['V_' strrep(sRefGy,'.','_') 'Gy'])

for StructNr = 1:size(cst,1)
    for runDX = 1:numel(refVol)
        V = [qi.(strcat('V_', num2str(refVol(runDX))))];

        FunctionNr = size(cst{StructNr,6},2)+1;
        if strcmp(cst{StructNr,3}, 'TARGET')
            cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_MinDVH(Penalty, V(StructNr)));
            cst{StructNr, 6}{1, FunctionNr}.parameters{1, 2} = refVol(runDX);
        end

        if strcmp(cst{StructNr,3}, 'OAR')
            cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_MaxDVH(Penalty, V(StructNr)));
            cst{StructNr, 6}{1, FunctionNr}.parameters{1, 2} = refVol(runDX);
        end
    end
end


end