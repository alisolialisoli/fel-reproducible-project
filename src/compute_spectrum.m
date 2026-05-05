% src/compute_spectrum.m
disp('Running real spectrum analysis from .fld.h5 files...');

normalizeSpectrum = false;
useHannWindow = false;

c = 299792458;

run_cfg(1).file   = fullfile(RAW_DIR, 'FIELD_END_RAD6_BRANCH_A.fld.h5');
run_cfg(1).lambda = 51.428e-9;
run_cfg(1).label  = 'H7 (51.4 nm)';

run_cfg(2).file   = fullfile(RAW_DIR, 'FIELD_END_RAD6_BRANCH_B.fld.h5');
run_cfg(2).lambda = 60.0e-9;
run_cfg(2).label  = 'H6 (60.0 nm)';

run_cfg(3).file   = fullfile(RAW_DIR, 'FIELD_END_RAD6_BRANCH_C.fld.h5');
run_cfg(3).lambda = 72.0e-9;
run_cfg(3).label  = 'H5 (72.0 nm)';

spec_data = struct();

fig = figure('Visible','off','Color','w','Position',[100 100 900 500]);
hold on; grid on;
xlabel('Wavelength (nm)');

if normalizeSpectrum
    ylabel('Normalized spectral intensity');
else
    ylabel('Spectral intensity [arb. units]');
end

title('Comparison of HGHG radiator spectra');

for i = 1:numel(run_cfg)
    fname = run_cfg(i).file;
    lambda0 = run_cfg(i).lambda;
    label = run_cfg(i).label;

    assert(isfile(fname), 'Missing file: %s', fname);
    fprintf('[+] Processing %s\n', label);

    info = h5info(fname);
    groupNames = {info.Groups.Name};
    sliceGroups = groupNames(contains(groupNames, 'slice'));

    sliceNums = zeros(numel(sliceGroups),1);
    for k = 1:numel(sliceGroups)
        token = regexp(sliceGroups{k}, 'slice(\d+)', 'tokens');
        if ~isempty(token)
            sliceNums(k) = str2double(token{1}{1});
        else
            sliceNums(k) = k;
        end
    end
    [~, idxSort] = sort(sliceNums);
    sliceGroups = sliceGroups(idxSort);

    numSlices = numel(sliceGroups);

    re0 = h5read(fname, [sliceGroups{1} '/field-real']);
    [ny, nx] = size(re0);

    E = zeros(ny, nx, numSlices);

    for s = 1:numSlices
        re = h5read(fname, [sliceGroups{s} '/field-real']);
        im = h5read(fname, [sliceGroups{s} '/field-imag']);
        E(:,:,s) = complex(re, im);
    end

    s_axis = [];
    s_candidates = {'/s','/Global/s'};
    for kc = 1:numel(s_candidates)
        try
            s_axis = h5read(fname, s_candidates{kc});
            s_axis = s_axis(:);
            break;
        catch
        end
    end

    if isempty(s_axis) || numel(s_axis) ~= numSlices
        fprintf('    s-axis not found or mismatched. Reconstructing from lambda.\n');
        sample = 1;
        s_axis = (0:numSlices-1)' * lambda0 * sample;
    end

    ds = mean(diff(s_axis));
    dt = ds / c;
    N  = numSlices;
    df = 1 / (N * dt);

    f_rel = ((-floor(N/2)):(ceil(N/2)-1))' * df;
    f0 = c / lambda0;
    f_abs = f0 + f_rel;

    if useHannWindow
        w = reshape(hann(N), 1, 1, N);
        E = E .* w;
    end

    Spec = fftshift(fft(E, [], 3), 3);
    PSD = squeeze(sum(sum(abs(Spec).^2, 1), 2));

    wav_axis = c ./ f_abs * 1e9;

    valid = f_abs > 0 & isfinite(wav_axis) & isfinite(PSD);
    wav_plot = wav_axis(valid);
    PSD_plot = PSD(valid);

    [wav_plot, idx] = sort(wav_plot);
    PSD_plot = PSD_plot(idx);

    if normalizeSpectrum
        PSD_to_plot = PSD_plot / max(PSD_plot);
    else
        PSD_to_plot = PSD_plot;
    end

    plot(wav_plot, PSD_to_plot, 'LineWidth', 2, 'DisplayName', label);

    branch_key = sprintf('branch_%d', i);
    spec_data.(branch_key).label = label;
    spec_data.(branch_key).wavelength_nm = wav_plot;
    spec_data.(branch_key).PSD = PSD_plot;
    spec_data.(branch_key).PSD_plotted = PSD_to_plot;
    spec_data.(branch_key).numSlices = N;
    spec_data.(branch_key).ds_m = ds;
    spec_data.(branch_key).dt_fs = dt * 1e15;

    fprintf('    N slices = %d\n', N);
    fprintf('    ds       = %.4e m\n', ds);
    fprintf('    dt       = %.4f fs\n', dt*1e15);
    fprintf('    lambda0  = %.4f nm\n', lambda0*1e9);
end

legend('Location','best');
xlim([45 85]);

if normalizeSpectrum
    ylim([0 1.05]);
end

saveas(fig, fullfile(FIGURES_DIR, 'spectrum_comparison.png'));
close(fig);

save(fullfile(PROCESSED_DIR, 'spectrum_data.mat'), 'spec_data', '-v7.3');

disp('Spectrum analysis completed.');