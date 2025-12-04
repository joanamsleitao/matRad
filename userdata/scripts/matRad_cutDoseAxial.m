function doseOut = matRad_cutDoseAxial(doseIn, ct, mode, zRef, zRef2)
% matRad_cutDoseAxial - Set dose to zero on selected axial slices
%
% Syntax:
%   doseOut = matRad_cutDoseAxial(doseIn, ct, mode, zRef)
%   doseOut = matRad_cutDoseAxial(doseIn, ct, mode, zRef, zRef2)
%
% Description:
%   "Cuts" a dose cube along the axial (z) direction by zeroing dose
%   voxels in a specified set of slices. The selection is defined via 'mode':
%     - 'cut_above'   : zero slices z >= zRef (keep z < zRef)
%     - 'cut_below'   : zero slices z <= zRef (keep z > zRef)
%     - 'cut_outside' : zero slices outside [zRef, zRef2] (keep between)
%     - 'cut_inside'  : zero slices inside [zRef, zRef2] (keep outside)
%
%   Inputs accept either a dose cube (3D numeric) or a matRad dose struct
%   with field 'cube'. The CT struct is used for validation via ct.cubeDim.
%
% Inputs:
%   doseIn - 3D numeric dose cube or matRad dose struct with field 'cube'
%   ct     - matRad CT struct (must include ct.cubeDim)
%   mode   - char/string: 'cut_above' | 'cut_below' | 'cut_outside' | 'cut_inside'
%   zRef   - reference slice index (1-based). For 'cut_outside'/'cut_inside', lower bound
%   zRef2  - upper reference slice index (1-based). Required for 'cut_outside'/'cut_inside'
%
% Outputs:
%   doseOut - same type as doseIn (cube or struct) with selected slices zeroed
%
% Notes:
%   - Indices are 1-based MATLAB axial slice indices (3rd dimension).
%   - zRef/zRef2 are clamped to [1, nZ].
%   - If doseIn is a struct, all fields are copied and only cube is changed.
%
% Reference List Entry:
%   Previous Name: N/A
%   Current Name : matRad_cutDoseAxial
%   Description  : Zero dose on selected axial slices with explicit cut semantics
%   Call         : doseOut = matRad_cutDoseAxial(doseIn, ct, mode, zRef, zRef2)
%   Status       : 🟢
%
% -------------------------------------------------------------------------
% Author: Joana Leitão 
% Date: 2025-11-13_0000
% -------------------------------------------------------------------------

    % Validate inputs
    if nargin < 4
        error('matRad_cutDoseAxial:NotEnoughInputs', ...
              'Provide doseIn, ct, mode, and zRef (plus zRef2 for ''cut_outside''/''cut_inside'').');
    end
    if ~ischar(mode) && ~isstring(mode)
        error('matRad_cutDoseAxial:InvalidMode',...
              'mode must be ''cut_above'', ''cut_below'', ''cut_outside'', or ''cut_inside''.');
    end
    mode = lower(string(mode));

    % Extract dose cube and remember struct shape
    isStruct = isstruct(doseIn) && isfield(doseIn,'cube');
    if isStruct
        doseCube = doseIn.cube;
    else
        doseCube = doseIn;
    end

    if ndims(doseCube) ~= 3
        error('matRad_cutDoseAxial:InvalidDose','dose cube must be 3D.');
    end
    if ~isfield(ct,'cubeDim')
        error('matRad_cutDoseAxial:InvalidCT','ct must contain field ct.cubeDim.');
    end

    % Validate dose dimensions match CT using ct.cubeDim
    if ~isequal(size(doseCube), ct.cubeDim)
        error('matRad_cutDoseAxial:DimensionMismatch', ...
              'Dose cube size [%s] does not match ct.cubeDim [%s].', ...
              num2str(size(doseCube)), num2str(ct.cubeDim));
    end

    % Determine z size from ct.cubeDim (axial is 3rd dimension)
    nZ = ct.cubeDim(3);

    % Build cut mask over z based on mode (true = to be zeroed)
    switch mode
        case "cut_above"
            validateattributes(zRef, {'numeric'}, {'nonempty','scalar','finite','real'});
            z0 = max(1, min(nZ, round(zRef)));
            cutZ = false(1,nZ); 
            cutZ(z0:nZ) = true;  % zero from z0 upward

        case "cut_below"
            validateattributes(zRef, {'numeric'}, {'nonempty','scalar','finite','real'});
            z0 = max(1, min(nZ, round(zRef)));
            cutZ = false(1,nZ);
            cutZ(1:z0) = true;   % zero from 1 to z0

        case "cut_outside"
            if nargin < 5 || isempty(zRef2)
                error('matRad_cutDoseAxial:MissingzRef2',...
                      'zRef2 is required for mode ''cut_outside''.');
            end
            z1 = max(1, min(nZ, round(min(zRef, zRef2))));
            z2 = max(1, min(nZ, round(max(zRef, zRef2))));
            cutZ = true(1,nZ);
            cutZ(z1:z2) = false; % keep between z1..z2, zero outside

        case "cut_inside"
            if nargin < 5 || isempty(zRef2)
                error('matRad_cutDoseAxial:MissingzRef2',...
                      'zRef2 is required for mode ''cut_inside''.');
            end
            z1 = max(1, min(nZ, round(min(zRef, zRef2))));
            z2 = max(1, min(nZ, round(max(zRef, zRef2))));
            cutZ = false(1,nZ);
            cutZ(z1:z2) = true;  % zero between z1..z2, keep outside

        otherwise
            error('matRad_cutDoseAxial:UnknownMode','Unknown mode: %s', mode);
    end

    % Apply mask explicitly and safely
    nx = size(doseCube,1); ny = size(doseCube,2);
    zMask3D = false(nx, ny, nZ);
    zMask3D(:,:,cutZ) = true;
    doseCube(zMask3D) = 0;

    % Return in same container type
    if isStruct
        doseOut = doseIn;
        doseOut.cube = doseCube;
    else
        doseOut = doseCube;
    end
end