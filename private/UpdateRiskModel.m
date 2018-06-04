function handles = UpdateRiskModel(handles, varargin)
% UpdateRiskModel is called by several subfunctions of
% SecondaryRiskCalculator and will update the the risk calculation and
% associated GUI components. It should not be called outside of the GUI.
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

% Retrieve age parameters
if get(handles.age_check, 'Value') == 1
    age_params = [str2double(get(handles.agee_input, 'String')) ...
        str2double(get(handles.agea_input, 'String'))];
else
    age_params = [];
end

% Retrieve leakage parameters
if get(handles.leakage_check, 'Value') == 1 && ...
        ~isempty(get(handles.mu_input, 'String'))
    leakage_params = [str2double(get(handles.leakage_input, 'String')) ...
        str2double(get(handles.mu_input, 'String'))];
else
    leakage_params = [];
end

% Create parameters table
if nargin == 2 && ~isempty(varargin{1})
    Event(['Updating parameter set with values from "', varargin{1}, '"']);
    params = varargin{1};
else
    params = cell2table(get(handles.model_table, 'Data'), 'VariableNames', ...
        get(handles.model_table, 'ColumnName'));
end

% If the user has provided DICOM data
if ~isempty(handles.image) && isfield(handles.image, 'structures') && ...
        ~isempty(handles.dose)
    
    % Scale dose according to MU
    dose = handles.dose;
    mu = str2double(get(handles.mu_input, 'String'));
    if isfield(handles.plan, 'mu') && ~isnan(mu) && mu ~= handles.plan.mu
        Event(sprintf('Scaling plan dose by MU difference: %i/%i', mu, ...
            handles.plan.mu));
        dose.data = dose.data * mu / handles.plan.mu;
    end
    
    % Update risk model
    risk = ApplyRiskModel(get(handles.model_menu, 'Value'), ...
        params, handles.image.structures, dose, ...
        str2double(get(handles.dvh_fx, 'String')), age_params, ...
        leakage_params);

    % Update plot
    handles.dvh_axes = PlotDVH(handles.dvh_axes, get(handles.dvh_menu, ...
        'Value'), handles.image.structures, dose, risk.Plot);
    
    % Clear temporary variables
    clear mu dose;
else
    
    % Update risk model
    risk = ApplyRiskModel(get(handles.model_menu, 'Value'), ...
        params, [], [], str2double(get(handles.dvh_fx, 'String')), ...
        age_params, leakage_params);

    % Update plot
    handles.dvh_axes = PlotDVH(handles.dvh_axes, get(handles.dvh_menu, ...
        'Value'), [], [], risk.Plot);
end

% Update risk column
risk.Plot = [];
set(handles.model_table, 'ColumnName', risk.Properties.VariableNames);
set(handles.model_table, 'ColumnEditable', ...
    [false true(1, size(risk,2)-2) false]);
set(handles.model_table, 'Data', table2cell(risk));

