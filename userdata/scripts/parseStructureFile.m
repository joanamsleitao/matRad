function outStruct = parseStructureFile(filename)
% parseStructureFile - Reads a structure alias file and stores aliases and RGB color codes.
% Lines should be formatted as:
%   StructName, [R G B], alias1, alias2, ...
%
% OUTPUT:
%   outStruct.(StructName).Aliases = {...}
%   outStruct.(StructName).Color   = [R G B]

    outStruct = struct();
    
    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open file: %s', filename);
    end
    
    line = fgetl(fid);
    while ischar(line)
        if ~isempty(strtrim(line))
            tokens = strsplit(strtrim(line), ', ');

            structName = matlab.lang.makeValidName(tokens{1});
            colorToken = tokens{2};

            % Parse color if formatted correctly
            colorMatch = regexp(colorToken, '\[(.*?)\]', 'tokens');
            if isempty(colorMatch)
                error('Could not parse RGB color from line: %s', line);
            end
            rgb = str2num(colorMatch{1}{1}); %#ok<ST2NM> % e.g., '0 1 0' → [0 1 0]
            if numel(rgb) ~= 3
                error('Invalid RGB vector in line: %s', line);
            end

            % Remaining tokens are aliases
            aliases = tokens(3:end);

            outStruct.(structName).Aliases = aliases;
            outStruct.(structName).Color   = rgb;
        end
        line = fgetl(fid);
    end
    
    fclose(fid);
end
