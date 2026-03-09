function [doseELOpt, wELOpt, weightsFiltered] = matRad_optSingleEL(dij, cst, pln, wAll, elStruct)
% matRad_optSingleEL - Reoptimize a single energy layer via spot removal
%
% Syntax:
%   [doseELOpt, wELOpt, weightsFiltered] = matRad_optSingleEL(dij, cst, pln, wAll, elStruct)
%
% Description:
%   Filters the global weight vector wAll using elStruct.spotMask to keep
%   only the spots belonging to the selected energy layer, then performs a
%   re-optimization using matRad_SpotRemovalDij. Afterwards, rescales the
%   optimized dose to match the maximum dose of the original EL dose.
%
% Inputs:
%   dij      - matRad dij struct
%   cst      - CST cell array
%   pln      - plan struct
%   wAll     - global weight vector (e.g. wRBE)
%   elStruct - struct for that EL, with fields:
%                .RBExDose  - original dose cube of this EL
%                .spotMask  - logical vector, same length as wAll
%
% Outputs:
%   doseELOpt       - optimized dose cube for this EL (rescaled)
%   wELOpt          - optimized weights (rescaled, same length as wAll)
%   weightsFiltered - initial filtered weights used as starting point
%
% Example:
%   [doseELOpt, wELOpt] = matRad_optSingleEL(dij, cst, pln, wRBE, EL_95MeV);
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_optSingleEL` | `matRad_optSingleEL` | Reoptimize a single EL via spot removal | `[doseELOpt, wELOpt, weightsFiltered] = matRad_optSingleEL(dij, cst, pln, wAll, elStruct)` | 🟢 |
% -------------------------------------------------------------------------

if ~isfield(elStruct, 'spotMask') || ~islogical(elStruct.spotMask)
    error('matRad_optSingleEL:InvalidSpotMask', ...
          'elStruct.spotMask must exist and be a logical vector.');
end
if ~isfield(elStruct, 'RBExDose') || isempty(elStruct.RBExDose)
    error('matRad_optSingleEL:MissingDose', ...
          'elStruct.RBExDose must exist and be non-empty.');
end

% Filter global weights for this EL
weightsFiltered = wAll;
keepMask = elStruct.spotMask;
if numel(keepMask) ~= numel(weightsFiltered)
    error('matRad_optSingleEL:SizeMismatch', ...
          'spotMask and weight vector must have same length.');
end
weightsFiltered(~keepMask) = 0;

% Reoptimize
spotRemover = matRad_SpotRemovalDij(dij, weightsFiltered);
resultELOpt = spotRemover.reoptimize(cst, pln);

% Rescale to original max dose
doseELorig = elStruct.RBExDose;
doseELOpt_raw = resultELOpt.RBExDose;
f = max(doseELorig(:)) / max(doseELOpt_raw(:));

doseELOpt = f * doseELOpt_raw;
wELOpt    = f * resultELOpt.w;

end