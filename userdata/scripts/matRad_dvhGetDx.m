function Dx = matRad_dvhGetDx(dvh, volumePct)  
    % Get dose at a given volume percentage (e.g., D95, D2)  
    %  
    % Inputs:  
    %   dvh       - struct with .doseGrid and .volumePoints fields  
    %   volumePct - volume percentage (0-100)  
    %  
    % Output:  
    %   Dx - dose [Gy] covering volumePct% of the structure  
      
    if numel(dvh.volumePoints) < 2  
        % Degenerate case: only one point  
        Dx = dvh.doseGrid(1);  
        return;  
    end  
    
    % Extract and ensure column vectors
    vol  = dvh.volumePoints(:);
    dose = dvh.doseGrid(:);
    
    % Sort by volume (in case not already sorted)
    [vol, idx] = sort(vol);
    dose = dose(idx);
    
    % Remove duplicate volume points (keep first occurrence)
    [vol_unique, ia] = unique(vol, 'stable');
    dose_unique = dose(ia);
    
    % Check if we still have enough points
    if numel(vol_unique) < 2
        warning('matRad_dvhGetDx: Less than 2 unique volume points after removing duplicates.');
        Dx = dose_unique(1);
        return;
    end
    
    % Linear interpolation with unique points
    Dx = interp1(vol_unique, dose_unique, volumePct, 'linear', 'extrap');  
end