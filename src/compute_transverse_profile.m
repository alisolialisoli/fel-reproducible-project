% src/compute_transverse_profile.m
disp('Running transverse profile analysis from .fld.h5 files...');

cfg(1).file   = fullfile(RAW_DIR, 'FIELD_END_RAD6_BRANCH_A.fld.h5');
cfg(1).label  = 'H7';

cfg(2).file   = fullfile(RAW_DIR, 'FIELD_END_RAD6_BRANCH_B.fld.h5');
cfg(2).label  = 'H6';

cfg(3).file   = fullfile(RAW_DIR, 'FIELD_END_RAD6_BRANCH_C.fld.h5');
cfg(3).label  = 'H5';

% Change to true only if the image orientation looks transposed
use_transpose_after_reshape = false;

transverse_data = struct();

for i = 1:numel(cfg)
    fname = cfg(i).file;
    label = cfg(i).label;

    assert(isfile(fname), 'Missing file: %s', fname);

    info = h5info(fname);
    groupNames = {info.Groups.Name};
    sliceGroups = groupNames(contains(groupNames, 'slice'));

    % Sort slices numerically
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

    nslices = numel(sliceGroups);

    % Read first slice to infer transverse grid size
    re0 = h5read(fname, [sliceGroups{1} '/field-real']);
    npts = numel(re0);
    ngrid = round(sqrt(npts));

    if ngrid^2 ~= npts
        error('Slice data in %s is not a square grid: numel = %d', fname, npts);
    end

    fprintf('[+] %s: nslices = %d, inferred ngrid = %d\n', label, nslices, ngrid);

    E_coh = zeros(ngrid, ngrid);

    for s = 1:nslices
        re = h5read(fname, [sliceGroups{s} '/field-real']);
        im = h5read(fname, [sliceGroups{s} '/field-imag']);

        Evec = complex(re, im);

        if numel(Evec) ~= ngrid * ngrid
            error('Slice %d in %s has inconsistent size.', s, fname);
        end

        Es = reshape(Evec, [ngrid, ngrid]);

        if use_transpose_after_reshape
            Es = Es.';
        end

        E_coh = E_coh + Es;
    end

    I_coh = abs(E_coh).^2;

    transverse_data.(label).E_coh = E_coh;
    transverse_data.(label).I_coh = I_coh;
    transverse_data.(label).nslices = nslices;
    transverse_data.(label).ngrid = ngrid;

    fig = figure('Visible','off','Color','w');
    imagesc(I_coh);
    axis image;
    set(gca,'YDir','normal');
    colorbar;
    title(sprintf('%s transverse profile (coherent sum)', label));
    xlabel('x index');
    ylabel('y index');
    saveas(fig, fullfile(FIGURES_DIR, ['transverse_' label '.png']));
    close(fig);
end

save(fullfile(PROCESSED_DIR, 'transverse_profiles.mat'), 'transverse_data', '-v7.3');

disp('Transverse profile analysis completed.');