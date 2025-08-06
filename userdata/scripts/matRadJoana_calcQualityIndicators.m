function qi = matRadJoana_calcQualityIndicators(cst, pln, doseCube, refGy, refVol)
% matRadJoana_calcQualityIndicators - Calculate DVH-based quality indicators
%
% Syntax:
%   qi = matRadJoana_calcQualityIndicators(cst, pln, doseCube)
%   qi = matRadJoana_calcQualityIndicators(cst, pln, doseCube, refGy, refVol)
%
% Inputs:
%   cst      - matRad structure table
%   pln      - matRad plan structure
%   doseCube - 3D dose matrix (Gy)
%   refGy    - (optional) vector of dose thresholds for Vx (%) [default: auto-generated]
%   refVol   - (optional) vector of volume thresholds for Dx (Gy) [default: [2 5 50 95 98]]
%
% Outputs:
%   qi - Structure array with DVH-based indicators for each VOI:
%        .mean, .max, .min, .D_X, .V_YGy, and optionally .HI_XGy, .CI_XGy
%
% Description:
%   Computes quality indicators including D_x, V_xGy, homogeneity index (HI),
%   and conformity index (CI) based on dose-volume histograms. If VOI is a
%   target (cst{i,3} == 'TARGET'), reference dose is inferred from objectives.
%
% Other m-files required: matRad_DoseOptimizationFunction
% Subfunctions: none
% MAT-files required: none
%
% References:
%   van’t Riet et al., IJROBP 1997;37(3):731–6.
%   Kataria et al., J Med Phys. 2012;37(4)
%
% See also: matRad_interp1, matRad_plotDVH
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2016 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSE.md. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


matRad_cfg = MatRad_Config.instance();

if ~exist('refVol', 'var') || isempty(refVol)
    refVol = [2 5 50 95 98];
end

if ~exist('refGy', 'var') || isempty(refGy)
    refGy = floor(linspace(0,max(doseCube(:)),6)*10)/10;
end

if ~exist('pln', 'var') || isempty(pln)
    numOfFractions = 1;
else
    numOfFractions = pln.numOfFractions;
end

    
% calculate QIs per VOI
qi = struct;
for runVoi = 1:size(cst,1)
    
    indices     = cst{runVoi,4}{1};
    numOfVoxels = numel(indices); 
    voiPrint    = sprintf('%3d %20s',cst{runVoi,1},cst{runVoi,2}); %String that will print quality indicators
    
    % get Dose, dose is sorted to simplify calculations
    doseInVoi    = sort(doseCube(indices));
        
    if ~isempty(doseInVoi)
        
        qi(runVoi).name = cst{runVoi,2};
        
        % easy stats
        qi(runVoi).mean = mean(doseInVoi);
        qi(runVoi).std  = std(doseInVoi);
        qi(runVoi).max  = doseInVoi(end);
        qi(runVoi).min  = doseInVoi(1);

        % voiPrint = sprintf('%s - Mean dose = %5.2f Gy +/- %5.2f Gy (Max dose = %5.2f Gy, Min dose = %5.2f Gy)\n%27s', ...
        %                    voiPrint,qi(runVoi).mean,qi(runVoi).std,qi(runVoi).max,qi(runVoi).min,' ');

        DX = @(x) matRad_interp1(linspace(0,1,numOfVoxels),doseInVoi,(100-x)*0.01);
        VX = @(x) numel(doseInVoi(doseInVoi >= x)) / numOfVoxels;

        % create VX and DX struct fieldnames at runtime and fill
        for runDX = 1:numel(refVol)
            qi(runVoi).(strcat('D_',num2str(refVol(runDX)))) = DX(refVol(runDX));
            % voiPrint = sprintf('%sD%d%% = %5.2f Gy, ',voiPrint,refVol(runDX),DX(refVol(runDX)));
        end
        % voiPrint = sprintf('%s\n%27s',voiPrint,' ');
        for runVX = 1:numel(refGy)
            sRefGy = num2str(refGy(runVX),3);
            qi(runVoi).(['V_' strrep(sRefGy,'.','_') 'Gy']) = VX(refGy(runVX));
            % voiPrint = sprintf(['%sV' sRefGy 'Gy = %6.2f%%, '],voiPrint,VX(refGy(runVX))*100);
        end
        % voiPrint = sprintf('%s\n%27s',voiPrint,' ');

        % if current voi is a target -> calculate homogeneity and conformity
        if strcmp(cst{runVoi,3},'TARGET') > 0      

            % loop over target objectives and get the lowest dose objective 
            referenceDose = inf;
            
            if isstruct(cst{runVoi,6})
                cst{runVoi,6} = num2cell(arrayfun(@matRad_DoseOptimizationFunction.convertOldOptimizationStruct,cst{runVoi,6}));
            end
            
            for runObjective = 1:numel(cst{runVoi,6})
               % check if this is an objective that penalizes underdosing 
               obj = cst{runVoi,6}{runObjective};
               if ~isa(obj,'matRad_DoseOptimizationFunction')
                   try
                       obj = matRad_DoseOptimizationFunction.createInstanceFromStruct(obj);
                   catch ME
                       matRad_cfg.dispWarning('Objective/Constraint not valid!\n%s',ME.message)
                       continue;
                   end
               end
               
               %if strcmp(cst{runVoi,6}(runObjective).type,'square deviation') > 0 || strcmp(cst{runVoi,6}(runObjective).type,'square underdosing') > 0
               if isa(obj,'DoseObjectives.matRad_SquaredDeviation') || isa(obj,'DoseObjectives.matRad_SquaredUnderdosing')
                   referenceDose = (min(obj.getDoseParameters(),referenceDose))/numOfFractions;
               end            
            end

            if referenceDose == inf 
                voiPrint = sprintf('%s%s',voiPrint,'Warning: target has no objective that penalizes underdosage, ');
            else
 
                StringReferenceDose = regexprep(num2str(round(referenceDose*100)/100),'\D','_');
                % Conformity Index, fieldname contains reference dose
                VTarget95 = sum(doseInVoi >= 0.95*referenceDose); % number of target voxels recieving dose >= 0.95 dPres
                VTreated95 = sum(doseCube(:) >= 0.95*referenceDose);  %number of all voxels recieving dose >= 0.95 dPres ("treated volume")
                qi(runVoi).(['CI_' StringReferenceDose 'Gy']) = VTarget95^2/(numOfVoxels * VTreated95); 

                % Homogeneity Index (one out of many), fieldname contains reference dose        
                qi(runVoi).(['HI_' StringReferenceDose 'Gy']) = (DX(5) - DX(95))/referenceDose * 100;

                % voiPrint = sprintf('%sCI = %6.4f, HI = %5.2f for reference dose of %3.1f Gy\n',voiPrint,...
                %                    qi(runVoi).(['CI_' StringReferenceDose 'Gy']),qi(runVoi).(['HI_' StringReferenceDose 'Gy']),referenceDose);
            end
        end
        %We do it this way so the percentages in the string are not interpreted as format specifiers
        % matRad_cfg.dispInfo('%s\n',voiPrint);    
    else        
        matRad_cfg.dispInfo('%d %s - No dose information.',cst{runVoi,1},cst{runVoi,2});        
    end
end

% assign VOI names which could be corrupted due to empty structures
listOfFields = fieldnames(qi);
for i = 1:size(cst,1)
  indices     = cst{i,4}{1};
  doseInVoi    = sort(doseCube(indices));
  if isempty(doseInVoi)
      for j = 1:numel(listOfFields)
          qi(i).(listOfFields{j}) = NaN;
      end
      qi(i).name = cst{i,2};
  end
end

end