function [hCMap,hCt,hContour] = matRadJoana_plotCTSlice(axesHandle,ct,cst,cubeIdx,plane,slice,thresh,alpha,contourColorMap,...
                                                                          doseColorMap,doseWindow,doseIsoLevels,voiSelection,colorBarLabel,boolPlotLegend,varargin)
% MATRADJOANA_PLOTCTSLICE - Plots CT slice with contours
%
% Syntax:  [hCMap,hCt,hContour] = matRadJoana_plotCTSlice(axesHandle,ct,cst,cubeIdx,plane,slice,thresh,alpha,contourColorMap,...
%                                                                          doseColorMap,doseWindow,doseIsoLevels,voiSelection,colorBarLabel,boolPlotLegend,varargin)
%
% Inputs:
%   axesHandle        - Handle to axes (handle)
%   ct                - CT structure (struct)
%   cst               - CST cell array (cell array)
%   cubeIdx           - Cube index (integer)
%   plane             - Plane view (1=coronal,2=sagittal,3=axial) (integer)
%   slice             - Slice number (integer)
%   thresh            - Dose threshold (double, optional)
%   alpha             - Alpha value (double, optional)
%   contourColorMap   - Contour colormap (matrix, optional)
%   doseColorMap      - Dose colormap (matrix, optional)
%   doseWindow        - Dose window (vector, optional)
%   doseIsoLevels     - Iso dose levels (vector, optional)
%   voiSelection      - VOI selection (logical array, optional)
%   colorBarLabel     - Colorbar label (string, optional)
%   boolPlotLegend    - Plot legend flag (logical, optional)
%   varargin          - Additional plotting parameters (varargin)
%
% Outputs:
%   hCMap     - Handle to colormap (handle)
%   hCt       - Handle to CT plot (handle)
%   hContour  - Handle to contour plot (handle)
%
% Other m-files required: matRad_plotCtSlice.m, matRad_plotVoiContourSlice.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_plotCtSlice, matRad_plotVoiContourSlice
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Handle the argument list
if ~exist('thresh','var') || isempty(thresh)
    thresh = [];
end
if ~exist('alpha','var') || isempty(alpha)
    alpha = [];
end
if ~exist('contourColorMap','var') || isempty(contourColorMap)
   contourColorMap = [];
end
if ~exist('doseColorMap','var') || isempty(doseColorMap)
   doseColorMap = [];
end
if ~exist('doseWindow','var') || isempty(doseWindow)
   doseWindow = [];
end
if ~exist('doseIsoLevels','var') || isempty(doseIsoLevels)
   doseIsoLevels = [];
end

if ~exist('voiSelection','var') || isempty(voiSelection)
   voiSelection = [];
end

if ~exist('colorBarLabel','var') || isempty(colorBarLabel)
   colorBarLabel = [];
end

if ~exist('boolPlotLegend','var') || isempty(boolPlotLegend)
   boolPlotLegend = false;
end

if ~exist('cst','var') || isempty(cst)
   cst = [];
end

matRad_cfg = MatRad_Config.instance();

set(axesHandle,'YDir','Reverse');
% plot ct slice
hCt = matRad_plotCtSlice(axesHandle,ct.cubeHU,cubeIdx,plane,slice); 
hold on;

% % plot dose
% if ~isempty(doseWindow) && doseWindow(2) - doseWindow(1) <= 0
%     doseWindow = [0 2];
% end

% [hDose,doseColorMap,doseWindow] = matRad_plotDoseSlice(axesHandle,dose,plane,slice,thresh,alpha,doseColorMap,doseWindow);

% % plot iso dose lines
% if ~isempty(doseIsoLevels)
%     hIsoDose = matRad_plotIsoDoseLines(axesHandle,dose,[],doseIsoLevels,false,plane,slice,doseColorMap,doseWindow,varargin{:});
%     hold on;
% else
%     hIsoDose = [];
% end

%plot VOI contours
if  ~isempty(cst)

    [hContour,~] = matRad_plotVoiContourSlice(axesHandle,cst,ct,cubeIdx,voiSelection,plane,slice,contourColorMap,varargin{:});

if boolPlotLegend
   visibleOnSlice = (~cellfun(@isempty,hContour));
   ixLegend = find(voiSelection);
   hContourTmp    = cellfun(@(X) X(1),hContour(visibleOnSlice),'UniformOutput',false);
   if ~isempty(voiSelection)
       hLegend        =  legend(axesHandle,[hContourTmp{:}],[cst(ixLegend(visibleOnSlice),2)],'AutoUpdate','off','TextColor',matRad_cfg.gui.textColor);
   else
       hLegend        =  legend(axesHandle,[hContourTmp{:}],[cst(visibleOnSlice,2)],'AutoUpdate','off','TextColor',matRad_cfg.gui.textColor);
   end
   set(hLegend,'Box','Off');
   set(hLegend,'TextColor',matRad_cfg.gui.textColor);
   set(hLegend,'FontSize',matRad_cfg.gui.fontSize);

end
else
    hContour = [];
end

axis(axesHandle,'tight');
set(axesHandle,'xtick',[],'ytick',[]);
% colormap(axesHandle,doseColorMap);

matRad_plotAxisLabels(axesHandle,ct,plane,slice,[])

% set axis ratio

ratios = [1/ct.resolution.x 1/ct.resolution.y 1/ct.resolution.z];
   
set(axesHandle,'DataAspectRatioMode','manual');
if plane == 1 
      res = [ratios(3) ratios(2)]./max([ratios(3) ratios(2)]);  
      set(axesHandle,'DataAspectRatio',[res 1])
elseif plane == 2 % sagittal plane
      res = [ratios(3) ratios(1)]./max([ratios(3) ratios(1)]);  
      set(axesHandle,'DataAspectRatio',[res 1]) 
elseif  plane == 3 % Axial plane
      res = [ratios(2) ratios(1)]./max([ratios(2) ratios(1)]);  
      set(axesHandle,'DataAspectRatio',[res 1])
end

% hCMap = matRad_plotColorbar(axesHandle,doseColorMap,doseWindow,'Location','EastOutside');
% set(hCMap,'Color',matRad_cfg.gui.textColor);
% if ~isempty(colorBarLabel)
%     set(get(hCMap,'YLabel'),'String', colorBarLabel,'FontSize',matRad_cfg.gui.fontSize);
% end

end