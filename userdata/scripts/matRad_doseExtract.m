function doseCube = matRad_doseExtract(resultGUI)
% Extract doseCube from resultGUI, if available
doseCube = [];
if isempty(resultGUI), return; end

if isfield(resultGUI, 'physicalDose')
    doseCube = resultGUI.physicalDose;
elseif isfield(resultGUI, 'RBExDose')
    doseCube = resultGUI.RBExDose;
else
    warning('No doseCube found in resultGUI.');
end
end
