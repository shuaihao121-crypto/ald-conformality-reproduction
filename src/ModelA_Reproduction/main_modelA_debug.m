clear
clc

% Load Model A baseline parameters
p = parameters_modelA();

% Basic parameter checks
AR = p.L / p.H;
Nx = round(p.fp * AR);

fprintf('Aspect ratio AR = %.0f\n', AR)
fprintf('Number of spatial points Nx = %d\n', Nx)
fprintf('H = %.3e m\n', p.H)
fprintf('L = %.3e m\n', p.L)
fprintf('q = %.3e 1/m^2\n', p.q)
% Hydraulic diameter
h = 2 / (1/p.H + 1/p.W);

fprintf('Hydraulic diameter h = %.6e m\n', h)
% Eq. (7): collision rate at unit pressure
Q = p.NA / sqrt(2*pi*p.MA*p.R*p.T);

fprintf('Collision rate Q = %.6e 1/(m^2*s*Pa)\n', Q)
% Adsorption equilibrium constant
K = p.c * Q / (p.q * p.Pd);

fprintf('Adsorption equilibrium constant K = %.6e 1/Pa\n', K)
% Knudsen diffusion coefficient
DKn = h * sqrt(8*p.R*p.T / (9*pi*p.MA));

fprintf('Knudsen diffusion coefficient DKn = %.6e m^2/s\n', DKn)
% Average molecular speed of Reactant A
vA = sqrt(8*p.R*p.T / (pi*p.MA));

fprintf('Average molecular speed vA = %.6e m/s\n', vA)
% ----- Diagnostic test: first pressure evaluation -----

t_test = 0.001;      % s
pA_prev = 0;         % Pa, initial gas pressure inside the channel
% Collision frequency of Reactant A
zA = pi/4 * (p.dA + p.dI)^2 ...
    * sqrt(8*p.R*p.T/pi * (1/p.MA + 1/p.MI)) ...
    * p.pI*p.NA/(p.R*p.T) ...
    + pi*p.dA^2 ...
    * sqrt(16*p.R*p.T/(pi*p.MA)) ...
    * pA_prev*p.NA/(p.R*p.T);

fprintf('Collision frequency zA = %.6e 1/s\n', zA)
% Gas-phase diffusion coefficient
DA = 3*pi*vA^2 / (16*zA);

fprintf('Gas-phase diffusion coefficient DA = %.6e m^2/s\n', DA)
% Eq. (2): effective diffusion coefficient
Deff = 1 / (1/DA + 1/DKn);

fprintf('Effective diffusion coefficient Deff = %.6e m^2/s\n', Deff)
% Apparent longitudinal diffusion coefficient
D = p.pA0 * p.H * Deff ...
    / (p.q * p.kB * p.T ...
    * (1 - log(K*p.pA0 + 1)/(K*p.pA0)));

fprintf('Apparent longitudinal diffusion coefficient D = %.6e m^2/s\n', D)
% Eq. (5): gas-front distance
xs = sqrt(D*t_test);

fprintf('Gas-front distance xs = %.6e m\n', xs)
% Eq. (6): auxiliary length
aux = sqrt(h*p.NA*Deff / (4*p.R*p.T*p.c*Q));

if xs > aux
    xt = xs - aux;
else
    xt = 0;
end

fprintf('Auxiliary length = %.6e m\n', aux)
fprintf('Transition position xt = %.6e m\n', xt)
% Eq. (9): pressure at transition position
pt = p.pA0 * (1 - xt/xs);

fprintf('Pressure at transition point pt = %.6e Pa\n', pt)
% Test several positions inside the channel
x_test = [0 1 2 5 10 20] * 1e-6;   % m
% Eq. (8): exponential pressure region
pA_test = pt * exp(-(x_test - xt) / (xs - xt));
fprintf('\nPressure profile at t = %.4f s:\n', t_test)

for i = 1:length(x_test)
    fprintf('x = %6.2f um, pA = %.6f Pa\n', ...
        x_test(i)*1e6, pA_test(i))
end
figure
plot(x_test*1e6, pA_test, 'o-')

xlabel('Distance x (\mum)')
ylabel('Reactant A partial pressure p_A (Pa)')
title('Test pressure profile at t = 0.001 s')
grid on
%% Test pressure_modelA.m

x_test2 = [0 1 2 5 10 20]' * 1e-6;
pA_prev_test = zeros(size(x_test2));

pA_function = pressure_modelA(0.001, x_test2, p, pA_prev_test);

fprintf('\nPressure calculated by pressure_modelA.m:\n')

for i = 1:length(x_test2)
    fprintf('x = %6.2f um, pA = %.6f Pa\n', ...
        x_test2(i)*1e6, pA_function(i))
end
%% Test modelA_rhs.m

clear modelA_rhs

x_test3 = [0 1 2 5 10 20]' * 1e-6;

% Bare surface
theta_test = zeros(size(x_test3));

dtheta_test = modelA_rhs(0.001, theta_test, x_test3, p);

fprintf('\nCoverage rate at t = 0.001 s:\n')

for i = 1:length(x_test3)
    fprintf('x = %6.2f um, dtheta/dt = %.6f 1/s\n', ...
        x_test3(i)*1e6, dtheta_test(i))
end
%% Full baseline Model A simulation

% Reset persistent pressure stored inside modelA_rhs
clear modelA_rhs

% Spatial grid
x = linspace(0, p.L, Nx)';

% Initial surface coverage: bare surface
theta0 = zeros(Nx, 1);

% Time interval
% Follow the public DReaM-ALD baseline implementation
tspan = [0.001 0.05 p.tend];

fprintf('\nStarting ode23 simulation...\n')

% Solve Model A
[t_sol, theta_sol] = ode23( ...
    @(t, theta) modelA_rhs(t, theta, x, p), ...
    tspan, ...
    theta0);

fprintf('ode23 simulation finished.\n')

% Surface coverage at the end of exposure
theta_final = theta_sol(end, :)';
%% Check final coverage data

fprintf('\nFinal coverage checks:\n')
fprintf('theta at channel entrance = %.6f\n', theta_final(1))
fprintf('minimum theta = %.6e\n', min(theta_final))
fprintf('maximum theta = %.6f\n', max(theta_final))

fprintf('Number of NaN values = %d\n', sum(isnan(theta_final)))
fprintf('Number of negative theta values = %d\n', sum(theta_final < 0))
fprintf('Number of theta > 1 values = %d\n', sum(theta_final > 1))
% Inspect a few points along the channel

check_index = [1, 200, 500, 1000, 1500, 2000];

fprintf('\nSelected final coverage values:\n')

for j = 1:length(check_index)

    i = check_index(j);

    fprintf('x/H = %8.2f, theta = %.6f\n', ...
        x(i)/p.H, theta_final(i))

end
%% Plot baseline saturation profile

x_dimensionless = x / p.H;

figure
plot(x_dimensionless, theta_final, 'LineWidth', 1.5)

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')
title('Model A baseline: p_{A0} = 10 Pa')

xlim([0 1000])
ylim([0 1.05])

grid on
%% Estimate half-coverage penetration depth

idx = find(theta_final <= 0.5, 1, 'first');

x1 = x_dimensionless(idx-1);
x2 = x_dimensionless(idx);

theta1 = theta_final(idx-1);
theta2 = theta_final(idx);

x_half = x1 + (0.5-theta1) * (x2-x1) / (theta2-theta1);

fprintf('\nHalf-coverage penetration depth x/H = %.3f\n', x_half)
%% Step 9: Reproduce Fig. 3(b), Model A

pA0_values = [1 2.5 5 10 20];

% Matrix for storing final coverage profiles
theta_profiles = zeros(Nx, length(pA0_values));

% Store half-coverage penetration depths
x_half_values = zeros(size(pA0_values));

for k = 1:length(pA0_values)

    % Copy baseline parameters
    p_case = p;

    % Change only inlet partial pressure
    p_case.pA0 = pA0_values(k);

    % Important: reset persistent pressure before each new simulation
    clear modelA_rhs

    % Bare surface
    theta0 = zeros(Nx, 1);

    % Same exposure duration: 1 s
    tspan = [0.001 0.05 p_case.tend];

    fprintf('\nRunning pA0 = %.1f Pa...\n', p_case.pA0)

    % Solve Model A
    [~, theta_case] = ode23( ...
        @(t, theta) modelA_rhs(t, theta, x, p_case), ...
        tspan, ...
        theta0);

    % Final coverage profile
    theta_profiles(:, k) = theta_case(end, :)';

    % Half-coverage penetration depth
    idx = find(theta_profiles(:, k) <= 0.5, 1, 'first');

    if ~isempty(idx) && idx > 1

        x1 = x_dimensionless(idx-1);
        x2 = x_dimensionless(idx);

        th1 = theta_profiles(idx-1, k);
        th2 = theta_profiles(idx, k);

        x_half_values(k) = x1 ...
            + (0.5-th1)*(x2-x1)/(th2-th1);

    else
        x_half_values(k) = NaN;
    end

end
%% Plot Fig. 3(b), Model A

figure
hold on

for k = 1:length(pA0_values)

    plot(x_dimensionless, theta_profiles(:, k), ...
        'LineWidth', 1.5)

end

hold off

xlabel('Dimensionless distance x/H')
ylabel('Surface coverage \theta')
title('Model A: effect of inlet partial pressure')

legend('1 Pa', '2.5 Pa', '5 Pa', '10 Pa', '20 Pa', ...
    'Location', 'best')

xlim([0 1000])
ylim([0 1.05])

grid on
fprintf('\nHalf-coverage penetration depths:\n')

for k = 1:length(pA0_values)

    fprintf('pA0 = %5.1f Pa, x_half/H = %.3f\n', ...
        pA0_values(k), x_half_values(k))

end
%% Stage 7: Extract Fig. 4(b) parameters

slope_half_values = NaN(size(pA0_values));

for k = 1:length(pA0_values)

    idx = find(theta_profiles(:,k) <= 0.5, 1, 'first');

    if ~isempty(idx) && idx > 1

        x1 = x_dimensionless(idx-1);
        x2 = x_dimensionless(idx);

        th1 = theta_profiles(idx-1,k);
        th2 = theta_profiles(idx,k);

        % Absolute slope at half coverage
        slope_half_values(k) = abs((th2-th1)/(x2-x1));

    end
end

fprintf('\nExtracted parameters:\n')

for k = 1:length(pA0_values)
    fprintf('pA0 = %5.1f Pa, entrance theta = %.6f, x_half = %.3f, slope = %.6f\n', ...
        pA0_values(k), theta_profiles(1,k), ...
        x_half_values(k), slope_half_values(k))
end
%% Reproduce Fig. 4(b), Model A

valid_idx = 2:5;

figure

tiledlayout(1,2)

% Left: half-coverage penetration depth
nexttile
plot(pA0_values(valid_idx), ...
     x_half_values(valid_idx), ...
     'o-', 'LineWidth', 1.5)

xlabel('Initial partial pressure p_{A0} (Pa)')
ylabel('Half-coverage penetration depth x_{0.5}/H')
grid on


% Right: absolute slope
nexttile
plot(pA0_values(valid_idx), ...
     slope_half_values(valid_idx), ...
     'o-', 'LineWidth', 1.5)

xlabel('Initial partial pressure p_{A0} (Pa)')
ylabel('|d\theta/d(x/H)| at \theta = 0.5')
grid on




















































