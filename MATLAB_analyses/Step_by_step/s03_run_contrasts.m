clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

%% MCC SETTINGS
%  USE_BOOTSTRAP = 0  →  FDR (fast, low memory — use first)
%  USE_BOOTSTRAP = 1  →  Bootstrap (slow — use for final results)

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

fprintf('Loaded data and LMM results.\n');

nCoef = length(lmexample.CoefficientNames);

% Coefficient order (Neutral = reference emotion, Control = reference group):
%   1:  (Intercept)
%   2:  group_ASD
%   3:  group_SAD
%   4:  emotion_Anger         8: group_ASD:emotion_Anger     9: group_SAD:emotion_Anger
%   5:  emotion_Fear         10: group_ASD:emotion_Fear     11: group_SAD:emotion_Fear
%   6:  emotion_Happiness    12: group_ASD:emotion_Happiness 13: group_SAD:emotion_Happiness
%   7:  emotion_Sadness      14: group_ASD:emotion_Sadness  15: group_SAD:emotion_Sadness

% emo_cols: [ASD_interaction_col, SAD_interaction_col] per emotion
% emotions_list order = {'Anger', 'Fear', 'Happiness', 'Neutral', 'Sadness'}
% Neutral = reference → no interaction columns → [0, 0]
emo_cols = [ 8  9;   % Anger
            10 11;   % Fear
            12 13;   % Happiness
             0  0;   % Neutral ← reference
            14 15];  % Sadness

StatMap_c_all = cell(length(emotions_list), 1);

for e = 1:length(emotions_list)
    emo     = emotions_list{e};
    asd_col = emo_cols(e, 1);
    sad_col = emo_cols(e, 2);

    c_ASDvsC = zeros(1, nCoef);
    c_ASDvsC(2) = 1;
    if asd_col > 0, c_ASDvsC(asd_col) = 1; end

    c_SADvsC = zeros(1, nCoef);
    c_SADvsC(3) = 1;
    if sad_col > 0, c_SADvsC(sad_col) = 1; end

    c_ASDvsS = zeros(1, nCoef);
    c_ASDvsS(2) =  1;
    c_ASDvsS(3) = -1;
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