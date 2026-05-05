% src/power_along_z.m
disp('Running power-along-z analysis from .out.h5 files...');

c = 299792458;

% ------------------------------------------------
% Full branch definitions
% ------------------------------------------------
branches.A.label = 'H7';
branches.A.files = { ...
    fullfile(RAW_DIR, 'A_H7_RAD12.out.h5'), ...
    fullfile(RAW_DIR, 'A_PROP_THROUGH_RAD36.out.h5') ...
};

branches.B.label = 'H6';
branches.B.files = { ...
    fullfile(RAW_DIR, 'B_H6_RAD34.out.h5'), ...
    fullfile(RAW_DIR, 'B_PROP_THROUGH_RAD56.out.h5') ...
};

branches.C.label = 'H5';
branches.C.files = { ...
    fullfile(RAW_DIR, 'C_H5_RAD56.out.h5') ...
};

[zA, PpeakA, EpulseA, brA] = stitch_branch(branches.A.files, c);
[zB, PpeakB, EpulseB, brB] = stitch_branch(branches.B.files, c);
[zC, PpeakC, EpulseC, brC] = stitch_branch(branches.C.files, c);

zscan.A.label = branches.A.label;
zscan.A.z_m = zA;
zscan.A.peak_power_W = PpeakA;
zscan.A.pulse_energy_J = EpulseA;
zscan.A.breaks_m = brA;

zscan.B.label = branches.B.label;
zscan.B.z_m = zB;
zscan.B.peak_power_W = PpeakB;
zscan.B.pulse_energy_J = EpulseB;
zscan.B.breaks_m = brB;

zscan.C.label = branches.C.label;
zscan.C.z_m = zC;
zscan.C.peak_power_W = PpeakC;
zscan.C.pulse_energy_J = EpulseC;
zscan.C.breaks_m = brC;

save(fullfile(PROCESSED_DIR, 'power_along_z.mat'), 'zscan', '-v7.3');

% ------------------------------------------------
% Combined peak power plot
% ------------------------------------------------
fig = figure('Visible','off','Color','w');
plot(zA, PpeakA, 'LineWidth', 1.8); hold on;
plot(zB, PpeakB, 'LineWidth', 1.8);
plot(zC, PpeakC, 'LineWidth', 1.8);
grid on;
xlabel('z [m]');
ylabel('Peak power [W]');
title('Peak power evolution along z');
legend('H7','H6','H5','Location','best');
saveas(fig, fullfile(FIGURES_DIR, 'power_along_z_peak_all.png'));
close(fig);

% ------------------------------------------------
% Combined pulse energy plot
% ------------------------------------------------
fig = figure('Visible','off','Color','w');
plot(zA, EpulseA, 'LineWidth', 1.8); hold on;
plot(zB, EpulseB, 'LineWidth', 1.8);
plot(zC, EpulseC, 'LineWidth', 1.8);
grid on;
xlabel('z [m]');
ylabel('Pulse energy [J]');
title('Pulse energy evolution along z');
legend('H7','H6','H5','Location','best');
saveas(fig, fullfile(FIGURES_DIR, 'power_along_z_energy_all.png'));
close(fig);

% ------------------------------------------------
% Individual branch plots
% ------------------------------------------------
save_single_branch_plot(zA, PpeakA, EpulseA, brA, 'H7', FIGURES_DIR);
save_single_branch_plot(zB, PpeakB, EpulseB, brB, 'H6', FIGURES_DIR);
save_single_branch_plot(zC, PpeakC, EpulseC, brC, 'H5', FIGURES_DIR);

fprintf('\nEND OF BRANCH EVOLUTION SUMMARY\n');
fprintf('H7 end: Peak = %.6e W, Energy = %.6e J\n', PpeakA(end), EpulseA(end));
fprintf('H6 end: Peak = %.6e W, Energy = %.6e J\n', PpeakB(end), EpulseB(end));
fprintf('H5 end: Peak = %.6e W, Energy = %.6e J\n\n', PpeakC(end), EpulseC(end));

disp('Power-along-z analysis completed.');

% ============================================================
% Helpers
% ============================================================

function z = read_z_axis(outFile)
    cand = {'/Lattice/zplot','/Global/zplot','/zplot'};
    z = [];
    for k = 1:numel(cand)
        try
            z = double(h5read(outFile, cand{k}));
            z = z(:).';
            return;
        catch
        end
    end
    error('Could not find z axis in %s', outFile);
end

function [zg, Ppeak_g, Epulse_g, zBreaks] = stitch_branch(fileList, c)
    zg = [];
    Ppeak_g = [];
    Epulse_g = [];
    zBreaks = [];

    zOffset = 0;

    for f = 1:numel(fileList)
        outFile = fileList{f};
        assert(isfile(outFile), 'File not found: %s', outFile);

        s = double(h5read(outFile, '/Global/s'));
        s = s(:);
        t_s = s / c;

        P = double(h5read(outFile, '/Field/power'));
        P = squeeze(P);

        if size(P,1) ~= numel(t_s) && size(P,2) == numel(t_s)
            P = P.';
        end

        assert(size(P,1) == numel(t_s), ...
            'Power dimensions do not match /Global/s in file: %s', outFile);

        zloc = read_z_axis(outFile);

        Ppeak  = max(P, [], 1);
        Epulse = trapz(t_s, P, 1);

        % Shift subsequent files so z is continuous
        zloc = zloc + zOffset;

        % Remove duplicated first point for all but the first file
        if f > 1
            zloc   = zloc(2:end);
            Ppeak  = Ppeak(2:end);
            Epulse = Epulse(2:end);
        end

        zg       = [zg, zloc];
        Ppeak_g  = [Ppeak_g, Ppeak];
        Epulse_g = [Epulse_g, Epulse];

        zOffset = zg(end);
        zBreaks(end+1) = zg(end);
    end
end

function save_single_branch_plot(z, Ppeak, Epulse, zBreaks, label, figures_dir)
    fig = figure('Visible','off','Color','w','Position',[100 100 900 700]);

    tiledlayout(2,1,'Padding','compact','TileSpacing','compact');

    nexttile;
    plot(z, Ppeak, 'LineWidth', 1.8); grid on;
    xlabel('z [m]');
    ylabel('Peak power [W]');
    title(sprintf('%s branch: peak power along z', label));
    for xb = zBreaks(1:end-1)
        xline(xb, '--');
    end

    nexttile;
    plot(z, Epulse, 'LineWidth', 1.8); grid on;
    xlabel('z [m]');
    ylabel('Pulse energy [J]');
    title(sprintf('%s branch: pulse energy along z', label));
    for xb = zBreaks(1:end-1)
        xline(xb, '--');
    end

    saveas(fig, fullfile(figures_dir, ['power_along_z_' label '.png']));
    close(fig);
end