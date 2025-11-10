function [ct, cst, pln, stf, resultGUI] = matRad_loadMat1(filePath, fallbackMat)
fprintf('→ Loading MAT file: %s\n', filePath);
[ct, cst, pln, stf, resultGUI] = matRad_dataLoadMat(filePath);

if (isempty(ct) || isempty(cst)) && ~isempty(fallbackMat)
    if isfile(fallbackMat)
        fprintf('→ Using fallback MAT: %s\n', fallbackMat);
        [ct_fb, cst_fb, ~, ~, ~] = matRad_dataLoadMat(fallbackMat);
        if isempty(ct), ct = ct_fb; fprintf('  • CT replaced from fallback MAT.\n'); end
        if isempty(cst), cst = cst_fb; fprintf('  • CST replaced from fallback MAT.\n'); end
    else
        warning('Fallback MAT file not found: %s', fallbackMat);
    end
end
fprintf('✓ MAT file loaded successfully.\n');
end