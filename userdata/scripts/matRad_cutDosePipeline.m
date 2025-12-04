function [doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef, zRef2, nSlicesTarget, planesToShow)
% matRad_cutDosePipeline - Cut specified axial slices to zero and visualize with matRad_showAllPlanes
%
% Syntax:
%   [doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef)
%   [doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef, zRef2)
%   [doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef, zRef2, nSlicesTarget)
%   [doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef, zRef2, nSlicesTarget, planesToShow)
%
% Description:
%   Integrated pipeline that:
%     1) Calls matRad_cutDoseAxial to zero dose on specified axial slices
%     2) Calls matRad_showAllPlanes to visualize with cut slices highlighted
%
%   Modes:
%     - 'cut_above'   : zero slices >= zRef (keep below)
%     - 'cut_below'   : zero slices <= zRef (keep above)
%     - 'cut_outside' : zero slices outside [zRef, zRef2] (keep between)
%     - 'cut_inside'  : zero slices inside [zRef, zRef2] (keep outside)
%
% Inputs:
%   doseIn        - 3D dose cube or matRad dose struct with field 'cube'
%   ct            - matRad CT struct (must include ct.cubeDim)
%   cst           - matRad CST cell array (VOIs)
%   mode          - 'cut_above' | 'cut_below' | 'cut_outside' | 'cut_inside'
%   zRef          - reference slice index (1-based)
%   zRef2         - upper reference slice index (1-based, required for 'cut_outside'/'cut_inside')
%   nSlicesTarget - (optional) target number of slices per plane for viewer (default: 30)
%   planesToShow  - (optional) planes to display: 1=axial, 2=coronal, 3=sagittal (default: 1:3)
%
% Outputs:
%   doseCut - cut dose (same type as doseIn)
%   hFig    - struct with figure handles from matRad_showAllPlanes
%
% Notes:
%   - Altered slices (those set to zero) are highlighted in axial plane with orange asterisk.
%
% Reference List Entry:
%   Previous Name: N/A
%   Current Name : matRad_cutDosePipeline
%   Description  : Cut axial slices to zero and visualize with matRad_showAllPlanes
%   Call         : [doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef, zRef2, nSlicesTarget, planesToShow)
%   Status       : 🟢
%
% -------------------------------------------------------------------------
% Author: Joana Leitão 
% Date: 2025-11-13_0000
% -------------------------------------------------------------------------

    if nargin < 5
        error('matRad_cutDosePipeline:NotEnoughInputs', ...
              'Provide doseIn, ct, cst, mode, and zRef (plus zRef2 for ''cut_outside''/''cut_inside'').');
    end
    if nargin < 6, zRef2 = []; end
    if nargin < 7 || isempty(nSlicesTarget), nSlicesTarget = 30; end
    if nargin < 8 || isempty(planesToShow), planesToShow = 1:3; end

    if ~isfield(ct,'cubeDim')
        error('matRad_cutDosePipeline:InvalidCT','ct must contain field ct.cubeDim.');
    end
    nZ = ct.cubeDim(3);

    % Determine cut slices (these will be zeroed) based on mode
    mode = lower(string(mode));
    switch mode
        case "cut_above"
            z0 = max(1, min(nZ, round(zRef)));
            cutZ = false(1,nZ); 
            cutZ(z0:nZ) = true;

        case "cut_below"
            z0 = max(1, min(nZ, round(zRef)));
            cutZ = false(1,nZ);
            cutZ(1:z0) = true;

        case "cut_outside"
            if isempty(zRef2)
                error('matRad_cutDosePipeline:MissingzRef2','zRef2 required for ''cut_outside''.');
            end
            z1 = max(1, min(nZ, round(min(zRef, zRef2))));
            z2 = max(1, min(nZ, round(max(zRef, zRef2))));
            cutZ = true(1,nZ);
            cutZ(z1:z2) = false;

        case "cut_inside"
            if isempty(zRef2)
                error('matRad_cutDosePipeline:MissingzRef2','zRef2 required for ''cut_inside''.');
            end
            z1 = max(1, min(nZ, round(min(zRef, zRef2))));
            z2 = max(1, min(nZ, round(max(zRef, zRef2))));
            cutZ = false(1,nZ);
            cutZ(z1:z2) = true;

        otherwise
            error('matRad_cutDosePipeline:UnknownMode','Unknown mode: %s', mode);
    end

    alteredSlices = find(cutZ);

    % Cut dose
    if strcmp(mode, 'cut_outside') || strcmp(mode, 'cut_inside')
        doseCut = matRad_cutDoseAxial(doseIn, ct, mode, zRef, zRef2);
    else
        doseCut = matRad_cutDoseAxial(doseIn, ct, mode, zRef);
    end

    % Prepare viewer dose cube
    if isstruct(doseCut) && isfield(doseCut,'cube')
        doseCubeVis = doseCut.cube;
    else
        doseCubeVis = doseCut;
    end

    % Visualize with altered (cut) slices highlighted in axial plane
    hFig = matRad_showAllPlanes(ct, cst, doseCubeVis, nSlicesTarget, alteredSlices, planesToShow);

    fprintf('✅ matRad_cutDosePipeline: mode=%s, cut %d axial slices to zero.\n', ...
        char(mode), numel(alteredSlices));
end