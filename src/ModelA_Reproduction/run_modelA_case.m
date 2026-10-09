function result = run_modelA_case(p)
% RUN_MODELA_CASE
% Run one complete Model A simulation
%
% Input:
%   p - parameter structure
%
% Output:
%   result.x
%   result.x_dim
%   result.theta
%   result.entrance_theta
%   result.x_half
%   result.slope_half
%   result.broadness


%% =========================================================
% Spatial grid
% ==========================================================

AR = p.L / p.H;
Nx = round(p.fp * AR);

x = linspace(0, p.L, Nx)';


%% =========================================================
% Initial surface coverage
% ==========================================================

theta0 = zeros(Nx,1);


%% =========================================================
% Reset pressure history
% ==========================================================

clear modelA_rhs


%% =========================================================
% Integration start time
% ==========================================================

% Default value based on public DReaM-ALD implementation
if isfield(p, 'tstart')
    tstart = p.tstart;
else
    tstart = 1e-3;
end

% Check that start time is smaller than exposure time
if tstart >= p.tend
    error('tstart must be smaller than tend.')
end


%% =========================================================
% Integration time span
% ==========================================================

% Keep 0.05 s intermediate output when possible
if p.tend > 0.05 && tstart < 0.05

    tspan = [tstart 0.05 p.tend];

else

    tspan = [tstart p.tend];

end


%% =========================================================
% Solve Model A with ode23
% ==========================================================

[~, theta_sol] = ode23( ...
    @(t,theta) modelA_rhs(t,theta,x,p), ...
    tspan, ...
    theta0);

theta = theta_sol(end,:)';


%% =========================================================
% Dimensionless distance
% ==========================================================

x_dim = x / p.H;


%% =========================================================
% Half-coverage penetration depth and slope
% ==========================================================

idx05 = find(theta <= 0.5, 1, 'first');

if ~isempty(idx05) && idx05 > 1

    x1 = x_dim(idx05-1);
    x2 = x_dim(idx05);

    th1 = theta(idx05-1);
    th2 = theta(idx05);

    % Linear interpolation to theta = 0.5
    x_half = x1 ...
        + (0.5-th1)*(x2-x1)/(th2-th1);

    % Absolute slope using the two points around theta = 0.5
    slope_half = abs((th2-th1)/(x2-x1));

else

    x_half = NaN;
    slope_half = NaN;

end


%% =========================================================
% Adsorption-front broadness
% ==========================================================

% Paper definition:
% first point where theta < 0.9
% first point where theta < 0.1

idx09 = find(theta < 0.9, 1, 'first');
idx01 = find(theta < 0.1, 1, 'first');

if ~isempty(idx09) && ~isempty(idx01)

    broadness = x_dim(idx01) - x_dim(idx09);

else

    broadness = NaN;

end


%% =========================================================
% Return results
% ==========================================================

result.x = x;
result.x_dim = x_dim;
result.theta = theta;

result.entrance_theta = theta(1);

result.x_half = x_half;
result.slope_half = slope_half;
result.broadness = broadness;

end