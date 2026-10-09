clear
clc
close all

%% =========================================================
% Model B - Paper baseline simulation
% ==========================================================

% Load baseline parameters
p = parameters_modelB();

fprintf('Model B baseline simulation\n')
fprintf('---------------------------------\n')
fprintf('AR = %.0f\n', p.AR)
fprintf('fs = %.2f\n', p.fs)
fprintf('Nseg = %.0f\n', p.AR*p.fs)
fprintf('pA0 = %.2f Pa\n', p.pA0)
fprintf('beta0 = %.4g\n', p.beta0)
fprintf('s0 = %.4e m^2\n', p.s0)

%% Run complete baseline

tic

r = run_modelB_case(p);

elapsed = toc;

%% =========================================================
% Display results
% ==========================================================

fprintf('\nSimulation finished\n')
fprintf('---------------------------------\n')

fprintf('Runtime = %.2f s\n', elapsed)
fprintf('Number of time steps = %d\n', r.n_steps)

fprintf('f0 = %.6e 1/(m^2*s)\n', r.f0)
fprintf('t0 = %.6e s\n', r.t0)
fprintf('tau_end = %.6f\n', r.tau_end)

fprintf('Entrance coverage = %.12f\n', ...
    r.entrance_theta)

fprintf('Minimum coverage = %.12f\n', ...
    min(r.theta))

fprintf('Maximum coverage = %.12f\n', ...
    max(r.theta))

fprintf('x_half/H = %.6f\n', ...
    r.x_half)

fprintf('Slope at half coverage = %.6f\n', ...
    r.slope_half)

fprintf('Broadness = %.6f\n', ...
    r.broadness)

%% =========================================================
% Plot baseline saturation profile
% ==========================================================

figure

plot(r.x_dim, r.theta, ...
    'LineWidth', 1.5)

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')

title('Model B baseline saturation profile')

xlim([0 p.AR])
ylim([0 1.05])

grid on