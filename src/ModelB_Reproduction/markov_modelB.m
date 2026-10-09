function out = markov_modelB(theta, beta0, geom, r_guess)
% MARKOV_MODELB
% Frozen-surface Markov transport solver

if nargin < 4
    r_guess = [];
end

N = geom.N;

surface_idx = geom.surface_idx;
entry_idx = geom.entry_idx;
end_idx = geom.end_idx;

%% =========================================================
% Current sticking probabilities
%% ==========================================================

sprob = zeros(N,1);

% Entrance = absorbing exit state
sprob(entry_idx) = 1;

beta = beta0 .* (1 - theta);

sprob(surface_idx) = beta;

nonreact = 1 - sprob;

%% =========================================================
% Initial collision distribution after entry
%% ==========================================================

p_in = zeros(N,1);

p_in(geom.wall_idx) = geom.entry_to_wall;
p_in(end_idx) = geom.q_end_entry;

%% =========================================================
% Solve:
%
% (I-Q)r = p_in
%
% Q*x = q * (nonreact .* x)
%% ==========================================================

if ~isempty(geom.q)

    % Small system: exact dense solution

    Q = geom.q .* nonreact';

    r = (eye(N) - Q) \ p_in;

    flag = 0;
    relres = 0;
    iter = 0;

else

    % Large system: FFT matrix-free iterative solution

    Afun = @(x) ...
        x - qmul_modelB(nonreact .* x, geom);

    tol = 1e-9;
    maxit = 500;

    if isempty(r_guess)
        r_guess = p_in;
    end

    [r, flag, relres, iter] = bicgstab( ...
        Afun, ...
        p_in, ...
        tol, ...
        maxit, ...
        [], ...
        [], ...
        r_guess);

    if flag ~= 0

        warning( ...
            ['BiCGSTAB did not fully converge. ' ...
             'flag = %d, relres = %.3e'], ...
             flag, relres)

    end

end

%% =========================================================
% Absorption probabilities
%% ==========================================================

P_all = sprob .* r;

P_exit = P_all(entry_idx);
P_ads  = P_all(surface_idx);

prob_sum = ...
    P_exit + sum(P_ads);

%% Return

out.beta = beta;

out.p_in = p_in;
out.r = r;

out.P_ads = P_ads;
out.P_exit = P_exit;

out.prob_sum = prob_sum;

out.solver_flag = flag;
out.solver_relres = relres;
out.solver_iter = iter;

end