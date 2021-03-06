function [rawNumeric, splitData, numTrials, index ] = importfile(pathname, filename)
%IMPORTFILE Import numeric data and string data from a text file as a
%matrix

% Modified from version generated by MATLAB

% keyboard

%% Get number of columns

fileID = fopen(strcat(pathname, filename),'r');
delimiter = char(9); % tab delimiter
tLines = fgets(fileID); % Read line from file, keeping the newline character
numCols = numel(strfind(tLines,delimiter))+1; % Find one string within another
fclose(fileID);

%% Extract data as string

fileID = fopen(strcat(pathname, filename),'r');
fmt = repmat('%s', 1, numCols);
V = textscan(fileID, fmt, 'headerlines', 1, 'delimiter', '\t');
fclose(fileID);

%% Convert contents of columns containing numeric strings to numbers

% replace non-numeric strings with NaN
raw = [V{:,1:end}];
numericData = NaN(size(V{1},1),size(V,2)); %pre-allocate with NaN matrix

for col=[1,4,5,8:numCols]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = V{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once')); % Match regular expression, S = regexp(STRING,EXPRESSION)
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f'); % Replace string with another,  strrep(ORIGSTR,OLDSUBSTR,NEWSUBSTR)
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,4,5,8:numCols]);
rawCellColumns = raw(:, [2,3,6,7]);

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

rawNumeric = cell2mat(rawNumericColumns);

%% Separate data in trials and get # of trials

splitData = sepTrials( rawNumeric, rawCellColumns, filename); % Separate data file into separate trials
numTrials = length(splitData.trial);
index = zeros(numTrials, 1); % so we can retrieve subject # in raw data struct "keyData"
end