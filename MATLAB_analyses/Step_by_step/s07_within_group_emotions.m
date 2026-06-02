clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

%% MCC SETTINGS
USE_BOOTSTRAP = 0;
NBOOT         = 500;

if USE_BOOTSTRAP
    fprintf('⚠️  Bootstrap MCC (%d iterations)\n', NBOOT);
    mccopt_base.methods   = 'bootstrap';
    mccopt_base.bootgroup = {'group'};
    mccopt_base.nboot     = NBOOT;
    mccopt_base.bootopt   = 1;
    mccopt_base.tfce      = 0;
else
    fprintf('ℹ️  FDR correction enabled\n');
    mccopt_base.methods = 'FDR';
end

imap_folder = fullfile(project_root, 'iMap4');
addpath(genpath(imap_folder));

load(fullfile(project_root, 'fixmap_data.mat'));
load(fullfile(project_root, 'LMMmap_results.mat'));

nCoef = length(lmexample.CoefficientNames);

% Coefficient order (Neutral = reference emotion, Control = reference group):
%   1:  (Intercept)
%   2:  group_ASD
%   3:  group_SAD
%   4:  emotion_Anger        8:  group_ASD:emotion_Anger    9:  group_SAD:emotion_Anger
%   5:  emotion_Fear        10:  group_ASD:emotion_Fear    11:  group_SAD:emotion_Fear
%   6:  emotion_Happiness   12:  group_ASD:emotion_Happiness 13: group_SAD:emotion_Happiness
%   7:  emotion_Sadness     14:  group_ASD:emotion_Sadness 15:  group_SAD:emotion_Sadness

TMAP_FIELD = 'map';
SIG_FIELD  = 'Pmask';

% emotions to contrast vs Neutral (reference)
contrast_emotions = {'Anger', 'Fear', 'Happiness', 'Sadness'};
nCE = length(contrast_emotions);

% emotion main effect coefficient (= Control group's emotion shift vs Neutral)
emo_main = [4, 5, 6, 7];

% interaction coefficients [ASD_col, SAD_col] — added on top for ASD/SAD
emo_int  = [ 8  9;   % Anger
            10 11;   % Fear
            12 13;   % Happiness
            14 15];  % Sadness

groups_plot = {'Control', 'ASD', 'SAD'};
nG_plot     = length(groups_plot);


%% COMPUTE WITHIN-GROUP EMOTION CONTRASTS
% For each group × emotion: how does fixation shift vs Neutral?
%
%   Control: contrast = β_emotion  (main effect only)
%   ASD:     contrast = β_emotion + β_ASD:emotion
%   SAD:     contrast = β_emotion + β_SAD:emotion
%
% Positive t (after sign correction) = that emotion drives MORE fixation
% than Neutral at that pixel for that group.

fprintf('Computing within-group emotion contrasts vs Neutral...\n');
StatMap_within = cell(nG_plot, nCE);

for ig = 1:nG_plot
    for ie = 1:nCE

        c = zeros(1, nCoef);
        c(emo_main(ie)) = 1;          % emotion main effect (Control baseline)

        if ig == 2                    % ASD: add interaction
            c(emo_int(ie, 1)) = 1;
        elseif ig == 3                % SAD: add interaction
            c(emo_int(ie, 2)) = 1;
        end

        opt_con       = struct;
        opt_con.type  = 'predictor beta';
        opt_con.alpha = .05;
        opt_con.c     = {c};
        opt_con.name  = {sprintf('%s — %s vs Neutral', groups_plot{ig}, contrast_emotions{ie})};

        [StatMap]   = imapLMMcontrast(LMMmap, opt_con);
        [StatMap_c] = imapLMMmcc(StatMap, LMMmap, mccopt_base, fixmapMat);

        StatMap_within{ig, ie} = StatMap_c;
        fprintf('  Done: %s — %s vs Neutral\n', groups_plot{ig}, contrast_emotions{ie});
    end
end

save(fullfile(project_root, 'within_emotion_results.mat'), 'StatMap_within', '-v7.3');
fprintf('Saved to within_emotion_results.mat\n\n');


%% PLOT — rows = groups, columns = emotions
% blue = that emotion drives MORE fixation than Neutral at that pixel
% red  = Neutral drives MORE fixation than that emotion at that pixel

% shared colour limits across all panels
all_tvals = [];
for ig = 1:nG_plot
    for ie = 1:nCE
        tmap = -squeeze(StatMap_within{ig, ie}(1).(TMAP_FIELD)(1, :, :));
        all_tvals = [all_tvals; tmap(masktmp)];
    end
end
clim_val = prctile(abs(all_tvals), 99);
if clim_val == 0, clim_val = 1; end

fig = figure('Name',     'Within-group: emotion vs Neutral', ...
             'Color',    'white', ...
             'Position', [50 50 260*nCE 300*nG_plot + 60]);

tl = tiledlayout(fig, nG_plot, nCE, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Fixation shift vs Neutral — by group', ...
      'FontSize', 15, 'FontWeight', 'bold');

fprintf('══════════════════════════════════════\n');
fprintf(' Within-group emotion contrasts\n');
fprintf('══════════════════════════════════════\n');

for ig = 1:nG_plot
    for ie = 1:nCE

        tmap   = -squeeze(StatMap_within{ig, ie}(1).(TMAP_FIELD)(1, :, :));
        sigmap =  squeeze(StatMap_within{ig, ie}(1).(SIG_FIELD)(1, :, :));
        sigmap = logical(sigmap) & masktmp;

        fprintf('  %s | %s vs Neutral | sig px = %d\n', ...
            groups_plot{ig}, contrast_emotions{ie}, sum(sigmap(:)));

        ax = nexttile((ig-1)*nCE + ie);
        imshow(bg, 'Parent', ax);
        hold(ax, 'on');

        h_sig = imagesc(ax, tmap .* sigmap, [-clim_val clim_val]);
        set(h_sig, 'AlphaData', double(sigmap) * 0.7);

        colormap(ax, roma);
        axis(ax, 'equal', 'off');
        clim(ax, [-clim_val clim_val]);

        if any(sigmap(:))
            contour(ax, double(sigmap), [0.5 0.5], 'k-', 'LineWidth', 1.2);
        end

        % top row: show emotion name as title
        % left column: show group name as title prefix
        if ig == 1 && ie == 1
            title(ax, sprintf('%s\n%s', groups_plot{ig}, contrast_emotions{ie}), ...
                  'FontSize', 10, 'FontWeight', 'bold');
        elseif ig == 1
            title(ax, contrast_emotions{ie}, 'FontSize', 10, 'FontWeight', 'bold');
        elseif ie == 1
            title(ax, groups_plot{ig}, 'FontSize', 10, 'FontWeight', 'bold');
        end

    end
end

% shared colorbar
last_ax = nexttile(tl, nG_plot * nCE);
cb = colorbar(last_ax, 'Location', 'eastoutside');
colormap(last_ax, roma);
cb.Label.String   = 't-statistic  (blue = emotion > Neutral,  red = Neutral > emotion)';
cb.Label.FontSize = 9;
cb.FontSize       = 9;
nice_ticks = unique([-clim_val, -2, 0, 2, clim_val]);
nice_ticks = nice_ticks(nice_ticks >= -clim_val & nice_ticks <= clim_val);
cb.Ticks      = nice_ticks;
cb.TickLabels = arrayfun(@(v) sprintf('%.1f', v), nice_ticks, 'UniformOutput', false);
clim(last_ax, [-clim_val clim_val]);

fprintf('\nDone.\n');
