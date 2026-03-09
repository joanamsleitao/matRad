function cb = matRad_setDoseCbarTicks(cb, nBins, dMin, dMaxPlot)
% matRad_setDoseCbarTicks - Put ticks at bin borders (0..21) and label plateau start at 21
%
% Syntax:
%   cb = matRad_setDoseCbarTicks(colorbar, nBins, 0, dMaxPlot)

if nargin < 4
    error('Need cb, nBins, dMin, dMaxPlot.');
end

thr = 21;

% Bin borders in data units (these are true dose values)
borders = linspace(dMin, thr, nBins).';

% Only keep those within the displayed range
borders = borders(borders >= dMin & borders <= dMaxPlot);

cb.Ticks = borders;

labs = compose('%.0f', borders);
% Ensure the threshold tick is clearly marked as plateau start
i21 = find(abs(borders - thr) < 1e-9, 1, 'first');
if ~isempty(i21)
    labs(i21) = "21 (plateau)";
end
cb.TickLabels = cellstr(labs);

cb.Label.String = 'Dose (Gy)';
cb.TickDirection = 'out';
end