function colorMap = matRad_machineColorMap(stf)
% matRad_machineColorMap - Generate machine-specific energy → RGB colormap
%
% Syntax:
%   colorMap = matRad_machineColorMap(stf)
%
% Description:
%   Builds a containers.Map that assigns a unique RGB color to each
%   available machine energy (in MeV) for the radiation mode / machine
%   combination used in the current STF.
%
%   The machine is loaded from the standard matRad machine file:
%       <radiationMode>_<machine>.mat
%   where both fields are taken from the first STF entry.
%
%   Example:
%       cmap = matRad_machineColorMap(stf);
%       c130 = cmap(130);  % 1x3 RGB for 130 MeV
%
% Inputs:
%   stf - matRad steering file struct (array of beams), must contain:
%           stf(1).radiationMode
%           stf(1).machine
%
% Outputs:
%   colorMap - containers.Map with:
%                 key:   energy (double, MeV)
%                 value: 1x3 RGB row vector in [0,1]
%
% Notes:
%   - Energies are taken from machine.data(:).energy.
%   - Energies are sorted before assigning colors, to ensure deterministic
%     mapping across runs.
%   - No special sub-selection (e.g., 21:40) is enforced; if you need that
%     behavior, it should be handled externally.
%
% Other m-files required: none (aside from matRad machine .mat files)
% Subfunctions: none
% MAT-files required: machine .mat file (e.g., 'protons_Generic.mat')
%
% See also:
%   matRad_plotSpotsSlice, matRad_plotDoseELsum
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_getMachineE...` | `matRad_machineColorMap` | Build machine-specific EL → RGB mapping for plotting | `cmap = matRad_machineColorMap(stf)` | 🟡 |
% -------------------------------------------------------------------------

% Basic checks
if nargin < 1 || isempty(stf)
    error('matRad_machineColorMap:InvalidSTF', ...
          'STF input is empty or missing.');
end
if ~isfield(stf(1), 'radiationMode') || ~isfield(stf(1), 'machine')
    error('matRad_machineColorMap:MissingFields', ...
          'STF(1) must contain fields "radiationMode" and "machine".');
end

% Compose machine file name: e.g., 'protons_Generic'
machineFileName = [stf(1).radiationMode, '_', stf(1).machine];

% Load machine struct
try
    loaded = load(machineFileName);
catch ME
    error('matRad_machineColorMap:MachineLoadFailed', ...
          'Could not load machine file "%s": %s', machineFileName, ME.message);
end

if ~isfield(loaded, 'machine')
    error('matRad_machineColorMap:NoMachineField', ...
          'File "%s" does not contain a variable named "machine".', machineFileName);
end

machine = loaded.machine;

% Extract available energies
if ~isfield(machine, 'data') || isempty(machine.data) || ...
   ~isfield(machine.data(1), 'energy')
    error('matRad_machineColorMap:NoEnergyField', ...
          'Machine struct in "%s" has no "data(:).energy" field.', machineFileName);
end

machineEnergies = [machine.data(:).energy];
machineEnergies = unique(sort(machineEnergies(:)'));   % sorted, unique

% Build colormap
nEnergies = numel(machineEnergies);
cmap = jet(nEnergies);  % can be parula, turbo, etc.

colorMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

for i = 1:nEnergies
    colorMap(machineEnergies(i)) = cmap(i,:);
end

end