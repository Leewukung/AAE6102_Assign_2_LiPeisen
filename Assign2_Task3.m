% Predefined error variances (based on Bonus parameters)
sigma_UDRE = 0.5;   % Pseudorange correction error variance
sigma_UIVE = 0.5;   % Vertical ionospheric error variance
sigma_SNR = 0.22;   % Signal-to-noise ratio error variance
sigma_m45 = 0.22;   % Multipath error variance at 45 degrees
sigma_trv = 0.15;   % Tropospheric error variance

% Number of satellites N
N = 8;  % Example, set according to the number of visible satellites

% Satellite elevation angles (extracted from the data)
satEA = navSolutionsCT.satEA;  % Satellite elevation angles (extracted from data)
satAZ = navSolutionsCT.satAZ;  % Satellite azimuth angles (extracted from data)

% Calculate the variance for each satellite (based on the error model)
sigma_i = sqrt(sigma_UDRE^2 + sigma_UIVE^2 + sigma_SNR^2 + ...
                sigma_m45^2 * tan(deg2rad(satEA)).^2 + ...
                sigma_trv^2 * sin(deg2rad(satEA)).^2);

% Construct the weight matrix W, which is a diagonal matrix containing the variance squared for each satellite
W = diag(sigma_i.^2);  % This is a diagonal matrix containing the error variance for each satellite

% Set the probability of false alarm PFA (typically a small value like 10^-7)
PFA = 10^-7;

% Calculate the threshold based on the given PFA and number of satellites N
threshold = chi_squared_threshold(N, PFA);  % chi_squared_threshold is a function that calculates the threshold based on the chi-squared distribution

% Pseudorange measurements y (extracted from the data)
y = navSolutionsCT.rawPseudorange;  % Use the actual pseudorange data

% Observation matrix G (calculated from satellite angles and user position)
d = y;  % Use the actual pseudorange data as the distance between the satellite and the user
G = [d .* cos(deg2rad(satEA)) .* cos(deg2rad(satAZ));  % X direction
     d .* cos(deg2rad(satEA)) .* sin(deg2rad(satAZ));  % Y direction
     d .* sin(deg2rad(satEA))];  % Z direction

% Calculate the weighted least squares solution
K = inv(G' * W * G) * G' * W;  % Weighted least squares solution
x = K * y;  % Calculate the position solution (x is the position vector)

% Calculate the weighted sum of squared errors (WSSE)
P = G * inv(G' * W * G) * G';  % Calculate matrix P
WSSE = y' * W * (eye(N) - P) * y;  % Calculate WSSE

% Display the calculated WSSE
disp(['Calculated WSSE: ', num2str(WSSE)]);

% Check if the WSSE exceeds the threshold, and if so, remove the satellite with the largest contribution
while WSSE > threshold && size(G,1) > 4  % Ensure at least 4 satellites remain
    % Calculate residuals and find the satellite with the largest contribution
    residuals = (eye(N) - P) * y;  % Calculate residuals
    satellite_contributions = abs(residuals);  % Calculate the contribution of each satellite (absolute value)
    
    % Find the satellite with the largest contribution and remove it
    [~, idx_to_remove] = max(satellite_contributions);  % Find the satellite with the largest contribution
    
    % Display the index of the satellite to be removed
    disp(['Satellite index to be removed: ', num2str(idx_to_remove)]);
    
    % Remove the pseudorange data for the satellite from the measurements
    y(idx_to_remove) = [];
    G(idx_to_remove, :) = [];  % Remove the corresponding row from the geometry matrix
    W(idx_to_remove, :) = [];  % Remove the corresponding row/column from the weight matrix
    
    % Recalculate the weighted least squares solution with the remaining satellites
    K = inv(G' * W * G) * G' * W;
    x = K * y;  % Recalculate the position solution
    disp(['New position solution: ', num2str(x')]);  % Display the new position solution
    
    % Recalculate the weighted sum of squared errors
    P = G * inv(G' * W * G) * G';
    WSSE = y' * W * (eye(N) - P) * y;  % Recalculate the new WSSE
end

% Chi-squared threshold calculation function, returns the threshold for given N and PFA
function threshold = chi_squared_threshold(N, PFA)
    % Calculate the threshold based on the given N and PFA using the chi-squared distribution
    % The threshold can be obtained by using the chi2inv function in MATLAB:
    
    degrees_of_freedom = N - 4;  % Degrees of freedom are N - 4
    threshold = chi2inv(1 - PFA, degrees_of_freedom);  % Calculate the chi-squared critical value
end