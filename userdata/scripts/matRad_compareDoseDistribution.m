function [gammaCube,gammaPassRate,hfig] = matRad_compareDoseDistribution(cube1, cube2, ct, cst, contours, pln, criteria, n,localglobal)
% Comparison of two dose cubes in terms of gamma index, absolute and visual difference
%
% call
%   [gammaCube,gammaPassRate,hfig] = matRad_compareDose(cube1, cube2, ct, cst)
%   [gammaCube,gammaPassRate,hfig] = matRad_compareDose(cube1, cube2, ct, cst,enable , contours, pln, criteria, n,localglobal)
%
% input
%   cube1:         dose cube 1 as an M x N x O array
%   cube2:         dose cube 2 as an M x N x O array
%   ct:            ct struct with ct cube
%   cst:           list of interesting volumes inside the patient as matRad
%                  struct (optional, does not calculate gamma and DVH)
%   enable         (optional) specify if all sections are evaluated
%                  boolean 3x1 array
%                  [1 0 0]: evaluate only basic plots
%                  [0 1 0]: evaluate only line profiles
%                  [0 0 1]: evaluate only DVH
%   contours       (optional) specify if contours are plotted,
%                  'on' or 'off'
%   pln            (optional) specify BfioModel for DVH plot
%   criteria:      (optional)[1x2] vector specifying the distance to agreement
%                  criterion; first element is percentage difference,
%                  second element is distance [mm], default [3 3]
%   n:             (optional) number of interpolations. there will be 2^n-1
%                  interpolation points. The maximum suggested value is 3.
%                  default n=0
%   localglobal:   (optional) parameter to choose between 'global' and 'local'
%                  normalization
%
%
% output
%
%   gammaCube:      result of gamma index calculation
%   gammaPassRate:  rate of voxels passing the specified gamma criterion
%                   evaluated for every structure listed in 'cst'.
%                   note that only voxels exceeding the dose threshold are
%                   considered.
%   hfig:           Figure handle struct for all 3 figures and subplots,
%                   indexed by plane names
%
% References gamma analysis:
%   [1]  http://www.ncbi.nlm.nih.gov/pubmed/9608475
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team.
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

colorSpec = {'Color',matRad_cfg.gui.elementColor,...
    'XColor',matRad_cfg.gui.textColor,...
    'YColor',matRad_cfg.gui.textColor,...
    'GridColor',matRad_cfg.gui.textColor,...
    'MinorGridColor',matRad_cfg.gui.backgroundColor};

%% check if cubes consistent
if ~isequal(size(cube1),size(cube2))
    matRad_cfg.dispError('dose cubes must be the same size\n');
end

if ~exist('localglobal','var')
    localglobal = 'global';
end
if ~exist('n','var')
    n = 0;
end
if ~exist('criteria','var')
    criteria = [3 3];
end
if ~exist('cst','var') || isempty(cst)
    cst = [];
    skip = 1;
    matRad_cfg.dispWarning('cst not specified, skipping DVH, isocenter in the center of the doseCube');
else
    skip = 0;
end
if ~exist('pln','var') || isempty(pln)
    pln = [];
end
if ~exist('contours','var') || isempty(contours)
    contours = true;
end
if exist('contours','var') || ~isempty(contours)
    if strcmp(contours,'on')
        contours = true;
    else
        contours = false;
    end
end

% Load colormap for difference
diffCMap = matRad_getColormap('diffMap');

%% Calculate iso-center slices and resolution
if isempty(cst)
    isoCenterIx = round(ct.cubeDim./2);
else
    isoCenterIx = matRad_world2cubeIndex( matRad_getIsoCenter(cst,ct,0),ct);
end

resolution = [ct.resolution.x ct.resolution.y ct.resolution.z];

sliceName = {isoCenterIx(1),isoCenterIx(2),isoCenterIx(3)};
doseWindow = [0 max([cube1(:); cube2(:)])*1.001];
planeName = {'coronal','sagittal','axial'};

%% Integral Energy Output
if ~isempty(pln)
    intEnergy1 = matRad_calcIntEnergy(cube1,ct,pln);
    intEnergy2 = matRad_calcIntEnergy(cube2,ct,pln);

    matRad_cfg.dispInfo('Integral energy comparison: Cube 1 = %1.4g MeV, Cube 2 = %1.4g MeV, difference = %1.4g Mev\n',intEnergy1,intEnergy2,intEnergy1-intEnergy2);
end

%% Colorwash images


    % % Get the gamma cube
    % matRad_cfg.dispInfo('Calculating gamma index cube...\n');
    if exist('criteria','var')
        relDoseThreshold = criteria(1); % in [%]
        dist2AgreeMm     = criteria(2); % in [mm]
    else
        dist2AgreeMm     = 3; % in [mm]
        relDoseThreshold = 3; % in [%]
    end

    [gammaCube,gammaPassRate] = matRad_gammaIndex(cube1,cube2,resolution,criteria,[],n,localglobal,cst);


    % Calculate absolute difference cube and dose windows for plots
    differenceCube  = cube1-cube2;
    doseDiffWindow  = [-max(abs(differenceCube(:))) max(abs(differenceCube(:)))];
    %doseGammaWindow = [0 max(gammaCube(:))];
    doseGammaWindow = [0 2]; %We choose 2 as maximum value since the gamma colormap has a sharp cut in the middle


    % Plot everything
    % Plot dose slices
    if contours == false
        cstHandle = [];
    else
        cstHandle = cst;
    end

    for plane = 3
        matRad_cfg.dispInfo('Plotting %s plane...\n',planeName{plane});

        % Initialize Figure
        hfig.(planeName{plane}).('fig') = figure('Position', [10 50 800 800],'Color',matRad_cfg.gui.backgroundColor);

        % Plot Dose 1
        hfig.(planeName{plane}).('cube1').Axes = subplot(2,2,1,colorSpec{:});
        [hfig.(planeName{plane}).('cube1').CMap,...
            hfig.(planeName{plane}).('cube1').Dose,...
            hfig.(planeName{plane}).('cube1').Ct,...
            hfig.(planeName{plane}).('cube1').Contour,...
            hfig.(planeName{plane}).('cube1').IsoDose] = ...
            matRad_plotSliceWrapper(gca,ct,cstHandle,1,cube1,plane,sliceName{plane},[],[],colorcube,jet,doseWindow,[],100);

        % % Plot Dose 2
        % hfig.(planeName{plane}).('cube2').Axes = subplot(2,2,2,colorSpec{:});
        % [hfig.(planeName{plane}).('cube2').CMap,...
        %     hfig.(planeName{plane}).('cube2').Dose,...
        %     hfig.(planeName{plane}).('cube2').Ct,...
        %     hfig.(planeName{plane}).('cube2').Contour,...
        %     hfig.(planeName{plane}).('cube2').IsoDose] = ...
        %     matRad_plotSliceWrapper(gca,ct,cstHandle,1,cube2,plane,sliceName{plane},[],[],colorcube,jet,doseWindow,[],100);
        %
        % Plot absolute difference
        hfig.(planeName{plane}).('diff').Axes = subplot(2,2,3,colorSpec{:});
        [hfig.(planeName{plane}).('diff').CMap,...
            hfig.(planeName{plane}).('diff').Dose,...
            hfig.(planeName{plane}).('diff').Ct,...
            hfig.(planeName{plane}).('diff').Contour,...
            hfig.(planeName{plane}).('diff').IsoDose] = ...
            matRad_plotSliceWrapper(gca,ct,cstHandle,1,differenceCube,plane,sliceName{plane},[],[],colorcube,diffCMap,doseDiffWindow,[],100);

        % % Plot gamma analysis
        % hfig.(planeName{plane}).('gamma').Axes = subplot(2,2,4,colorSpec{:});
        % gammaCMap = matRad_getColormap('gammaIndex');
        % [hfig.(planeName{plane}).('gamma').CMap,...
        %     hfig.(planeName{plane}).('gamma').Dose,...
        %     hfig.(planeName{plane}).('gamma').Ct,...
        %     hfig.(planeName{plane}).('gamma').Contour,...
        %     hfig.(planeName{plane}).('gamma').IsoDose]=...
        %     matRad_plotSliceWrapper(gca,ct,cstHandle,1,gammaCube,plane,sliceName{plane},[],[],colorcube,gammaCMap,doseGammaWindow,[],100);
        %
        % Adjusting axes
        matRad_plotAxisLabels(hfig.(planeName{plane}).('cube1').Axes,ct,plane,sliceName{plane},[],100);
        set(get(hfig.(planeName{plane}).('cube1').Axes, 'title'), 'string', 'Dose 1');

        % matRad_plotAxisLabels(hfig.(planeName{plane}).('cube2').Axes,ct,plane,sliceName{plane},[],100);
        % set(get(hfig.(planeName{plane}).('cube2').Axes, 'title'), 'string', 'Dose 2');
        %
        matRad_plotAxisLabels(hfig.(planeName{plane}).('diff').Axes,ct,plane,sliceName{plane},[],100);
        set(get(hfig.(planeName{plane}).('diff').Axes, 'title'), 'string', 'Absolute difference');

        % matRad_plotAxisLabels(hfig.(planeName{plane}).('gamma').Axes,ct,plane,sliceName{plane},[],100);
        % set(get(hfig.(planeName{plane}).('gamma').Axes, 'title'), 'string', {[num2str(gammaPassRate{1,2},5) '% of points > ' num2str(relDoseThreshold) '% pass gamma criterion (' num2str(relDoseThreshold) '% / ' num2str(dist2AgreeMm) 'mm)']; ['with ' num2str(2^n-1) ' interpolation points']});
        %
    
end