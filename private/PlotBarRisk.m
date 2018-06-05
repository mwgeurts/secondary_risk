function axis = PlotBarRisk(axis, varargin)
% PlotBarRisk generates a horizontal bar risk plot for
% SecondaryRiskCalculator. It requires two inputs, the axis to plot on and
% a risk table (see ApplyRiskModel for details on the table format). The
% risk can be persistently stored.
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
persistent risk;

% If new inputs are provided, store them
if nargin > 1
    risk = varargin{1};
end

% If risk data exists
if ~isempty(risk) && any(~cellfun(@isempty, risk.Risk))
    
    % Log action
    Event('Updating risk bar plot');
    
    % Set axis
    axes(axis);
    cla reset;
    
    % Plot names and non-zero risks, along with total
    barh(categorical(risk.Site(~cellfun(@isempty, risk.Risk))), ...
        cell2mat(risk.Risk(~cellfun(@isempty, risk.Risk))));
    
    % Add X axis label
    xlabel('Risk (per 10,000 persons)'); 
    
    % Turn on major gridlines and border
    box on;
    grid on;
    
    % Enable plot
    set(allchild(axis), 'visible', 'on'); 
    set(axis, 'visible', 'on');
    
% Otherwise clear the plot
else
    set(allchild(axis), 'visible', 'off'); 
    set(axis, 'visible', 'off');
end


