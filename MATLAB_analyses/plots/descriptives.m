clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

load(fullfile(project_root, 'fixmap_data.mat'));

%% GLOBAL FONT SETTINGS — Arial, 16pt, normal weight, applied everywhere
set(groot, 'DefaultAxesFontName',  'Arial');
set(groot, 'DefaultAxesFontSize',  16);
set(groot, 'DefaultAxesFontWeight','normal');
set(groot, 'DefaultTextFontName',  'Arial');
set(groot, 'DefaultTextFontSize',  16);
set(groot, 'DefaultTextFontWeight','normal');

% groups_u  = {'Control'=1, 'ASD'=2, 'SAD'=3}
% positive difference -> first-named group (ASD / SAD) fixates MORE
% consistent with LMM contrast direction in s04
diff_pairs  = [2 1;   % ASD - Control
               3 1;   % SAD - Control
               2 3];  % ASD - SAD

diff_labels = { ...
    'ASD - Control', 'Ctrl > ASD', 'ASD > Ctrl'; ...
    'SAD - Control', 'Ctrl > SAD', 'SAD > Ctrl'; ...
    'ASD - SAD',     'SAD > ASD', 'ASD > SAD'};


%% MEAN FIXATION MAPS: Group x Emotion

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

%% LAYOUT — all sizes in centimeters, 0.5 cm gap between images
gap_cm    = 0.3;
img_h_cm  = 4;                          % height of each image
img_w_cm  = img_h_cm * (xSize / ySize); % width, preserving aspect ratio

left_margin_cm   = 1.0;   % space for group row labels
top_margin_cm    = 0.7;   % space for emotion column titles
right_margin_cm  = 2.7;   % space for colorbar
bottom_margin_cm = 0.2;

fig_w_cm = left_margin_cm + nE*img_w_cm + (nE-1)*gap_cm + right_margin_cm;
fig_h_cm = top_margin_cm  + nG*img_h_cm + (nG-1)*gap_cm + bottom_margin_cm;

fig_ge = figure('Name', 'Mean fixation maps: Group x Emotion', ...
                'Color', 'white', ...
                'Units', 'centimeters', ...
                'Position', [2 2 fig_w_cm fig_h_cm]);

colormap(fig_ge, lapaz);

for ig = 1:nG
    for ie = 1:nE
        left_cm   = left_margin_cm   + (ie-1)*(img_w_cm + gap_cm);
        bottom_cm = bottom_margin_cm + (nG-ig)*(img_h_cm + gap_cm);

        ax = axes(fig_ge, 'Units', 'normalized', ...
            'Position', [left_cm/fig_w_cm, bottom_cm/fig_h_cm, ...
                          img_w_cm/fig_w_cm, img_h_cm/fig_h_cm]);

        map = squeeze(allMaps(ig, ie, :, :));

        image(ax, bg);
        hold(ax, 'on');
        h = imagesc(ax, map, [clim_min clim_max]);
        set(h, 'AlphaData', 0.85);
        axis(ax, 'image', 'off');

        % row labels (group names)
        if ie == 1
            text(ax, -0.02, 0.5, groups_u{ig}, 'Units', 'normalized', ...
                'Rotation', 90, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 16, 'FontWeight', 'normal');
        end

        % column titles (emotion names)
        if ig == 1
            text(ax, 0.5, 1.02, emotions_list{ie}, 'Units', 'normalized', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 16, 'FontWeight', 'normal');
        end

        hold(ax, 'off');
    end
end

% single shared colorbar, full height of the grid
cb_left_cm = left_margin_cm + nE*img_w_cm + (nE-1)*gap_cm + 0.3;
cb_width_cm = 0.4;
cb_bottom_cm = bottom_margin_cm;
cb_height_cm = nG*img_h_cm + (nG-1)*gap_cm;

cb_ge = colorbar(ax);
cb_ge.Units    = 'normalized';
cb_ge.Position = [cb_left_cm/fig_w_cm, cb_bottom_cm/fig_h_cm, ...
                  cb_width_cm/fig_w_cm, cb_height_cm/fig_h_cm];
cb_ge.Label.String   = 'Mean fixation intensity (Z-scored)';
cb_ge.Label.FontSize = 16;
cb_ge.FontSize       = 16;
clim(ax, [clim_min clim_max]);
%% MEAN FIXATION MAPS: Group only (collapsed across emotions)

allMaps_group = zeros(nG, ySize, xSize);
for ig = 1:nG
    idx = strcmp(cellstr(char(groupVec)), groups_u{ig});
    allMaps_group(ig, :, :) = squeeze(mean(fixmapMat(idx,:,:), 1));
end

clim_min_g = min(allMaps_group(:));
clim_max_g = max(allMaps_group(:));

%% LAYOUT — all sizes in centimeters, 0.5 cm gap between images
gap_cm    = 0.3;
img_h_cm  = 6;                          % height of each image
img_w_cm  = img_h_cm * (xSize / ySize); % width, preserving aspect ratio

left_margin_cm   = 0.2;
top_margin_cm    = 1.3;   % space for group titles
right_margin_cm  = 2.7;   % space for colorbar
bottom_margin_cm = 1.3;

fig_w_cm = left_margin_cm + nG*img_w_cm + (nG-1)*gap_cm + right_margin_cm;
fig_h_cm = top_margin_cm  + img_h_cm + bottom_margin_cm;

fig_g = figure('Name', 'Mean fixation maps: Group (all emotions)', ...
               'Color', 'white', ...
               'Units', 'centimeters', ...
               'Position', [2 2 fig_w_cm fig_h_cm]);

colormap(fig_g, lapaz);

for ig = 1:nG
    left_cm = left_margin_cm + (ig-1)*(img_w_cm + gap_cm);

    ax = axes(fig_g, 'Units', 'normalized', ...
        'Position', [left_cm/fig_w_cm, bottom_margin_cm/fig_h_cm, ...
                      img_w_cm/fig_w_cm, img_h_cm/fig_h_cm]);

    map = squeeze(allMaps_group(ig, :, :));

    image(ax, bg);
    hold(ax, 'on');
    h = imagesc(ax, map, [clim_min_g 5]);
    set(h, 'AlphaData', 0.85);
    axis(ax, 'image', 'off');

    text(ax, 0.5, 1.02, groups_u{ig}, 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 16, 'FontWeight', 'normal');

    hold(ax, 'off');
end

% single shared colorbar, full height of the images
cb_left_cm   = left_margin_cm + nG*img_w_cm + (nG-1)*gap_cm + 0.3;
cb_width_cm  = 0.4;
cb_bottom_cm = bottom_margin_cm;
cb_height_cm = img_h_cm;

cb_g = colorbar(ax);
cb_g.Units    = 'normalized';
cb_g.Position = [cb_left_cm/fig_w_cm, cb_bottom_cm/fig_h_cm, ...
                 cb_width_cm/fig_w_cm, cb_height_cm/fig_h_cm];
cb_g.Label.String   = 'Mean fixation intensity (Z-scored)';
cb_g.Label.FontSize = 16;
cb_g.FontSize       = 16;
clim(ax, [clim_min_g 5]);


%% RAW DIFFERENCE MAPS

% layout — all sizes in centimeters, 0.5 cm gap between images
gap_cm    = 0.3;
img_h_cm  = 4;
img_w_cm  = img_h_cm * (xSize / ySize);

left_margin_cm   = 0.2;
top_margin_cm    = 1.2;   % space for two-line title + colored annotation
right_margin_cm  = 3;   % space for colorbar
bottom_margin_cm = 1.2;

nP = 3;   % ASD vs Control, SAD vs Control, ASD vs SAD

fig_w_cm = left_margin_cm + nP*img_w_cm + (nP-1)*gap_cm + right_margin_cm;
fig_h_cm = top_margin_cm  + img_h_cm + bottom_margin_cm;

% global color limit — shared across all emotions
all_diffs = [];
for ie = 1:nE
    for ip = 1:3
        ga = diff_pairs(ip, 1);
        gb = diff_pairs(ip, 2);
        d  = squeeze(allMaps(ga, ie, :, :)) - squeeze(allMaps(gb, ie, :, :));
        all_diffs = [all_diffs; d(:)];
    end
end
abs_max = prctile(abs(all_diffs), 99);
if abs_max == 0, abs_max = 1; end
fprintf('Global color limit (99th percentile of |diff|): %.3f\n', abs_max);

for ie = 1:nE
    emo = emotions_list{ie};

    diffMaps = zeros(3, ySize, xSize);
    for ip = 1:3
        ga = diff_pairs(ip, 1);
        gb = diff_pairs(ip, 2);
        diffMaps(ip,:,:) = squeeze(allMaps(ga, ie, :, :)) - ...
                           squeeze(allMaps(gb, ie, :, :));
    end

    fig = figure('Name', sprintf('Difference maps - %s', emo), ...
                 'Color', 'white', ...
                 'Units', 'centimeters', ...
                 'Position', [2 2 fig_w_cm fig_h_cm]);

    colormap(fig, roma);

    for ip = 1:3
        left_cm = left_margin_cm + (ip-1)*(img_w_cm + gap_cm);

        ax = axes(fig, 'Units', 'normalized', ...
            'Position', [left_cm/fig_w_cm, bottom_margin_cm/fig_h_cm, ...
                          img_w_cm/fig_w_cm, img_h_cm/fig_h_cm]);

        dmap = squeeze(diffMaps(ip,:,:));

        image(ax, bg);
        hold(ax, 'on');
        h_ghost = imagesc(ax, dmap, [-abs_max abs_max]);
        set(h_ghost, 'AlphaData', 0.4);
        axis(ax, 'image', 'off');
        clim(ax, [-abs_max abs_max]);

        %annotation_str = sprintf( ...
           % '\\color[rgb]{0.8 0.1 0.1}%s   \\color[rgb]{0.1 0.1 0.8}%s', ...
            %diff_labels{ip,2}, diff_labels{ip,3});

        text(ax, 0.5, 1.02, diff_labels{ip,1}, 'Units', 'normalized', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 16, 'FontWeight', 'normal');
       %text(ax, 0.5, 1.02, annotation_str, 'Units', 'normalized', ...
            %'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            %'FontSize', 16, 'Interpreter', 'tex');

        hold(ax, 'off');
    end

    % single shared colorbar, full height of the images
    cb_left_cm   = left_margin_cm + nP*img_w_cm + (nP-1)*gap_cm + 0.3;
    cb_width_cm  = 0.4;
    cb_bottom_cm = bottom_margin_cm;
    cb_height_cm = img_h_cm;

    cb = colorbar(ax);
    cb.Units    = 'normalized';
    cb.Position = [cb_left_cm/fig_w_cm, cb_bottom_cm/fig_h_cm, ...
                   cb_width_cm/fig_w_cm, cb_height_cm/fig_h_cm];
    cb.Label.String      = '\Delta Z-score (mean fixation)';
    cb.Label.FontSize    = 14;
    cb.FontSize          = 14;
    cb.Label.Interpreter = 'tex';
    nice_ticks = unique([-abs_max, (-abs_max)/2, 0, abs_max/2, abs_max]);
    nice_ticks = nice_ticks(nice_ticks >= -abs_max & nice_ticks <= abs_max);
    cb.Ticks      = nice_ticks;
    cb.TickLabels = arrayfun(@(v) sprintf('%.2f', v), nice_ticks, ...
                             'UniformOutput', false);
    clim(ax, [-abs_max abs_max]);

    fprintf('Difference maps - %s: range [%.3f, %.3f]\n', emo, -abs_max, abs_max);
end

fprintf('\nDescriptive plots done.\n');