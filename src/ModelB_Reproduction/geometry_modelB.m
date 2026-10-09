function geom = geometry_modelB(AR, fs)
% GEOMETRY_MODELB
% Efficient geometry representation for Model B.
%
% Convention:
% q(j,i) = probability FROM state i TO state j

%% Basic geometry

Nseg = round(AR * fs);
dh = AR / Nseg;

N = Nseg + 2;

entry_idx = 1;
wall_idx  = 2:(Nseg+1);
end_idx   = N;

%% Relative surface areas

area = zeros(N,1);

area(entry_idx) = 1;
area(wall_idx)  = 2*dh;
area(end_idx)   = 1;

%% =========================================================
% Cross-section factor F(d)
% d = 0,1,...,Nseg
%% ==========================================================

d = (0:Nseg)';
z = dh .* d;

F = 1 ./ (z + sqrt(1 + z.^2));
F(1) = 1;

%% =========================================================
% Entrance / end-wall coupling
%% ==========================================================

entry_to_wall = F(1:Nseg) - F(2:Nseg+1);
end_to_wall   = flipud(entry_to_wall);

wall_to_entry = entry_to_wall ./ (2*dh);
wall_to_end   = end_to_wall   ./ (2*dh);

q_end_entry = 1 - sum(entry_to_wall);
q_entry_end = 1 - sum(end_to_wall);

%% =========================================================
% Wall-to-wall off-diagonal view factors
%
% g(d) for distance d = 1,...,Nseg-1
%% ==========================================================

if Nseg > 1

    g = ...
        (F(1:Nseg-1) ...
       - 2*F(2:Nseg) ...
       + F(3:Nseg+1)) ...
       ./ (2*dh);

else

    g = [];

end

%% =========================================================
% Wall self-view factor
%% ==========================================================

cs = [0; cumsum(g)];

i = (1:Nseg)';

offsum = ...
    cs(i) ...
    + cs(Nseg - i + 1);

self_view = ...
    1 ...
    - wall_to_entry ...
    - wall_to_end ...
    - offsum;

%% =========================================================
% FFT representation of wall-wall Toeplitz matrix
%
% Off-diagonal matrix has first column:
% [0, g1, g2, ...]'
%% ==========================================================

first_col = [0; g];

circ_col = ...
    [first_col; ...
     0; ...
     flipud(first_col(2:end))];

wall_kernel_fft = fft(circ_col);

%% =========================================================
% Spatial coordinates
%% ==========================================================

x_wall = ((0:Nseg-1)' + 0.5) * dh;

x_dim = [x_wall; AR];

%% =========================================================
% Small-system dense q matrix
%
% Only construct it for debugging.
% Never construct 4000x4000 q explicitly.
%% ==========================================================

if Nseg <= 200

    q = zeros(N,N);

    q(wall_idx,entry_idx) = entry_to_wall;
    q(end_idx,entry_idx) = q_end_entry;

    q(wall_idx,end_idx) = end_to_wall;
    q(entry_idx,end_idx) = q_entry_end;

    q(entry_idx,wall_idx) = wall_to_entry';
    q(end_idx,wall_idx) = wall_to_end';

    wall_q = toeplitz(first_col);

    wall_q = ...
        wall_q ...
        + diag(self_view);

    q(wall_idx,wall_idx) = wall_q;

else

    q = [];

end

%% Return

geom.AR = AR;
geom.fs = fs;

geom.Nseg = Nseg;
geom.N = N;

geom.dh = dh;
geom.area = area;

geom.entry_idx = entry_idx;
geom.wall_idx = wall_idx;
geom.end_idx = end_idx;
geom.surface_idx = 2:N;

geom.x_dim = x_dim;

geom.entry_to_wall = entry_to_wall;
geom.end_to_wall = end_to_wall;

geom.wall_to_entry = wall_to_entry;
geom.wall_to_end = wall_to_end;

geom.q_end_entry = q_end_entry;
geom.q_entry_end = q_entry_end;

geom.self_view = self_view;
geom.wall_kernel_fft = wall_kernel_fft;

geom.q = q;

end