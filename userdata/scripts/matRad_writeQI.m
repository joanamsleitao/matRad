function T = matRad_writeQI(qi, filePath, T, label)
% matRad_writeQiToTxt - Export or append dose statistics (qi) to .txt or table
%
% Syntax:
%   matRad_writeQiToTxt(qi, filePath)
%   T = matRad_writeQiToTxt(qi, [], T, label)
%
% Inputs:
%   qi        - Struct array (with consistent field names)
%   filePath  - Path to .txt file (optional; only used if you want to save)
%   T         - Existing table to append to (optional)
%   label     - Optional string label (appears as separator row)
%
% Output:
%   T         - Combined table with appended qi section (if requested)
%
% Behavior:
%   - If only qi and filePath are given → creates and saves .txt.
%   - If T is provided → appends new qi to existing T.
%   - If label is provided → inserts a separator row with the label text.
%
% Example 1: Save new qi
%   matRad_writeQiToTxt(qi, 'summary.txt');
%
% Example 2: Append qi from another patient before saving
%   T = matRad_writeQiToTxt(qi1);
%   T = matRad_writeQiToTxt(qi2, [], T, '--- Patient 2 ---');
%   writetable(T, 'combined_summary.txt', 'Delimiter', '\t');
%
% See also: struct2table, writetable

    % === Input handling ===
    if nargin < 2
        filePath = '';
    end
    if nargin < 3
        T = [];
    end
    if nargin < 4
        label = '';
    end

    % --- Convert qi to table
    try
        Tnew = struct2table(qi);
    catch ME
        error('Failed to convert qi struct to table: %s', ME.message);
    end

    % --- Clean NaN for aesthetics
    for fn = Tnew.Properties.VariableNames
        if isnumeric(Tnew.(fn{1}))
            Tnew.(fn{1})(isnan(Tnew.(fn{1}))) = 0;
        end
    end

    % === Append mode ===
    if ~isempty(T)
        % Ensure same columns
        missingInT = setdiff(T.Properties.VariableNames, Tnew.Properties.VariableNames);
        missingInNew = setdiff(Tnew.Properties.VariableNames, T.Properties.VariableNames);

        % Add missing columns as NaN/empty
        for m = missingInT
            Tnew.(m{1}) = NaN(height(Tnew), 1);
        end
        for m = missingInNew
            T.(m{1}) = NaN(height(T), 1);
        end

        % Reorder to match
        Tnew = Tnew(:, T.Properties.VariableNames);

        % Optional separator
        if ~isempty(label)
            sepRow = T(1,:);
            sepRow.(sepRow.Properties.VariableNames{1}) = {label};
            for fn = 2: size(sepRow.Properties.VariableNames, 2)
                sepRow.(sepRow.Properties.VariableNames{fn}) = 0; % empty strings
            end
            T = [T; sepRow];
        end

        % Append
        T = [T; Tnew];
    else
        T = Tnew;
    end

    % === Save if filePath provided ===
    if ~isempty(filePath)
        writetable(T, filePath, 'Delimiter', '\t', 'FileType', 'text');
        fprintf('✅ qi data written to "%s"\n', filePath);
    end
end
