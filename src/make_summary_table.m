% src/make_summary_table.m
disp('Creating real summary table from saved pulse metrics...');

metrics_file = fullfile(PROCESSED_DIR, 'pulse_metrics.mat');
assert(isfile(metrics_file), 'Missing metrics file: %s', metrics_file);

S = load(metrics_file);
metrics = S.metrics;

branch = metrics.branch(:);
wavelength_nm = [51.4286; 60.0; 72.0];
peak_power_W = metrics.peak_power_W(:);
pulse_energy_J = metrics.pulse_energy_J(:);
fwhm_fs = metrics.fwhm_fs(:);

T = table(branch, wavelength_nm, peak_power_W, pulse_energy_J, fwhm_fs);

writetable(T, fullfile(TABLES_DIR, 'summary.csv'));

disp('Real summary table saved.');
disp(T);