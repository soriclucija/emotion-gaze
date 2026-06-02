clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

imap_folder = fullfile(project_root, 'iMap4');
addpath(genpath(imap_folder));

load(fullfile(project_root, 'fixmap_data.mat'));
load(fullfile(project_root, 'LMMmap_results.mat'));
load(fullfile(project_root, 'contrast_results.mat'));

TMAP_FIELD = 'map';
SIG_FIELD  = 'Pmask';

% emo_cols: [ASD_interaction_col, SAD_interaction_col] per emotion
% emotions_list order = {'Anger', 'Fear', 'Happiness', 'Neutral', 'Sadness'}
emo_cols = [ 8  9;   % Anger
            10 11;   % Fear
            12 13;   % Happiness
             0  0;   % Neutral ← reference
            14 15];  % Sadness

contrast_names = { ...
    'ASD vs Control'; ...
    'SAD vs Control'; ...
    'ASD vs SAD'};

% red = first-named group fixates MORE, blue = second fixates MORE
contrast_labels = {'Ctrl > ASD', 'ASD > Ctrl'; ...
                   'Ctrl > SAD', 'SAD > Ctrl'; ...
                   'SAD > ASD', 'ASD > SAD'};

for e = 1:length(emotions_list)
    emo       = emotions_list{e};
    StatMap_c = StatMap_c_all{e};
    nC        = 3;

    fig = figure('Name',     sprintf('Contrasts — %s', emo), ...
                 'Color',    'white', ...
                 'Position', [50 50 420*nC 430]);

    tl = tiledlayout(fig, 1, nC, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('Group Contrasts — %s', emo), ...
          'FontSize', 15, 'FontWeight', 'bold');

    fprintf('\n══════════════════════════════════\n');
    fprintf(' Emotion: %s\n', emo);
    fprintf('══════════════════════════════════\n');

    for ic = 1:nC

        % Sign negated so that positive t = first-named group fixates MORE.
        % If maps still appear flipped vs mean maps, remove the minus sign.
        tmap   = -squeeze(StatMap_c(1).(TMAP_FIELD)(ic, :, :));
        sigmap =  squeeze(StatMap_c(1).(SIG_FIELD)(ic, :, :));
        sigmap = logical(sigmap) & masktmp;

        tvals    = tmap(masktmp);
        clim_val = prctile(abs(tvals), 99);
        if clim_val == 0, clim_val = 1; end

        fprintf('  [%s — %s]  t range: [%.3f, %.3f]  |  sig px: %d\n', ...
            contrast_names{ic}, emo, min(tvals), max(tvals), sum(sigmap(:)));

        ax = nexttile(ic);
        imshow(bg, 'Parent', ax);
        hold(ax, 'on');

        h_sig = imagesc(ax, tmap .* sigmap, [-clim_val clim_val]);
        set(h_sig, 'AlphaData', double(sigmap) * 0.7);

        colormap(ax, roma);
        axis(ax, 'equal', 'off');

        contour(ax, double(sigmap), [0.5 0.5], 'k-', 'LineWidth', 1.4);

        if ic == nC
            cb = colorbar(ax, 'Location', 'eastoutside');
            cb.Label.String   = 't-statistic';
            cb.Label.FontSize = 10;
            cb.FontSize       = 9;
            nice_ticks = unique([-clim_val, -12, -6, 0, 6, 12, clim_val]);
            nice_ticks = nice_ticks(nice_ticks >= -clim_val & nice_ticks <= clim_val);
            cb.Ticks      = nice_ticks;
            cb.TickLabels = arrayfun(@(v) sprintf('%.1f', v), nice_ticks, ...
                                     'UniformOutput', false);
        end
        clim(ax, [-clim_val clim_val]);

        annotation_str = sprintf( ...
            '\\color[rgb]{0.8 0.1 0.1}%s   \\color[rgb]{0.1 0.1 0.8}%s', ...
            contrast_labels{ic,1}, contrast_labels{ic,2});
        title(ax, {sprintf('%s — %s', contrast_names{ic}, emo), annotation_str}, ...
              'FontSize', 9, 'FontWeight', 'bold', 'Interpreter', 'tex');

    end
end

fprintf('\nDone plotting contrasts.\n');