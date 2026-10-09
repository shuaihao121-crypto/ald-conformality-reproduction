clear
clc
close all

p0 = parameters_modelA();


%% =========================================================
% Case definitions from Table 2
% ==========================================================

case_names = {
    'Temperature T'
    'Pressure pA0'
    'Molar mass MA'
    'Aspect ratio L/H'
    'Exposure time tend'
    'Sticking coefficient c'
    'Average surface site area s0'
    'Constant dose'
};


% Case I: Temperature
values{1} = [373.15 473.15 573.15 673.15 773.15];

% Case II: Reactant A inlet pressure
values{2} = [1 2.5 5 10 20];

% Case III: Reactant A molar mass
values{3} = [0.05 0.1 0.15 0.2 0.25];

% Case IV: Channel height
values{4} = [0.125 0.25 0.5 1 2] * 1e-6;

% Case V: Exposure duration
values{5} = [0.01 0.1 1 10 100];

% Case VI: Sticking coefficient
values{6} = [1 0.1 0.01 0.001 0.0001 0.00001];

% Case VII: Adsorption capacity
values{7} = [0.5 1 2 4 8] * 1e18;


% Case VIII: constant dose
pA0_case8 = [0.08 0.4 2 10 50];
tend_case8 = [125 25 5 1 0.2];


%% =========================================================
% Run Cases I-VII
% ==========================================================

results = cell(8,1);

for case_id = 1:7

    n = length(values{case_id});
    results{case_id} = cell(n,1);

    fprintf('\n========================================\n')
    fprintf('Running Case %d: %s\n', ...
        case_id, case_names{case_id})
    fprintf('========================================\n')

    for k = 1:n

        p = p0;

        switch case_id

            case 1
                p.T = values{case_id}(k);

            case 2
                p.pA0 = values{case_id}(k);

            case 3
                p.MA = values{case_id}(k);

            case 4
                p.H = values{case_id}(k);

            case 5
                p.tend = values{case_id}(k);

            case 6
                p.c = values{case_id}(k);

            case 7
                p.q = values{case_id}(k);

        end


        r = run_modelA_case(p);

        results{case_id}{k} = r;


        fprintf(['Run %d: entrance = %.6f, ' ...
                 'x_half = %.3f, slope = %.6f, ' ...
                 'broadness = %.3f\n'], ...
                 k, ...
                 r.entrance_theta, ...
                 r.x_half, ...
                 r.slope_half, ...
                 r.broadness)

    end
end


%% =========================================================
% Run Case VIII: constant dose
% ==========================================================

results{8} = cell(length(pA0_case8),1);

fprintf('\n========================================\n')
fprintf('Running Case VIII: Constant dose\n')
fprintf('========================================\n')

for k = 1:length(pA0_case8)

    p = p0;

    p.pA0 = pA0_case8(k);
    p.tend = tend_case8(k);

    r = run_modelA_case(p);

    results{8}{k} = r;


    fprintf(['pA0 = %7.2f Pa, tend = %7.2f s, ' ...
             'dose = %7.2f Pa*s, x_half = %.3f\n'], ...
             p.pA0, ...
             p.tend, ...
             p.pA0*p.tend, ...
             r.x_half)

end


%% =========================================================
% Fig. 3 - Model A saturation profiles
% ==========================================================

figure
tiledlayout(4,2)

for case_id = 1:8

    nexttile
    hold on


    if case_id <= 7

        for k = 1:length(results{case_id})

            r = results{case_id}{k};

            % Case IV uses normalized distance x/L
            if case_id == 4

                x_plot = r.x / r.x(end);

            else

                x_plot = r.x_dim;

            end

            plot(x_plot, r.theta, ...
                'LineWidth', 1.2)

        end

    else

        for k = 1:length(results{8})

            r = results{8}{k};

            plot(r.x_dim, r.theta, ...
                'LineWidth', 1.2)

        end

    end


    hold off

    ylim([0 1.05])

    ylabel('Surface coverage \theta')
    title(case_names{case_id})

    if case_id == 4
        xlabel('Normalized distance x/L')
    else
        xlabel('Dimensionless distance x/H')
    end

    grid on

end


%% =========================================================
% Prepare x-axis values for Fig. 4 and Fig. 5
% ==========================================================

xdata = cell(8,1);

% I: temperature
xdata{1} = values{1};

% II: inlet partial pressure
xdata{2} = values{2};

% III: molar mass
xdata{3} = values{3};

% IV: aspect ratio L/H
xdata{4} = p0.L ./ values{4};

% V: exposure duration
xdata{5} = values{5};

% VI: sticking coefficient
xdata{6} = values{6};

% VII:
% q is stored in m^-2
% convert q to nm^-2 first
q_nm2 = values{7} / 1e18;

% s0 = 1/q, unit nm^2
xdata{7} = 1 ./ q_nm2;

% VIII: exposure = pA0 * tend
xdata{8} = pA0_case8 .* tend_case8;


%% =========================================================
% Extract Fig. 4 and Fig. 5 data
% ==========================================================

xhalf_all = cell(8,1);
slope_all = cell(8,1);
broad_all = cell(8,1);


% Numerical tolerance for saturation
sat_tol = 1e-3;


for case_id = 1:8

    n = length(results{case_id});

    xhalf = NaN(1,n);
    slope = NaN(1,n);
    broad = NaN(1,n);


    for k = 1:n

        r = results{case_id}{k};


        %% Fig. 4 validity

        entrance_saturated = ...
            r.entrance_theta >= (1 - sat_tol);

        whole_channel_saturated = ...
            min(r.theta) >= (1 - sat_tol);


        if entrance_saturated && ...
                ~whole_channel_saturated

            xhalf(k) = r.x_half;
            slope(k) = r.slope_half;

        end


        %% Fig. 5 validity

        if entrance_saturated && ...
                min(r.theta) < 0.1

            broad(k) = r.broadness;

        end

    end


    xhalf_all{case_id} = xhalf;
    slope_all{case_id} = slope;
    broad_all{case_id} = broad;

end


%% =========================================================
% Fig. 4 - Model A extracted parameters
% ==========================================================

figure
tiledlayout(4,2)

for case_id = 1:8

    nexttile


    % Sort x-axis for clean presentation
    [x_sorted, idx_sort] = sort(xdata{case_id});

    xhalf_sorted = xhalf_all{case_id}(idx_sort);
    slope_sorted = slope_all{case_id}(idx_sort);


    yyaxis left

    plot(x_sorted, ...
         xhalf_sorted, ...
         'o-', ...
         'LineWidth', 1.2)

    ylabel('Half-coverage penetration depth')


    yyaxis right

    plot(x_sorted, ...
         slope_sorted, ...
         'o-', ...
         'LineWidth', 1.2)

    ylabel('|slope| at \theta = 0.5')


    xlabel(case_names{case_id})
    title(case_names{case_id})

    grid on

end


%% =========================================================
% Fig. 5 - Model A adsorption-front broadness
% ==========================================================

figure
tiledlayout(4,2)

for case_id = 1:8

    nexttile


    [x_sorted, idx_sort] = sort(xdata{case_id});

    broad_sorted = broad_all{case_id}(idx_sort);


    plot(x_sorted, ...
         broad_sorted, ...
         'o-', ...
         'LineWidth', 1.2)


    xlabel(case_names{case_id})
    ylabel('Adsorption front broadness')
    title(case_names{case_id})

    grid on

end


%% =========================================================
% Numerical sensitivity test for tstart
% ==========================================================

fprintf('\n\n')
fprintf('========================================\n')
fprintf('tstart sensitivity test\n')
fprintf('========================================\n')


tstart_values = [1e-3 1e-4 1e-5];

baseline_xhalf = zeros(size(tstart_values));

dose_xhalf = zeros( ...
    length(tstart_values), ...
    length(pA0_case8));


for m = 1:length(tstart_values)

    tstart = tstart_values(m);


    %% Baseline test

    p = p0;

    p.tstart = tstart;

    r = run_modelA_case(p);

    baseline_xhalf(m) = r.x_half;


    %% Constant-dose test

    for k = 1:length(pA0_case8)

        p = p0;

        p.tstart = tstart;

        p.pA0 = pA0_case8(k);
        p.tend = tend_case8(k);

        r = run_modelA_case(p);

        dose_xhalf(m,k) = r.x_half;

    end


    fprintf('\n')
    fprintf('tstart = %.0e s\n', tstart)

    fprintf('Baseline x_half = %.6f\n', ...
        baseline_xhalf(m))

    fprintf('Constant-dose x_half values:\n')

    fprintf('  %.6f', dose_xhalf(m,:))
    fprintf('\n')

    fprintf('Constant-dose spread = %.6f\n', ...
        max(dose_xhalf(m,:)) ...
        - min(dose_xhalf(m,:)))

end


%% =========================================================
% Plot tstart sensitivity
% ==========================================================

figure

semilogx( ...
    tstart_values, ...
    baseline_xhalf, ...
    'o-', ...
    'LineWidth', 1.5)

set(gca, 'XDir', 'reverse')

xlabel('Integration start time t_{start} (s)')
ylabel('Baseline x_{0.5}/H')
title('Sensitivity of baseline result to t_{start}')

grid on



























