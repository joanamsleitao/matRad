function stamp = matRad_nowTag()
% matRad_nowTag - Return current timestamp tag in format yyyy-mm-dd_hhMM
%
% Syntax:
%   stamp = matRad_nowTag()
%
% Description:
%   Returns a compact timestamp string for filenames and figure names.
%   Format is fixed to: yyyy-mm-dd_hhMM
%
% Outputs:
%   stamp - timestamp string (char)
%
% Reference entry:
% | `matRad_nowTag` | `matRad_nowTag` | Timestamp tag yyyy-mm-dd_hhMM | `stamp = matRad_nowTag()` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

stamp = datestr(now,'yyyy-mm-dd_HHMM');

end