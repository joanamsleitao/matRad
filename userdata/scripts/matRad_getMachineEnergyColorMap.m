function colorMap = matRad_getMachineEnergyColorMap(stf)
% Generate a colormap based on energy levels for a given STF (stf).
% Loads the machine and maps energies to RGB colors.
% For 'protons_generic', only energies 21 and 94 are considered.

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
