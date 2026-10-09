function p = parameters_modelB()
% PARAMETERS_MODELB
% Baseline physical parameters for Model B

%% Physical constants
p.R  = 8.314462618;
p.NA = 6.02214076e23;
p.kB = 1.380649e-23;

%% Process parameters
p.T    = 573.15;     % K
p.pA0  = 10;         % Pa
p.tend = 1;          % s

%% Reactant
p.MA = 0.1;          % kg/mol

%% Surface reaction
p.beta0 = 1e-3;
p.s0    = 0.25e-18;  % 0.25 nm^2 -> m^2

%% Geometry - final paper baseline
p.AR = 1000;
p.fs = 4;

end