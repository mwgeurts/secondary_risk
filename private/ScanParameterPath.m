function params = ScanParameterPath(path)
% ScanParameterPath scans the provided path input for available parameters
% files. See documentation for available formats. Note, this function does
% not verify that a given parameter file contains all of the relevant
% parameters; rather, it only verifies that the file can be read by
% readtable().
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

% If the path is a command to prompt the user
if strcmp(path, 'uigetdir')
    path = uigetdir(pwd, 'Select folder containing parameters files:');
end

% List directory contents
files = dir(path);
params = cell(0,2);

% Loop through files, testing whether they can be read in
for i = 1:length(files)
    if ~strcmp(files(i).name, '.') && ~strcmp(files(i).name, '..')
        try
            readtable(fullfile(path, files(i).name));
            [~, name, ~] = fileparts(files(i).name);
            params{size(params,1)+1,1} = strrep(name, '_', ' ');
            params{size(params,1),2} = fullfile(path, files(i).name);
            Event(['Parameter file "', files(i).name, '" loaded']);
        catch
            Event(['Parameter file "', files(i).name, ...
                '" skipped as it coult not be read']);
        end
    end
end
