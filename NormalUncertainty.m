function varargout = NormalUncertainty(varargin)
% NormalUncertainty displays a GUI to allow the user to enter uncertainty
% model parameters for the Normal distribution uncertainty model. See
% SimulateUncertainty for more information.
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

% Edit the above text to modify the response to help NormalUncertainty

% Last Modified by GUIDE v2.5 06-Jun-2018 12:38:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NormalUncertainty_OpeningFcn, ...
                   'gui_OutputFcn',  @NormalUncertainty_OutputFcn, ...
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
function NormalUncertainty_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NormalUncertainty (see VARARGIN)

% Choose default command line output for NormalUncertainty
handles.output = hObject;

% Load structure from varargin
inputs = struct;
for i = 1:2:nargin-3
    inputs.(varargin{i}) = varargin{i+1};
end

% Initialize parameter table
set(handles.stdev_table, 'ColumnName', inputs.names);
set(handles.stdev_table, 'ColumnFormat', horzcat({'char'}, ...
    repmat({'numeric'}, 1, length(inputs.names)-1)));
if ~isfield(inputs, 'uparams')
    set(handles.stdev_table, 'Data', horzcat(inputs.sites, ...
        num2cell(zeros(length(inputs.sites), length(inputs.names)-1))));
else
    set(handles.stdev_table, 'Data', inputs.uparams);
end

% Initialize simulation parameters
set(handles.ci_input, 'String', sprintf('%0.0f%%', (1 - inputs.alpha) * 100));
set(handles.n_input, 'String', sprintf('%0.0e', inputs.n));

% Update handles structure
guidata(hObject, handles);

% Wait for UI to be closed
uiwait(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = NormalUncertainty_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Return global return variable
global return_vars;
varargout = return_vars;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function umodel_input_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to umodel_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function umodel_input_CreateFcn(hObject, ~, ~)
% hObject    handle to umodel_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function n_input_Callback(hObject, ~, handles)
% hObject    handle to n_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse value
set(hObject, 'String', sprintf('%0.0e', str2double(get(hObject, 'String'))));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function n_input_CreateFcn(hObject, ~, ~)
% hObject    handle to n_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ci_input_Callback(hObject, ~, handles)
% hObject    handle to ci_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Parse value
set(hObject, 'String', sprintf('%0.0f%%', ...
    str2double(strrep(get(hObject, 'String'), '%', ''))));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ci_input_CreateFcn(hObject, ~, ~)
% hObject    handle to ci_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function run_button_Callback(~, ~, handles)
% hObject    handle to run_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update the return variables
global return_vars;
return_vars{1} = cell2table(get(handles.stdev_table, 'Data'), ...
    'VariableNames', get(handles.stdev_table, 'ColumnName'));
return_vars{2} = 1 - str2double(strrep(get(handles.ci_input, ...
    'String'), '%', ''))/100;
return_vars{3} = str2double(get(handles.n_input, 'String'));

% Close the figure
close(handles.output);
