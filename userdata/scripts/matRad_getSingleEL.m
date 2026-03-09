function [elDoseStruct, elQiStruct] = matRad_getSingleEL(topELStruct, qiByEL, elName)
% matRad_getSingleEL - Extract single energy-layer entries from structs
%
% Syntax:
%   [elDoseStruct, elQiStruct] = matRad_getSingleEL(topELStruct, qiByEL, elName)
%
% Description:
%   Extracts a single energy layer from both topELStruct and qiByEL,
%   returning small structs containing only that layer. This is meant as a
%   clean handoff to a single-EL analysis / optimization pipeline.
%
% Inputs:
%   topELStruct - struct with all energy layers (fields = EL names)
%   qiByEL      - struct with per-EL VOI metrics (fields = EL names)
%   elName      - string, e.g. 'EL_95_3MeV'
%
% Outputs:
%   elDoseStruct - struct with fields:
%                    .EL   = topELStruct.(elName)
%   elQiStruct   - struct with fields:
%                    .EL   = qiByEL.(elName)
%
% Example:
%   [ELdose, ELqi] = matRad_getSingleEL(topELStruct, qiByEL, 'EL_95_3MeV');
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_getSingleEL` | `matRad_getSingleEL` | Extract single EL dose + metrics structs | `[elDoseStruct, elQiStruct] = matRad_getSingleEL(topELStruct, qiByEL, elName)` | 🟢 |
% -------------------------------------------------------------------------

if ~isfield(topELStruct, elName)
    error('matRad_getSingleEL:UnknownEL', 'EL "%s" not found in topELStruct.', elName);
end

elDoseStruct = struct();
elDoseStruct.EL = topELStruct.(elName);

if nargin > 1 && ~isempty(qiByEL)
    if ~isfield(qiByEL, elName)
        error('matRad_getSingleEL:UnknownELqi', 'EL "%s" not found in qiByEL.', elName);
    end
    elQiStruct = struct();
    elQiStruct.EL = qiByEL.(elName);
else
    elQiStruct = struct();
end

end