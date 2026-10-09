clear
clc
close all

%% =========================================================
% Model B - Pressure scan
%
% Reproduce:
% Fig. 3(b) saturation profiles
% Fig. 4(b) x_half and slope
% Fig. 5(b) broadness
%% ==========================================================

p0 = parameters_modelB();

pA0_values = [1 2.5 5 10 20];

ncase = length(pA0_values);

results = cell(ncase,1);

xhalf_raw = NaN(1,ncase);
slope_raw = NaN(1,ncase);
broad_raw = NaN(1,ncase);

entrance_values = NaN(1,ncase);
end_values = NaN(1,ncase);

runtime_values = NaN(1,ncase);

%% =========================================================
% Screening settings
%
% Same numerical saturation tolerance currently used
% in Model A reproduction.
%% ==========================================================

% Numerical saturation tolerance for Model B.
% The paper does not specify an exact numerical threshold.
% 0.005 keeps pA0 = 2.5 Pa as saturated while clearly
% excluding pA0 = 1 Pa.
sat_tol = 5e-3;
threshold = 1 - sat_tol;

fig4_valid = false(1,ncase);
fig5_valid = false(1,ncase);

%% =========================================================
% Run five pressure cases
%% ==========================================================

fprintf('Model B pressure scan\n')
fprintf('========================================\n')

for k = 1:ncase

    p = p0;

    % Change only inlet partial pressure
    p.pA0 = pA0_values(k);

    fprintf('\n----------------------------------------\n')
    fprintf('Running pA0 = %.2f Pa\n', p.pA0)

    tic

    r = run_modelB_case(p);

    runtime_values(k) = toc;

    results{k} = r;

    %% Raw extracted quantities

    entrance_values(k) = r.entrance_theta;

    xhalf_raw(k) = r.x_half;
    slope_raw(k) = r.slope_half;
    broad_raw(k) = r.broadness;

    end_values(k) = r.theta(end);

    %% Fig. 4 screening

    entrance_saturated = ...
        r.entrance_theta >= threshold;

    whole_channel_saturated = ...
        min(r.theta) >= threshold;

    fig4_valid(k) = ...
        entrance_saturated ...
        && ~whole_channel_saturated ...
        && isfinite(r.x_half) ...
        && isfinite(r.slope_half);

    %% Fig. 5 screening

    fig5_valid(k) = ...
        entrance_saturated ...
        && min(r.theta) < 0.1 ...
        && isfinite(r.broadness);

    %% Print result

    fprintf('Runtime = %.2f s\n', runtime_values(k))

    fprintf('Entrance theta = %.12f\n', ...
        r.entrance_theta)

    fprintf('x_half/H = %.6f\n', ...
        r.x_half)

    fprintf('Slope = %.6f\n', ...
        r.slope_half)

    fprintf('Broadness = %.6f\n', ...
        r.broadness)

    fprintf('End-wall coverage = %.6f\n', ...
        r.theta(end))

    fprintf('Fig.4 valid = %d\n', ...
        fig4_valid(k))

    fprintf('Fig.5 valid = %d\n', ...
        fig5_valid(k))

end

%% =========================================================
% Fig. 3(b) - Saturation profiles
%% ==========================================================

figure
hold on

for k = 1:ncase

    r = results{k};

    plot( ...
        r.x_dim, ...
        r.theta, ...
        'LineWidth', 1.4, ...
        'DisplayName', ...
        sprintf('p_{A0} = %.1f Pa', pA0_values(k)))

end

hold off

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')

title('Model B: effect of inlet partial pressure')

legend('Location','best')

xlim([0 p0.AR])
ylim([0 1.05])

grid on

%% =========================================================
% Apply screening to Fig. 4 data
%% ==========================================================

xhalf_plot = xhalf_raw;
slope_plot = slope_raw;

xhalf_plot(~fig4_valid) = NaN;
slope_plot(~fig4_valid) = NaN;

%% =========================================================
% Fig. 4(b)
%% ==========================================================

figure

yyaxis left

plot( ...
    pA0_values, ...
    xhalf_plot, ...
    'o-', ...
    'LineWidth', 1.4)

ylabel('Half-coverage penetration depth x_{0.5}/H')

yyaxis right

plot( ...
    pA0_values, ...
    slope_plot, ...
    'o-', ...
    'LineWidth', 1.4)

ylabel('|\Delta\theta/\Delta(x/H)| at \theta = 0.5')

xlabel('Initial partial pressure p_{A0} (Pa)')

title('Model B: extracted Fig. 4(b) quantities')

grid on

%% =========================================================
% Apply screening to Fig. 5 data
%% ==========================================================

broad_plot = broad_raw;

broad_plot(~fig5_valid) = NaN;

%% =========================================================
% Fig. 5(b)
%% ==========================================================

figure

plot( ...
    pA0_values, ...
    broad_plot, ...
    'o-', ...
    'LineWidth', 1.4)

xlabel('Initial partial pressure p_{A0} (Pa)')
ylabel('Adsorption-front broadness')

title('Model B: adsorption-front broadness')

grid on

%% =========================================================
% Final summary
%% ==========================================================

fprintf('\n\n')
fprintf('========================================\n')
fprintf('Pressure-scan summary\n')
fprintf('========================================\n')

fprintf(['pA0(Pa)   entrance        x_half        ' ...
         'slope        broadness    end_cov   F4 F5\n'])

for k = 1:ncase

    fprintf( ...
        '%7.2f   %.9f   %10.4f   %10.6f   %10.4f   %.6f   %d  %d\n', ...
        pA0_values(k), ...
        entrance_values(k), ...
        xhalf_raw(k), ...
        slope_raw(k), ...
        broad_raw(k), ...
        end_values(k), ...
        fig4_valid(k), ...
        fig5_valid(k))

end