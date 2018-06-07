function ci = SimulateUncertainty(varargin)
% SimulateUncertainty estimates the risk uncertainty given provided
% parameter uncertainties, using a Monte Carlo approach to simulate variant
% input parameters.
%
% The following name/value pairs can be provided as input arguments. The 
% 'model' and 'params' fields are required:
%   model: the index of the risk model to compute.
%   params: a table of sites, corresponding DICOM structures, 
%       logicals indicating whether to compute each structure, and model
%       parameters.
%   uparams: optional table of uncertainty parameters for each model
%       parameter. If not provided, a GUI will appear prompting the user to
%       enter them.
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
%   config: a structure of configuration options. If not provided, the user
%       will be prompted to enter them via a GUI.
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

% Load structure from varargin
inputs = struct;
for i = 1:2:nargin
    inputs.(varargin{i}) = varargin{i+1};
end

% Validate required inputs were provided
if ~isfield(inputs, 'model') || ~isfield(inputs, 'params')
    Event('The model and params input arguments are required', 'ERROR');
end

% (Re)set random numbers to produce deterministic response
rng(0,'twister');

% If uparams or config parameters are not provided, display a GUI
if ~isfield(inputs, 'uparams') || isempty(inputs.uparams) || ...
        ~isfield(inputs, 'config') || isempty(inputs.config)

    % Log action
    Event('Opening figure to display uncertainty model inputs');

    % Pull parameters variables, removing DICOM/include flags
    names = inputs.params.Properties.VariableNames;
    names(strcmp(names,'DICOM')) = [];
    names(strcmp(names,'Include')) = [];
    names(strcmp(names,'Risk')) = [];
    
    % Load input UI for Normal model
    if ~isfield(inputs, 'config') || ~isfield(inputs.config, ...
            'UNCERTAINTY_TYPE') || strcmpi(inputs.config.UNCERTAINTY_TYPE, ...
            'Normal')
        
        % Launch NormalUncertainty figure
        [uparams, ci, n] = NormalUncertainty('names', names, 'sites', ...
            inputs.params.Site, 'ci', ...
            inputs.config.CONF_INTERVAL, 'n', ...
            inputs.config.NUM_SIMULATIONS);
        
        % Store results
        umodel = 'Normal';
    
    % Otherwise, an unsupported uncertainty model was provided
    else
        Event(['An unsupported uncertainty model was provided: ', ...
            inputs.config.UNCERTAINTY_TYPE], 'ERROR');
    end
    
% Otherwise, use provided values    
else
    uparams = inptus.uparams;
    beta = inputs.config.CONF_INTERVAL;
    n = inputs.config.NUM_SIMULATIONS;
    umodel = inputs.config.UNCERTAINTY_TYPE;
end

% Loop through simulations
for i = 1:n

    % Start with provided parameters
    params = inputs.params;
    
    % Apply randomization
    switch umodel
        
        % Normal randomization
        case 'Normal'
            
           
    end
    

end

