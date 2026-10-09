clear
clc
close all

p = parameters_modelB();

% Small test geometry
p.AR = 5;
p.fs = 4;

% Full 1 s exposure
p.tend = 1;

r = run_modelB_case(p);

fprintf('Complete small-model simulation\n')
fprintf('---------------------------------\n')

fprintf('Number of steps = %d\n', r.n_steps)
fprintf('f0 = %.6e 1/(m^2*s)\n', r.f0)
fprintf('t0 = %.6e s\n', r.t0)
fprintf('tau_end = %.6f\n', r.tau_end)

fprintf('Entrance theta = %.12f\n', ...
    r.entrance_theta)

fprintf('Minimum theta = %.12f\n', ...
    min(r.theta))

fprintf('Maximum theta = %.12f\n', ...
    max(r.theta))

fprintf('x_half = %.6f\n', ...
    r.x_half)

fprintf('slope = %.6f\n', ...
    r.slope_half)

fprintf('broadness = %.6f\n', ...
    r.broadness)

figure

plot(r.x_dim, r.theta, 'o-')

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')

title('Model B complete test, AR = 5')

ylim([0 1.05])
grid on