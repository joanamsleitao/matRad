function dpDose_linear = matRad_linearizeDose(dij, w, pln, ct, cst, showFig)
% matRad_linearizeDose Collapse dose influence matrix into linear vector
% and optionally plot a dose slice for verification.
%
% USAGE:
%   dpDose_linear = matRad_linearizeDose(dij, w, pln, ct, cst);
%   dpDose_linear = matRad_linearizeDose(dij, w, pln, ct, cst, 1);
%
% INPUTS:
%   dij      - matRad dose influence struct (physicalDose{1,1} used)
%   w        - spot weight vector [nSpots x 1]
%   pln      - matRad plan struct
%   ct       - matRad CT struct
%   cst      - matRad structure/contour struct
%   showFig  - (optional) 1 = show dose slice, 0 (default) = no plot
%
% OUTPUT:
%   dpDose_linear - sparse vector [nVoxels*nSpots x 1]

    if nargin < 6
        showFig = 0;
    end

    % --- Extract dose influence matrix ---
    dpDose = dij.physicalDose{1,1};   % [nVoxels x nSpots]

    % --- Collapse to linear sparse vector ---
    [row, col, val] = find(dpDose);
    linear_idx = sub2ind(size(dpDose), row, col);
    dpDose_linear = sparse(linear_idx, 1, val, numel(dpDose), 1);
    
    % Optional: full linear vector
    % dpDose_linear = dpDose(:);

    % --- Compute dose per voxel ---
    w = w(:);  % ensure column
    d = dpDose * w;   % [nVoxels x 1]

    % --- Reshape into 3D dose cube ---
    D = reshape(full(d), dij.doseGrid.dimensions);

    % --- Interpolate dose to CT grid ---
    D_CT = matRad_interp3( ...
        dij.doseGrid.x, dij.doseGrid.y', dij.doseGrid.z, ...
        D, ...
        dij.ctGrid.x, dij.ctGrid.y', dij.ctGrid.z, ...
        'linear', 0);

    % --- Plot slice if requested ---
    if showFig
        slice = round(pln.propStf.isoCenter(1,3) ./ ct.resolution.z);
        figure;
        matRad_showSliceFast(ct, cst, D_CT);
        axis equal tight;
        xlabel('x [mm]'); ylabel('y [mm]');
        title(sprintf('Dose slice at z = %.1f mm', pln.propStf.isoCenter(1,3)));
        colormap jet; colorbar;
    end
end
