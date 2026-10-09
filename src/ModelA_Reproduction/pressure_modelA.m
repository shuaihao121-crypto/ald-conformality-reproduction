function pA = pressure_modelA(t, x, p, pA_prev)
% PRESSURE_MODELA
% Calculate Reactant A partial pressure pA(x,t)
% for Model A.
%
% Inputs:
%   t        - current time, s
%   x        - spatial positions, m
%   p        - Model A parameter structure
%   pA_prev  - Reactant A pressure from previous time step, Pa
%
% Output:
%   pA       - Reactant A partial pressure at current time, Pa


%% Make sure x and pA_prev are column vectors

x = x(:);
pA_prev = pA_prev(:);


%% Basic transport quantities

% Hydraulic diameter
h = 2 / (1/p.H + 1/p.W);

% Average molecular speed of Reactant A
vA = sqrt(8*p.R*p.T / (pi*p.MA));

% Knudsen diffusion coefficient
DKn = h * sqrt(8*p.R*p.T / (9*pi*p.MA));

% Eq. (7): collision rate at unit pressure
Q = p.NA / sqrt(2*pi*p.MA*p.R*p.T);

% Adsorption equilibrium constant
K = p.c * Q / (p.q * p.Pd);


%% Initialize pressure vector

pA = zeros(size(x));


%% Calculate pressure at every spatial position

for i = 1:length(x)

    % Pressure from previous time step at this location
    pA_old = pA_prev(i);


    % Collision frequency of Reactant A
    zA = pi/4 * (p.dA + p.dI)^2 ...
        * sqrt(8*p.R*p.T/pi * (1/p.MA + 1/p.MI)) ...
        * p.pI*p.NA/(p.R*p.T) ...
        + pi*p.dA^2 ...
        * sqrt(16*p.R*p.T/(pi*p.MA)) ...
        * pA_old*p.NA/(p.R*p.T);


    % Gas-phase diffusion coefficient
    DA = 3*pi*vA^2 / (16*zA);


    % Eq. (2): effective diffusion coefficient
    Deff = 1 / (1/DA + 1/DKn);


    % Apparent longitudinal diffusion coefficient
    D = p.pA0 * p.H * Deff ...
        / (p.q * p.kB * p.T ...
        * (1 - log(K*p.pA0 + 1)/(K*p.pA0)));


    % Eq. (5): characteristic gas-front distance
    xs = sqrt(D*t);


    % Eq. (6): transition position
    aux = sqrt(h*p.NA*Deff ...
        / (4*p.R*p.T*p.c*Q));

    if xs > aux
        xt = xs - aux;
    else
        xt = 0;
    end


    % Eq. (4) or Eq. (8)-(9): local pressure
    if x(i) < xt

        % Eq. (4): linear region
        pA(i) = p.pA0 * (1 - x(i)/xs);

    else

        % Eq. (9)
        pt = p.pA0 * (1 - xt/xs);

        % Eq. (8): exponential region
        pA(i) = pt * exp(-(x(i)-xt)/(xs-xt));

    end

end

end












