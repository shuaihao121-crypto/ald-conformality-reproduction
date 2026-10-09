clear
clc
close all

%% =========================================================
% MODEL A vs MODEL B
% Reproduction of Fig. 6 parity plots
%
% Panel (a): half-coverage penetration depth
% Panel (b): absolute slope at half coverage
% Panel (c): adsorption-front broadness
%
% Model A is recalculated here.
% Model B values are copied from the completed Model B scan.
%% ==========================================================

p0 = parameters_modelA();


%% =========================================================
% 1. Parameter definitions
%% ==========================================================

% Case I: Temperature
values{1} = ...
    [373.15 473.15 573.15 673.15 773.15];

% Case II: Pressure
values{2} = ...
    [1 2.5 5 10 20];

% Case III: Molar mass
values{3} = ...
    [0.05 0.1 0.15 0.2 0.25];

% Case IV: Channel height
% L = 500 um
% corresponding AR = [4000 2000 1000 500 250]
values{4} = ...
    [0.125 0.25 0.5 1 2] * 1e-6;

% Case V: Exposure duration
values{5} = ...
    [0.01 0.1 1 10 100];

% Case VI: Sticking coefficient
values{6} = ...
    [1 0.1 0.01 0.001 1e-4 1e-5];

% Case VII: Model A adsorption capacity q
% Corresponding Model B s0:
% [2 1 0.5 0.25 0.125] nm^2
values{7} = ...
    [0.5 1 2 4 8] * 1e18;

% Case VIII: Constant exposure
pA0_case8 = ...
    [0.08 0.4 2 10 50];

tend_case8 = ...
    [125 25 5 1 0.2];


%% =========================================================
% 2. Run Model A - Cases I-VII
%% ==========================================================

A_results = cell(8,1);

fprintf('========================================\n')
fprintf('Running Model A for A/B comparison\n')
fprintf('========================================\n')

for case_id = 1:7

    n = length(values{case_id});

    A_results{case_id} = cell(n,1);

    fprintf('\nCase %d\n', case_id)

    for k = 1:n

        p = p0;

        switch case_id

            case 1
                p.T = values{1}(k);

            case 2
                p.pA0 = values{2}(k);

            case 3
                p.MA = values{3}(k);

            case 4
                p.H = values{4}(k);

            case 5
                p.tend = values{5}(k);

            case 6
                p.c = values{6}(k);

            case 7
                p.q = values{7}(k);

        end

        r = run_modelA_case(p);

        A_results{case_id}{k} = r;

        fprintf( ...
            ['Run %d: entrance = %.6f, ' ...
             'xhalf = %.3f, slope = %.6f, ' ...
             'broadness = %.3f\n'], ...
             k, ...
             r.entrance_theta, ...
             r.x_half, ...
             r.slope_half, ...
             r.broadness)

    end

end


%% =========================================================
% 3. Run Model A - Case VIII
%% ==========================================================

A_results{8} = cell(5,1);

fprintf('\nCase VIII: Constant exposure\n')

for k = 1:5

    p = p0;

    p.pA0 = pA0_case8(k);

    p.tend = tend_case8(k);

    r = run_modelA_case(p);

    A_results{8}{k} = r;

    fprintf( ...
        ['pA0 = %.2f Pa, tend = %.2f s, ' ...
         'xhalf = %.6f\n'], ...
         p.pA0, ...
         p.tend, ...
         r.x_half)

end


%% =========================================================
% 4. Extract Model A values
%% ==========================================================

A_xhalf = cell(8,1);
A_slope = cell(8,1);
A_broad = cell(8,1);

A_valid4 = cell(8,1);
A_valid5 = cell(8,1);

% Week2 Model A screening criterion
sat_tol_A = 1e-3;
threshold_A = 1 - sat_tol_A;


for case_id = 1:8

    n = length(A_results{case_id});

    A_xhalf{case_id} = NaN(1,n);
    A_slope{case_id} = NaN(1,n);
    A_broad{case_id} = NaN(1,n);

    A_valid4{case_id} = false(1,n);
    A_valid5{case_id} = false(1,n);


    for k = 1:n

        r = A_results{case_id}{k};

        entrance_saturated = ...
            r.entrance_theta >= threshold_A;

        whole_channel_saturated = ...
            min(r.theta) >= threshold_A;


        % Fig. 4 validity
        A_valid4{case_id}(k) = ...
            entrance_saturated ...
            && ~whole_channel_saturated ...
            && isfinite(r.x_half) ...
            && isfinite(r.slope_half);


        if A_valid4{case_id}(k)

            A_xhalf{case_id}(k) = ...
                r.x_half;

            A_slope{case_id}(k) = ...
                r.slope_half;

        end


        % Fig. 5 validity
        A_valid5{case_id}(k) = ...
            entrance_saturated ...
            && min(r.theta) < 0.1 ...
            && isfinite(r.broadness);


        if A_valid5{case_id}(k)

            A_broad{case_id}(k) = ...
                r.broadness;

        end

    end

end


%% =========================================================
% 5. Model B completed results
%% ==========================================================

% ---------------------------------------------------------
% Case I: Temperature
% ---------------------------------------------------------

B_xhalf{1} = ...
    [418.0022 390.4591 369.4309 352.5856 338.6306];

B_slope{1} = ...
    [0.005070 0.005111 0.005144 0.005177 0.005196];

B_broad{1} = ...
    [233.50 230.25 228.00 225.75 224.25];

B_valid4{1} = ...
    [1 1 1 1 1];

B_valid5{1} = ...
    [1 1 1 1 1];


% ---------------------------------------------------------
% Case II: Pressure
% ---------------------------------------------------------

B_xhalf{2} = ...
    [75.9084 156.7736 244.7839 369.4309 548.2682];

B_slope{2} = ...
    [0.006091 0.005668 0.005398 0.005144 0.004900];

B_broad{2} = ...
    [180.00 198.25 211.75 228.00 250.75];

B_valid4{2} = ...
    [0 1 1 1 1];

B_valid5{2} = ...
    [0 1 1 1 1];


% ---------------------------------------------------------
% Case III: Molar mass
% ---------------------------------------------------------

B_xhalf{3} = ...
    [450.7073 369.4309 328.2710 301.5770 282.1881];

B_slope{3} = ...
    [0.005023 0.005144 0.005219 0.005272 0.005309];

B_broad{3} = ...
    [237.50 228.00 223.00 219.50 217.00];

B_valid4{3} = ...
    [1 1 1 1 1];

B_valid5{3} = ...
    [1 1 1 1 1];


% ---------------------------------------------------------
% Case IV: Aspect ratio
% AR = [4000 2000 1000 500 250]
% ---------------------------------------------------------

B_xhalf{4} = ...
    [369.3950 369.3970 369.4309 379.8159 NaN];

B_slope{4} = ...
    [0.005145 0.005145 0.005144 0.003973 NaN];

B_broad{4} = ...
    [227.75 227.75 228.00 NaN NaN];

B_valid4{4} = ...
    [1 1 1 1 0];

B_valid5{4} = ...
    [1 1 1 0 0];


% ---------------------------------------------------------
% Case V: Exposure time
% ---------------------------------------------------------

B_xhalf{5} = ...
    [NaN NaN 369.4309 NaN NaN];

B_slope{5} = ...
    [NaN NaN 0.005144 NaN NaN];

B_broad{5} = ...
    [NaN NaN 228.00 NaN NaN];

B_valid4{5} = ...
    [0 0 1 0 0];

B_valid5{5} = ...
    [0 0 1 0 0];


% ---------------------------------------------------------
% Case VI: Sticking coefficient
% ---------------------------------------------------------

B_xhalf{6} = ...
    [373.4027 376.1530 377.5871 369.4309 NaN NaN];

B_slope{6} = ...
    [0.070074 0.036456 0.014592 0.005144 NaN NaN];

B_broad{6} = ...
    [70.00 75.00 102.50 228.00 NaN NaN];

B_valid4{6} = ...
    [1 1 1 1 0 0];

B_valid5{6} = ...
    [1 1 1 1 0 0];


% ---------------------------------------------------------
% Case VII: surface site area
% Model B s0 = [2 1 0.5 0.25 0.125] nm^2
% ---------------------------------------------------------

B_xhalf{7} = ...
    [NaN 814.6347 548.2682 369.4309 244.7839];

B_slope{7} = ...
    [NaN 0.003865 0.004900 0.005144 0.005398];

B_broad{7} = ...
    [NaN NaN 250.75 228.00 211.75];

B_valid4{7} = ...
    [0 1 1 1 1];

B_valid5{7} = ...
    [0 0 1 1 1];


% ---------------------------------------------------------
% Case VIII: Constant exposure
% ---------------------------------------------------------

B_xhalf{8} = ...
    369.430945364 * ones(1,5);

B_slope{8} = ...
    0.005144 * ones(1,5);

B_broad{8} = ...
    228.00 * ones(1,5);

B_valid4{8} = ...
    [1 1 1 1 1];

B_valid5{8} = ...
    [1 1 1 1 1];


%% =========================================================
% 6. Assemble parity-plot data
%
% Only use a point when BOTH Model A and Model B
% satisfy the extraction conditions.
%% ==========================================================

markers = ...
    {'s','o','^','v','<','>','d','+'};

case_labels = {
    'I, T'
    'II, p_{A0}'
    'III, M_A'
    'IV, H'
    'V, t_{end}'
    'VI, c'
    'VII, q / s_0'
    'VIII, p_{A0}t_{end}'
};


%% =========================================================
% FIGURE 6
%% ==========================================================

figure

tiledlayout(3,1)


%% =========================================================
% Fig. 6(a): Half-coverage penetration depth
%% ==========================================================

nexttile

hold on

for case_id = 1:8

    valid = ...
        logical(A_valid4{case_id}) ...
        & logical(B_valid4{case_id}) ...
        & isfinite(A_xhalf{case_id}) ...
        & isfinite(B_xhalf{case_id});


    plot( ...
        B_xhalf{case_id}(valid), ...
        A_xhalf{case_id}(valid), ...
        markers{case_id}, ...
        'LineStyle','none', ...
        'MarkerSize',7, ...
        'LineWidth',1.5, ...
        'DisplayName',case_labels{case_id})

end

plot( ...
    [0 1000], ...
    [0 1000], ...
    '--', ...
    'HandleVisibility','off')

hold off

xlabel('Model B, x_{0.5}')
ylabel('Model A, x_{0.5}')

title('(a) Half-coverage penetration depth')

xlim([0 1000])
ylim([0 1000])

axis square
grid on

legend('Location','northwest')


%% =========================================================
% Fig. 6(b): Slope
%% ==========================================================

nexttile

hold on

for case_id = 1:8

    valid = ...
        logical(A_valid4{case_id}) ...
        & logical(B_valid4{case_id}) ...
        & isfinite(A_slope{case_id}) ...
        & isfinite(B_slope{case_id}) ...
        & A_slope{case_id} > 0 ...
        & B_slope{case_id} > 0;


    loglog( ...
        B_slope{case_id}(valid), ...
        A_slope{case_id}(valid), ...
        markers{case_id}, ...
        'LineStyle','none', ...
        'MarkerSize',7, ...
        'LineWidth',1.5, ...
        'DisplayName',case_labels{case_id})

end

loglog( ...
    [1e-3 1], ...
    [1e-3 1], ...
    '--', ...
    'HandleVisibility','off')

hold off

xlabel('Model B, |slope| at \theta = 0.5')
ylabel('Model A, |slope| at \theta = 0.5')

title('(b) Absolute slope at half coverage')

xlim([1e-3 1])
ylim([1e-3 1])

axis square
grid on

legend('Location','southeast')


%% =========================================================
% Fig. 6(c): Adsorption-front broadness
%% ==========================================================

nexttile

hold on

for case_id = 1:8

    valid = ...
        logical(A_valid5{case_id}) ...
        & logical(B_valid5{case_id}) ...
        & isfinite(A_broad{case_id}) ...
        & isfinite(B_broad{case_id});


    plot( ...
        B_broad{case_id}(valid), ...
        A_broad{case_id}(valid), ...
        markers{case_id}, ...
        'LineStyle','none', ...
        'MarkerSize',7, ...
        'LineWidth',1.5, ...
        'DisplayName',case_labels{case_id})

end

plot( ...
    [0 260], ...
    [0 260], ...
    '--', ...
    'HandleVisibility','off')

hold off

xlabel('Model B, x_{0.1} - x_{0.9}')
ylabel('Model A, x_{0.1} - x_{0.9}')

title('(c) Adsorption-front broadness')

xlim([0 260])
ylim([0 260])

axis square
grid on

legend('Location','northwest')


%% =========================================================
% 7. Quantitative A/B summary
%% ==========================================================

penetration_ratio = [];
slope_ratio = [];
broadness_ratio = [];


for case_id = 1:8

    %% Penetration

    valid = ...
        logical(A_valid4{case_id}) ...
        & logical(B_valid4{case_id}) ...
        & isfinite(A_xhalf{case_id}) ...
        & isfinite(B_xhalf{case_id});

    penetration_ratio = ...
        [penetration_ratio, ...
         B_xhalf{case_id}(valid) ...
         ./ A_xhalf{case_id}(valid)];


    %% Slope

    valid = ...
        logical(A_valid4{case_id}) ...
        & logical(B_valid4{case_id}) ...
        & isfinite(A_slope{case_id}) ...
        & isfinite(B_slope{case_id});

    slope_ratio = ...
        [slope_ratio, ...
         A_slope{case_id}(valid) ...
         ./ B_slope{case_id}(valid)];


    %% Broadness

    valid = ...
        logical(A_valid5{case_id}) ...
        & logical(B_valid5{case_id}) ...
        & isfinite(A_broad{case_id}) ...
        & isfinite(B_broad{case_id});

    broadness_ratio = ...
        [broadness_ratio, ...
         B_broad{case_id}(valid) ...
         ./ A_broad{case_id}(valid)];

end


fprintf('\n\n')
fprintf('========================================\n')
fprintf('MODEL A / MODEL B COMPARISON\n')
fprintf('========================================\n')

fprintf( ...
    'Valid penetration pairs = %d\n', ...
    length(penetration_ratio))

fprintf( ...
    'Mean B/A penetration ratio = %.4f\n', ...
    mean(penetration_ratio))

fprintf( ...
    'Mean penetration increase of Model B = %.2f %%\n', ...
    100*(mean(penetration_ratio)-1))


fprintf('\n')

fprintf( ...
    'Valid slope pairs = %d\n', ...
    length(slope_ratio))

fprintf( ...
    'Mean A/B slope ratio = %.4f\n', ...
    mean(slope_ratio))


fprintf('\n')

fprintf( ...
    'Valid broadness pairs = %d\n', ...
    length(broadness_ratio))

fprintf( ...
    'Mean B/A broadness ratio = %.4f\n', ...
    mean(broadness_ratio))


%% =========================================================
% End
%% =========================================================