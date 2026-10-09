clear
clc

% Load baseline parameters
p = parameters_modelA();

% Set sticking coefficient
p.c = 0.1;

% Run Model A
r = run_modelA_case(p);

% Current screening threshold
sat_tol = 1e-3;
threshold = 1 - sat_tol;

fprintf('c = %.3f\n', p.c)
fprintf('Entrance theta = %.12f\n', r.entrance_theta)
fprintf('Threshold      = %.12f\n', threshold)
fprintf('Difference     = %.12e\n', r.entrance_theta - threshold)

fprintf('\nMinimum theta in channel = %.12f\n', min(r.theta))
fprintf('x_half = %.6f\n', r.x_half)
fprintf('slope  = %.6f\n', r.slope_half)
fprintf('broadness = %.6f\n', r.broadness)

% Check screening logic
entrance_saturated = r.entrance_theta >= threshold;
whole_channel_saturated = min(r.theta) >= threshold;
fig4_ok = entrance_saturated && ~whole_channel_saturated;
fig5_ok = entrance_saturated && min(r.theta) < 0.1;

fprintf('\nScreening result:\n')
fprintf('entrance_saturated      = %d\n', entrance_saturated)
fprintf('whole_channel_saturated = %d\n', whole_channel_saturated)
fprintf('Fig.4 valid             = %d\n', fig4_ok)
fprintf('Fig.5 valid             = %d\n', fig5_ok)