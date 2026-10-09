clear
clc
close all

p0 = parameters_modelB();

fs_values = [0.25 0.5 1];

results = cell(size(fs_values));

figure
hold on

for k = 1:length(fs_values)

    p = p0;
    p.fs = fs_values(k);

    fprintf('\n==============================\n')
    fprintf('Running fs = %.2f\n', p.fs)
    fprintf('Nseg = %.0f\n', p.AR*p.fs)

    tic
    r = run_modelB_case(p);
    elapsed = toc;

    results{k} = r;

    fprintf('Runtime = %.2f s\n', elapsed)
    fprintf('x_half/H = %.6f\n', r.x_half)
    fprintf('Slope = %.6f\n', r.slope_half)
    fprintf('Broadness = %.6f\n', r.broadness)
    fprintf('End coverage = %.6f\n', r.theta(end))

    plot(r.x_dim, r.theta, ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('f_s = %.2f', p.fs))
end

hold off

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')

title('Model B resolution test')

legend('Location','best')
xlim([0 p0.AR])
ylim([0 1.05])

grid on