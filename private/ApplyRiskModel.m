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
%   varargin{3}: a string indicating gender ('M' or 'F'). Only applied if a
%       GenderRatio field exists in the parameters.
%   varargin{4}: a cell array of structures. See LoadDICOMStructures for
%       information on the format expected.
%   varargin{5}: a dose structure. See LoadDICOMDose for information on the
%       format expected.
%   varargin{6}: an optional number of fractions used to consider 
%   varargin{7}: a vector of patient age at exposure and risk evaluation, 
%       or empty if age is ignored
%   varargin{8}: a vector of leakage parameters (leakage fraction, MU), or 
%       empty of structures outside of the CT are to be ignored
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

% Define the number of bins
bins = 200;

% Execute code block based on format provided in varargin{1}
switch varargin{1}

    % UNSCEAR fractionated
    case 1
        
        % If a table array was not provided, create one
        if ~istable(varargin{2})
            
            % Load default model parameters
            params = readtable(varargin{2});
            risk = table(params{:,1}, cell(size(params,1),1), ...
                true(size(params,1), 1), params.Alpha1, params.Beta1, ...
                params.Alpha2, params.Beta2, ...
                'VariableNames', {'Site', 'DICOM', 'Include', ...
                'Alpha1', 'Beta1', 'Alpha2', 'Beta2'});
            
            % If a gender flag was provided
            if nargin > 2 && ~isempty(varargin{3}) && ...
                    ismember('GenderRatio', params.Properties.VariableNames)
                
                % Update Alpha1 (GenderRatio is Female/Male)
                for i = 1:size(params, 1)
                    
                    % A GenderRatio of Inf means there is no male risk
                    if params.GenderRatio(i) == Inf && ...
                            startsWith(varargin{3}, 'M')
                        risk.Include(i) = false;
                        risk.Alpha1(i) = 0;

                    % A GenderRatio of 0 means there is no female risk
                    elseif params.GenderRatio(i) == 0  && ...
                            startsWith(varargin{3}, 'F')
                        risk.Include(i) = false;
                        risk.Alpha1(i) = 0;

                    % Otherwise, scale the Male risk for Females
                    elseif startsWith(varargin{3}, 'F') && ...
                            params.GenderRatio(i) ~= Inf
                        risk.Alpha1(i) = risk.Alpha1(i) * ...
                            params.GenderRatio(i);
                    end
                end
            end
            
            % Append age parameters, if available
            if ismember('GammaE', params.Properties.VariableNames) && ...
                    ismember('GammaA', params.Properties.VariableNames)
                risk.GammaE = params.GammaE;
                risk.GammaA = params.GammaA;
            end
        
            % Append empty risk column
            risk.Risk = cell(size(params,1),1);
        
        % Otherwise, use provided one
        else
            risk = varargin{2};
        end
        
        % Append empty risk plot column
        risk.Plot = cell(size(risk,1),1);
        
        % If fractions were provided
        if nargin > 5 && ~isempty(varargin{6})
            n = varargin{6};
        else
            n = 1;
        end
        
        % Calculate risk for each matched site with include flag
        for i = 1:size(risk,1)
            
            % Compute risk plot using provided parameters
            if isempty(varargin{5})
                d = (0:bins)/bins * 30;
            else
                d = (0:bins)/bins * ceil(max(max(max(varargin{5}.data))));
            end
            risk.Plot{i} = [d; (risk.Alpha1(i) * d + ...
                risk.Beta1(i) * d.^2 / n) .* ...
                exp(-risk.Alpha2(i) * d - risk.Beta2(i) * d.^2 / n)];
            
            % If include is unchecked, do not compute and skip ahead
            if ~risk.Include(i)
                risk.Risk{i} = '';
            
            % If site matches to a DICOM structure, compute DVH risk
            elseif any(isletter(risk.DICOM{i})) && nargin > 3 && ...
                    ~isempty(varargin{4}) && ~isempty(varargin{5})
                
                % Loop through structures and find match
                for j = 1:length(varargin{4})
                    if strcmp(varargin{4}{j}.name, risk.DICOM{i})
                        
                        % Compute differential risk
                        risk.Risk{i} = sum(interp1(risk.Plot{i}(1,:), ...
                            risk.Plot{i}(2,:), varargin{5}.data(...
                            varargin{4}{j}.mask), 'linear')) / ...
                            sum(sum(sum(varargin{4}{j}.mask))) * 1e4;
                    end
                end
                
            % Otherwise, if parameters are provided, compute leakage risk
            elseif nargin > 7 && ~isempty(varargin{8})
                
                % Assume site is uniformly irradiated by leakage
                risk.Risk{i} = interp1(risk.Plot{i}(1,:), ...
                    risk.Plot{i}(2,:), varargin{8}(1) * varargin{8}(2), ...
                    'linear', 0) * 1e4;
            
            % Otherwise, do not compute risk
            else
                risk.Risk{i} = '';
            end
        end
end

% If age paraemeters were provided
if nargin > 6 && ~isempty(varargin{7})
    
    % Apply age risk for each site
    for i = 1:size(risk,1)
        
        % Compute risk
        mu = exp(risk.GammaE(i) * (varargin{7}(1) - 30) / 10 + ...
            risk.GammaA(i) * log(varargin{7}(2)/70));
        
        % Scale risk plot
        risk.Plot{i}(2,:) = risk.Plot{i}(2,:) * mu;
        
        % If structure risk was computed
        if ~isempty(risk.Risk{i})
            risk.Risk{i} = risk.Risk{i} * mu;
        end
    end
end