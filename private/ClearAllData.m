function handles = ClearAllData(handles)
% ClearAllData is called by SecondaryRiskCalculator during application 
% initialization and if the user presses "Clear All" to reset the UI and 
% initialize all runtime data storage variables. Note that all checkboxes 
% will get updated to their configuration default settings.
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

% Log action
if isfield(handles, 'plan')
    Event('Clearing data from memory and resetting parameters');
else
    Event('Initializing parameters');
end

% Clear DICOM data
handles.image = [];
handles.dose = [];
handles.plan = [];

% Clear path string
set(handles.path_text, 'String', '');

% Reset age inputs
set(handles.age_check, 'Value', handles.config.INCLUDE_AGE);
set(handles.agee_input, 'String', sprintf('%i', handles.config.DEFAULT_AGE_E));
set(handles.agea_input, 'String', sprintf('%i', handles.config.DEFAULT_AGE_A));
if ~handles.config.INCLUDE_AGE
    set(handles.agee_text, 'Enable', 'off');
    set(handles.agee_input, 'Enable', 'off');
    set(handles.agea_text, 'Enable', 'off');
    set(handles.agea_input, 'Enable', 'off');
end
if get(handles.age_check, 'Value') == 1
    age_params = [str2double(get(handles.agee_input, 'String')) ...
        str2double(get(handles.agea_input, 'String'))];
else
    age_params = [];
end

% Reset leakage inputs
set(handles.leakage_check, 'Value', handles.config.INCLUDE_LEAKAGE);
set(handles.leakage_input, 'String', sprintf('%0.2f%%', ...
    handles.config.DEFAULT_LEAKAGE * 100));
if ~handles.config.INCLUDE_LEAKAGE
    set(handles.leakage_text, 'Enable', 'off');
    set(handles.leakage_input, 'Enable', 'off');
    set(handles.mu_text, 'Enable', 'Off');
    set(handles.mu_input, 'Enable', 'Off');
end

% Reset and hide TCS options
set(handles.tcs_t, 'visible', 'off');
set(handles.tcs_t, 'Value', 1);
set(handles.tcs_c, 'visible', 'off');
set(handles.tcs_c, 'Value', 0);
set(handles.tcs_s, 'visible', 'off');
set(handles.tcs_s, 'Value', 0);
if isfield(handles, 'tcsplot')
    delete(handles.tcsplot);
else
    set(handles.tcs_slider, 'visible', 'off');
    set(allchild(handles.tcs_axes), 'visible', 'off'); 
    set(handles.tcs_axes, 'visible', 'off');
    colorbar(handles.tcs_axes,'off');
end

set(handles.alpha, 'String', ...
    sprintf('%0.1f%%', handles.config.DEFAULT_ALPHA * 100));
set(handles.alpha, 'visible', 'off');

% Hide risk plot
set(allchild(handles.risk_axes), 'visible', 'off'); 
set(handles.risk_axes, 'visible', 'off');

% Disable simulation
set(handles.sim_button, 'enable', 'off');

% Set parameters menu
handles.parameters = ScanParameterPath(handles.config.PARAM_PATH);
set(handles.param_menu, 'String', handles.parameters{:,1});
set(handles.param_menu, 'Value', ...
    find(strcmp(handles.config.DEFAULT_PARAM, ...
    get(handles.param_menu, 'String')), 1));

% Set model menu
set(handles.model_menu, 'String', ApplyRiskModel());
set(handles.model_menu, 'Value', ...
    find(strcmp(handles.config.DEFAULT_MODEL, ...
    get(handles.model_menu, 'String')), 1));

% Set fractions
set(handles.dvh_fx, 'String', sprintf('%i', ...
    handles.config.DEFAULT_FRACTIONS));

% Set gender menu
set(handles.gender_menu, 'String', {'Male', 'Female'});
set(handles.gender_menu, 'Value', 1);

% Initialize parameters table
risk = ApplyRiskModel(get(handles.model_menu, 'Value'), ...
    handles.parameters{get(handles.param_menu, 'Value'), 2}, 'M', [], [], ...
    str2double(get(handles.dvh_fx, 'String')), age_params, []);

% If Gamma params are missing, disable age model
if ~isfield(risk, 'GammaE') || ~isfield(risk, 'GammaA')
    set(handles.age_check, 'Value', 0);
end
    
% Update DVH dropdown and plot
set(handles.dvh_menu, 'String', risk.Site);
set(handles.dvh_menu, 'Value', 1);
handles.dvh_axes = PlotDVH(handles.dvh_axes, 1, [], [], risk.Plot);

% Set parameters table (minus the Plot data)
risk.Plot = [];
set(handles.model_table, 'ColumnName', risk.Properties.VariableNames);
set(handles.model_table, 'ColumnEditable', ...
    [false true(1, size(risk,2)-2) false]);
set(handles.model_table, 'Data', table2cell(risk));

% Clear temporary variables
clear risk;