function p = parameters_modelA()
% PARAMETERS_MODELA
% Baseline parameters for Model A
% Based on Table 2 of the paper

%% ---------- Physical constants ----------

p.R  = 8.314462618;      % Gas constant, J/(mol*K)
p.NA = 6.02214076e23;    % Avogadro constant, 1/mol
p.kB = 1.380649e-23;     % Boltzmann constant, J/K


%% ---------- Process parameters ----------

p.T    = 573.15;         % Temperature, K
p.pA0  = 10;             % Reactant A inlet partial pressure, Pa
p.pI   = 0;              % Inert gas partial pressure, Pa
p.tend = 1;              % Exposure duration, s


%% ---------- Molecular parameters ----------

p.MA    = 0.1;           % Reactant A molar mass, kg/mol
p.MI    = 0.028;         % Inert gas molar mass, kg/mol
p.Mfilm = 0.05;          % Film molar mass, kg/mol

p.dA = 0.6e-9;           % Reactant A molecular diameter, m
p.dI = 0.4e-9;           % Inert gas molecular diameter, m


%% ---------- Surface reaction parameters ----------

p.c  = 1e-3;             % Sticking coefficient, dimensionless
p.Pd = 1e-4;             % Desorption probability, 1/s

% Paper value: q = 4 nm^-2
% 1 nm^-2 = 1e18 m^-2
p.q = 4e18;              % Saturation adsorption capacity, 1/m^2


%% ---------- Film parameters ----------

p.rho   = 3500;          % Film density, kg/m^3
p.bA    = 1;             % Metal atoms per Reactant A molecule
p.bfilm = 1;             % Metal atoms per film formula unit


%% ---------- Channel geometry ----------

p.H = 0.5e-6;            % Channel height, m
p.W = 0.01;              % Channel width, m
p.L = 500e-6;            % Channel length, m

p.fp = 2;                % Discretization points per aspect-ratio unit

end