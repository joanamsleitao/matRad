function outStruct = parseStructureFile(filename)
% parseStructureFile - Reads a text file line by line. Each line contains a structure name
% followed by values. The structure name is used as the field name AND kept as the first element
% of the associated cell array.
%
% Example input line:
% External Patient Body External
%
% Output:
% outStruct.External = {'External', 'Patient', 'Body', 'External'};

    % Initialize output structure
    outStruct = struct();
    
    % Open file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open file: %s', filename);
    end
    
    % Read each line
    line = fgetl(fid);
    while ischar(line)
        % Skip empty lines
        if ~isempty(strtrim(line))
            % Split line into words
            words = strsplit(strtrim(line), ', ');
            
            % Use first word as struct field name
            structName = matlab.lang.makeValidName(words{1});
            
            % Store entire line as cell array
            outStruct.(structName) = words;
        end
        
        % Next line
        line = fgetl(fid);
    end
    
    fclose(fid);
end
