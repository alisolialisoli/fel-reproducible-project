% workflow/run_all.m
clear; clc;

% ------------------------------------------------
% Resolve project root robustly
% ------------------------------------------------
this_file = mfilename('fullpath');
workflow_dir = fileparts(this_file);
project_root = fileparts(workflow_dir);

disp('===============================================');
disp('Starting reproducible FEL analysis workflow...');
disp('Case: multicolor helical H7 / H6 / H5');
disp(['Project root: ' project_root]);
disp('===============================================');

% ------------------------------------------------
% Define key directories
% ------------------------------------------------
results_dir   = fullfile(project_root, 'results');
figures_dir   = fullfile(results_dir, 'figures');
tables_dir    = fullfile(results_dir, 'tables');
processed_dir = fullfile(project_root, 'data', 'processed');
src_dir       = fullfile(project_root, 'src');
raw_dir       = fullfile(project_root, 'data', 'raw');

% ------------------------------------------------
% Create output directories if they do not exist
% ------------------------------------------------
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

if ~exist(figures_dir, 'dir')
    mkdir(figures_dir);
end

if ~exist(tables_dir, 'dir')
    mkdir(tables_dir);
end

if ~exist(processed_dir, 'dir')
    mkdir(processed_dir);
end

% ------------------------------------------------
% Check that required raw files exist
% ------------------------------------------------
disp('Step 1: checking required raw data files...');

required_files = {
    fullfile(raw_dir, 'FIELD_END_RAD6_BRANCH_A.fld.h5')
    fullfile(raw_dir, 'FIELD_END_RAD6_BRANCH_B.fld.h5')
    fullfile(raw_dir, 'FIELD_END_RAD6_BRANCH_C.fld.h5')
    fullfile(raw_dir, 'A_H7_RAD12.out.h5')
    fullfile(raw_dir, 'A_PROP_THROUGH_RAD36.out.h5')
    fullfile(raw_dir, 'B_H6_RAD34.out.h5')
    fullfile(raw_dir, 'B_PROP_THROUGH_RAD56.out.h5')
    fullfile(raw_dir, 'C_H5_RAD56.out.h5')
};

for k = 1:numel(required_files)
    if ~isfile(required_files{k})
        error('Missing required file: %s', required_files{k});
    end
end

disp('All required raw files were found.');

% ------------------------------------------------
% Make project paths visible to analysis scripts
% ------------------------------------------------
assignin('base', 'PROJECT_ROOT', project_root);
assignin('base', 'RESULTS_DIR', results_dir);
assignin('base', 'FIGURES_DIR', figures_dir);
assignin('base', 'TABLES_DIR', tables_dir);
assignin('base', 'PROCESSED_DIR', processed_dir);
assignin('base', 'RAW_DIR', raw_dir);

% ------------------------------------------------
% Run analysis steps
% ------------------------------------------------
disp('Step 2: running temporal profile analysis...');
run(fullfile(src_dir, 'analyze_temporal_profile.m'));

disp('Step 3: running spectrum analysis...');
run(fullfile(src_dir, 'compute_spectrum.m'));

disp('Step 4: running transverse profile analysis...');
run(fullfile(src_dir, 'compute_transverse_profile.m'));

disp('Step 5: running power-along-z analysis...');
run(fullfile(src_dir, 'power_along_z.m'));

disp('Step 6: creating summary table...');
run(fullfile(src_dir, 'make_summary_table.m'));

% ------------------------------------------------
% Finish
% ------------------------------------------------
disp('===============================================');
disp('Workflow completed successfully.');
disp(['Figures: ' figures_dir]);
disp(['Tables : ' tables_dir]);
disp('===============================================');