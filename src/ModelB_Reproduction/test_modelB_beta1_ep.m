clear
clc
close all

p0 = parameters_modelB();

% Difficult Case VI point
p0.beta0 = 1;

% Show progress so we know it is running
p0.show_progress = true;

% Numerical-step sensitivity test
ep_values = [5 2];

fprintf('Model B beta0 = 1 sensitivity test\n')
fprintf('========================================\n')

for k = 1:length(ep_values)

    p = p0;

    p.ep = ep_values(k);

    fprintf('\n----------------------------------------\n')
    fprintf('Running ep = %.3f\n', p.ep)

    tic

    r = run_modelB_case(p);

    elapsed = toc;

    fprintf('\nResult for ep = %.3f\n', p.ep)
    fprintf('Runtime = %.2f s\n', elapsed)
    fprintf('Steps = %d\n', r.n_steps)
    fprintf('Entrance theta = %.12f\n', r.entrance_theta)
    fprintf('x_half/H = %.6f\n', r.x_half)
    fprintf('Slope = %.6f\n', r.slope_half)
    fprintf('Broadness = %.6f\n', r.broadness)

end