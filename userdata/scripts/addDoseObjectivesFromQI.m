function cstOut = addDoseObjectivesFromQI(cstIn, qiPat, basePenalty)
% ADDDOSEOBJECTIVESFROMQI - Adds D_2, D_98, mean and VxGy objectives to CST based on QI
%
% Syntax:  cstOut = addDoseObjectivesFromQI(cstIn, qiPat, basePenalty)
%
% Inputs:
%   cstIn       - Original CST table (cell array)
%   qiPat       - Quality indicators from clinical/reference plan (struct array)
%   basePenalty - Base penalty for all objectives (double)
%
% Outputs:
%   cstOut      - Modified CST with objectives added for each VOI (cell array)
%
% Other m-files required: parseStructureFile.m
% Subfunctions: none
% MAT-files required: none
%
% See also: addDVHReplicationObjectives

    VOINames = parseStructureFile('VOINames.txt');
    cstOut = cstIn;

    for i = 1:numel(qiPat)
        voiName = qiPat(i).name;

        % Skip External
        if contains(voiName, VOINames.External)
            continue;
        end

        % Find index in CST
        ixVOI = find(contains(cstOut(:,2), voiName), 1);
        if isempty(ixVOI)
            warning('VOI %s not found in CST, skipping...', voiName);
            continue;
        end

        % Determine if this is a PTV
        isPTV = contains(voiName, VOINames.PTV);

        objList = {};

        % % D_2
        % obj.className = 'DoseObjectives.matRad_SquaredOverdosing';
        % obj.parameters{1} = ceil(qiPat(i).D_2);
        % obj.penalty = basePenalty * 50;
        % objList{end+1} = obj;
        % 
        % % D_98
        % obj.className = 'DoseObjectives.matRad_SquaredUnderdosing';
        % obj.parameters{1} = floor(qiPat(i).D_98);
        % obj.penalty = basePenalty * 50;
        % objList{end+1} = obj;

        % mean
        obj.className = 'DoseObjectives.matRad_SquaredDeviation';
        obj.parameters{1} = qiPat(i).D_50;
        obj.penalty = basePenalty;
        objList{end+1} = obj;

        % Add VxGy only if PTV
        if isPTV
            vFields = fieldnames(qiPat(i));
            for v = 1:numel(vFields)
                field = vFields{v};
                if startsWith(field, 'V_') && endsWith(field, 'Gy')
                    numStr = extractBetween(field, 3, strlength(field)-2);
                    doseVal = str2double(strrep(numStr, '_', '.'));
                    if ~isnan(doseVal)
                        obj.className = 'DoseObjectives.matRad_MinDVH'; 
                        obj.parameters{1} = doseVal;
                        obj.parameters{2} = qiPat(i).(field);
                        obj.penalty = basePenalty;
                        objList{end+1} = obj;
                    end
                end
            end
        end

        % Assign to CST
        cstOut{ixVOI, 6} = objList;
    end
end
