% src/analyze_temporal_profile.m
disp('Running real temporal profile analysis from .out.h5 files...');

c = 299792458;

outA = fullfile(RAW_DIR, 'A_PROP_THROUGH_RAD36.out.h5');
outB = fullfile(RAW_DIR, 'B_PROP_THROUGH_RAD56.out.h5');
outC = fullfile(RAW_DIR, 'C_H5_RAD56.out.h5');

assert(isfile(outA), 'Missing file: %s', outA);
assert(isfile(outB), 'Missing file: %s', outB);
assert(isfile(outC), 'Missing file: %s', outC);

[tA_fs, PA, peakA, fwhmA_fs, EA_J] = final_pulse_from_out(outA, c);
[tB_fs, PB, peakB, fwhmB_fs, EB_J] = final_pulse_from_out(outB, c);
[tC_fs, PC, peakC, fwhmC_fs, EC_J] = final_pulse_from_out(outC, c);

% Save metrics to processed MAT file for later reuse
metrics.peak_power_W = [peakA; peakB; peakC];
metrics.fwhm_fs      = [fwhmA_fs; fwhmB_fs; fwhmC_fs];
metrics.pulse_energy_J = [EA_J; EB_J; EC_J];
metrics.branch = {'H7'; 'H6'; 'H5'};
save(fullfile(PROCESSED_DIR, 'pulse_metrics.mat'), 'metrics');

% Save pulse shapes too
pulse_data.H7.t_fs = tA_fs; pulse_data.H7.P = PA;
pulse_data.H6.t_fs = tB_fs; pulse_data.H6.P = PB;
pulse_data.H5.t_fs = tC_fs; pulse_data.H5.P = PC;
save(fullfile(PROCESSED_DIR, 'final_pulses.mat'), 'pulse_data', '-v7.3');

% Combined plot
fig = figure('Visible','off','Color','w');
plot(tA_fs, PA, 'LineWidth', 1.8); hold on;
plot(tB_fs, PB, 'LineWidth', 1.8);
plot(tC_fs, PC, 'LineWidth', 1.8);
grid on;
xlabel('Time [fs]');
ylabel('Power [W]');
title('Final output pulse at end of RAD6');
legend( ...
    sprintf('H7  Peak=%.3e W  FWHM=%.2f fs  E=%.3e J', peakA, fwhmA_fs, EA_J), ...
    sprintf('H6  Peak=%.3e W  FWHM=%.2f fs  E=%.3e J', peakB, fwhmB_fs, EB_J), ...
    sprintf('H5  Peak=%.3e W  FWHM=%.2f fs  E=%.3e J', peakC, fwhmC_fs, EC_J), ...
    'Location','best');
saveas(fig, fullfile(FIGURES_DIR, 'final_pulses_all.png'));
close(fig);

% Individual plots
save_single_pulse_plot(tA_fs, PA, 'H7', peakA, fwhmA_fs, EA_J, FIGURES_DIR);
save_single_pulse_plot(tB_fs, PB, 'H6', peakB, fwhmB_fs, EB_J, FIGURES_DIR);
save_single_pulse_plot(tC_fs, PC, 'H5', peakC, fwhmC_fs, EC_J, FIGURES_DIR);

fprintf('\nFINAL PULSE SUMMARY @ END OF RAD6\n');
fprintf('H7: Peak = %.6e W, FWHM = %.3f fs, Energy = %.6e J (%.3f uJ)\n', peakA, fwhmA_fs, EA_J, EA_J*1e6);
fprintf('H6: Peak = %.6e W, FWHM = %.3f fs, Energy = %.6e J (%.3f uJ)\n', peakB, fwhmB_fs, EB_J, EB_J*1e6);
fprintf('H5: Peak = %.6e W, FWHM = %.3f fs, Energy = %.6e J (%.3f uJ)\n\n', peakC, fwhmC_fs, EC_J, EC_J*1e6);

disp('Temporal profile analysis completed.');

function save_single_pulse_plot(t_fs, Pfinal, label, peakW, fwhm_fs, EJ, figures_dir)
    fig = figure('Visible','off','Color','w');
    plot(t_fs, Pfinal, 'LineWidth', 1.8);
    grid on;
    xlabel('Time [fs]');
    ylabel('Power [W]');
    title(sprintf('%s final pulse at end of RAD6', label));
    subtitle(sprintf('Peak=%.3e W, FWHM=%.2f fs, E=%.3e J', peakW, fwhm_fs, EJ));
    saveas(fig, fullfile(figures_dir, ['temporal_' label '.png']));
    close(fig);
end

function [t_fs, Pfinal, pmax, fwhm_fs, Epulse_J] = final_pulse_from_out(outFile, c)
    sPathCandidates = {'/Global/s','/Global/s_arr','/Global/slice_s','/Global/spos'};
    s = [];
    for k = 1:numel(sPathCandidates)
        if h5exists(outFile, sPathCandidates{k})
            s = double(h5read(outFile, sPathCandidates{k}));
            break;
        end
    end
    if isempty(s)
        error('Could not find /Global/s in %s', outFile);
    end
    s = s(:);

    t_s  = s / c;
    t_fs = t_s * 1e15;

    if ~h5exists(outFile, '/Field/power')
        error('Missing /Field/power in %s', outFile);
    end
    Pout = double(h5read(outFile, '/Field/power'));
    Pout = squeeze(Pout);

    if size(Pout,1) ~= numel(t_fs) && size(Pout,2) == numel(t_fs)
        Pout = Pout.';
    end

    Nz = size(Pout,2);
    Pfinal = Pout(:, Nz);

    Epulse_J = trapz(t_s, Pfinal);
    pmax = max(Pfinal);

    if pmax <= 0
        fwhm_fs = NaN;
        return;
    end

    halfMax = 0.5 * pmax;
    above = (Pfinal >= halfMax);
    if nnz(above) < 2
        fwhm_fs = NaN;
        return;
    end

    Ns = numel(Pfinal);
    i1 = find(above, 1, 'first');
    i2 = find(above, 1, 'last');

    if i1 == 1
        t1 = t_fs(1);
    else
        t1 = interp1(Pfinal(i1-1:i1), t_fs(i1-1:i1), halfMax, 'linear', 'extrap');
    end

    if i2 == Ns
        t2 = t_fs(end);
    else
        t2 = interp1(Pfinal(i2:i2+1), t_fs(i2:i2+1), halfMax, 'linear', 'extrap');
    end

    fwhm_fs = abs(t2 - t1);
end

function tf = h5exists(fname, dsetPath)
    tf = false;
    try
        h5info(fname, dsetPath);
        tf = true;
    catch
        tf = false;
    end
end