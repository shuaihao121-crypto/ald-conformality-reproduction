function dtheta = modelA_rhs(t, theta, x, p)
% MODELA_RHS
% Right-hand side of Model A surface coverage ODE
%
% Eq. (15)/(16):
% dtheta/dt = c*Q*pA/q * (1-theta) - Pd*theta

% Make vectors column vectors
theta = theta(:);
x = x(:);

% Remember pressure from previous ODE evaluation
persistent pA

if isempty(pA)
    % Initial gas pressure inside the channel
    pA_prev = zeros(size(x));
else
    pA_prev = pA;
end

% Calculate current Reactant A pressure
pA = pressure_modelA(t, x, p, pA_prev);

% Eq. (7): collision rate at unit pressure
Q = p.NA / sqrt(2*pi*p.MA*p.R*p.T);

% Eq. (16): surface coverage evolution
dtheta = (p.c * Q .* pA / p.q) .* (1 - theta) ...
         - p.Pd .* theta;

end