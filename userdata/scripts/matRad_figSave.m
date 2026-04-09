function matRad_figSave(hFig, outFolder, baseName, varargin)
% matRad_figSave - Save a figure for PowerPoint (PNG + FIG) with notes
%
% Syntax:
%   matRad_figSave(hFig, outFolder, baseName)
%   matRad_figSave(..., 'DPI', 300, 'Notes', 'text')
%
% Description:
%   Exports the figure as a high-resolution PNG (PowerPoint-friendly) and
%   also saves a MATLAB FIG for later editing. Optionally writes a TXT note
%   file with context for slides.
%
% Inputs:
%   hFig      - figure handle
%   outFolder - destination folder
%   baseName  - filename base (no extension)
%
% Name-Value Pairs:
%   'DPI'   - export resolution (default: 300)
%   'Notes' - text saved to baseName_notes.txt (default: '')
%
% Outputs:
%   (none)
%
% Reference entry (add to your catalog):
% | `matRad_figSave` | `matRad_figSave` | Save figures (PNG+FIG) for PPT with notes | `matRad_figSave(gcf,outFolder,'name','DPI',300)` | 🟡 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

p = inputParser;
p.addParameter('DPI',300,@(x)isnumeric(x)&&isscalar(x));
p.addParameter('Notes','',@(s)ischar(s)||isstring(s));
p.parse(varargin{:});

dpi   = p.Results.DPI;
notes = string(p.Results.Notes);

% Basic formatting for PPT
set(hFig,'Color','w');
axs = findall(hFig,'Type','axes');
for iAx = 1:numel(axs)
    set(axs(iAx),'FontName','Arial','FontSize',12,'LineWidth',1);
end

pngFile = fullfile(outFolder, baseName + ".png");
figFile = fullfile(outFolder, baseName + ".fig");
txtFile = fullfile(outFolder, baseName + "_notes.txt");

% Use exportgraphics when available (R2020a+)
try
    exportgraphics(hFig, pngFile, 'Resolution', dpi, 'BackgroundColor','white');
catch
    % fallback
    print(hFig, pngFile, '-dpng', ['-r',num2str(dpi)]);
end

savefig(hFig, figFile);

if strlength(notes) > 0
    fid = fopen(txtFile,'w');
    fprintf(fid,'%s\n', notes);
    fclose(fid);
end
end
