clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

load(fullfile(project_root, 'fixmap_data.mat'));

% groups_u  = {'Control'=1, 'ASD'=2, 'SAD'=3}
% positive difference → first-named group (ASD / SAD) fixates MORE
% consistent with LMM contrast direction in s04
diff_pairs  = [2 1;   % ASD - Control
               3 1;   % SAD - Control
               2 3];  % ASD - SAD

diff_labels = { ...
    'ASD - Control', 'Ctrl > ASD', 'ASD > Ctrl'; ...
    'SAD - Control', 'Ctrl > SAD', 'SAD > Ctrl'; ...
    'ASD - SAD',     'SAD > ASD', 'ASD > SAD'};


%% ── MEAN FIXATION MAPS: Group × Emotion ────────────────────────────────

allMaps = zeros(nG, nE, ySize, xSize);
for ig = 1:nG
    for ie = 1:nE
        idx = strcmp(cellstr(char(groupVec)), groups_u{ig}) & ...
              strcmp(cellstr(char(emotionVec)), emotions_list{ie});
        allMaps(ig, ie, :, :) = squeeze(mean(fixmapMat(idx,:,:), 1));
    end
end

clim_min = min(allMaps(:));
clim_max = max(allMaps(:));

fig_ge = figure('Name',     'Mean fixation maps: Group × Emotion', ...
                'Color',    'white', ...
                'Position', [50 50 220*nE 230*nG + 60]);

tl_ge = tiledlayout(fig_ge, nG, nE, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl_ge, 'Mean Fixation Maps by Group × Emotion', ...
      'FontSize', 16, 'FontWeight', 'bold');
xlabel(tl_ge, 'Emotion', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(tl_ge, 'Group',   'FontSize', 13, 'FontWeight', 'bold');

for ig = 1:nG
    for ie = 1:nE
        ax  = nexttile(tl_ge, (ig-1)*nE + ie);
        map = squeeze(allMaps(ig, ie, :, :));

        imshow(bg, 'Parent', ax);
        hold(ax, 'on');
        h = imagesc(ax, map, [clim_min clim_max]);
        set(h, 'AlphaData', 0.7);
        axis(ax, 'equal', 'off');
        colormap(ax, navia);

        if ie == 1
            ylabel(ax, groups_u{ig}, ...
                'FontSize', 13, 'FontWeight', 'bold', 'Rotation', 90);
        end
        if ig == 1
            title(ax, emotions_list{ie}, 'FontSize', 12, 'FontWeight', 'bold');
        end
    end
end

cb_ge = colorbar(nexttile(tl_ge, nG*nE), 'Location', 'eastoutside');
colormap(nexttile(tl_ge, nG*nE), navia);
cb_ge.Label.String   = 'Mean fixation intensity (Z-scored)';
cb_ge.Label.FontSize = 11;
cb_ge.FontSize       = 9;
clim(nexttile(tl_ge, nG*nE), [clim_min clim_max]);


%% ── MEAN FIXATION MAPS: Group only (collapsed across emotions) ──────────

allMaps_group = zeros(nG, ySize, xSize);
for ig = 1:nG
    idx = strcmp(cellstr(char(groupVec)), groups_u{ig});
    allMaps_group(ig, :, :) = squeeze(mean(fixmapMat(idx,:,:), 1));
end

clim_min_g = min(allMaps_group(:));
clim_max_g = max(allMaps_group(:));

fig_g = figure('Name',     'Mean fixation maps: Group (all emotions)', ...
               'Color',    'white', ...
               'Position', [50 50 370*nG 380]);

tl_g = tiledlayout(fig_g, 1, nG, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl_g, 'Mean Fixation Maps by Group (All Emotions)', ...
      'FontSize', 16, 'FontWeight', 'bold');

for ig = 1:nG
    ax  = nexttile(tl_g, ig);
    map = squeeze(allMaps_group(ig, :, :));

    imshow(bg, 'Parent', ax);
    hold(ax, 'on');
    h = imagesc(ax, map, [clim_min_g clim_max_g]);
    set(h, 'AlphaData', 0.75);
    axis(ax, 'equal', 'off');
    colormap(ax, navia);
    title(ax, groups_u{ig}, 'FontSize', 16, 'FontWeight', 'bold');
end

cb_g = colorbar(nexttile(tl_g, nG), 'Location', 'eastoutside');
colormap(nexttile(tl_g, nG), navia);
cb_g.Label.String   = 'Mean fixation intensity (Z-scored)';
cb_g.Label.FontSize = 12;
cb_g.FontSize       = 10;
clim(nexttile(tl_g, nG), [clim_min_g clim_max_g]);


%% ── RAW DIFFERENCE MAPS ─────────────────────────────────────────────────

for ie = 1:nE
    emo = emotions_list{ie};

    diffMaps = zeros(3, ySize, xSize);
    for ip = 1:3
        ga = diff_pairs(ip, 1);
        gb = diff_pairs(ip, 2);
        diffMaps(ip,:,:) = squeeze(allMaps(ga, ie, :, :)) - ...
                           squeeze(allMaps(gb, ie, :, :));
    end

    abs_max = prctile(abs(diffMaps(:)), 99);
    if abs_max == 0, abs_max = 1; end

    fig = figure('Name',     sprintf('Difference maps — %s', emo), ...
                 'Color',    'white', ...
                 'Position', [50 50 420*3 430]);

    tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('Raw Fixation Difference Maps — %s', emo), ...
          'FontSize', 15, 'FontWeight', 'bold');

    for ip = 1:3
        ax   = nexttile(ip);
        dmap = squeeze(diffMaps(ip,:,:));

        imshow(bg, 'Parent', ax);
        hold(ax, 'on');

        h_ghost = imagesc(ax, dmap, [-abs_max abs_max]);
        set(h_ghost, 'AlphaData', 0.4);

        colormap(ax, roma);
        axis(ax, 'equal', 'off');
        clim(ax, [-abs_max abs_max]);

        annotation_str = sprintf( ...
            '\\color[rgb]{0.8 0.1 0.1}%s   \\color[rgb]{0.1 0.1 0.8}%s', ...
            diff_labels{ip,2}, diff_labels{ip,3});
        title(ax, {diff_labels{ip,1}, annotation_str}, ...
              'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'tex');

        if ip == 3
            cb = colorbar(ax, 'Location', 'eastoutside');
            cb.Label.String      = '\DeltaZ-score (mean fixation)';
            cb.Label.FontSize    = 10;
            cb.FontSize          = 9;
            cb.Label.Interpreter = 'tex';
            nice_ticks = unique([-abs_max, -0.5, 0, 0.5, abs_max]);
            nice_ticks = nice_ticks(nice_ticks >= -abs_max & nice_ticks <= abs_max);
            cb.Ticks      = nice_ticks;
            cb.TickLabels = arrayfun(@(v) sprintf('%.2f', v), nice_ticks, ...
                                     'UniformOutput', false);
        end
    end

    fprintf('Difference maps — %s: range [%.3f, %.3f]\n', emo, -abs_max, abs_max);
end

fprintf('\nDescriptive plots done.\n');