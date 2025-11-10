function colorMap = matRad_getMachineEnergyColorMap(stf)
% matRad_getMachineEnergyColorMap - Generate energy-based colormap for machine energies
%
% Syntax:
%   colorMap = matRad_getMachineEnergyColorMap(stf)
%
% Inputs:
%   stf - matRad steering file struct containing machine and radiation mode info
%
% Outputs:
%   colorMap - containers.Map with energy keys (MeV) and RGB values (1x3 array)
%
% Description:
%   Creates a colormap that maps machine energy levels to RGB colors.
%   For 'protons_Generic', uses a subset of energies (21 to 40).
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: machine .mat file (e.g., 'protons_Generic.mat')
%
% See also: matRad_plotEnergyLayerHistogram
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Get machine name from STF
    machineName = stf(1).machine;

    % Load machine data
    % machine = matRad_loadMachine(machineName);
    % 
    % % Load machine if not provided
    machineName = append(stf.radiationMode, '_', stf.machine);
    machine = load(machineName);
    machine = machine.machine;

    % Extract available energies
    machineEnergies = [machine.data(:).energy];

    % Special handling for 'protons_generic'
    if strcmp(machineName, 'protons_Generic')
        machineEnergies = machineEnergies(21:40);
    end

    % Sort energies to ensure color order is consistent
    machineEnergies = sort(machineEnergies(:)');

    % Create colormap
    nEnergies = numel(machineEnergies);
    cmap = jet(nEnergies);  % or parula/turbo/etc.
    colorMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

    % Assign RGB color to each energy
    for i = 1:nEnergies
        colorMap(machineEnergies(i)) = cmap(i,:);
    end
end
