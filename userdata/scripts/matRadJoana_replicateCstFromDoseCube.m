function [cst, qi] = matRadJoana_replicateCstFromDoseCube(cst, doseCube, prescribedDose, penalty, refGy, refVol)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% call
%   qi = matRad_calcQualityIndicators(cst,pln,doseCube)
%   qi = matRad_calcQualityIndicators(cst,pln,doseCube,refGy,refVol)
%
% input
%   cst:                matRad cst struct
%   pln:                matRad pln struct
%   doseCube:           arbitrary doseCube (e.g. physicalDose)
%   refGy: (optional)   array of dose values used for V_XGy calculation
%                       default is [40 50 60]
%   refVol:(optional)   array of volumes (0-100) used for D_X calculation
%                       default is [2 5 95 98]
%                       NOTE: Call either both or none!

%%
if ~exist('penalty', 'var') || isempty(refGy)
    penalty = 50;
end

if ~exist('refVol', 'var') || isempty(refVol)
    refVol = [2 5 50 95 98];
end

if ~exist('refGy', 'var') || isempty(refGy)
    refGy = floor(linspace(0,max(doseCube(:)),6)*10)/10;
end

%%
qi = matRadJoana_calcQualityIndicators(cst,[],doseCube,refGy,refVol);
meanDose = [qi.mean];
minDose = [qi.D_98]; % actually D_98 not max
maxDose = [qi.D_2];

%% Sq Dev for Target
for StructNr = 1:size(cst,1)
    if strcmp(cst{StructNr,3}, 'TARGET')
        % To overwrite
        if ~isempty(cst{StructNr,6})
            FunctionNr = size(cst{StructNr,6},2);
        else
            FunctionNr = size(cst{StructNr,6},2)+1;
        end
        cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_SquaredDeviation(penalty, prescribedDose));
        cst{StructNr,6}{1}.penalty = 2000; % struct(DoseObjectives.matRad_MeanDose(penalty, MeanDose(g)));

        FunctionNr = size(cst{StructNr,6},2)+1;
        minDoseGoalStruct = floor(minDose(StructNr));
        maxDoseGoalStruct = ceil(maxDose(StructNr));

        cst{StructNr,6}{FunctionNr} = struct(DoseConstraints.matRad_MinMaxDose({[minDoseGoalStruct] [maxDoseGoalStruct] [1]}, 'dose'));
        % redundant?
        cst{StructNr,6}{FunctionNr}.parameters{1} = floor(minDose(StructNr));
        cst{StructNr,6}{FunctionNr}.parameters{2} = ceil(maxDose(StructNr));
    end
end

%% Constraint - MinMaxDose for OARs
for StructNr = 1:size(cst,1)
    if strcmp(cst{StructNr,3}, 'OAR')
        FunctionNr = size(cst{StructNr,6},2)+1;
        cst{StructNr,6}{FunctionNr} = struct(DoseConstraints.matRad_MinMaxDose({1 1 1}, 'dose'));
        cst{StructNr,6}{FunctionNr}.parameters{1} = minDose(StructNr)*1.0;
        cst{StructNr,6}{FunctionNr}.parameters{2} = maxDose(StructNr)*1.08;

        FunctionNr = size(cst{StructNr,6},2)+1;
        cst{StructNr,6}{FunctionNr} = struct(DoseConstraints.matRad_MinMaxMeanDose({1 1}));
        cst{StructNr,6}{FunctionNr}.parameters{1} = meanDose(StructNr)*0.95;
        cst{StructNr,6}{FunctionNr}.parameters{2} = meanDose(StructNr)*1.05;

        FunctionNr = size(cst{StructNr,6},2)+1;
        cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_SquaredDeviation(penalty, meanDose(StructNr)));
        cst{StructNr,6}{1}.penalty = 300; % struct(DoseObjectives.matRad_MeanDose(penalty, MeanDose(g)));
    end
end

%% Objectives
% Vref
% V20 = [qi.V_20Gy];
% D = [qi.(strcat('D_',num2str(refVol(runDX))))];
% sRefGy = num2str(refGy(runVX),3); qi(runVoi).(['V_' strrep(sRefGy,'.','_') 'Gy'])

for StructNr = 1:size(cst,1)
    for runDX = 1:numel(refGy)
        V = [qi.(append('V_', num2str(refGy(runDX)), 'Gy'))];

        FunctionNr = size(cst{StructNr,6},2)+1;
        if strcmp(cst{StructNr,3}, 'TARGET')
            cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_MinDVH(penalty, V(StructNr)));
            cst{StructNr, 6}{1, FunctionNr}.parameters{1, 2} = refGy(runDX);
        end

        if strcmp(cst{StructNr,3}, 'OAR')
            cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_MaxDVH(penalty, V(StructNr)));
            cst{StructNr, 6}{1, FunctionNr}.parameters{1, 2} = refGy(runDX);
        end
    end
end

%% Unused
% % % MeanDose
% % for StructNr = 1:size(cst,1)
% %     FunctionNr = size(cst{StructNr,6},2)+1;
% %     cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_MeanDose(Penalty, MeanDose(StructNr)));
% %     if strcmp(cst{StructNr,3}, 'TARGET')
% %         cst{StructNr,6}{FunctionNr}.penalty = Penalty; % struct(DoseObjectives.matRad_MeanDose(penalty, MeanDose(g)));
% %     end
% % end
% 
% % Min and Max
% for StructNr = 1:size(cst,1)
%     FunctionNr = size(cst{StructNr,6},2)+1;
%     if strcmp(cst{StructNr,3}, 'TARGET')
%         cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_SquaredUnderdosing(Penalty, minDose(StructNr)));
%         cst{StructNr, 6}{1, FunctionNr}.parameters{1, 2} = 98;
% 
%         cst{StructNr,6}{FunctionNr+1} = struct(DoseObjectives.matRad_SquaredOverdosing(Penalty, maxDose(StructNr)));
%         cst{StructNr, 6}{1, FunctionNr+1}.parameters{1, 2} = 2;
%     end
% 
%     if strcmp(cst{StructNr,3}, 'OAR')
%         cst{StructNr,6}{FunctionNr} = struct(DoseObjectives.matRad_MaxDVH(Penalty*2, maxDose(StructNr)));
%         cst{StructNr, 6}{1, FunctionNr}.parameters{1, 2} = 2;
%     end
% end
end