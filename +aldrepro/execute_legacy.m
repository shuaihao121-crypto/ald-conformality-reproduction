function snapshot = execute_legacy(script_path)
%EXECUTE_LEGACY Isolate clear in preserved scripts from runner bookkeeping.
run(script_path);
% All wrapper variables below are constructed AFTER the script's clear.
snapshot = struct();
names_to_capture = {'p','p0','result','results','A_results','values','case_names', ...
    'pA0_case8','tend_case8','runtime_all','tstart_values','baseline_xhalf', ...
    'dose_xhalf','sat_tol','sat_tol_A','threshold_A','B_xhalf','B_slope', ...
    'B_broad','B_valid4','B_valid5','A_xhalf','A_slope','A_broad', ...
    'A_valid4','A_valid5','xhalf_all','slope_all','broad_all','valid4_all', ...
    'valid5_all','penetration_ratio','slope_ratio','broadness_ratio'};
for capture_index = 1:numel(names_to_capture)
    capture_name = names_to_capture{capture_index};
    if exist(capture_name,'var')
        snapshot.(capture_name) = eval(capture_name);
    end
end
end
