clear
clc
close all

%% =========================================================
% Model A - Baseline simulation
% ==========================================================

% Load baseline parameters
p = parameters_modelA();

% Run one complete Model A simulation
result = run_modelA_case(p);


%% =========================================================
% Display key results
% ==========================================================

fprintf('Model A baseline simulation\n')
fprintf('---------------------------------\n')

fprintf('Entrance coverage = %.6f\n', ...
    result.entrance_theta)

fprintf('Half-coverage penetration depth x/H = %.3f\n', ...
    result.x_half)

fprintf('Absolute slope at half coverage = %.6f\n', ...
    result.slope_half)

fprintf('Adsorption-front broadness = %.3f\n', ...
    result.broadness)


%% =========================================================
% Plot baseline saturation profile
% ==========================================================

figure

plot(result.x_dim, result.theta, ...
    'LineWidth', 1.5)

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')

title('Model A baseline saturation profile')

xlim([0 1000])
ylim([0 1.05])

grid on




















































