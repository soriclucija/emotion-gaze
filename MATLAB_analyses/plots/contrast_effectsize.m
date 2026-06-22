clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

load(fullfile(project_root, 'fixmap_data.mat'));
load(fullfile(project_root, 'contrast_results.mat'));

%% GLOBAL FONT SETTINGS — Arial, 16pt, normal weight, applied everywhere
set(groot, 'DefaultAxesFontName',  'Arial');
set(groot, 'DefaultAxesFontSize',  16);
set(groot, 'DefaultAxesFontWeight','normal');
set(groot, 'DefaultTextFontName',  'Arial');
set(groot, 'DefaultTextFontSize',  16);
set(groot, 'DefaultTextFontWeight','normal');

COHEN_CLIM = 0.5;
SIG_FIELD  = 'Pmask';

% groups_u = {'Control'=1, 'ASD'=2, 'SAD'=3}
diff_pairs  = [2 1;   % ASD - Control
               3 1;   % SAD - Control
               2 3];  % ASD - SAD

diff_labels = { ...
    'ASD - Control', 'Ctrl > ASD', 'ASD > Ctrl'; ...
    'SAD - Control', 'Ctrl > SAD', 'SAD > Ctrl'; ...
    'ASD - SAD',     'SAD > ASD', 'ASD > SAD'};

%% PRE-COMPUTE PER-GROUP MEANS AND SDs
fprintf('Computing per-group pixel means and SDs...\n');
groupMean = zeros(nG, nE, ySize, xSize);
groupSD   = zeros(nG, nE, ySize, xSize);
for ig = 1:nG
    for ie = 1:nE
        idx    = strcmp(cellstr(char(groupVec)), groups_u{ig}) & ...
                 strcmp(cellstr(char(emotionVec)), emotions_list{ie});
        trials = fixmapMat(idx, :, :);
        groupMean(ig, ie, :, :) = mean(trials, 1);
        groupSD(ig,   ie, :, :) = std(trials,  0, 1);
    end
end
fprintf('Done.\n\n');

%% LAYOUT — all sizes in centimeters, 0.5 cm gap between images
gap_cm    = 0.5;
img_h_cm  = 4;
img_w_cm  = img_h_cm * (xSize / ySize);

left_margin_cm   = 0.2;
top_margin_cm    = 1.2;   % space for two-line title + colored annotation
right_margin_cm  = 2.7;   % space for colorbar
bottom_margin_cm = 0.5;

nP = 3;

fig_w_cm = left_margin_cm + nP*img_w_cm + (nP-1)*gap_cm + right_margin_cm;
fig_h_cm = top_margin_cm  + img_h_cm + bottom_margin_cm;

%% PLOT COHEN'S d — significant pixels only
ref_ticks  = [-COHEN_CLIM, -0.2, 0, 0.2, COHEN_CLIM];
ref_labels = { ...
    sprintf('%.1f', -COHEN_CLIM), '-0.2', '0', '0.2', ...
    sprintf('%.1f', COHEN_CLIM)};
in_range   = ref_ticks >= -COHEN_CLIM & ref_ticks <= COHEN_CLIM;

for ie = 1:nE
    emo         = emotions_list{ie};
    StatMap_c_e = StatMap_c_all{ie};

    fprintf('==========================================\n');
    fprintf(' Cohen''s d - %s\n', emo);
    fprintf('==========================================\n');

    fig = figure('Name', sprintf("Cohen's d - %s", emo), ...
                  'Color', 'white', ...
                  'Units', 'centimeters', ...
                  'Position', [2 2 fig_w_cm fig_h_cm]);

    colormap(fig, roma);

    for ip = 1:3
        ga = diff_pairs(ip, 1);
        gb = diff_pairs(ip, 2);

        mu_a      = squeeze(groupMean(ga, ie, :, :));
        mu_b      = squeeze(groupMean(gb, ie, :, :));
        sd_a      = squeeze(groupSD(ga,   ie, :, :));
        sd_b      = squeeze(groupSD(gb,   ie, :, :));
        pooled_sd = sqrt((sd_a.^2 + sd_b.^2) / 2);

        dmap        = zeros(ySize, xSize);
        valid       = pooled_sd > 0 & masktmp;
        dmap(valid) = (mu_a(valid) - mu_b(valid)) ./ pooled_sd(valid);

        sig_ic = squeeze(StatMap_c_e(1).(SIG_FIELD)(ip, :, :));
        sig_ic = logical(sig_ic) & masktmp;

        if any(sig_ic(:))
            sig_d   = dmap(sig_ic);
            [~, mi] = max(abs(sig_d));
            peak_d  = sig_d(mi);
            fprintf('  %s | peak d = %.3f | sig px = %d\n', ...
                diff_labels{ip,1}, peak_d, sum(sig_ic(:)));
        else
            fprintf('  %s | no significant pixels\n', diff_labels{ip,1});
        end

        left_cm = left_margin_cm + (ip-1)*(img_w_cm + gap_cm);
        ax = axes(fig, 'Units', 'normalized', ...
            'Position', [left_cm/fig_w_cm, bottom_margin_cm/fig_h_cm, ...
                          img_w_cm/fig_w_cm, img_h_cm/fig_h_cm]);

        image(ax, bg);
        hold(ax, 'on');

        h_sig = imagesc(ax, dmap .* sig_ic, [-COHEN_CLIM COHEN_CLIM]);
        set(h_sig, 'AlphaData', double(sig_ic) * 0.55);

        axis(ax, 'image', 'off');
        clim(ax, [-COHEN_CLIM COHEN_CLIM]);

        if any(sig_ic(:))
            contour(ax, double(sig_ic), [0.5 0.5], 'k-', 'LineWidth', 1.4);
        end

        %annotation_str = sprintf( ...
            %'\\color[rgb]{0.8 0.1 0.1}%s   \\color[rgb]{0.1 0.1 0.8}%s', ...
            %diff_labels{ip,2}, diff_labels{ip,3});

        text(ax, 0.5, 1.02, diff_labels{ip,1}, 'Units', 'normalized', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 16, 'FontWeight', 'normal');
        %text(ax, 0.5, 1.02, annotation_str, 'Units', 'normalized', ...
            %'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            %'FontSize', 16, 'Interpreter', 'tex');

        hold(ax, 'off');
    end

    % single shared colorbar, full image height
    cb_left_cm   = left_margin_cm + nP*img_w_cm + (nP-1)*gap_cm + 0.3;
    cb_width_cm  = 0.4;
    cb_bottom_cm = bottom_margin_cm;
    cb_height_cm = img_h_cm;

    cb = colorbar(ax);
    cb.Units    = 'normalized';
    cb.Position = [cb_left_cm/fig_w_cm, cb_bottom_cm/fig_h_cm, ...
                   cb_width_cm/fig_w_cm, cb_height_cm/fig_h_cm];
    cb.Label.String   = "Cohen's d";
    cb.Label.FontSize = 14;
    cb.FontSize       = 14;
    cb.Ticks      = ref_ticks(in_range);
    cb.TickLabels = ref_labels(in_range);
    clim(ax, [-COHEN_CLIM COHEN_CLIM]);
end

fprintf('\nCohen''s d maps complete.\n');
