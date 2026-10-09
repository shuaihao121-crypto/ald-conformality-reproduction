clear
clc

%% Load parameters

p = parameters_modelB();

%% Small test geometry

AR_test = 5;
fs_test = 4;

geom = geometry_modelB(AR_test, fs_test);

fprintf('AR = %.2f\n', AR_test)
fprintf('fs = %.2f\n', fs_test)
fprintf('Wall segments = %d\n', geom.Nseg)
fprintf('Total states = %d\n', geom.N)

%% ---------------------------------------------------------
% Check q matrix
%% ---------------------------------------------------------

column_sum = sum(geom.q,1);

fprintf('\nView-factor checks\n')
fprintf('Maximum |sum(q)-1| = %.3e\n', ...
    max(abs(column_sum - 1)))

fprintf('Minimum q = %.6e\n', min(geom.q(:)))
fprintf('Maximum q = %.6e\n', max(geom.q(:)))

%% ---------------------------------------------------------
% Bare surface
%% ---------------------------------------------------------

theta = zeros(length(geom.surface_idx),1);

out = markov_modelB(theta, p.beta0, geom);

%% ---------------------------------------------------------
% Markov checks
%% ---------------------------------------------------------

fprintf('\nMarkov checks\n')

fprintf('Minimum beta = %.6e\n', min(out.beta))
fprintf('Maximum beta = %.6e\n', max(out.beta))

fprintf('Exit probability = %.12f\n', ...
    out.P_exit)

fprintf('Total adsorption probability = %.12f\n', ...
    sum(out.P_ads))

fprintf('Probability sum = %.12f\n', ...
    out.prob_sum)

fprintf('Probability error = %.3e\n', ...
    abs(out.prob_sum - 1))

%% Plot adsorption probability distribution

figure

plot(geom.x_dim, out.P_ads, 'o-')

xlabel('Dimensionless distance x/H')
ylabel('Adsorption probability P_i')

title('Model B core test: bare surface')

grid on
%% =========================================================
% One adaptive time step
% ==========================================================

% Fraction of available surface sites
av = 1 - theta;

% Surface quantities only
r_surface = out.r(geom.surface_idx);
area_surface = geom.area(geom.surface_idx);

% Entrance area
entry_area = geom.area(geom.entry_idx);

% Machball normalized coverage-evolution coefficient
k = entry_area .* p.beta0 .* r_surface ./ area_surface;

% Machball adaptive-step parameter
% Numerical implementation choice, not a Table 2 physical parameter
ep = 0.05;

% Adaptive normalized time step
dtau = ep / max(k);

% Implicit update of available-site fraction
av_new = av ./ (1 + k .* dtau);

% New surface coverage
theta_new = 1 - av_new;


%% =========================================================
% Convert normalized time step to physical time
% ==========================================================

f0 = p.NA * p.pA0 ...
    / sqrt(2*pi*p.MA*p.R*p.T);

t0 = 1 / (p.s0 * f0);

dt_physical = dtau * t0;


%% =========================================================
% Display one-step results
% ==========================================================

fprintf('\nOne adaptive time-step test\n')
fprintf('f0 = %.6e 1/(m^2*s)\n', f0)
fprintf('t0 = %.6e s\n', t0)

fprintf('dtau = %.6e\n', dtau)
fprintf('Physical dt = %.6e s\n', dt_physical)

fprintf('Minimum theta_new = %.12f\n', ...
    min(theta_new))

fprintf('Maximum theta_new = %.12f\n', ...
    max(theta_new))

fprintf('Number theta < 0 = %d\n', ...
    sum(theta_new < 0))

fprintf('Number theta > 1 = %d\n', ...
    sum(theta_new > 1))


%% =========================================================
% Re-run Markov solver after one coverage update
% ==========================================================

out2 = markov_modelB(theta_new, p.beta0, geom);

fprintf('\nAfter one coverage update\n')

fprintf('Minimum beta = %.12e\n', ...
    min(out2.beta))

fprintf('Maximum beta = %.12e\n', ...
    max(out2.beta))

fprintf('Probability sum = %.12f\n', ...
    out2.prob_sum)

fprintf('Probability error = %.3e\n', ...
    abs(out2.prob_sum - 1))


%% =========================================================
% Plot coverage after one step
% ==========================================================

figure

plot(geom.x_dim, theta_new, 'o-')

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')

title('Model B: coverage after one adaptive time step')

grid on









