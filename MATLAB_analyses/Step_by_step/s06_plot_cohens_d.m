clear all
clc

load('fixmap_data.mat');
load('contrast_results.mat');

COHEN_CLIM = 0.5;   % display cap — raise if effects exceed this
SIG_FIELD  = 'Pmask';

% groups_u = {'Control'=1, 'ASD'=2, 'SAD'=3}
% positive d → first-named group fixates MORE (consistent with LMM contrasts in s04)
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


%% PLOT COHEN'S d — significant pixels only
for ie = 1:nE
    emo         = emotions_list{ie};
    StatMap_c_e = StatMap_c_all{ie};

    fig = figure('Name',     sprintf("Cohen's d — %s", emo), ...
                 'Color',    'white', ...
                 'Position', [50 50 420*3 430]);

    tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf("Cohen's d Effect Size — %s (significant pixels only)", emo), ...
          'FontSize', 14, 'FontWeight', 'bold');

    fprintf('══════════════════════════════════\n');
    fprintf(' Cohen''s d — %s\n', emo);
    fprintf('══════════════════════════════════\n');

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
            peak_d = NaN;
            fprintf('  %s | no significant pixels\n', diff_labels{ip,1});
        end

        ax = nexttile(ip);
        imshow(bg, 'Parent', ax);
        hold(ax, 'on');

        h_sig = imagesc(ax, dmap .* sig_ic, [-COHEN_CLIM COHEN_CLIM]);
        set(h_sig, 'AlphaData', double(sig_ic) * 0.5);

        colormap(ax, roma);
        axis(ax, 'equal', 'off');
        clim(ax, [-COHEN_CLIM COHEN_CLIM]);

        if any(sig_ic(:))
            contour(ax, double(sig_ic), [0.5 0.5], 'k-', 'LineWidth', 1.4);
        end

        annotation_str = sprintf( ...
            '\\color[rgb]{0.8 0.1 0.1}%s   \\color[rgb]{0.1 0.1 0.8}%s', ...
            diff_labels{ip,2}, diff_labels{ip,3});
        title(ax, {diff_labels{ip,1}, annotation_str}, ...
              'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'tex');

        if ip == 3
            cb = colorbar(ax, 'Location', 'eastoutside');
            cb.Label.String   = "Cohen's d";
            cb.Label.FontSize = 10;
            cb.FontSize       = 9;
            ref_ticks  = [-COHEN_CLIM, -0.2, 0, 0.2, COHEN_CLIM];
            ref_labels = { ...
                sprintf('%.1f', -COHEN_CLIM), ...
                '-0.2 (small)', '0', ...
                '0.2 (small)',  ...
                sprintf('%.1f', COHEN_CLIM)};
            in_range      = ref_ticks >= -COHEN_CLIM & ref_ticks <= COHEN_CLIM;
            cb.Ticks      = ref_ticks(in_range);
            cb.TickLabels = ref_labels(in_range);
        end

    end
end

fprintf('\nCohen''s d maps complete.\n');
