clear
clc
close all

%% =========================================================
% MODEL B - COMPLETE TABLE 2 REPRODUCTION
%
% Reproduce Model B results corresponding to:
%
% Fig. 3 : saturation profiles
% Fig. 4 : half-coverage penetration depth + slope
% Fig. 5 : adsorption-front broadness
%
% Cases I-VIII follow Table 2 of the paper.
%% ==========================================================

p0 = parameters_modelB();

% Disable internal progress printing during batch scan
p0.show_progress = false;


%% =========================================================
% Case names
%% ==========================================================

case_names = {
    'Temperature T'
    'Pressure pA0'
    'Molar mass MA'
    'Aspect ratio L/H'
    'Exposure time tend'
    'Sticking coefficient beta0'
    'Surface site area s0'
    'Constant exposure'
};


%% =========================================================
% Case definitions
%% ==========================================================

% ---------------------------------------------------------
% Case I: Temperature
% ---------------------------------------------------------

values{1} = ...
    [373.15 473.15 573.15 673.15 773.15];


% ---------------------------------------------------------
% Case II: Initial partial pressure
% ---------------------------------------------------------

values{2} = ...
    [1 2.5 5 10 20];


% ---------------------------------------------------------
% Case III: Reactant A molar mass
% ---------------------------------------------------------

values{3} = ...
    [0.05 0.1 0.15 0.2 0.25];


% ---------------------------------------------------------
% Case IV: Aspect ratio
%
% H =
% 0.125, 0.25, 0.5, 1, 2 um
%
% L = 500 um
%
% AR = L/H =
% 4000, 2000, 1000, 500, 250
% ---------------------------------------------------------

values{4} = ...
    [4000 2000 1000 500 250];


% ---------------------------------------------------------
% Case V: Exposure duration
% ---------------------------------------------------------

values{5} = ...
    [0.01 0.1 1 10 100];


% ---------------------------------------------------------
% Case VI: Bare-surface sticking probability beta0
% ---------------------------------------------------------

values{6} = ...
    [1 0.1 0.01 0.001 1e-4 1e-5];


% ---------------------------------------------------------
% Case VII: Average surface site area
%
% Values below are in nm^2
% ---------------------------------------------------------

s0_nm2 = ...
    [2 1 0.5 0.25 0.125];

values{7} = ...
    s0_nm2 * 1e-18;


% ---------------------------------------------------------
% Case VIII: Constant exposure
%
% Exposure = pA0 * tend = 10 Pa*s
% ---------------------------------------------------------

pA0_case8 = ...
    [0.08 0.4 2 10 50];

tend_case8 = ...
    [125 25 5 1 0.2];

exposure_case8 = ...
    pA0_case8 .* tend_case8;


%% =========================================================
% Storage
%% ==========================================================

results = cell(8,1);

runtime_all = cell(8,1);


%% =========================================================
% Run Cases I-VII
%% ==========================================================

for case_id = 1:7

    n = length(values{case_id});

    results{case_id} = cell(n,1);

    runtime_all{case_id} = zeros(1,n);


    fprintf('\n\n')
    fprintf('========================================\n')
    fprintf('Running Case %d: %s\n', ...
        case_id, case_names{case_id})
    fprintf('========================================\n')


    for k = 1:n

        p = p0;


        %% -------------------------------------------------
        % Change only the parameter belonging to this case
        %% -------------------------------------------------

        switch case_id

            %% Case I: Temperature
            case 1

                p.T = values{1}(k);


            %% Case II: Pressure
            case 2

                p.pA0 = values{2}(k);


            %% Case III: Molar mass
            case 3

                p.MA = values{3}(k);


            %% Case IV: Aspect ratio
            case 4

                p.AR = values{4}(k);


            %% Case V: Exposure duration
            case 5

                p.tend = values{5}(k);


            %% Case VI: Sticking coefficient
            case 6

                p.beta0 = values{6}(k);

                % -----------------------------------------
                % Numerical adaptive-step acceleration
                %
                % ep is NOT a physical parameter.
                %
                % Default:
                % ep = 0.05
                %
                % beta0 = 1 is extremely slow with ep=0.05.
                %
                % Sensitivity test:
                %
                % ep = 5:
                % x_half = 370.569331
                % slope  = 0.073463
                % broad  = 70.75
                %
                % ep = 2:
                % x_half = 373.402663
                % slope  = 0.070074
                % broad  = 70.00
                %
                % Therefore:
                %
                % beta0 = 1   -> ep = 2
                % beta0 = 0.1 -> ep = 0.2
                % otherwise   -> ep = 0.05
                % -----------------------------------------

                if p.beta0 == 1

                    p.ep = 2;

                elseif p.beta0 == 0.1

                    p.ep = 0.2;

                else

                    p.ep = 0.05;

                end


            %% Case VII: Surface site area
            case 7

                p.s0 = values{7}(k);

        end


        %% -------------------------------------------------
        % Run simulation
        %% -------------------------------------------------

        tic

        r = run_modelB_case(p);

        runtime_all{case_id}(k) = toc;

        results{case_id}{k} = r;


        %% -------------------------------------------------
        % Print result
        %% -------------------------------------------------

        fprintf( ...
            ['Run %d: entrance = %.6f, ' ...
             'x_half = %.3f, slope = %.6f, ' ...
             'broadness = %.3f, runtime = %.1f s'], ...
             k, ...
             r.entrance_theta, ...
             r.x_half, ...
             r.slope_half, ...
             r.broadness, ...
             runtime_all{case_id}(k))


        if case_id == 6

            fprintf(', ep = %.3g', p.ep)

        end


        fprintf('\n')

    end

end


%% =========================================================
% Run Case VIII: Constant exposure
%% ==========================================================

n8 = length(pA0_case8);

results{8} = cell(n8,1);

runtime_all{8} = zeros(1,n8);


fprintf('\n\n')
fprintf('========================================\n')
fprintf('Running Case VIII: Constant exposure\n')
fprintf('========================================\n')


for k = 1:n8

    p = p0;

    p.pA0 = pA0_case8(k);

    p.tend = tend_case8(k);


    tic

    r = run_modelB_case(p);

    runtime_all{8}(k) = toc;

    results{8}{k} = r;


    fprintf( ...
        ['pA0 = %7.2f Pa, tend = %7.2f s, ' ...
         'exposure = %7.2f Pa*s, ' ...
         'x_half = %.6f, runtime = %.1f s\n'], ...
         p.pA0, ...
         p.tend, ...
         p.pA0*p.tend, ...
         r.x_half, ...
         runtime_all{8}(k))

end


%% =========================================================
% FIG. 3 - MODEL B SATURATION PROFILES
%% ==========================================================

figure

tiledlayout(4,2)


for case_id = 1:8

    nexttile

    hold on


    for k = 1:length(results{case_id})

        r = results{case_id}{k};


        %% -------------------------------------------------
        % Case IV uses normalized distance x/L
        %% -------------------------------------------------

        if case_id == 4

            AR_current = values{4}(k);

            x_plot = ...
                r.x_dim / AR_current;

        else

            x_plot = r.x_dim;

        end


        plot( ...
            x_plot, ...
            r.theta, ...
            'LineWidth', 1.2)

    end


    hold off

    ylim([0 1.05])

    ylabel('Surface coverage \theta')

    title(case_names{case_id})


    if case_id == 4

        xlabel('Normalized distance x/L')

        xlim([0 1])

    else

        xlabel('Dimensionless distance x/H')

    end


    grid on

end


%% =========================================================
% Prepare horizontal-axis values for Fig. 4 / Fig. 5
%% ==========================================================

xdata = cell(8,1);


% Case I: Temperature
xdata{1} = values{1};


% Case II: Pressure
xdata{2} = values{2};


% Case III: Molar mass
xdata{3} = values{3};


% Case IV: Aspect ratio
xdata{4} = values{4};


% Case V: Exposure duration
xdata{5} = values{5};


% Case VI: Sticking coefficient
xdata{6} = values{6};


% Case VII: Surface site area, nm^2
xdata{7} = s0_nm2;


% Case VIII:
% Exposure = pA0 * tend
% Unit: Pa*s
%
% All five values equal 10 Pa*s.

xdata{8} = exposure_case8;


%% =========================================================
% Extract Fig. 4 / Fig. 5 quantities
%% ==========================================================

xhalf_all = cell(8,1);

slope_all = cell(8,1);

broad_all = cell(8,1);


valid4_all = cell(8,1);

valid5_all = cell(8,1);


%% ---------------------------------------------------------
% Numerical saturation tolerance
%
% The paper does not specify an exact numerical threshold.
%
% Here:
%
% theta_entrance >= 0.995
%
% is regarded as saturated.
%
% This is a numerical implementation choice.
%% ---------------------------------------------------------

sat_tol = 5e-3;

threshold = 1 - sat_tol;


for case_id = 1:8

    n = length(results{case_id});


    xhalf = NaN(1,n);

    slope = NaN(1,n);

    broad = NaN(1,n);


    valid4 = false(1,n);

    valid5 = false(1,n);


    for k = 1:n

        r = results{case_id}{k};


        %% -------------------------------------------------
        % Entrance saturation test
        %% -------------------------------------------------

        entrance_saturated = ...
            r.entrance_theta >= threshold;


        %% -------------------------------------------------
        % Entire-channel saturation test
        %% -------------------------------------------------

        whole_channel_saturated = ...
            min(r.theta) >= threshold;


        %% -------------------------------------------------
        % Fig. 4 validity
        %% -------------------------------------------------

        valid4(k) = ...
            entrance_saturated ...
            && ~whole_channel_saturated ...
            && isfinite(r.x_half) ...
            && isfinite(r.slope_half);


        if valid4(k)

            xhalf(k) = r.x_half;

            slope(k) = r.slope_half;

        end


        %% -------------------------------------------------
        % Fig. 5 validity
        %% -------------------------------------------------

        valid5(k) = ...
            entrance_saturated ...
            && min(r.theta) < 0.1 ...
            && isfinite(r.broadness);


        if valid5(k)

            broad(k) = r.broadness;

        end

    end


    xhalf_all{case_id} = xhalf;

    slope_all{case_id} = slope;

    broad_all{case_id} = broad;


    valid4_all{case_id} = valid4;

    valid5_all{case_id} = valid5;

end


%% =========================================================
% FIG. 4 - HALF-COVERAGE DEPTH + SLOPE
%% ==========================================================

figure

tiledlayout(4,2)


for case_id = 1:8

    nexttile


    %% -----------------------------------------------------
    % Sort horizontal axis for plotting
    %% -----------------------------------------------------

    [x_sorted, idx_sort] = ...
        sort(xdata{case_id});


    xhalf_sorted = ...
        xhalf_all{case_id}(idx_sort);


    slope_sorted = ...
        slope_all{case_id}(idx_sort);


    %% -----------------------------------------------------
    % Left axis: half-coverage penetration depth
    %% -----------------------------------------------------

    yyaxis left


    plot( ...
        x_sorted, ...
        xhalf_sorted, ...
        'o-', ...
        'LineWidth', 1.2)


    ylabel('Half-coverage penetration depth')


    %% -----------------------------------------------------
    % Right axis: slope
    %% -----------------------------------------------------

    yyaxis right


    plot( ...
        x_sorted, ...
        slope_sorted, ...
        'o-', ...
        'LineWidth', 1.2)


    ylabel('|slope| at \theta = 0.5')


    %% -----------------------------------------------------
    % X-axis label
    %% -----------------------------------------------------

    if case_id == 8

        xlabel('Exposure (Pa s)')

    else

        xlabel(case_names{case_id})

    end


    title(case_names{case_id})

    grid on

end


%% =========================================================
% FIG. 5 - ADSORPTION-FRONT BROADNESS
%% ==========================================================

figure

tiledlayout(4,2)


for case_id = 1:8

    nexttile


    [x_sorted, idx_sort] = ...
        sort(xdata{case_id});


    broad_sorted = ...
        broad_all{case_id}(idx_sort);


    plot( ...
        x_sorted, ...
        broad_sorted, ...
        'o-', ...
        'LineWidth', 1.2)


    %% -----------------------------------------------------
    % X-axis label
    %% -----------------------------------------------------

    if case_id == 8

        xlabel('Exposure (Pa s)')

    else

        xlabel(case_names{case_id})

    end


    ylabel('Adsorption-front broadness')

    title(case_names{case_id})

    grid on

end


%% =========================================================
% COMPLETE NUMERICAL SUMMARY
%% ==========================================================

fprintf('\n\n')

fprintf('========================================\n')

fprintf('MODEL B COMPLETE SUMMARY\n')

fprintf('========================================\n')


for case_id = 1:7

    fprintf('\n')

    fprintf('----------------------------------------\n')

    fprintf('Case %d: %s\n', ...
        case_id, ...
        case_names{case_id})

    fprintf('----------------------------------------\n')


    fprintf( ...
        ['Value        entrance       x_half      ' ...
         'slope       broadness    F4 F5\n'])


    for k = 1:length(results{case_id})

        r = results{case_id}{k};


        fprintf( ...
            ['%10.5g   %.9f   %10.4f   ' ...
             '%10.6f   %10.4f   %d  %d\n'], ...
             xdata{case_id}(k), ...
             r.entrance_theta, ...
             r.x_half, ...
             r.slope_half, ...
             r.broadness, ...
             valid4_all{case_id}(k), ...
             valid5_all{case_id}(k))

    end

end


%% =========================================================
% Case VIII numerical summary
%% ==========================================================

fprintf('\n')

fprintf('----------------------------------------\n')

fprintf('Case 8: Constant exposure\n')

fprintf('----------------------------------------\n')


fprintf( ...
    ['pA0(Pa)   tend(s)   exposure(Pa*s)   ' ...
     'entrance       x_half      slope       ' ...
     'broadness    F4 F5\n'])


for k = 1:n8

    r = results{8}{k};


    fprintf( ...
        ['%7.2f   %7.2f      %7.2f       ' ...
         '%.9f   %10.4f   %10.6f   ' ...
         '%10.4f   %d  %d\n'], ...
         pA0_case8(k), ...
         tend_case8(k), ...
         exposure_case8(k), ...
         r.entrance_theta, ...
         r.x_half, ...
         r.slope_half, ...
         r.broadness, ...
         valid4_all{8}(k), ...
         valid5_all{8}(k))

end


%% =========================================================
% CONSTANT-EXPOSURE CONSISTENCY CHECK
%% ==========================================================

dose_xhalf = zeros(1,n8);


for k = 1:n8

    dose_xhalf(k) = ...
        results{8}{k}.x_half;

end


fprintf('\n')

fprintf('========================================\n')

fprintf('Constant-exposure check\n')

fprintf('========================================\n')


fprintf('pA0 values (Pa):\n')

fprintf('  %.6f', pA0_case8)

fprintf('\n')


fprintf('tend values (s):\n')

fprintf('  %.6f', tend_case8)

fprintf('\n')


fprintf('Exposure values (Pa*s):\n')

fprintf('  %.6f', exposure_case8)

fprintf('\n')


fprintf('x_half values:\n')

fprintf('  %.9f', dose_xhalf)

fprintf('\n')


fprintf( ...
    'x_half spread = %.12e\n', ...
    max(dose_xhalf) ...
    - min(dose_xhalf))


%% =========================================================
% End
%% =========================================================