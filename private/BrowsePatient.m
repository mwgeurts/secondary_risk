function handles = BrowsePatient(handles)
% BrowsePatient is called by SecondaryRiskCalculator when the browse button
% is clicked. It opens a browser to allow the user to select a folder, then
% scans the folder for DICOM files, loads them into the tool, and updates
% the risk calculations.
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
Event('Browse button selected. Opening folder browser...');

% Open folder browser
path = uigetdir(handles.config.DEFAULT_PATH, ...
    'Select folder containing DICOM data');

% If a valid path was selected
if path ~= 0
    
    % Log path
    Event(['User selected path "', path, '"']);
    
    % Update default path
    handles.config.DEFAULT_PATH = path;
    
    % Update folder text
    set(handles.path_text, 'String', path);
    
    % Scan folder for DICOM data
    files = ScanDICOMPath(path);
    
    % Verify at least one image, structure set, dose, and plan exist
    if sum(ismember(files(:,3), 'CT')) == 0
        Event('DICOM data must contain a CT image dataset', 'ERROR');
    elseif sum(ismember(files(:,3), 'RTSTRUCT')) == 0
        Event('DICOM data must contain a structure set', 'ERROR');
    elseif sum(ismember(files(:,3), 'RTPLAN')) == 0
        Event('DICOM data must contain an RT plan', 'ERROR');
    elseif sum(ismember(files(:,3), 'RTDOSE')) == 0
        Event('DICOM data must contain a dose set', 'ERROR');
    end
    
    % Verify all files have the same FoR and referenced study
    if ~all(ismember(files(:,7), files(1,7)))
        Event(['All DICOM files must have the same Frame of Reference. ', ...
            'It is possible this directory contained multiple plans. ', ...
            'Separate the plans and try again.'], 'ERROR');
    elseif ~all(ismember(files(:,8), files(1,8)))
        Event(['All DICOM files must have the same referenced study. ', ...
            'It is possible this directory contained multiple plans. ', ...
            'Separate the plans and try again.'], 'ERROR');
    end
    
    % Load the image, structures, dose, and plan
    handles.image = LoadDICOMImages(...
        files{find(ismember(files(:,3), 'CT'),1),2}, ...
        files(ismember(files(:,3), 'CT'),1));
    handles.image.structures = LoadDICOMStructures(...
        files{find(ismember(files(:,3), 'RTSTRUCT'),1),2}, ...
        files{find(ismember(files(:,3), 'RTSTRUCT'),1),1}, handles.image);
    handles.dose = LoadDICOMDose(...
        files{find(ismember(files(:,3), 'RTDOSE'),1),2}, ...
        files{find(ismember(files(:,3), 'RTDOSE'),1),1});
    handles.plan = dicominfo(fullfile(...
        files{find(ismember(files(:,3), 'RTPLAN'),1),2}, ...
        files{find(ismember(files(:,3), 'RTPLAN'),1),1}));
    
    % Set empty image registration
    handles.dose.registration = [0 0 0 0 0 0];

    % If the dose array is not identical to the image, re-sample it
    if ~isequal(handles.image.dimensions, handles.dose.dimensions) || ...
            ~isequal(handles.image.width, handles.dose.width) || ...
            ~isequal(handles.image.start, handles.dose.start)

        % Log action
        Event(['The dose grid is not aligned to the image and ', ...
            'will be interpolated']);

        % Compute X, Y, and Z meshgrids for the CT image dataset 
        % positions using the start and width values, permuting X/Y
        [refX, refY, refZ] = meshgrid(single(handles.image.start(2) + ...
            handles.image.width(2) * (size(handles.image.data,2) - 1): ...
            -handles.image.width(2):handles.image.start(2)), ...
            single(handles.image.start(1):handles.image.width(1)...
            :handles.image.start(1) + handles.image.width(1)...
            * (size(handles.image.data,1) - 1)), ...
            single(handles.image.start(3):handles.image.width(3):...
            handles.image.start(3) + handles.image.width(3)...
            * (size(handles.image.data,3) - 1)));

        % Compute X, Y, and Z meshgrids for the dose dataset using
        % the start and width values, permuting X/Y
        [tarX, tarY, tarZ] = meshgrid(single(handles.dose.start(2) + ...
            handles.dose.width(2) * (size(handles.dose.data,2) - 1): ...
            -handles.dose.width(2):handles.dose.start(2)), ...
            single(handles.dose.start(1):handles.dose.width(1):...
            handles.dose.start(1) + handles.dose.width(1) ...
            * (size(handles.dose.data,1) - 1)), ...
            single(handles.dose.start(3):handles.dose.width(3):...
            handles.dose.start(3) + handles.dose.width(3) ...
            * (size(handles.dose.data,3) - 1)));

        % Start try-catch block to safely test for CUDA functionality
        try
            % Clear and initialize GPU memory.  If CUDA is not enabled, or if the
            % Parallel Computing Toolbox is not installed, this will error, and the
            % function will automatically rever to CPU computation via the catch
            % statement
            gpuDevice(1);

            % Run GPU interp3 function to compute the dose
            % values at the specified target coordinate points
            handles.dose.data = gather(interp3(gpuArray(tarX), ...
                gpuArray(tarY), gpuArray(tarZ), ...
                gpuArray(single(handles.dose.data)), gpuArray(refX), ...
                gpuArray(refY), gpuArray(refZ), 'linear', 0));

        % If GPU fails, revert to CPU computation
        catch

            % Log GPU failure (if cpu flag is not set)
            Event('GPU failed, reverting to CPU method', 'WARN'); 

            % Run CPU interp3 function to compute the dose
            % values at the specified target coordinate points
            handles.dose.data = interp3(tarX, tarY, tarZ, ...
                single(handles.dose.data), refX, ...
                refY, refZ, '*linear', 0);
        end

        % Set interpolated voxel parameters to CT
        handles.dose.start = handles.image.start;
        handles.dose.width = handles.image.width;
        handles.dose.dimensions = handles.image.dimensions;

    end

    % Enable and retrieve T/C/S selector
    set(handles.tcs_t, 'visible', 'on');
    set(handles.tcs_c, 'visible', 'on');
    set(handles.tcs_s, 'visible', 'on');
    if get(handles.tcs_t, 'Value') == 1
        o = 'T';
    elseif get(handles.tcs_c, 'Value') == 1
        o = 'C';
    else
        o = 'S';
    end
    
    % Initialize transverse viewer
    handles.tcs = ImageViewer('axis', handles.tcs_axes, ...
        'tcsview', o, 'background', handles.image, ...
        'overlay', handles.dose, 'alpha', ...
        sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
        'structures', handles.image.structures, ...
        'slider', handles.tcs_slider, 'cbar', 'on', 'pixelval', 'off');

    % Enable transparency
    set(handles.alpha, 'visible', 'on');

    % Update exposure age with patient's age
    if isfield(handles.plan, 'PatientAge') && ...
            ~isempty(handles.plan.PatientAge)
        set(handles.agee_input, 'String', ...
            sprintf('%i', handles.plan.PatientAge));
        Event(['Exposure age updated to ', get(handles.agee_input, ...
            'String'), ' years using DICOM patient age']);
        
    % Alternatively, used birth and study date
    elseif isfield(handles.plan, 'PatientBirthDate') && ...
            ~isempty(handles.plan.PatientBirthDate)
        try
            set(handles.agee_input, 'String', ...
                sprintf('%i', floor((datenum(handles.plan.PatientBirthDate, ...
                'yyyymmdd') - datenum(handles.plan.StudyDate, 'yyyymmdd')) / ...
                365.25)));
            Event(['Exposure age updated to ', get(handles.agee_input, ...
                'String'), ' years using DICOM birthdate']);
        catch
            Event('Date of birth could not be parsed from DICOM plan', ...
                'WARN');
        end
    end
    
    % Compute cumulative MU for this plan
    mu = 0;
    for i = 1:length(fieldnames(handles.plan.FractionGroupSequence))
        for j = 1:length(fieldnames(handles.plan.FractionGroupSequence...
                .(sprintf('Item_%i', i)).ReferencedBeamSequence))
            mu = mu + handles.plan.FractionGroupSequence...
                .(sprintf('Item_%i', i)).ReferencedBeamSequence...
                .(sprintf('Item_%i', j)).BeamMeterset;
        end
    end
    mu = round(mu);
    handles.plan.mu = mu;
    if mu > 0
        set(handles.mu_input, 'String', sprintf('%0.0f', mu));
        Event(['Monitor Units set to ', get(handles.mu_input, ...
            'String'), ' based on DICOM header']);
    else
        set(handles.mu_input, 'String', '');
        Event('Monitor Units could not be parsed from DICOM plan', 'WARN');
    end
    
    % Update number of fractions
    fx = 0;
    if isfield(handles.plan, 'FractionGroupSequence')
        for i = 1:length(fieldnames(handles.plan.FractionGroupSequence))
            fx = fx + handles.plan.FractionGroupSequence.(...
                sprintf('Item_%i', i)).NumberOfFractionsPlanned;
        end
    end
    if fx > 0
        set(handles.dvh_fx, 'String', sprintf('%0.0f', fx));
        Event(['Number of fractions set to ', get(handles.dvh_fx, ...
            'String'), ' based on DICOM header']);
    else
        set(handles.dvh_fx, 'String', '1');
        Event('Number of fractions could not be parsed from DICOM plan', ...
            'WARN');
    end
    
    % Correct gender, if available
    genders = get(handles.gender_menu, 'String');
    if isfield(handles.plan, 'PatientSex') && ...
            startsWith(genders{3 - get(handles.gender_menu, 'Value')}, ...
            handles.plan.PatientSex(1))
            
        % Update gender
        set(handles.gender_menu, 'Value', 3 - ...
            get(handles.gender_menu, 'Value'));
        
        % Force parameter refresh
        params = ApplyRiskModel(get(handles.param_menu, 'Value'),...
            handles.parameters{get(handles.param_menu, 'Value'),2}, ...
            handles.plan.PatientSex);
    
    % Otherwise use existing parameters
    else
        params = get(handles.model_table, 'Data');
    end
    
    % Set structure list
    structures = cell(1, length(handles.image.structures)+1);
    structures{1} = ' ';
    names = cell(1, length(handles.image.structures));
    for i = 1:length(handles.image.structures)
        names{i} = handles.image.structures{i}.name;
        structures{i+1} = sprintf(...
            '<html><font id="%s" color="rgb(%i,%i,%i)">%s</font></html>', ...
            handles.image.structures{i}.name, ...
            handles.image.structures{i}.color(1), ...
            handles.image.structures{i}.color(2), ...
            handles.image.structures{i}.color(3), ...
            handles.image.structures{i}.name);
    end
    formats = get(handles.model_table, 'ColumnFormat');
    formats{2} = structures;
    set(handles.model_table, 'ColumnFormat', formats);
    
    % Attempt to match structures
    for i = 1:size(params, 1)
        [c, d] = strnearest(params{i,1}, names, 'case');
        if length(c) == 1 && ...
                handles.config.MATCH_THRESHOLD > d / length(params{i,1})
            Event(sprintf(['Site %s matched to structure %s with a ', ...
                'distance %i'], params{i,1}, names{c}, d));
            params{i,2} = names{c};
        else
            params{i,2} = ' ';
        end
    end
    
    % Update parameters table
    set(handles.model_table, 'Data', params);
    
    % Recalculate the risk model
    handles = UpdateRiskModel(handles);
    
    % Enable uncertainty simulation
    set(handles.sim_button, 'Enable', 'on');
end

