clear all
clc

%% SET THIS — same folder as s01
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

imap_folder = fullfile(project_root, 'iMap4-master');
addpath(genpath(imap_folder));

load(fullfile(project_root, 'fixmap_data.mat'));

fprintf('Loaded fixmap_data.mat\n');
fprintf('Map size: %d x %d  |  Mask pixels: %d (%.1f%%)\n', ...
    xSize, ySize, sum(masktmp(:)), 100*mean(masktmp(:)));

%% FIT LMM
fprintf('\nFitting LMM on %d maps, %d pixels...\n', Nitem, sum(masktmp(:)));
tic

opt             = struct;
opt.singlepredi = 1;

[LMMmap, lmexample] = imapLMM( ...
    fixmapMat, Tbl, masktmp, opt, ...
    'PixelIntensity ~ group + emotion + group:emotion + (1|sbj) + (1|actor)', ...
    'DummyVarCoding', 'reference');

toc
fprintf('DONE: LMM fitted.\n\n');

fprintf('Coefficient names — verify order matches expected below:\n');
disp(lmexample.CoefficientNames);

% Expected (Neutral = reference emotion, Control = reference group):
%   1:  (Intercept)
%   2:  group_ASD
%   3:  group_SAD
%   4:  emotion_Anger
%   5:  emotion_Fear
%   6:  emotion_Happiness
%   7:  emotion_Sadness
%   8:  group_ASD:emotion_Anger
%   9:  group_SAD:emotion_Anger
%   10: group_ASD:emotion_Fear
%   11: group_SAD:emotion_Fear
%   12: group_ASD:emotion_Happiness
%   13: group_SAD:emotion_Happiness
%   14: group_ASD:emotion_Sadness
%   15: group_SAD:emotion_Sadness


%% SAVE
save(fullfile(project_root, 'LMMmap_results.mat'), 'LMMmap', 'lmexample', '-v7.3');
fprintf('DONE: Saved to LMMmap_results.mat\n');