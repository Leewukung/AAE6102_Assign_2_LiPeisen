% Assume your data is stored in the structure navSolutionsCT
satEA = navSolutionsCT.satEA;  % Actual satellite elevation (height angle)
satAZ = navSolutionsCT.satAZ;  % Actual satellite azimuth angle

% Theoretical maximum visible elevation from Skymask (used to judge multipath effects)
theoretical_elevation = [15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70];  % Example: theoretical elevation angles at azimuth 0, 10, 20, ..., 350° (in degrees)
azimuth_intervals = 0:10:350;  % Azimuth intervals, in degrees

% Set elevation threshold; satellites below this threshold are considered not visible
elevation_threshold = 10;

% Create a logical array to mark visible satellites
visible = false(size(satEA));  % Assume no satellites are visible initially

% Record the azimuth, elevation, and the theoretical elevation angle difference for each satellite
angle_diff = [];

% Loop through each satellite to determine visibility
for i = 1:length(satEA)
    % Get the current satellite's azimuth and elevation angle
    az = satAZ(i);
    ea = satEA(i);
    
    % Determine the azimuth interval the satellite belongs to
    for j = 1:length(azimuth_intervals)-1
        if az >= azimuth_intervals(j) && az < azimuth_intervals(j+1)
            % Interpolate to calculate the theoretical elevation angle for this azimuth
            theoretical_elevation_angle = interp1(azimuth_intervals(j:j+1), theoretical_elevation(j:j+1), az, 'linear');
            
            % Calculate the difference between actual and theoretical elevation angle
            angle_diff(i) = abs(ea - theoretical_elevation_angle);  % Save the difference for each satellite
            
            % Check if the actual elevation is greater than or equal to the theoretical elevation
            if ea >= theoretical_elevation_angle
                visible(i) = true;  % If the condition is met, mark the satellite as visible
            end
            break;  % Exit the loop and move to the next satellite
        end
    end
end

% Find the satellites that need to be removed (those with the largest difference between theoretical and actual elevation)
to_remove = find(~visible);  % Find the invisible satellites
[~, idx_sort] = sort(angle_diff(to_remove), 'descend');  % Sort by the largest difference, with the largest at the front

% Gradually remove satellites with the largest difference until the remaining visible satellites are >= 4
for i = 1:length(idx_sort)
    % Remove the satellite with the largest difference
    visible(to_remove(idx_sort(i))) = false;  % Set the current satellite with the largest difference as invisible
    
    % Stop removing if the number of remaining visible satellites is >= 4
    if sum(visible) >= 4
        break;
    end
end

% If there are fewer than 4 visible satellites, show a warning
if sum(visible) < 4
    warning('Insufficient number of visible satellites (less than 4), positioning cannot be solved.');
else
    % Perform positioning calculation with the remaining visible satellites (assuming you have a positioning function)
    % For example, call the positioning function for PVT calculation:
    % result = pvt_calculation(visible, other_parameters);
end

% Plot visible satellites' azimuth and elevation
theta = satAZ(visible);  % Azimuth angles
rho = 90 - satEA(visible);  % Zenith angles (90° - Elevation angle)
figure;
polarplot(deg2rad(theta), rho, 'ro');  % Plot visible satellites with red circular markers

% Plot invisible satellites (those affected by multipath)
hold on;
theta_invisible = satAZ(~visible);
rho_invisible = 90 - satEA(~visible);
polarplot(deg2rad(theta_invisible), rho_invisible, 'bo');  % Plot invisible satellites with blue circular markers
title('Skyplot with Visible and Invisible Satellites');
hold off;