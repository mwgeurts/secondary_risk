function axis = PlotDVH(axis, i, varargin)
% PlotDVH generates a differential DVH and risk plot for
% SecondaryRiskCalculator. It is called with two different input
% combinations:
%
% axis = PlotDVH(axis, i, structures, dose, risk);
% axis = PlotDVH(axis, i);
%
% The first input set will compute and plot the differential dose and risk
% for structure i and persistently store the results. Then, when called
% with only two inputs, it will use the stored values and update the plot.
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

% Define persistent variables
persistent structures dose dvh risk;

% Define number of DVH bins
bins = 100;

% If new inputs are provided, store them
if nargin > 2
    structures = varargin{1};
    dose = varargin{2};
    risk = varargin{3};
    
    % Recompute the differential DVH
    if ~isempty(structures) &&  ~isempty(dose) && ~isempty(risk)
        
        % Initialize DVH array
        dvh = zeros(length(structures)+1, bins + 1);
        
        % Compute dose bins
        dvh(1,:) = (0:bins)/bins * ceil(max(max(max(dose.data))));
        
        % Loop through structures, computing differential DVH
        for j = 1:length(structures)
            if ~isempty(structures{j})
                dvh(j+1,1:bins) = ...
                    histcounts(dose.data(structures{j}.mask), dvh(1,:));
                dvh(j+1,:) = dvh(j+1,:) / sum(dvh(j+1,:));
            end
        end
    else
        dvh = [];
    end
end

% If risk data exists
if ~isempty(risk) && i > 0
    
    % Log action
    Event('Updating DVH/risk plot');
    
    % Set axis
    axes(axis);
    cla reset;
    
    % Plot the risk for the specified structure
    if ~isempty(dvh) && sum(dvh(i+1,:)) > 0
        yyaxis left;
    end
    plot(risk{i}(1,:), risk{i}(2,:) * 1e4);
    ylabel('Risk (per 10,000 persons)');

    % Turn on major gridlines and border
    box on;
    grid on;
    
    % If DVH data also exists
    if ~isempty(dvh) && sum(dvh(i+1,:)) > 0
        yyaxis right;
        plot(dvh(1,:), dvh(i+1,:)*100);
        ylabel('Relative Volume (%)');
    end
    
    % Set x limit to max dose or 30 Gy
    if ~isempty(dose)
        xlim([0 ceil(max(max(max(dose.data))))]);
    else
        xlim([0 max(risk{i}(1,:))]);
    end
    xlabel('Dose (Gy)');
    
    % Enable plot
    set(allchild(axis), 'visible', 'on'); 
    set(axis, 'visible', 'on');
    
% Otherwise clear the plot
else
    set(allchild(axis), 'visible', 'off'); 
    set(axis, 'visible', 'off');
end


