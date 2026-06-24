clear all
clc

%% =========================================================================
%  s08_shift_difference.m
%
%  PURPOSE: Test whether the emotion-vs-neutral fixation shift differs
%  between groups (Group x Emotion interaction contrasts). For each
%  contrast emotion the shift difference simplifies to the interaction
%  term(s) alone:
%    ASD vs Control shift = beta_ASD:emotion_E
%    SAD vs Control shift = beta_SAD:emotion_E
%    ASD vs SAD shift     = beta_ASD:emotion_E - beta_SAD:emotion_E
% =========================================================================

%% SET THIS — same folder as everything else
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

imap_folder = fullfile(project_root, 'iMap4-master');
addpath(genpath(imap_folder));

load(fullfile(project_root, 'fixmap_data.mat'));
load(fullfile(project_root, 'LMMmap_results.mat'));

%% GLOBAL FONT SETTINGS
set(groot, 'DefaultAxesFontName',  'Arial');
set(groot, 'DefaultAxesFontSize',  16);
set(groot, 'DefaultAxesFontWeight','normal');
set(groot, 'DefaultTextFontName',  'Arial');
set(groot, 'DefaultTextFontSize',  16);
set(groot, 'DefaultTextFontWeight','normal');

%% MCC SETTINGS — match s03
USE_BOOTSTRAP = 0;
NBOOT         = 1000;

if USE_BOOTSTRAP
    fprintf('Bootstrap MCC (%d iterations)\n', NBOOT);
    mccopt_base.methods   = 'bootstrap';
    mccopt_base.bootgroup = {'group'};
    mccopt_base.nboot     = NBOOT;
    mccopt_base.bootopt   = 1;
    mccopt_base.tfce      = 0;
else
    fprintf('FDR correction enabled\n');
    mccopt_base.methods = 'FDR';
end

%% CONTRAST SETUP
contrast_emotions = {'Anger', 'Fear', 'Happiness', 'Sadness'};
nCE = length(contrast_emotions);

nCoef     = length(lmexample.CoefficientNames);
coefnames = lmexample.CoefficientNames;

% group main effect columns (needed for ASD vs SAD shift)
asd_main_col = find(strcmp(coefnames, 'group_ASD'));
sad_main_col = find(strcmp(coefnames, 'group_SAD'));

fprintf('Coefficient names:\n');
disp(lmexample.CoefficientNames);

%% -------------------------------------------------------------------------
%  RUN SHIFT-DIFFERENCE CONTRASTS
%  StatMap_shift_all{ie}: cell per contrast emotion, 3 contrasts stacked
% -------------------------------------------------------------------------

StatMap_shift_all = cell(nCE, 1);

fprintf('==========================================\n');
fprintf(' Shift-difference contrasts\n');
fprintf('==========================================\n');

for ie = 1:nCE
    emo = contrast_emotions{ie};

    % interaction term columns for this emotion
    asd_int_name = sprintf('group_ASD:emotion_%s', emo);
    sad_int_name = sprintf('group_SAD:emotion_%s', emo);

    asd_int_col = find(strcmp(coefnames, asd_int_name));
    sad_int_col = find(strcmp(coefnames, sad_int_name));

    assert(~isempty(asd_int_col), '%s not found in CoefficientNames', asd_int_name);
    assert(~isempty(sad_int_col), '%s not found in CoefficientNames', sad_int_name);

    fprintf('  %s -> ASD int col: %d, SAD int col: %d\n', emo, asd_int_col, sad_int_col);

    % ASD vs Control shift = beta_ASD:emotion_E
    c_ASDvsC = zeros(1, nCoef);
    c_ASDvsC(asd_int_col) = 1;

    % SAD vs Control shift = beta_SAD:emotion_E
    c_SADvsC = zeros(1, nCoef);
    c_SADvsC(sad_int_col) = 1;

    % ASD vs SAD shift = beta_ASD:emotion_E - beta_SAD:emotion_E
    c_ASDvsS = zeros(1, nCoef);
    c_ASDvsS(asd_int_col) =  1;
    c_ASDvsS(sad_int_col) = -1;

    opt_con       = struct;
    opt_con.type  = 'predictor beta';
    opt_con.alpha = .05;
    opt_con.c     = {c_ASDvsC; c_SADvsC; c_ASDvsS};
    opt_con.name  = { ...
        sprintf('ASD vs Control shift — %s', emo); ...
        sprintf('SAD vs Control shift — %s', emo); ...
        sprintf('ASD vs SAD shift — %s',     emo)};

    [StatMap]   = imapLMMcontrast(LMMmap, opt_con);
    [StatMap_c] = imapLMMmcc(StatMap, LMMmap, mccopt_base, fixmapMat);
    StatMap_shift_all{ie} = StatMap_c;

    fprintf('  Contrasts done — %s\n', emo);
end

save(fullfile(project_root, 'shift_diff_results.mat'), 'StatMap_shift_all', '-v7.3');
fprintf('DONE: Saved shift_diff_results.mat\n\n');

%% =========================================================================
%  PLOT — one figure per emotion, 3 panels (ASD-C, SAD-C, ASD-SAD)
% =========================================================================

TMAP_FIELD = 'map';
SIG_FIELD  = 'Pmask';

shift_labels = { ...
    'ASD vs Control'; ...
    'SAD vs Control'; ...
    'ASD vs SAD'};

%% GLOBAL COLOR LIMIT — shared across all emotions and contrasts
fprintf('Computing global t-statistic range...\n');
all_tvals_global = [];
for ie = 1:nCE
    StatMap_c_e = StatMap_shift_all{ie};
    for ip = 1:3
        tmap = squeeze(StatMap_c_e(1).(TMAP_FIELD)(ip, :, :));
        all_tvals_global = [all_tvals_global; tmap(masktmp)];
    end
end
T_CLIM = prctile(abs(all_tvals_global), 99);
if T_CLIM == 0, T_CLIM = 1; end
fprintf('Done. Global |t| limit (99th percentile): %.3f\n\n', T_CLIM);

%% LAYOUT
gap_cm    = 0.5;
img_h_cm  = 4;
img_w_cm  = img_h_cm * (xSize / ySize);

left_margin_cm   = 0.2;
top_margin_cm    = 1.2;
right_margin_cm  = 2.7;
bottom_margin_cm = 0.5;

nP = 3;

fig_w_cm = left_margin_cm + nP*img_w_cm + (nP-1)*gap_cm + right_margin_cm;
fig_h_cm = top_margin_cm  + img_h_cm + bottom_margin_cm;

ref_ticks  = [-T_CLIM, -T_CLIM/2, 0, T_CLIM/2, T_CLIM];
ref_labels = {sprintf('%.1f', -T_CLIM), sprintf('%.1f', -T_CLIM/2), '0', ...
              sprintf('%.1f', T_CLIM/2), sprintf('%.1f', T_CLIM)};
in_range   = ref_ticks >= -T_CLIM & ref_ticks <= T_CLIM;

for ie = 1:nCE
    emo         = contrast_emotions{ie};
    StatMap_c_e = StatMap_shift_all{ie};

    fprintf('==========================================\n');
    fprintf(' Shift-difference t-statistic — %s\n', emo);
    fprintf('==========================================\n');

    fig = figure('Name', sprintf('Shift-difference t-statistic — %s', emo), ...
                  'Color', 'white', ...
                  'Units', 'centimeters', ...
                  'Position', [2 2 fig_w_cm fig_h_cm]);

    colormap(fig, roma);

    for ip = 1:3
        tmap = squeeze(StatMap_c_e(1).(TMAP_FIELD)(ip, :, :));

        sig_ic = squeeze(StatMap_c_e(1).(SIG_FIELD)(ip, :, :));
        sig_ic = logical(sig_ic) & masktmp;

        if any(sig_ic(:))
            sig_t   = tmap(sig_ic);
            [~, mi] = max(abs(sig_t));
            peak_t  = sig_t(mi);
            fprintf('  %s | peak t = %.3f | sig px = %d\n', ...
                shift_labels{ip}, peak_t, sum(sig_ic(:)));
        else
            fprintf('  %s | no significant pixels\n', shift_labels{ip});
        end

        left_cm = left_margin_cm + (ip-1)*(img_w_cm + gap_cm);
        ax = axes(fig, 'Units', 'normalized', ...
            'Position', [left_cm/fig_w_cm, bottom_margin_cm/fig_h_cm, ...
                          img_w_cm/fig_w_cm, img_h_cm/fig_h_cm]);

        image(ax, bg);
        hold(ax, 'on');

        h_sig = imagesc(ax, tmap .* sig_ic, [-T_CLIM T_CLIM]);
        set(h_sig, 'AlphaData', double(sig_ic) * 0.55);

        axis(ax, 'image', 'off');
        clim(ax, [-T_CLIM T_CLIM]);

        if any(sig_ic(:))
            contour(ax, double(sig_ic), [0.5 0.5], 'k-', 'LineWidth', 1.4);
        end

        text(ax, 0.5, 1.02, shift_labels{ip}, 'Units', 'normalized', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 16, 'FontWeight', 'normal');

        hold(ax, 'off');
    end

    % single shared colorbar
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
    clim(ax, [-T_CLIM T_CLIM]);
end

fprintf('\nShift-difference maps complete.\n');