function Vx = matRad_dvhGetVx(dvh, doseValue)  
    % Get volume percentage receiving >= doseValue (e.g., V14Gy)  
    %  
    % Inputs:  
    %   dvh       - struct with .doseGrid and .volumePoints fields  
    %   doseValue - dose threshold [Gy]  
    %  
    % Output:  
    %   Vx - volume percentage [%] receiving >= doseValue  
    
    if numel(dvh.doseGrid) < 2  
        % Degenerate case: only one point  
        if dvh.doseGrid(1) >= doseValue  
            Vx = 100;  
        else  
            Vx = 0;  
        end  
        return;  
    end  
    
    % Extract and ensure column vectors
    dose = dvh.doseGrid(:);
    vol  = dvh.volumePoints(:);
    
    % Sort by dose (descending for cumulative DVH)
    [dose, idx] = sort(dose, 'descend');
    vol = vol(idx);
    
    % Remove duplicate dose points (keep first occurrence)
    [dose_unique, ia] = unique(dose, 'stable');
    vol_unique = vol(ia);
    
    % Check if we still have enough points
    if numel(dose_unique) < 2
        if dose_unique(1) >= doseValue
            Vx = vol_unique(1);
        else
            Vx = 0;
        end
        return;
    end
    
    % Linear interpolation (dose -> volume)
    Vx = interp1(dose_unique, vol_unique, doseValue, 'linear', 'extrap');  
    
    % Clamp to valid range [0, 100]  
    Vx = max(0, min(100, Vx));  
end