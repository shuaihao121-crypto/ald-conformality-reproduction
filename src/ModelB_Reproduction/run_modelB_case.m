function result = run_modelB_case(p)
% RUN_MODELB_CASE
% Run one complete Model B simulation
%
% Input:
%   p - Model B parameter structure
%
% Output:
%   result.x_dim
%   result.theta
%   result.entrance_theta
%   result.x_half
%   result.slope_half
%   result.broadness
%   result.f0
%   result.t0
%   result.tau_end
%   result.n_steps

%% =========================================================
% 1. Build geometry
% ==========================================================

geom = geometry_modelB(p.AR, p.fs);

surface_idx = geom.surface_idx;

%% =========================================================
% 2. Gas impingement quantities
% ==========================================================

% Incident molecular flux at channel entrance
%
% f0 = NA*pA0 / sqrt(2*pi*MA*R*T)

f0 = p.NA * p.pA0 ...
    / sqrt(2*pi*p.MA*p.R*p.T);

% Characteristic physical time
%
% t0 = 1/(s0*f0)

t0 = 1 / (p.s0 * f0);

% Normalized final exposure time
%
% tau = t/t0 = s0*f0*t

tau_end = p.tend / t0;

%% =========================================================
% 3. Initial surface coverage
% ==========================================================

% theta contains:
% wall segments + closed end wall

theta = zeros(length(surface_idx),1);

tau = 0;

%% =========================================================
% 4. Adaptive time-step parameter
% ==========================================================

% Numerical parameter used by Machball implementation
% Adaptive-step numerical parameter
% Machball default: ep = 0.05

if isfield(p, 'ep')
    ep = p.ep;
else
    ep = 0.05;
end

%% =========================================================
% 5. Progress-output option
% ==========================================================

if isfield(p, 'show_progress')

    show_progress = p.show_progress;

else

    show_progress = true;

end

%% =========================================================
% 6. Time evolution
% ==========================================================

step = 0;

% Previous Markov solution is used as the initial guess
% for the next BiCGSTAB solve

r_guess = [];

while tau < tau_end

    step = step + 1;

    %% -----------------------------------------------------
    % Frozen-surface Markov transport
    %% -----------------------------------------------------

    out = markov_modelB( ...
        theta, ...
        p.beta0, ...
        geom, ...
        r_guess);

    % Reuse current solution in the next time step
    r_guess = out.r;

    %% -----------------------------------------------------
    % Available-site fraction
    %% -----------------------------------------------------

    av = 1 - theta;

    %% -----------------------------------------------------
    % Surface quantities
    %% -----------------------------------------------------

    r_surface = out.r(surface_idx);

    area_surface = geom.area(surface_idx);

    entry_area = geom.area(geom.entry_idx);

    %% -----------------------------------------------------
    % Normalized coverage-evolution coefficient
    %
    % k_i = (S0/Si)*beta0*r_i
    %% -----------------------------------------------------

    k = entry_area ...
        .* p.beta0 ...
        .* r_surface ...
        ./ area_surface;

    %% -----------------------------------------------------
    % Adaptive normalized time step
    %% -----------------------------------------------------

    max_k = max(k);

    if max_k <= 0 || ~isfinite(max_k)

        error('Invalid Model B evolution coefficient max(k).')

    end

    dtau = ep / max_k;

    %% -----------------------------------------------------
    % Do not step past final exposure time
    %% -----------------------------------------------------

    if tau + dtau > tau_end

        dtau = tau_end - tau;

    end

    %% -----------------------------------------------------
    % Implicit update
    %
    % av_new = av_old/(1 + k*dtau)
    %% -----------------------------------------------------

    av = av ./ (1 + k .* dtau);

    theta = 1 - av;

    tau = tau + dtau;

    %% -----------------------------------------------------
    % Progress display
    %% -----------------------------------------------------

    if show_progress && mod(step,500) == 0

        fprintf( ...
            'Step %d, %.1f%% complete\n', ...
            step, ...
            100*tau/tau_end)

    end

end

%% =========================================================
% 7. Physical validity checks
% ==========================================================

if any(~isfinite(theta))

    error('Model B produced NaN or Inf coverage values.')

end

if any(theta < -1e-12) || any(theta > 1+1e-12)

    warning('Coverage outside physical range [0,1].')

end

%% =========================================================
% 8. Dimensionless spatial coordinates
% ==========================================================

x_dim = geom.x_dim;

%% =========================================================
% 9. Half-coverage penetration depth
% ==========================================================

idx05 = find(theta <= 0.5, 1, 'first');

if ~isempty(idx05) && idx05 > 1

    x1 = x_dim(idx05-1);
    x2 = x_dim(idx05);

    th1 = theta(idx05-1);
    th2 = theta(idx05);

    % Linear interpolation to theta = 0.5

    x_half = ...
        x1 ...
        + (0.5-th1) ...
        * (x2-x1) ...
        / (th2-th1);

    % Absolute slope around half coverage

    slope_half = ...
        abs((th2-th1)/(x2-x1));

else

    x_half = NaN;
    slope_half = NaN;

end

%% =========================================================
% 10. Adsorption-front broadness
% ==========================================================

% Same extraction definition as Model A:
%
% first point theta < 0.9
% first point theta < 0.1

idx09 = find(theta < 0.9, 1, 'first');
idx01 = find(theta < 0.1, 1, 'first');

if ~isempty(idx09) && ~isempty(idx01)

    broadness = ...
        x_dim(idx01) ...
        - x_dim(idx09);

else

    broadness = NaN;

end

%% =========================================================
% 11. Return results
% ==========================================================

result.x_dim = x_dim;
result.theta = theta;

result.entrance_theta = theta(1);
result.end_theta = theta(end);

result.x_half = x_half;
result.slope_half = slope_half;
result.broadness = broadness;

result.f0 = f0;
result.t0 = t0;
result.tau_end = tau_end;

result.n_steps = step;

end