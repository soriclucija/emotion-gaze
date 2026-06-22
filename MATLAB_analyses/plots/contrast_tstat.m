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

TMAP_FIELD = 'map';
SIG_FIELD  = 'Pmask';

% groups_u = {'Control'=1, 'ASD'=2, 'SAD'=3}
diff_pairs  = [2 1;   % ASD - Control
               3 1;   % SAD - Control
               2 3];  % ASD - SAD

diff_labels = { ...
    'ASD - Control', 'Ctrl > ASD', 'ASD > Ctrl'; ...
    'SAD - Control', 'Ctrl > SAD', 'SAD > Ctrl'; ...
    'ASD - SAD',     'SAD > ASD', 'ASD > SAD'};

%% GLOBAL COLOR LIMIT — symmetric, shared across ALL emotions and contrasts
fprintf('Computing global t-statistic range...\n');
all_tvals_global = [];
for ie = 1:nE
    StatMap_c_e = StatMap_c_all{ie};
    for ip = 1:3
        tmap = squeeze(StatMap_c_e(1).(TMAP_FIELD)(ip, :, :));
        all_tvals_global = [all_tvals_global; abs(tmap(masktmp))];
    end
end
T_CLIM = prctile(all_tvals_global, 99);
if T_CLIM == 0, T_CLIM = 1; end
fprintf('Done. Global |t| limit (99th percentile): %.3f\n\n', T_CLIM);

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

%% PLOT t-STATISTIC — significant pixels only
ref_ticks  = [0, T_CLIM/2, T_CLIM];
ref_labels = { ...
    '0', sprintf('%.1f', T_CLIM/2), sprintf('%.1f', T_CLIM)};
in_range   = ref_ticks >= 0 & ref_ticks <= T_CLIM;

for ie = 1:nE
    emo         = emotions_list{ie};
    StatMap_c_e = StatMap_c_all{ie};

    fprintf('==========================================\n');
    fprintf(' t-statistic - %s\n', emo);
    fprintf('==========================================\n');

    fig = figure('Name', sprintf('t-statistic - %s', emo), ...
                  'Color', 'white', ...
                  'Units', 'centimeters', ...
                  'Position', [2 2 fig_w_cm fig_h_cm]);

    colormap(fig, lajolla);

    for ip = 1:3
        tmap = squeeze(StatMap_c_e(1).(TMAP_FIELD)(ip, :, :));

        sig_ic = squeeze(StatMap_c_e(1).(SIG_FIELD)(ip, :, :));
        sig_ic = logical(sig_ic) & masktmp;

        if any(sig_ic(:))
            sig_t   = tmap(sig_ic);
            [~, mi] = max(abs(sig_t));
            peak_t  = sig_t(mi);
            fprintf('  %s | peak t = %.3f | sig px = %d\n', ...
                diff_labels{ip,1}, peak_t, sum(sig_ic(:)));
        else
            fprintf('  %s | no significant pixels\n', diff_labels{ip,1});
        end

        left_cm = left_margin_cm + (ip-1)*(img_w_cm + gap_cm);
        ax = axes(fig, 'Units', 'normalized', ...
            'Position', [left_cm/fig_w_cm, bottom_margin_cm/fig_h_cm, ...
                          img_w_cm/fig_w_cm, img_h_cm/fig_h_cm]);

        image(ax, bg);
        hold(ax, 'on');

        h_sig = imagesc(ax, tmap .* sig_ic, [0 T_CLIM]);
        set(h_sig, 'AlphaData', double(sig_ic) * 0.55);

        axis(ax, 'image', 'off');
        clim(ax, [0 T_CLIM]);

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
    cb.Label.String   = 't-statistic';
    cb.Label.FontSize = 14;
    cb.FontSize       = 14;
    cb.Ticks      = ref_ticks(in_range);
    cb.TickLabels = ref_labels(in_range);
    clim(ax, [0 T_CLIM]);
end

fprintf('\nt-statistic maps complete.\n');