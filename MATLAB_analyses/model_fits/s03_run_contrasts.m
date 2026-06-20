clear all
clc

%% =========================================================================
%  s03_contrasts.m
%
%  PURPOSE: Compute pixel-wise pairwise group contrasts from the fitted LMM
%  maps, separately for each emotion. For every emotion we test three
%  contrasts at every pixel:
%    (1) ASD vs Control
%    (2) SAD vs Control
%    (3) ASD vs SAD
%
%  Contrast vectors are built from the LMM coefficient structure. Because
%  the model includes group × emotion interactions, the group difference at
%  a specific emotion is the sum of the group main effect AND the
%  corresponding interaction term (see contrast vector section below).
%
%  INPUT:  fixmap_data.mat       — trial fixation maps + metadata (from s01)
%          LMMmap_results.mat    — pixel-wise LMM fit (from s02)
%  OUTPUT: contrast_results.mat  — StatMap_c_all: cell array {nEmotions x 1}
%                                  each cell holds MCC-corrected stat maps
%                                  for the three contrasts of that emotion
% =========================================================================

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

%% MCC SETTINGS
%  USE_BOOTSTRAP = 0  →  FDR (fast, low memory — use first)
%  USE_BOOTSTRAP = 1  →  Bootstrap (slow — use for final results)
USE_BOOTSTRAP = 0;
NBOOT         = 1000; % My laptop could not run this yet

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

imap_folder = fullfile(project_root, 'iMap4');
addpath(genpath(imap_folder));

load(fullfile(project_root, 'fixmap_data.mat'));
load(fullfile(project_root, 'LMMmap_results.mat'));
fprintf('Loaded data and LMM results.\n');

nCoef     = length(lmexample.CoefficientNames);
coefnames = lmexample.CoefficientNames;

% Sanity check: confirm group_ASD / group_SAD main effect columns exist
asd_main_col = find(strcmp(coefnames, 'group_ASD'));
sad_main_col = find(strcmp(coefnames, 'group_SAD'));
assert(~isempty(asd_main_col) && ~isempty(sad_main_col), ...
    'group_ASD / group_SAD main effect columns not found in CoefficientNames — check formula/coding.');

%% -------------------------------------------------------------------------
%  BUILD AND RUN CONTRASTS — LOOP OVER EMOTIONS
%
%  MODEL STRUCTURE (reference: Control group, Neutral emotion):
%
%    y = β0                           ← Control, Neutral (intercept)
%        + β_ASD                      ← ASD main effect (vs Control, at Neutral)
%        + β_SAD                      ← SAD main effect (vs Control, at Neutral)
%        + β_emotion_e                ← emotion main effect (vs Neutral, for Control)
%        + β_ASD:emotion_e            ← ASD × emotion interaction
%        + β_SAD:emotion_e            ← SAD × emotion interaction
%        + ...
%
%  CONTRAST LOGIC:
%  The predicted value for group G at emotion E is:
%    Control at E  = β0 + β_emotion_e
%    ASD at E      = β0 + β_ASD + β_emotion_e + β_ASD:emotion_e
%    SAD at E      = β0 + β_SAD + β_emotion_e + β_SAD:emotion_e
%
%  So the group contrasts at emotion E simplify to:
%    ASD vs Control = β_ASD + β_ASD:emotion_e   → c = [0…1…0…1…0]
%    SAD vs Control = β_SAD + β_SAD:emotion_e   → c = [0…1…0…1…0]
%    ASD vs SAD     = (β_ASD - β_SAD) + (β_ASD:emotion_e - β_SAD:emotion_e)
%                                               → c = [0…1…-1…1…-1…0]
%
%  For Neutral (the reference emotion), there are no interaction terms in the
%  model, so asd_col / sad_col come back empty and the contrast reduces to
%  the main effect alone: c = [0…1…0…].
%% -------------------------------------------------------------------------

StatMap_c_all = cell(length(emotions_list), 1);

for e = 1:length(emotions_list)
    emo = emotions_list{e};

    % Look up interaction columns directly from CoefficientNames.
    % For the reference emotion (Neutral), no interaction term exists,
    % so these will come back empty -> treated as 0 (no adjustment).
    asd_name = sprintf('group_ASD:emotion_%s', emo);
    sad_name = sprintf('group_SAD:emotion_%s', emo);

    asd_col = find(strcmp(coefnames, asd_name));
    sad_col = find(strcmp(coefnames, sad_name));
    if isempty(asd_col), asd_col = 0; end
    if isempty(sad_col), sad_col = 0; end

    fprintf('Emotion %-10s -> ASD interaction col: %d, SAD interaction col: %d\n', ...
        emo, asd_col, sad_col);

    c_ASDvsC = zeros(1, nCoef);
    c_ASDvsC(asd_main_col) = 1;
    if asd_col > 0, c_ASDvsC(asd_col) = 1; end

    c_SADvsC = zeros(1, nCoef);
    c_SADvsC(sad_main_col) = 1;
    if sad_col > 0, c_SADvsC(sad_col) = 1; end

    c_ASDvsS = zeros(1, nCoef);
    c_ASDvsS(asd_main_col) =  1;
    c_ASDvsS(sad_main_col) = -1;
    if asd_col > 0, c_ASDvsS(asd_col) =  1; end
    if sad_col > 0, c_ASDvsS(sad_col) = -1; end

    opt_con       = struct;
    opt_con.type  = 'predictor beta';
    opt_con.alpha = .05;
    opt_con.c     = {c_ASDvsC; c_SADvsC; c_ASDvsS};
    opt_con.name  = { ...
        sprintf('ASD vs Control — %s', emo); ...
        sprintf('SAD vs Control — %s', emo); ...
        sprintf('ASD vs SAD — %s',     emo)};

    [StatMap]   = imapLMMcontrast(LMMmap, opt_con);
    [StatMap_c] = imapLMMmcc(StatMap, LMMmap, mccopt_base, fixmapMat);
    StatMap_c_all{e} = StatMap_c;

    fprintf('Contrasts done — %s\n', emo);
end

save(fullfile(project_root, 'contrast_results.mat'), 'StatMap_c_all', '-v7.3');
fprintf('DONE: Saved to contrast_results.mat\n');