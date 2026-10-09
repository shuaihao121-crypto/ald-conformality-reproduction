function report = ald_repro(task, options)
%ALD_REPRO Run and archive the preserved ALD reproduction implementation.
%   ALD_REPRO() displays help without running a model or writing files.
%   REPORT = ALD_REPRO(TASK, OPTIONS) supports:
%     smoke               small deterministic correctness checks
%     baseline-a/b        original single-case solvers
%     scan-a/b            original full Table 2 scripts (potentially slow)
%     compare-historical  original A recomputation versus hardcoded B values
%     replot-historical   seven-case parity from historical CSV, no model run
%   OPTIONS is a scalar struct with optional fields:
%     OutputDir       exact output directory; default unique results directory
%     ExportFigures   logical scalar, default true
%     FigureVisible   'off' (default) or 'on'
%   Original scripts retain their clear/clc/close all behavior, but execute
%   in an isolated function workspace. Original numerical code is unchanged.

if nargin < 1 || isempty(task), task = 'help'; end
if nargin < 2 || isempty(options), options = struct(); end
task = validatestring(task, {'help','smoke','baseline-a','baseline-b', ...
    'scan-a','scan-b','compare-historical','replot-historical'});
root = fileparts(mfilename('fullpath'));
options = validate_options(options);
if strcmp(task, 'help')
    fprintf(['ALD conformality reproduction -- preserved research sources\n' ...
        '  ald_repro(''smoke'')                Small checks; no full scan\n' ...
        '  ald_repro(''replot-historical'')    Recorded I-VII parity; no solver\n' ...
        '  ald_repro(''baseline-a'')           Original Model A single case\n' ...
        '  ald_repro(''baseline-b'')           Original Model B single case\n' ...
        '  ald_repro(''scan-a'')               Full A scan + sensitivity; may be slow\n' ...
        '  ald_repro(''scan-b'')               Full B scan; may be slow\n' ...
        '  ald_repro(''compare-historical'')    Recompute A; historical B arrays\n' ...
        'Options: OutputDir, ExportFigures (true), FigureVisible (''off'').\n' ...
        'Every run writes manifest.json, run.log, warnings.txt, workspace.mat,\n' ...
        'metrics.csv and, if enabled, figures in PNG/PDF/SVG.\n' ...
        'See docs for inherited numerical approximations and source provenance.\n']);
    report = struct('task','help','root',root,'status','help');
    return
end

started = datetime('now','TimeZone','UTC');
run_id = [task '_' char(datetime(started,'Format','yyyyMMdd''T''HHmmssSSS''Z''')) ...
    '_' unique_suffix()];
if isempty(options.OutputDir)
    output_dir = fullfile(root, 'results', run_id);
else
    output_dir = options.OutputDir;
end
if exist(fullfile(output_dir,'manifest.json'),'file') || ...
        exist(fullfile(output_dir,'workspace.mat'),'file')
    error('aldrepro:ExistingRun', ...
        'OutputDir already contains a run. Choose a new directory: %s', output_dir);
end
if ~exist(output_dir,'dir'), mkdir(output_dir); end
% Resolve the actual output path before legacy run() changes its directory.
[ok, attributes] = fileattrib(output_dir);
if ~ok, error('aldrepro:OutputDir','Cannot resolve OutputDir.'); end
output_dir = attributes.Name;

old_path = path;
old_directory = pwd;
old_visibility = get(groot,'defaultFigureVisible');
old_warning = warning;
[old_lastwarning, old_lastwarning_id] = lastwarn;
restore = onCleanup(@() restore_environment(old_path, old_visibility, ...
    old_warning, old_lastwarning, old_lastwarning_id, old_directory));
addpath(fullfile(root,'src','ModelA_Reproduction'));
addpath(fullfile(root,'src','ModelB_Reproduction'));
set(groot,'defaultFigureVisible',options.FigureVisible);
lastwarn('','');
log_file = fullfile(output_dir,'run.log');
existing_figures = findall(groot,'Type','figure');
timer = tic;
report = struct('schema_version',1,'run_id',run_id,'task',task, ...
    'status','running','output_dir',output_dir,'started_utc',utc_text(started), ...
    'source_policy','Original numerical sources are preserved byte-for-byte.', ...
    'options',options,'environment',environment_info(), ...
    'artifacts',struct(),'warnings',struct());
failure = [];
snapshot = struct();
header_text = sprintf('Task: %s\nOutput: %s\n',task,output_dir);
fprintf('%s',header_text);
transcript = evalc('execute_recorded_task()');
fprintf('%s',transcript);
[warning_message,warning_id] = lastwarn;
report.elapsed_seconds = toc(timer);
report.finished_utc = utc_text(datetime('now','TimeZone','UTC'));
report.warnings = struct('last_message',warning_message,'last_identifier',warning_id, ...
    'full_transcript','run.log','extract','warnings.txt', ...
    'capture_note','evalc captures task output and warnings; lastwarn records only the final warning.');
report.artifacts.log = 'run.log';
report.artifacts.warnings = 'warnings.txt';
tail_text = sprintf('Status: %s; elapsed %.3f s\n',report.status,report.elapsed_seconds);
fprintf('%s',tail_text);
aldrepro.write_text(log_file,[header_text transcript tail_text]);
aldrepro.write_warning_extract(log_file,fullfile(output_dir,'warnings.txt'));
aldrepro.write_json(fullfile(output_dir,'manifest.json'),report);
if ~isempty(failure), rethrow(failure); end

    function execute_recorded_task()
try
    report.sources = aldrepro.source_hashes(root);
    if any(~[report.sources.matches_manifest])
        error('aldrepro:SourceIntegrity', ...
            'A preserved numerical source differs from data/source_manifest.json.');
    end
    switch task
        case 'smoke'
            snapshot.smoke = aldrepro.smoke();
        case {'baseline-a','baseline-b'}
            model = upper(task(end));
            if model == 'A'
                snapshot.p = parameters_modelA();
                snapshot.result = run_modelA_case(snapshot.p);
            else
                snapshot.p = parameters_modelB();
                snapshot.result = run_modelB_case(snapshot.p);
            end
            snapshot.model = model;
            aldrepro.plot_baseline(snapshot.result,model);
        case 'scan-a'
            snapshot = aldrepro.execute_legacy(fullfile(root,'src', ...
                'ModelA_Reproduction','scan_modelA_all.m'));
        case 'scan-b'
            snapshot = aldrepro.execute_legacy(fullfile(root,'src', ...
                'ModelB_Reproduction','scan_modelB_all.m'));
        case 'compare-historical'
            snapshot = aldrepro.execute_legacy(fullfile(root,'src', ...
                'ModelA_Reproduction','compare_modelAB.m'));
        case 'replot-historical'
            snapshot = aldrepro.historical(root,true);
            writetable(snapshot.pairs,fullfile(output_dir,'historical_pairs.csv'));
            aldrepro.write_json(fullfile(output_dir,'summary.json'),snapshot.summary);
            report.artifacts.historical_pairs = 'historical_pairs.csv';
            report.artifacts.summary = 'summary.json';
    end
    report.parameters = aldrepro.describe_run(task,snapshot);
    metrics = aldrepro.metrics(task,snapshot);
    writetable(metrics,fullfile(output_dir,'metrics.csv'));
    report.artifacts.metrics = 'metrics.csv';
    save(fullfile(output_dir,'workspace.mat'),'snapshot','metrics','-v7.3');
    report.artifacts.workspace = 'workspace.mat';
    new_figures = findall(groot,'Type','figure');
    if ~isempty(existing_figures)
        new_figures = new_figures(~ismember(new_figures,existing_figures));
    end
    if options.ExportFigures
        report.artifacts.figures = aldrepro.export_figures(new_figures,output_dir);
    else
        report.artifacts.figures = {};
    end
    report.status = 'success';
catch exception
    failure = exception;
    report.status = 'failed';
    report.error = struct('identifier',exception.identifier,'message',exception.message, ...
        'report',getReport(exception,'extended','hyperlinks','off'));
    fprintf(2,'%s\n',report.error.report);
    % Preserve anything captured before failure; never create a success marker.
    save(fullfile(output_dir,'workspace.mat'),'snapshot','-v7.3');
    report.artifacts.workspace = 'workspace.mat';
end
    end
end

function options = validate_options(options)
if ~isstruct(options) || ~isscalar(options)
    error('aldrepro:Options','OPTIONS must be a scalar struct.');
end
allowed = {'OutputDir','ExportFigures','FigureVisible'};
unknown = setdiff(fieldnames(options),allowed);
if ~isempty(unknown), error('aldrepro:Options','Unknown option: %s',unknown{1}); end
if ~isfield(options,'OutputDir'), options.OutputDir = ''; end
if ~isfield(options,'ExportFigures'), options.ExportFigures = true; end
if ~isfield(options,'FigureVisible'), options.FigureVisible = 'off'; end
if ~(ischar(options.OutputDir) && (isrow(options.OutputDir) || isempty(options.OutputDir))) && ...
        ~(isstring(options.OutputDir) && isscalar(options.OutputDir))
    error('aldrepro:Options','OutputDir must be a character vector or string scalar.');
end
options.OutputDir = char(options.OutputDir);
validateattributes(options.ExportFigures,{'logical'},{'scalar'});
options.FigureVisible = validatestring(options.FigureVisible,{'on','off'});
end

function result = unique_suffix()
if usejava('jvm')
    result = char(java.util.UUID.randomUUID());
    result = result(1:8);
else
    [~,result] = fileparts(tempname); % Does not create a file or modify RNG.
end
end

function text_value = utc_text(value)
value.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''';
text_value = char(value);
end

function info = environment_info()
info = struct('matlab_version',version,'matlab_release',version('-release'), ...
    'computer',computer,'architecture',computer('arch'),'platform',system_dependent('getos'), ...
    'has_jvm',usejava('jvm'),'dependencies','MATLAB built-in numerical and graphics functions');
if usejava('jvm'), info.java = version('-java'); end
end

function restore_environment(old_path, visibility, warnings, last_message, last_id, directory)
if exist(directory,'dir'), cd(directory); end
path(old_path);
set(groot,'defaultFigureVisible',visibility);
warning(warnings);
lastwarn(last_message,last_id);
end
