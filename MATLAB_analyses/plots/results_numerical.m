clear all
clc

%% SET THIS — same folder as all
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

load(fullfile(project_root, 'fixmap_data.mat'));
load(fullfile(project_root, 'contrast_results.mat'));    % s03 — StatMap_c_all{emotion}
load(fullfile(project_root, 'shift_diff_results.mat')); % shfit_difference_contrasts — StatMap_shift_all{emotion}

TMAP_FIELD = 'map';
SIG_FIELD  = 'Pmask';
P_FIELD    = 'Pmap';

n_mask_px = sum(masktmp(:));

%% HELPER
function row = summarize_contrast(StatMap_c, ic, masktmp, n_mask_px, ...
                                   TMAP_FIELD, SIG_FIELD, P_FIELD, ...
                                   analysis, contrast_name, emo)

    tmap   = squeeze(StatMap_c(1).(TMAP_FIELD)(ic, :, :));
    sigmap = squeeze(StatMap_c(1).(SIG_FIELD)(ic, :, :));
    sigmap = logical(sigmap) & masktmp;

    n_sig   = sum(sigmap(:));
    pct_sig = 100 * n_sig / n_mask_px;

    if n_sig > 0
        sig_t = tmap(sigmap);
        min_t = min(sig_t);
        max_t = max(sig_t);

        if ~isempty(P_FIELD) && isfield(StatMap_c(1), P_FIELD)
            pmap  = squeeze(StatMap_c(1).(P_FIELD)(ic, :, :));
            sig_p = pmap(sigmap);
            min_p = min(sig_p);
            max_p = max(sig_p);
        else
            min_p = NaN;
            max_p = NaN;
        end
    else
        min_t = NaN; max_t = NaN;
        min_p = NaN; max_p = NaN;
    end

    row = table( ...
        {analysis}, {contrast_name}, {emo}, ...
        n_mask_px, n_sig, pct_sig, ...
        min_t, max_t, min_p, max_p, ...
        'VariableNames', { ...
            'Analysis', 'Contrast', 'Emotion', ...
            'n_mask_px', 'n_sig_px', 'pct_sig', ...
            'min_t', 'max_t', 'min_p', 'max_p'});
end

%% GROUP CONTRASTS (s03)
contrast_names = {'ASD vs Control', 'SAD vs Control', 'ASD vs SAD'};

results = table();
for ie = 1:length(emotions_list)
    StatMap_c = StatMap_c_all{ie};
    emo       = emotions_list{ie};

    for ic = 1:3
        row = summarize_contrast(StatMap_c, ic, masktmp, n_mask_px, ...
            TMAP_FIELD, SIG_FIELD, P_FIELD, ...
            'group_contrast', contrast_names{ic}, emo);
        results = [results; row];
    end
end

%% SHIFT-DIFFERENCE CONTRASTS (shift_difference_contrasts)
contrast_emotions = {'Anger', 'Fear', 'Happiness', 'Sadness'};

for ie = 1:length(contrast_emotions)
    StatMap_c = StatMap_shift_all{ie};
    emo       = contrast_emotions{ie};

    for ic = 1:3
        row = summarize_contrast(StatMap_c, ic, masktmp, n_mask_px, ...
            TMAP_FIELD, SIG_FIELD, P_FIELD, ...
            'shift_difference', contrast_names{ic}, emo);
        results = [results; row];
    end
end

%% DISPLAY AND SAVE
disp(results)
writetable(results, fullfile(project_root, 'results.csv'));
fprintf('\nSaved to results.csv\n');