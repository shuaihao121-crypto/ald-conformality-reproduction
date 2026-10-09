function snapshot = historical(root,make_figure)
%HISTORICAL Pair explicitly recorded, valid I-VII metrics; never run a model.
if nargin < 2, make_figure = false; end
input_file = fullfile(root,'data','historical','metrics.csv');
if ~exist(input_file,'file')
    error('aldrepro:MissingHistorical','Historical CSV not found: %s',input_file);
end
required = {'model','case_id','run_index','param_name','param_value_SI', ...
    'param_unit','entrance_theta','x_half','slope_half','broadness', ...
    'x_half_status','slope_status','broadness_status','valid_half','valid_broad', ...
    'exclusion_reason','source_id'};
import = detectImportOptions(input_file,'Delimiter',',');
if ~all(ismember(required,import.VariableNames))
    error('aldrepro:HistoricalSchema','Historical metrics CSV is missing required columns.');
end
% Import text first so a blank and recorded NaN remain semantically distinct
% through the explicit status columns; never infer a missing value as zero.
import = setvartype(import,import.VariableNames,'string');
records = readtable(input_file,import);
for name = {'case_id','run_index','param_value_SI','entrance_theta','x_half','slope_half','broadness'}
    records.(name{1}) = str2double(records.(name{1}));
end
records.model = upper(strtrim(records.model));
if any(~ismember(records.model,["A","B"])) || ...
        any(~ismember(records.case_id,1:8)) || ...
        any(~isfinite(records.run_index) | records.run_index<1 | mod(records.run_index,1)~=0)
    error('aldrepro:HistoricalKeys','Invalid model/case_id/run_index in historical records.');
end
keys = records.model + ":" + string(records.case_id) + ":" + string(records.run_index);
if numel(unique(keys))~=height(records)
    error('aldrepro:DuplicateHistorical','Historical model/case/run keys must be unique.');
end
pairs = repmat(struct('case_id',0,'run_index',0,'A_x_half',NaN,'B_x_half',NaN, ...
    'A_slope_half',NaN,'B_slope_half',NaN,'A_broadness',NaN,'B_broadness',NaN, ...
    'valid_penetration',false,'valid_slope',false,'valid_broadness',false, ...
    'A_source_id','','B_source_id',''),0,1);
for case_id = 1:7
    a_indices = find(records.model=="A" & records.case_id==case_id);
    [~,ordering] = sort(records.run_index(a_indices));
    a_indices = a_indices(ordering);
    for a_index = a_indices'
        run_index = records.run_index(a_index);
        b_index = find(records.model=="B" & records.case_id==case_id & records.run_index==run_index);
        if isempty(b_index)
            error('aldrepro:UnpairedHistorical','No B record for case %d, run %d.',case_id,run_index);
        end
        a = records(a_index,:); b = records(b_index,:);
        half_mask = text_is(a.valid_half,'true') && text_is(b.valid_half,'true');
        broad_mask = text_is(a.valid_broad,'true') && text_is(b.valid_broad,'true');
        pair = struct('case_id',case_id,'run_index',run_index, ...
            'A_x_half',a.x_half,'B_x_half',b.x_half, ...
            'A_slope_half',a.slope_half,'B_slope_half',b.slope_half, ...
            'A_broadness',a.broadness,'B_broadness',b.broadness, ...
            'valid_penetration',half_mask && recorded_finite(a,'x_half','x_half_status') && recorded_finite(b,'x_half','x_half_status'), ...
            'valid_slope',half_mask && recorded_finite(a,'slope_half','slope_status') && recorded_finite(b,'slope_half','slope_status') && a.slope_half>0 && b.slope_half>0, ...
            'valid_broadness',broad_mask && recorded_finite(a,'broadness','broadness_status') && recorded_finite(b,'broadness','broadness_status'), ...
            'A_source_id',char(a.source_id),'B_source_id',char(b.source_id));
        pairs(end+1) = pair; %#ok<AGROW>
    end
end
pairs = struct2table(pairs);
penetration = pairs.B_x_half(pairs.valid_penetration)./pairs.A_x_half(pairs.valid_penetration);
slope = pairs.A_slope_half(pairs.valid_slope)./pairs.B_slope_half(pairs.valid_slope);
broadness = pairs.B_broadness(pairs.valid_broadness)./pairs.A_broadness(pairs.valid_broadness);
summary = struct('scope','Historical I-VII records; Case VIII excluded; no baseline de-duplication.', ...
    'input_csv','data/historical/metrics.csv','input_sha256',aldrepro.file_hash(input_file), ...
    'included_cases',1:7,'excluded_cases',8, ...
    'pair_counts',struct('penetration',numel(penetration),'slope',numel(slope),'broadness',numel(broadness)), ...
    'mean_ratios',struct('B_over_A_penetration',mean(penetration), ...
    'A_over_B_slope',mean(slope),'B_over_A_broadness',mean(broadness)), ...
    'numerical_simulation_executed',false);
snapshot = struct('records',records,'pairs',pairs,'summary',summary);
fprintf('Historical I-VII pairs: penetration %d, slope %d, broadness %d.\n', ...
    numel(penetration),numel(slope),numel(broadness));
fprintf('Mean ratios B/A penetration %.10f; A/B slope %.10f; B/A broadness %.10f.\n', ...
    mean(penetration),mean(slope),mean(broadness));
if make_figure, aldrepro.plot_historical(pairs); end
end

function value = text_is(input,expected)
value = ~ismissing(input) && strcmpi(strtrim(input),expected);
end

function value = recorded_finite(row,metric,status)
value = text_is(row.(status),'recorded') && isfinite(row.(metric));
end
