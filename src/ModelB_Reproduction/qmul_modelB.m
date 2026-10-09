function y = qmul_modelB(v, geom)
% QMUL_MODELB
%
% Compute y = q*v without explicitly storing the dense q matrix.
%
% Wall-wall part is evaluated using FFT Toeplitz multiplication.

Nseg = geom.Nseg;

entry_idx = geom.entry_idx;
wall_idx  = geom.wall_idx;
end_idx   = geom.end_idx;

%% Split vector

v_entry = v(entry_idx);
v_wall  = v(wall_idx);
v_end   = v(end_idx);

%% =========================================================
% Wall-wall Toeplitz multiplication using FFT
%% ==========================================================

vpad = [v_wall; zeros(Nseg,1)];

tmp = ifft( ...
    geom.wall_kernel_fft .* fft(vpad));

wall_offdiag = real(tmp(1:Nseg));

%% Add self-view contribution

wall_total = ...
    wall_offdiag ...
    + geom.self_view .* v_wall;

%% =========================================================
% Assemble result q*v
%% ==========================================================

y = zeros(Nseg+2,1);

% Target: entrance
y(entry_idx) = ...
    geom.wall_to_entry' * v_wall ...
    + geom.q_entry_end * v_end;

% Target: wall segments
y(wall_idx) = ...
    geom.entry_to_wall .* v_entry ...
    + wall_total ...
    + geom.end_to_wall .* v_end;

% Target: closed end wall
y(end_idx) = ...
    geom.q_end_entry * v_entry ...
    + geom.wall_to_end' * v_wall;

end