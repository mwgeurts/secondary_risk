function config = ParseConfigOptions(filename)
% ParseConfigOptions is executed by SecondaryRiskCalculator to open the  
% config file and update the application settings. The configuration 
% filename is passed to this function, and a config structure containing 
% the loaded configuration options is returned.
% 
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2018 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Log event
Event(['Opening file handle to ', filename]);

% Open file handle to config.txt file
fid = fopen(filename, 'r');

% Verify that file handle is valid
if fid < 3
    
    % If not, throw an error
    Event(['The ', filename, ' file could not be opened. Verify that this ', ...
        'file exists in the working directory. See documentation for ', ...
        'more information.'], 'ERROR');
end

% Scan config file contents
c = textscan(fid, '%s', 'Delimiter', '=', 'CommentStyle', '%');

% Close file handle
fclose(fid);

% Loop through textscan array, separating key/value pairs into array
for i = 1:2:length(c{1})
    config.(strtrim(c{1}{i})) = strtrim(c{1}{i+1});
end

% Clear temporary variables
clear c i fid;

% Log completion
Event(['Read ', filename, ' to end of file']);

% Default folder path when selecting input files
if strcmpi(config.DEFAULT_PATH, 'userpath')
    config.DEFAULT_PATH = userpath;
end
Event(['Default file path set to ', config.DEFAULT_PATH]);

% Parse default alpha
config.DEFAULT_ALPHA = str2double(config.DEFAULT_ALPHA);
Event(sprintf('Default alpha set to %0.1f%%', config.DEFAULT_ALPHA * 100));

% Parse age options
config.INCLUDE_AGE = logical(str2double(config.INCLUDE_AGE));
config.DEFAULT_AGE_E = str2double(config.DEFAULT_AGE_E);
Event(sprintf('Default exposed age set to %i years', ...
    config.DEFAULT_AGE_E));
config.DEFAULT_AGE_A = str2double(config.DEFAULT_AGE_A);
Event(sprintf('Default attained age set to %i years', ...
    config.DEFAULT_AGE_A));

% Parse leakage options
config.INCLUDE_LEAKAGE = logical(str2double(config.INCLUDE_LEAKAGE));
config.DEFAULT_LEAKAGE = str2double(config.DEFAULT_LEAKAGE);
Event(sprintf('Default leakage set to %0.2f%%', ...
    config.DEFAULT_LEAKAGE * 100));

% Parse default fractions
config.DEFAULT_FRACTIONS = str2double(config.DEFAULT_FRACTIONS);
Event(sprintf('Default fractions set to %i', config.DEFAULT_FRACTIONS));

% Parse match threshold
config.MATCH_THRESHOLD = str2double(config.MATCH_THRESHOLD);
Event(sprintf('Levenshtein match threshold set to %0.1f', ...
    config.MATCH_THRESHOLD));

% Parse uncertainty numerical options
config.ALPHA = str2double(config.ALPHA);
config.NUM_SIMULATIONS = str2double(config.NUM_SIMULATIONS);