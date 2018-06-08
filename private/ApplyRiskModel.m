function risk = ApplyRiskModel(varargin)
% ApplyRiskModel is called whenever the model dropdown menu is changed, or 
% if new data is loaded in SecondaryRiskCalculator. When called with no
% arguments, it returns a list of available models.
%
% Alternatively, this function can be called with one or more name/value
% pairs. The 'model' and 'params' fields are required.
%   model: the index of the model to compute
%   params: a table of sites, corresponding DICOM structures, 
%       logicals indicating whether to compute each structure, and model
%       parameters. Alternatively, this can be a string containing 
%       the file name of a parameter file to load.
%   gender: optional string indicating gender ('M' or 'F'). Only 
%       applied if a GenderRatio field exists in the parameters.
%   structures: optional cell array of structures. See LoadDICOMStructures 
%       for information on the format expected.
%   dose: optional dose structure. See LoadDICOMDose for information 
%       on the format expected. Both structures and dose are required to
%       compute DVH based risk.
%   fx: optional number of fractions used to consider. If not
%       provided, will assume 1 fraction.
%   age: optional vector of patient age at exposure and risk 
%       evaluation, ignored if not provided or parameters are empty.
%   leakage: optional vector of leakage parameters (leakage fraction, 
%       MU), ignored if not provided or parameters are empty.
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

% Load structure from varargin
inputs = struct;
for i = 1:2:nargin
    inputs.(varargin{i}) = varargin{i+1};
end

% Validate required inputs were provided
if ~isfield(inputs, 'model') || ~isfield(inputs, 'params')
    Event('The model and params input arguments are required', 'ERROR');
end

% Execute code block based on format provided in varargin{1}
switch inputs.model

    % UNSCEAR fractionated
    case 1
        
        % If a table array was not provided, create one
        if ~istable(inputs.params)
            
            % Load default model parameters
            params = readtable(inputs.params);
            risk = table(params{:,1}, cell(size(params,1),1), ...
                true(size(params,1), 1), params.Alpha1, params.Beta1, ...
                params.Alpha2, params.Beta2, ...
                'VariableNames', {'Site', 'DICOM', 'Include', ...
                'Alpha1', 'Beta1', 'Alpha2', 'Beta2'});
            
            % If a gender flag was provided
            if isfield(inputs, 'gender') && ~isempty(inputs.gender) && ...
                    ismember('GenderRatio', params.Properties.VariableNames)
                
                % Update Alpha1 (GenderRatio is Female/Male)
                for i = 1:size(params, 1)
                    
                    % A GenderRatio of Inf means there is no male risk
                    if params.GenderRatio(i) == Inf && ...
                            startsWith(inputs.gender, 'M')
                        risk.Include(i) = false;
                        risk.Alpha1(i) = 0;

                    % A GenderRatio of 0 means there is no female risk
                    elseif params.GenderRatio(i) == 0  && ...
                            startsWith(inputs.gender, 'F')
                        risk.Include(i) = false;
                        risk.Alpha1(i) = 0;

                    % Otherwise, scale the Male risk for Females
                    elseif startsWith(inputs.gender, 'F') && ...
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
        
        % Otherwise, use provided one, with cleared Risk
        else
            risk = inputs.params;
            risk.Risk = cell(size(risk,1),1);
        end
        
        % Append empty risk plot column
        risk.Plot = cell(size(risk,1),1);
        
        % If fractions were provided
        if isfield(inputs, 'fx') && ~isempty(inputs.fx)
            n = inputs.fx;
        else
            n = 1;
        end
        
        % Compute dose bins
        if isfield(inputs, 'dose') && ~isempty(inputs.dose)
            if isfield(inputs.dose, 'max')
                d = (0:bins)/bins * ceil(inputs.dose.max);
            else
                d = (0:bins)/bins * ceil(max(max(max(inputs.dose.data))));
            end
        else
            d = (0:bins)/bins * 30;
        end
        
        % Calculate risk for each matched site with include flag
        for i = 1:size(risk,1)
            
            % Compute risk plot using provided parameters
            risk.Plot{i} = [d; (risk.Alpha1(i) * d + ...
                risk.Beta1(i) * d.^2 / n) .* ...
                exp(-risk.Alpha2(i) * d - risk.Beta2(i) * d.^2 / n)];
            
            % If include is unchecked, do not compute and skip ahead
            if ~risk.Include(i)
                risk.Risk{i} = '';
            
            % If site matches to a DICOM structure, compute DVH risk
            elseif any(isletter(risk.DICOM{i})) && nargin > 3 && ...
                    ~isempty(inputs.structures) && ~isempty(inputs.dose)
                
                % Loop through structures and find match
                for j = 1:length(inputs.structures)
                    if strcmp(inputs.structures{j}.name, risk.DICOM{i})
                        
                        % Compute differential risk
                        risk.Risk{i} = sum(interp1(risk.Plot{i}(1,:), ...
                            risk.Plot{i}(2,:), inputs.dose.data(...
                            inputs.structures{j}.mask), 'linear')) * ...
                            prod(inputs.structures{j}.width) / ...
                            (inputs.structures{j}.volume) * 1e4;
                    end
                end
                
            % Otherwise, if parameters are provided, compute leakage risk
            elseif isfield(inputs, 'leakage') && ~isempty(inputs.leakage)
                
                % Assume site is uniformly irradiated by leakage
                risk.Risk{i} = interp1(risk.Plot{i}(1,:), ...
                    risk.Plot{i}(2,:), inputs.leakage(1) * ...
                    inputs.leakage(2) * n * 0.01, 'linear', 0) * 1e4;
            
            % Otherwise, do not compute risk
            else
                risk.Risk{i} = '';
            end
        end
end

% If age parameters were provided
if isfield(inputs, 'age') && ~isempty(inputs.age)
    
    % Apply age risk for each site
    for i = 1:size(risk,1)
        
        % Compute risk
        mu = exp(risk.GammaE(i) * (inputs.age(1) - 30) / 10 + ...
            risk.GammaA(i) * log(inputs.age(2)/70));
        
        % Scale risk plot
        risk.Plot{i}(2,:) = risk.Plot{i}(2,:) * mu;
        
        % If structure risk was computed
        if ~isempty(risk.Risk{i})
            risk.Risk{i} = risk.Risk{i} * mu;
        end
    end
end