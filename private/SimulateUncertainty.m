function [alpha, m, ci] = SimulateUncertainty(varargin)
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

%% Initialize data
% Load structure from varargin, initializing optional values
inputs = struct('structures', [], 'dose', [], 'fx', [], 'age', [], ...
    'leakage', []);
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
        [uparams, alpha, n] = NormalUncertainty('names', names, 'sites', ...
            inputs.params.Site, 'alpha', ...
            inputs.config.ALPHA, 'n', ...
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
    uparams = inputs.uparams;
    alpha = 1 - inputs.config.ALPHA;
    n = inputs.config.NUM_SIMULATIONS;
    umodel = inputs.config.UNCERTAINTY_TYPE;
end

% Initialize temporary params table
params = inputs.params;

% Initialize risk array
risk = zeros(size(uparams, 1), n);

% Start waitbar
if usejava('jvm') && feature('ShowFigureWindows')
    progress = waitbar(0, 'Running uncertainty simulations');
    c = 10;
    t = tic;
    bar = true;
end

%% Run simulations
% Loop through simulations
Event(sprintf('Starting %0.0e uncertainty simulations using %s model', n, ...
    umodel));
for i = 1:n
    
    % Update waitbar
    if bar && i > c
        c = i + n * 0.02;
        r = (n-i) * toc(t) / i;
        waitbar(i/n, progress, sprintf(['Running uncertainty simulations ', ...
            '(%02.0f:%02.0f remaining)'], floor(mod(r, 3600) / 60), ...
            mod(r, 60)));
    end
    
    % Apply randomization
    switch umodel
        
        % Normal randomization
        case 'Normal'

            % Use randn to apply random normal variation
            params{:,4:end-1} = max(0, inputs.params{:,4:end-1} + ...
                uparams{:,2:end} .* randn(size(uparams,1), ...
                size(uparams,2)-1));
            
            % Execute ApplyRiskModel
            result = ApplyRiskModel('model', inputs.model, 'params', ...
                params, 'structures', inputs.structures, 'dose', ...
                inputs.dose, 'fx', inputs.fx, 'age', inputs.age, 'leakage', ...
                inputs.leakage);
            
            % Append to risk array
            risk(:,i) = cell2mat(result.Risk);
    end
end

%% Finish up
% Close waitbar
close(progress);
Event('Simulations completed');

% Compute risk confidence interval by trimming alpha
Event('Computing confidence intervals');
m = median(risk, 2);
sorted = sort(risk, 2);
ci = horzcat(sorted(:, ceil(size(risk,2) * alpha/2)), ...
    sorted(:, floor(end - size(risk,2) * alpha/2)));

% Log completion
Event(sprintf(['Uncertainty simulation completed successfully in ', ...
    '%0.1f seconds'], toc(t)));

% Clear temporary variables
clear bar c i inputs n names params progress r resultrisk sorted umodel ...
    uparams;
