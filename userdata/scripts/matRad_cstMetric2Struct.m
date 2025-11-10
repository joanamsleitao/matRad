function obj = matRad_cstMetric2Struct(metricStr)
% matRad_cstMetrictoStruct
% -------------------------------------------------------------------------
% Converts a metric string (e.g. 'D_50 minDVH 28.70Gy 250.0')
% into a matRad-compatible objective struct.
% -------------------------------------------------------------------------

parts = strsplit(strtrim(metricStr));
obj = struct('className', '', 'parameters', {{}}, 'penalty', []);

switch true
    % === DVH objectives ===
    case contains(parts{1}, 'D_') && strcmpi(parts{2}, 'minDVH')
        vol = str2double(extractAfter(parts{1}, 'D_'));
        dose = parseGy(parts{3});
        obj.className = 'DoseObjectives.matRad_MinDVH';
        obj.parameters = {dose, vol};
        obj.penalty = str2double(parts{4});

    case contains(parts{1}, 'D_') && strcmpi(parts{2}, 'maxDVH')
        vol = str2double(extractAfter(parts{1}, 'D_'));
        dose = parseGy(parts{3});
        obj.className = 'DoseObjectives.matRad_MaxDVH';
        obj.parameters = {dose, vol};
        obj.penalty = str2double(parts{4});

    % === Mean dose ===
    case strcmpi(parts{1}, 'mean')
        obj.className = 'DoseObjectives.matRad_Mean';
        obj.parameters = {};
        obj.penalty = str2double(parts{2});

    % === Squared deviation ===
    case strcmpi(parts{1}, 'sqDev')
        obj.className = 'DoseObjectives.matRad_SquaredDeviation';
        obj.parameters = {parseGy(parts{2})};
        obj.penalty = str2double(parts{3});

    otherwise
        error('Unsupported or invalid metric format: %s', metricStr);
end
end

% --- Helper: parse dose string like '28.70Gy' ---
function dose = parseGy(str)
    if endsWith(str, 'Gy', 'IgnoreCase', true)
        str = extractBefore(str, 'Gy');
    end
    dose = str2double(str);
end