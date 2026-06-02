function hAx = matRad_plotSingleBeamSpots(ct, cst, stf, iBeam, doseCube, varargin)
% matRad_plotSingleBeamSpots - Plot all spots for a single beam
%
% Syntax:
%   hAx = matRad_plotSingleBeamSpots(ct, cst, stf, iBeam)
%   hAx = matRad_plotSingleBeamSpots(ct, cst, stf, iBeam, doseCube, 'mode', 'midOnly')
%
% Description:
%   Creates a new figure and plots all spots for beam `iBeam` using
%   matRad_plotBeamSpots. Optionally shows CT/CST/dose background.
%
% Inputs:
%   ct       - matRad CT struct
%   cst      - matRad CST (cell array)
%   stf      - matRad STF struct (array of beams)
%   iBeam    - index of beam to plot
%   doseCube - (optional) dose cube to show as background
%
% Name-Value Options:
%   'mode'           - 'all' (default) | 'midOnly'
%   'showBackground' - true (default) | false
%   'markerSize'     - marker size (default: 6)
%   'figureName'     - string for figure window title
%
% Output:
%   hAx - handle to the axes containing the plot
%
% Example:
%   hAx = matRad_plotSingleBeamSpots(ct, cst, stf, 2, doseCube, 'mode','midOnly');
%
% Reference entry:
% | `matRad_plotSingleBeamSpots` | `matRad_plotSingleBeamSpots` | Plot spots for a single beam in a dedicated figure | `hAx = matRad_plotSingleBeamSpots(ct,cst,stf,iBeam,doseCube)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% --- Parse inputs ---
p = inputParser;
addRequired(p,'ct');
addRequired(p,'cst');
addRequired(p,'stf');
addRequired(p,'iBeam', @(x) isnumeric(x) && isscalar(x));
addOptional(p,'doseCube', [], @(x) isempty(x) || isnumeric(x));
addParameter(p,'mode', 'midOnly', @(s) any(strcmp(s,{'all','midOnly'})));
addParameter(p,'showBackground', true, @islogical);
addParameter(p,'markerSize', 6, @isnumeric);
addParameter(p,'figureName', '', @ischar);
parse(p, ct, cst, stf, iBeam, doseCube, varargin{:});

doseCube = p.Results.doseCube;
mode = p.Results.mode;
showBackground = p.Results.showBackground;
markerSize = p.Results.markerSize;
customFigureName = p.Results.figureName;

% Validate beam index
nBeams = numel(stf);
if iBeam < 1 || iBeam > nBeams
    error('iBeam (%d) out of range [1,%d]', iBeam, nBeams);
end

% Create figure
if isempty(customFigureName)
    figName = sprintf('Beam %d Spots', iBeam);
else
    figName = customFigureName;
end
fig = figure('Name', figName, 'Color', 'w');
hAx = axes(fig);
hold(hAx,'on');

% Plot background if requested
if showBackground
    try
        matRad_showSliceFast(hAx, ct, cst, doseCube);
    catch
        try
            matRad_showSliceFast(ct, cst, doseCube);
        catch
            % Ignore background if unavailable
        end
    end
end

% Call matRad_plotBeamSpots (assumes it's on path)
matRad_plotBeamSpots(hAx, ct, cst, stf, iBeam, doseCube, ...
    'mode', mode, 'showBackground', false, 'markerSize', markerSize);

title(hAx, sprintf('Beam %d', iBeam), 'FontWeight','bold');
axis(hAx,'equal');
hold(hAx,'off');

end