function varargout = SecondaryRiskCalculator(varargin)
% SecondaryRiskCalculator opens a user interface to assess the risk of
% secondary malignancy following radiation therapy from a DICOM RT set.
% Different models can be applied by selecting them from the model dropdown
% menu and entering the parameters.
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

% Edit the above text to modify the response to help SecondaryRiskCalculator

% Last Modified by GUIDE v2.5 04-Jun-2018 16:02:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SecondaryRiskCalculator_OpeningFcn, ...
                   'gui_OutputFcn',  @SecondaryRiskCalculator_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SecondaryRiskCalculator_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SecondaryRiskCalculator (see VARARGIN)

% Choose default command line output for WaterTankAnalysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Turn off MATLAB warnings
warning('off','all');

% Choose default command line output for WaterTankAnalysis
handles.output = hObject;

% Set version handle
handles.version = '0.1.0';
set(handles.version_text, 'String', ['Version ', handles.version]);

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'Secondary Malignancy Risk Calculator'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

% Log action
Event('Loading submodules');

% Execute AddSubModulePaths to load all submodules
AddSubModulePaths();

% Log action
Event('Loading configuration options');

% Execute ParseConfigOptions to load the global variables
handles.config = ParseConfigOptions('config.txt');

% Execute ClearAllData to initialize data handles
handles = ClearAllData(handles);

% Report initilization status
Event(['Initialization completed successfully. Start by clicking Browse ', ...
    'to open a DICOM RT Dataset (CT/MR, Struct, Dose, and Plan required).']);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = SecondaryRiskCalculator_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clear_button_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to clear_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearAllData
handles = ClearAllData(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_t_Callback(hObject, ~, handles)
% hObject    handle to tcs_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If orientation was selected
if get(hObject, 'Value') == 1
    
    % Clear other two
    set(handles.tcs_c, 'Value', 0);
    set(handles.tcs_s, 'Value', 0);
    
    % Update viewer with transparency value
    handles.tcs.Initialize('tcsview', 'T');
else
    set(hObject, 'Value', 1);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_c_Callback(hObject, ~, handles)
% hObject    handle to tcs_c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If orientation was selected
if get(hObject, 'Value') == 1
    
    % Clear other two
    set(handles.tcs_t, 'Value', 0);
    set(handles.tcs_s, 'Value', 0);
    
    % Update viewer with transparency value
    handles.tcs.Initialize('tcsview', 'C');
else
    set(hObject, 'Value', 1);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_s_Callback(hObject, ~, handles)
% hObject    handle to tcs_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If orientation was selected
if get(hObject, 'Value') == 1
    
    % Clear other two
    set(handles.tcs_c, 'Value', 0);
    set(handles.tcs_t, 'Value', 0);
    
    % Update viewer with transparency value
    handles.tcs.Initialize('tcsview', 'S');
else
    set(hObject, 'Value', 1);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_Callback(hObject, ~, handles)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse and bound the value
value = max(0, min(100, ...
    str2double(strrep(get(hObject, 'String'), '%', ''))));

% Reformat
set(hObject, 'String', sprintf('%0.1f%%', value));

% Update viewer with transparency value
handles.tcs.Update('alpha', value/100);

% Clear temporary variable
clear value;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_CreateFcn(hObject, ~, ~)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_slider_Callback(hObject, ~, handles)
% hObject    handle to tcs_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update viewer with current slice
handles.tcs.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to tcs_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function path_text_Callback(~, ~, ~)
% hObject    handle to path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function path_text_CreateFcn(hObject, ~, ~)
% hObject    handle to path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function path_browse_Callback(hObject, ~, handles)
% hObject    handle to path_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowsePatient
handles = BrowsePatient(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model_menu_Callback(hObject, ~, handles)
% hObject    handle to model_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log change
models = cellstr(get(hObject,'String'));
Event(['Model changed to ', models{get(hObject,'Value')}]);

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to model_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Ppopupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function param_menu_Callback(hObject, ~, handles)
% hObject    handle to param_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log change
params = cellstr(get(hObject,'String'));
Event(['Parameter set changed to ', params{get(hObject,'Value')}]);

% Recalculate the risk model
handles = UpdateRiskModel(handles, ...
    handles.parameters{get(hObject,'Value'),2});

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function param_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to param_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dvh_menu_Callback(hObject, ~, handles)
% hObject    handle to dvh_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log choice
contents = cellstr(get(hObject,'String'));
Event(['DVH/risk plot changed to site ', contents{get(hObject,'Value')}]);

% Update plot
handles.dvh_axes = PlotDVH(handles.dvh_axes, get(hObject,'Value'));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dvh_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to dvh_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function age_check_Callback(hObject, ~, handles)
% hObject    handle to age_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If checkbox was enabled
if get(hObject, 'Value')
    
    % Make sure parameter set contains the necessary model parameters
    if ~contains('GammaE', get(handles.model_table, 'ColumnName')) || ...
            ~contains('GammaA', get(handles.model_table, 'ColumnName'))
        
        % If not, uncheck box and do nothing
        Event(['Age model could not be applied as one or more Gamma ', ...
            'parameters are missing from the selected set. Choose a ', ...
            'different parameter set'], 'WARN');
        set(hObject, 'Value', 0);
        return;
    end
    
    % Log action
    Event(['Exposed age model enabled with parameters [', ...
        get(handles.agee_input, 'String'), ', ', ...
        get(handles.agea_input, 'String'), '] years']);
    
    % Enable inputs
    set(handles.agee_text, 'Enable', 'On');
    set(handles.agee_input, 'Enable', 'On');
    set(handles.agea_text, 'Enable', 'On');
    set(handles.agea_input, 'Enable', 'On');

% OTherwise, checkbox was disabled
else
    
    % Log action
    Event('Exposed age model disabled');
    
    % Disable inputs
    set(handles.agee_text, 'Enable', 'Off');
    set(handles.agee_input, 'Enable', 'Off');
    set(handles.agea_text, 'Enable', 'Off');
    set(handles.agea_input, 'Enable', 'Off');
end

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function leakage_check_Callback(hObject, ~, handles)
% hObject    handle to leakage_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If checkbox was enabled
if get(hObject, 'Value')
    
    % Log action
    Event(['Leakage model enabled with parameters [', ...
        get(handles.leakage_input, 'String'), ']']);
    
    % Enable inputs
    set(handles.leakage_text, 'Enable', 'On');
    set(handles.leakage_input, 'Enable', 'On');
    set(handles.mu_text, 'Enable', 'On');
    set(handles.mu_input, 'Enable', 'On');

% OTherwise, checkbox was disabled
else
    
    % Log action
    Event('Leakage model disabled');
    
    % Disable inputs
    set(handles.leakage_text, 'Enable', 'Off');
    set(handles.leakage_input, 'Enable', 'Off');
    set(handles.mu_text, 'Enable', 'Off');
    set(handles.mu_input, 'Enable', 'Off');
end

% Recalculate the risk model only if plan data is loaded
if ~isempty(handles.plan)
    handles = UpdateRiskModel(handles);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dvh_fx_Callback(hObject, ~, handles)
% hObject    handle to dvh_fx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse as number and log change
set(hObject, 'String', floor(str2double(get(hObject, 'String'))));
Event(['Number of fractions changed to ', get(hObject, 'String')]);

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dvh_fx_CreateFcn(hObject, ~, ~)
% hObject    handle to dvh_fx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function agea_input_Callback(hObject, ~, handles)
% hObject    handle to agea_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse as number and log change
set(hObject, 'String', str2double(get(hObject, 'String')));
Event(['Attained age changed to ', get(hObject, 'String'), ' years']);

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function agea_input_CreateFcn(hObject, ~, ~)
% hObject    handle to agea_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function leakage_input_Callback(hObject, ~, handles)
% hObject    handle to leakage_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse as number and log change
set(hObject, 'String', sprintf('%0.2f%%', str2double(strrep(get(hObject, ...
    'String'), '%', ''))));
Event(['Head leakage changed to ', get(hObject, 'String')]);

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function leakage_input_CreateFcn(hObject, ~, ~)
% hObject    handle to leakage_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function agee_input_Callback(hObject, ~, handles)
% hObject    handle to agee_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse as number and log change
set(hObject, 'String', str2double(get(hObject, 'String')));
Event(['Exposed age changed to ', get(hObject, 'String'), ' years']);

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function agee_input_CreateFcn(hObject, ~, ~)
% hObject    handle to agee_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sim_button_Callback(hObject, ~, handles)
% hObject    handle to sim_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mu_input_Callback(hObject, ~, handles)
% hObject    handle to mu_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse as number and log change
set(hObject, 'String', str2double(get(hObject, 'String')));
Event(['Monitor Units changed to ', get(hObject, 'String')]);

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mu_input_CreateFcn(hObject, ~, ~)
% hObject    handle to mu_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to model_table (see GCBO)
% eventdata  structure with the following fields 
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

% Log change
data = get(hObject, 'Data');
columns = get(hObject, 'ColumnName');
if eventdata.Indices(2) == 2
    Event([data{eventdata.Indices(1),1}, ' structure set to ', ...
        regexprep(eventdata.EditData, '<[^>]*>', '')]);
    data{eventdata.Indices(1),2} = ...
        regexprep(eventdata.EditData, '<[^>]*>', '');
    set(hObject, 'Data', data);
elseif eventdata.Indices(2) == 3
    if eventdata.EditData
        Event([data{eventdata.Indices(1),1}, ' included in risk model']);
    else
        Event([data{eventdata.Indices(1),1}, ' excluded from risk model']);
    end
else
    Event([data{eventdata.Indices(1),1}, ' model parameter ', ...
        columns{eventdata.Indices(2),1},' set to ', eventdata.EditData]);
end

% Recalculate the risk model
handles = UpdateRiskModel(handles);

% Update handles structure
guidata(hObject, handles);

% Clear temporary variables
clear data columns;
