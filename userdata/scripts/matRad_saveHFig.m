function outFiles = matRad_saveHFig(hFig, outDir, basePrefix, varargin)
% matRad_saveHFig - Save figure(s) from either:
%   (A) an hFig struct returned by matRad_comp2DosesAllPlanes (or similar), or
%   (B) a single figure handle.
%
% Usage:
%   outFiles = matRad_saveHFig(hFig)
%   outFiles = matRad_saveHFig(hFig, outDir)
%   outFiles = matRad_saveHFig(hFig, outDir, basePrefix, 'Name',Value,...)
%
% Inputs:
%   hFig       - struct OR single figure handle
%   outDir     - output folder (default: fullfile(pwd,'fig_hFig'))
%   basePrefix - filename prefix (default: 'hFig')
%
% Name-Value Pairs:
%   'savePNG'      - true/false (default: true)
%   'saveFIG'      - true/false (default: true)
%   'savePDF'      - true/false (default: false)
%   'resolution'   - PNG resolution in dpi (default: 300)
%   'contentType'  - 'vector' or 'image' for PDF (default: 'vector')
%
% Output:
%   outFiles - cell array of saved file paths

if nargin < 2 || isempty(outDir)
    outDir = fullfile(pwd, 'fig_hFig');
end
if nargin < 3 || isempty(basePrefix)
    basePrefix = 'hFig';
end

p = inputParser;
addParameter(p, 'savePNG', true,  @(x)islogical(x) && isscalar(x));
addParameter(p, 'saveFIG', true,  @(x)islogical(x) && isscalar(x));
addParameter(p, 'savePDF', false, @(x)islogical(x) && isscalar(x));
addParameter(p, 'resolution', 300, @(x)isnumeric(x) && isscalar(x) && x>0);
addParameter(p, 'contentType', 'vector', @(s) any(strcmpi(s, {'vector','image'})));
parse(p, varargin{:});
opts = p.Results;

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

outFiles = {};

% ------------------------------------------------------------
% Case B: single figure handle
% ------------------------------------------------------------
if isa(hFig, 'matlab.ui.Figure') || (isscalar(hFig) && ishghandle(hFig) && strcmp(get(hFig,'Type'),'figure'))
    figHandle = hFig;
    baseName = local_sanitizeFilename(basePrefix);

    figure(figHandle);

    if opts.savePNG
        fn = fullfile(outDir, [baseName '.png']);
        exportgraphics(figHandle, fn, 'Resolution', opts.resolution);
        outFiles{end+1,1} = fn; %#ok<AGROW>
    end

    if opts.saveFIG
        fn = fullfile(outDir, [baseName '.fig']);
        savefig(figHandle, fn);
        outFiles{end+1,1} = fn; %#ok<AGROW>
    end

    if opts.savePDF
        fn = fullfile(outDir, [baseName '.pdf']);
        exportgraphics(figHandle, fn, 'ContentType', lower(opts.contentType));
        outFiles{end+1,1} = fn; %#ok<AGROW>
    end

    fprintf('Saved %d file(s) to: %s\n', numel(outFiles), outDir);
    return;
end

% ------------------------------------------------------------
% Case A: hFig struct
% ------------------------------------------------------------
if ~isstruct(hFig)
    error('matRad_saveHFig:InvalidInput', ...
        'hFig must be a struct (matRad hFig) or a figure handle.');
end

planeNames = fieldnames(hFig);
for pIdx = 1:numel(planeNames)
    planeName = planeNames{pIdx};
    entries = hFig.(planeName);

    for k = 1:numel(entries)
        if ~isfield(entries(k), 'fig')
            continue;
        end
        figHandle = entries(k).fig;

        if isempty(figHandle) || ~ishghandle(figHandle) || ~strcmp(get(figHandle,'Type'),'figure')
            continue;
        end

        baseName = sprintf('%s_%s_set%02d', basePrefix, planeName, k);
        baseName = local_sanitizeFilename(baseName);

        figure(figHandle);

        if opts.savePNG
            fn = fullfile(outDir, [baseName '.png']);
            exportgraphics(figHandle, fn, 'Resolution', opts.resolution);
            outFiles{end+1,1} = fn; %#ok<AGROW>
        end

        if opts.saveFIG
            fn = fullfile(outDir, [baseName '.fig']);
            savefig(figHandle, fn);
            outFiles{end+1,1} = fn; %#ok<AGROW>
        end

        if opts.savePDF
            fn = fullfile(outDir, [baseName '.pdf']);
            exportgraphics(figHandle, fn, 'ContentType', lower(opts.contentType));
            outFiles{end+1,1} = fn; %#ok<AGROW>
        end
    end
end

fprintf('Saved %d file(s) to: %s\n', numel(outFiles), outDir);

end

function s = local_sanitizeFilename(s)
s = char(s);
s = regexprep(s, '[<>:"/\\|?*]', '_');
s = regexprep(s, '\s+', '_');
end