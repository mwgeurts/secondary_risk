function risk = ApplyRiskModel(varargin)
% ApplyRiskModel is called whenever the model dropdown menu is changed, or 
% if new data is loaded in SecondaryRiskCalculator. When called with no
% arguments, it returns a list of available models.
%
% Alternatively, this function is called with six inputs:
%   varargin{1}: the index of the model to compute
%   varargin{2}: a table array of sites, corresponding DICOM structures, 
%       logicals indicating whether to compute each structure, and model
%       parameters. Alternatively, varargin{2} can be a string containing 
%       the file name of a parameter file to load.
%   varargin{3}: a cell array of structures. See LoadDICOMStructures for
%       information on the format expected.
%   varargin{4}: a dose structure. See LoadDICOMDose for information on the
%       format expected.
%   varargin{5}: a vector of patient age at exposure and risk evaluation, 
%       or empty if age is ignores
%   varargin{6}: a boolean indicating whether or not to consider structures
%       that exist outside of the patient CT.
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

% Specify options and order
options = {
    'UNSCEAR fractionated LQ competition model'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    risk = options;
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{1}
switch varargin{1}

    % UNSCEAR fractionated
    case 1
        
        % If a table array was not provided, create one
        if nargin < 2 || ~istable(varargin{2})
            
            % Load default model parameters
            params = readtable(varargin{2});
            risk = table(params{:,1}, cell(size(params,1),1), ...
                true(size(params,1), 1), params.Alpha1, params.Beta1, ...
                params.Alpha2, params.Alpha2, ...
                'VariableNames', {'Site', 'DICOM', 'Include', ...
                'Alpha1', 'Beta1', 'Alpha2', 'Beta2'});
            
            % If structures were provided, try to match them to each site
            if nargin > 2 && ~isempty(varargin{3})
               error('TODO'); 
            end
            
            % Append age parameters, if needed
            if nargin > 4 && ~isempty(varargin{5})
                risk.GammaE = params.GammaE;
                risk.GammaA = params.GammaA;
            end
        
            % Append empty risk column
            risk.Risk = cell(size(params,1),1);
        
        % Otherwise, use provided one
        else
            risk = varargin{2};
        end
        
        % Calculate risk for each matched site with include flag
        for i = 1:size(risk,1)
            
            % If include is unchecked, do not compute and skip ahead
            if ~risk{i,3}
                risk{i,end} = '';
                continue;
            end
            
            % If site matches to a DICOM structure, compute DVH risk
            if ~isempty(risk{i,2})
                
                
            % Otherwise, if the CT boolean is set, compute leakage risk
            elseif nargin > 5 && varargin{6}
                
            
            else
                risk{i,end} = '';
            end
        end
end
    