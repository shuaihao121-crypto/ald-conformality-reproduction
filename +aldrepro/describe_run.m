function description = describe_run(task,snapshot)
%DESCRIBE_RUN Record physical parameters separately from implementation choices.
description = struct('task',task,'numerical_sources_modified',false);
if strcmp(task,'smoke')
    description.scope = 'Small synthetic checks; not Table 2 reproduction validation.';
    description.test_parameters = snapshot.smoke.parameters;
    return
end
if strcmp(task,'replot-historical')
    description.scope = 'Historical metrics replot; no numerical model was run.';
    description.included_cases = 1:7;
    description.excluded_cases = 8;
    description.pairing = 'Same case_id/run_index, both recorded finite values and true masks.';
    description.metric_source = 'data/historical/metrics.csv';
    description.historical_sha256 = snapshot.summary.input_sha256;
    return
end
if strncmp(task,'baseline-',9)
    base = snapshot.p;
else
    base = snapshot.p0; % p in a legacy scan is the final Case VIII override.
end
model = 'A';
if strcmp(task,'baseline-b') || strcmp(task,'scan-b'), model = 'B'; end
description.model = model;
physical = base;
for name = {'fp','fs','ep','show_progress','tstart'}
    if isfield(physical,name{1}), physical = rmfield(physical,name{1}); end
end
description.baseline_physical_parameters_SI = physical;
if model == 'A'
    description.numerical = struct('solver','ode23', ...
        'solver_options_explicitly_passed',false, ...
        'relative_tolerance','MATLAB default (documented 1e-3)', ...
        'absolute_tolerance','MATLAB default (documented 1e-6)', ...
        'fp',base.fp,'N_points_rule','round(fp*L/H)', ...
        'tstart_seconds',1e-3,'pressure_history', ...
        'persistent pressure from previous RHS evaluation, including solver stages', ...
        'broadness','first grid points theta<0.1 minus theta<0.9; no interpolation', ...
        'half_coverage','first theta<=0.5 crossing; two-point interpolation and secant slope', ...
        'saturation_tolerance',1e-3);
    if isfield(base,'tstart'), description.numerical.tstart_seconds = base.tstart; end
    if strcmp(task,'scan-a')
        description.numerical.extra_tstart_sensitivity_seconds = [1e-3 1e-4 1e-5];
        description.numerical.extra_sensitivity_runs = 18;
    end
else
    description.numerical = struct('method','Frozen-surface Markov solve and implicit available-site update', ...
        'fs',base.fs,'N_segments_rule','round(fs*AR)', ...
        'ep_default',0.05,'dense_solver_max_segments',200, ...
        'large_solver','BiCGSTAB with FFT matrix-vector multiplication', ...
        'bicgstab_tolerance',1e-9,'bicgstab_max_iterations',500, ...
        'saturation_tolerance',5e-3, ...
        'half_coverage','first theta<=0.5 crossing; two-point interpolation and secant slope', ...
        'broadness','first grid points theta<0.1 minus theta<0.9; no interpolation');
    if isfield(base,'ep'), description.numerical.ep_default = base.ep; end
    if strcmp(task,'scan-b')
        description.numerical.case_VI_ep_policy = struct('beta_1',2,'beta_0_1',0.2,'otherwise',0.05);
    end
end
if isfield(snapshot,'values'), description.scan_values_SI = snapshot.values; end
if isfield(snapshot,'values')
    if model == 'A'
        description.case_parameter_mapping = {'I:T','II:pA0','III:MA','IV:H','V:tend','VI:c','VII:q','VIII:pA0 and tend'};
    else
        description.case_parameter_mapping = {'I:T','II:pA0','III:MA','IV:AR','V:tend','VI:beta0 and ep policy','VII:s0','VIII:pA0 and tend'};
    end
    description.case_construction = 'Copy baseline p0 and override the mapped fields in original scripts; values stored in SI.';
end
if isfield(snapshot,'pA0_case8')
    description.case_VIII = struct('pA0_Pa',snapshot.pA0_case8, ...
        'tend_seconds',snapshot.tend_case8,'nominal_dose_Pa_s',10);
end
if strcmp(task,'compare-historical')
    description.scope = 'Original A recomputation versus original hardcoded B arrays, including VIII.';
    description.B_data = 'Copied arrays in unchanged compare_modelAB.m; no Model B solver run.';
    description.B_ep_policy = struct('beta_1',2,'beta_0_1',0.2,'otherwise',0.05);
    description.B_saturation_tolerance = 5e-3;
    description.B_precision = 'Rounded values as stored in the original comparison script.';
end
end
