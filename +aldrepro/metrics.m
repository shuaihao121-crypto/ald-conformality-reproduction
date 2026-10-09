function records = metrics(task,snapshot)
%METRICS Archive actual returned values without substituting historical data.
if strcmp(task,'replot-historical')
    records = snapshot.records;
    return
end
rows = repmat(empty_row(),0,1);
if strcmp(task,'smoke')
    records = struct2table(rows);
    return
end
if strncmp(task,'baseline-',9)
    model = upper(task(end));
    rows(1) = result_row(snapshot.result,model,0,1,'baseline',NaN,'', ...
        ['live_' task]);
elseif strcmp(task,'scan-a') || strcmp(task,'scan-b') || strcmp(task,'compare-historical')
    model = upper(task(end));
    if strcmp(task,'compare-historical')
        model = 'A';
        results = snapshot.A_results;
    else
        results = snapshot.results;
    end
    for case_id = 1:numel(results)
        for run_index = 1:numel(results{case_id})
            [name,value,unit] = parameter_for(snapshot,model,case_id,run_index);
            rows(end+1) = result_row(results{case_id}{run_index},model,case_id, ...
                run_index,name,value,unit,['live_' task]); %#ok<AGROW>
        end
    end
    if strcmp(task,'compare-historical')
        for case_id = 1:numel(snapshot.B_xhalf)
            for run_index = 1:numel(snapshot.B_xhalf{case_id})
                [name,value,unit] = parameter_for(snapshot,'B',case_id,run_index);
                row = empty_row();
                row.model = 'B'; row.case_id = case_id; row.run_index = run_index;
                row.param_name = name; row.param_value_SI = value; row.param_unit = unit;
                row.x_half = snapshot.B_xhalf{case_id}(run_index);
                row.slope_half = snapshot.B_slope{case_id}(run_index);
                row.broadness = snapshot.B_broad{case_id}(run_index);
                row.x_half_status = recorded_status(row.x_half,'not_recorded');
                row.slope_status = recorded_status(row.slope_half,'not_recorded');
                row.broadness_status = recorded_status(row.broadness,'not_recorded');
                row.valid_half = logical_text(snapshot.B_valid4{case_id}(run_index));
                row.valid_broad = logical_text(snapshot.B_valid5{case_id}(run_index));
                row.exclusion_reason = 'original_hardcoded_masks_raw_profile_unavailable';
                row.source_id = 'unchanged_compare_modelAB_hardcoded_B';
                rows(end+1) = row; %#ok<AGROW>
            end
        end
    end
end
records = struct2table(rows);
end

function row = result_row(result,model,case_id,run_index,name,value,unit,source)
row = empty_row();
row.model = model; row.case_id = case_id; row.run_index = run_index;
row.param_name = name; row.param_value_SI = value; row.param_unit = unit;
row.entrance_theta = result.entrance_theta;
row.x_half = result.x_half; row.slope_half = result.slope_half;
row.broadness = result.broadness;
row.x_half_status = recorded_status(row.x_half,'no_crossing');
row.slope_status = recorded_status(row.slope_half,'no_crossing');
row.broadness_status = recorded_status(row.broadness,'no_crossing');
if model == 'A', tolerance = 1e-3; else, tolerance = 5e-3; end
entrance_saturated = result.entrance_theta >= 1-tolerance;
whole_saturated = min(result.theta) >= 1-tolerance;
valid_half = entrance_saturated && ~whole_saturated && ...
    isfinite(result.x_half) && isfinite(result.slope_half);
valid_broad = entrance_saturated && min(result.theta)<0.1 && isfinite(result.broadness);
row.valid_half = logical_text(valid_half);
row.valid_broad = logical_text(valid_broad);
reasons = {};
if ~entrance_saturated, reasons{end+1} = 'entrance_below_numerical_threshold'; end
if whole_saturated, reasons{end+1} = 'whole_channel_saturated'; end
if ~isfinite(result.x_half), reasons{end+1} = 'no_half_coverage_crossing'; end
if min(result.theta)>=0.1, reasons{end+1} = 'coverage_does_not_fall_below_0_1'; end
row.exclusion_reason = strjoin(reasons,';');
row.source_id = source;
end

function [name,value,unit] = parameter_for(snapshot,model,case_id,run_index)
names = {'T','pA0','MA','H','tend','c','q','pA0_constant_dose'};
units = {'K','Pa','kg/mol','m','s','1','m^-2','Pa'};
name = names{case_id}; unit = units{case_id};
if case_id == 8
    value = snapshot.pA0_case8(run_index);
else
    value = snapshot.values{case_id}(run_index);
end
if model == 'B'
    switch case_id
        case 4
            name = 'AR'; unit = '1';
            if isfield(snapshot,'A_results'), value = snapshot.p0.L/value; end
        case 6, name = 'beta0';
        case 7
            name = 's0'; unit = 'm^2';
            if isfield(snapshot,'A_results'), value = 1/value; end
    end
end
end

function row = empty_row()
row = struct('model','','case_id',NaN,'run_index',NaN,'param_name','', ...
    'param_value_SI',NaN,'param_unit','','entrance_theta',NaN, ...
    'x_half',NaN,'slope_half',NaN,'broadness',NaN, ...
    'x_half_status','not_recorded','slope_status','not_recorded', ...
    'broadness_status','not_recorded','valid_half','unknown', ...
    'valid_broad','unknown','exclusion_reason','','source_id','');
end

function status = recorded_status(value,missing_status)
if isfinite(value), status = 'recorded'; else, status = missing_status; end
end

function value = logical_text(input)
if input, value = 'true'; else, value = 'false'; end
end
