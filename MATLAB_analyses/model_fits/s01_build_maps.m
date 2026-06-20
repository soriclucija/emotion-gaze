clear all
clc

%% =========================================================================
%  s01_build_fixmaps.m
%
%  PURPOSE: Build z-scored, Gaussian-smoothed fixation maps for every trial
%  in the ASD/SAD/Control eye-tracking study. Also generates a binary mask
%  from the grand-mean fixation map, and saves all outputs to a single .mat
%  file for use in downstream LMM analysis (s02+).
%
%  OUTPUT: fixmap_data.mat  — contains:
%    fixmapMat   [Nitem x ySize x xSize]  z-scored fixation map per trial
%    masktmp     [ySize x xSize]          binary pixel mask
%    Tbl         dataset  trial-level metadata (group, emotion, actor, stDur)
%    bg          [ySize x xSize x 3]      downsampled reference face image
%    groupVec, emotionVec, sbjVec, actorVec  — condition vectors (Nitem x 1)
%    xSize, ySize, Nitem                  — map dimensions and trial count
%    groups_u, emotions_list, nG, nE      — label lists for looping
% =========================================================================

%% folder containing scripts, data, and iMap4
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

data_folder   = fullfile(project_root, 'imap_matfiles');
imap_folder   = fullfile(project_root, 'iMap4-master');
bg_image_path = fullfile(project_root, 'reference_picture.png');
cond_table    = fullfile(project_root, 'imap_condition_table.mat');
save_path     = fullfile(project_root, 'fixmap_data.mat');

addpath(genpath(imap_folder));


%% SMOOTHING PARAMETERS
screen_y_pixel       = 1080;
distance_y_cm        = 29.65; 
participant_distance = 50;

xSize_orig = 833;
ySize_orig = 480;
scale      = 0.5;
xSize      = round(xSize_orig * scale);   % 417
ySize      = round(ySize_orig * scale);   % 240

fprintf('Map size: %d x %d pixels\n', xSize, ySize);

smoothing_value   = 0.75;
user_visual_angle = smoothing_value / (2 * sqrt(log(2)));
smoothingpic_full = round( ...
    user_visual_angle / ...
    (atan(distance_y_cm / 2 / participant_distance) / pi * 180) * ...
    (screen_y_pixel / 2));
smoothingpic = round(smoothingpic_full * scale);

fprintf('Smoothing: %.2f deg = %dpx (full) = %dpx (half res)\n', ...
    smoothing_value, smoothingpic_full, smoothingpic);

% Build the 2D Gaussian kernel on a grid matching the map dimensions.
% this is not necessary if you are z scoring

[x, y]     = meshgrid( ...
    -floor(xSize/2)+.5 : floor(xSize/2)-.5, ...
    -floor(ySize/2)+.5 : floor(ySize/2)-.5);
gaussienne = exp(-(x.^2 / smoothingpic^2) - (y.^2 / smoothingpic^2));
gaussienne = (gaussienne - min(gaussienne(:))) / ...
             (max(gaussienne(:)) - min(gaussienne(:)));


%% LOAD CONDITION TABLE
load(cond_table);

file_idx  = file_idx(:);
subject_N = subject_N(:);
stim_idx  = stim_idx(:);
actor_id  = actor_id(:);
group     = group(:);
emotion   = emotion(:);

Nitem = length(file_idx);

% Remap group abbreviations to full names
group_mapped = group;
group_mapped(strcmp(group, 'A')) = {'ASD'};
group_mapped(strcmp(group, 'C')) = {'Control'};
group_mapped(strcmp(group, 'S')) = {'SAD'};

groupVec = nominal(group_mapped);
groupVec = reorderlevels(groupVec, {'Control','ASD','SAD'});

emotionVec = nominal(emotion);
emotionVec = reorderlevels(emotionVec, {'Neutral','Anger','Fear','Happiness','Sadness'});
sbjVec     = subject_N;
actorVec   = actor_id;

% Validate: catch any unmapped group or emotion values
assert(sum(isundefined(groupVec))   == 0, ...
    'groupVec has undefined entries — check group codes in condition table');
assert(sum(isundefined(emotionVec)) == 0, ...
    'emotionVec has undefined entries — check emotion strings in condition table');

Tbl = dataset(sbjVec, groupVec, emotionVec, actorVec);
Tbl.Properties.VarNames = {'sbj', 'group', 'emotion', 'actor'};

groups_u      = {'Control', 'ASD', 'SAD'};
emotions_list = {'Neutral', 'Anger', 'Fear', 'Happiness', 'Sadness'};
nG            = length(groups_u);
nE            = length(emotions_list);

fprintf('Condition table: %d trials, %d subjects, %d actors\n', ...
    Nitem, length(unique(sbjVec)), length(unique(actorVec)));

fprintf('\nTabulated group counts (expect ASD=1500, Control=1528, SAD=983 trials):\n');
tabulate(cellstr(char(groupVec)));


%% -------------------------------------------------------------------------
%  BUILD FIXATION MAPS
%  For each trial we:
%    1. Load the raw fixation data (x/y coordinates + durations in ms)
%    2. Discard out-of-bounds fixations
%    3. Accumulate duration-weighted fixations into a sparse map
%    4. Convolve with the Gaussian kernel to smooth
%    5. Z-score the smoothed map (zero mean, unit SD) so maps are comparable
%       across trials regardless of total fixation duration
% -------------------------------------------------------------------------

fixmapMat = zeros(Nitem, ySize, xSize);
stDur     = zeros(Nitem, 1);

fprintf('Building fixation maps...\n');

for item = 1:Nitem
    load(fullfile(data_folder, ['data' num2str(item) '.mat']));

    coordY = round(summary(:, 1) * scale);
    coordX = round(summary(:, 2) * scale);
    intv   = summary(:, 3);

    indx1 = coordX > 0 & coordY > 0 & coordX <= xSize & coordY <= ySize;

    rawmap    = full(sparse(coordY(indx1), coordX(indx1), intv(indx1), ySize, xSize));
    smoothpic = conv2(rawmap, gaussienne, 'same');

    if std(smoothpic(:)) > 0
        fixmapMat(item,:,:) = (smoothpic - mean(smoothpic(:))) ./ std(smoothpic(:)); 
    else
        fixmapMat(item,:,:) = smoothpic;
    end

    stDur(item) = sum(intv(indx1));

    if mod(item, 100) == 0 || item == Nitem
        fprintf('  %d / %d done\n', item, Nitem);
    end
end

Tbl.stDur = stDur;
fprintf('DONE: Fixation maps built.\n');


%% GENERATE MASK
bg_raw  = imread(bg_image_path);
bg      = imresize(bg_raw, [ySize, xSize]);
meanMap = squeeze(mean(fixmapMat, 1));

mask_threshold = 0.0045;   % empirically chosen threshold on Z-scored mean map - to exclude background pixels
% that are not fixated often
masktmp        = meanMap > mask_threshold;

fprintf('Mask: %d / %d pixels (%.1f%%)\n', ...
    sum(masktmp(:)), numel(masktmp), 100*mean(masktmp(:)));

figure('Name', 'Mean map + mask', 'Color', 'white', 'Position', [50 50 900 340]);
tl = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Mask diagnostic', 'FontSize', 13, 'FontWeight', 'bold');

ax1 = nexttile(1);
imshow(bg, 'Parent', ax1);
title(ax1, 'Reference face', 'FontSize', 11);

ax2 = nexttile(2);
imshow(bg, 'Parent', ax2);
hold(ax2, 'on');
h2 = imagesc(ax2, meanMap);
set(h2, 'AlphaData', 0.6);
colormap(ax2, navia);
axis(ax2, 'equal', 'off');
cb2 = colorbar(ax2);
cb2.Label.String = 'Mean fixation (Z)';
cb2.FontSize = 8;
title(ax2, 'Mean fixation map', 'FontSize', 11);
hold(ax2, 'off');

ax3 = nexttile(3);
imshow(bg, 'Parent', ax3);
hold(ax3, 'on');
green_overlay        = zeros(ySize, xSize, 3);
green_overlay(:,:,2) = 1;
h3 = image(ax3, green_overlay);
set(h3, 'AlphaData', double(masktmp) * 0.45);
axis(ax3, 'equal', 'off');
title(ax3, sprintf('Mask — %d px (%.1f%%)', ...
    sum(masktmp(:)), 100*mean(masktmp(:))), 'FontSize', 11);
hold(ax3, 'off');


%% SAVE
save(save_path, ...
    'fixmapMat', 'masktmp', 'Tbl', 'bg', ...
    'groupVec', 'emotionVec', 'sbjVec', 'actorVec', ...
    'xSize', 'ySize', 'Nitem', ...
    'groups_u', 'emotions_list', 'nG', 'nE', ...
    '-v7.3');
fprintf('DONE: Saved to %s\n', save_path);


%% VERIFY SAVED FILE — confirm group labels are correct in the saved data
load(save_path, 'sbjVec', 'groupVec');
T = table(sbjVec, cellstr(char(groupVec)), 'VariableNames', {'subject_N','group'});
T_unique = unique(T, 'rows');

fprintf('\nVerification — group assignment for known subjects in saved file:\n');
fprintf('  Subject 1  (P001, expect ASD):     %s\n', T_unique.group{T_unique.subject_N == 1});
fprintf('  Subject 32 (P033, expect Control): %s\n', T_unique.group{T_unique.subject_N == 32});

assert(strcmp(T_unique.group{T_unique.subject_N == 1},  'ASD'), ...
    'Subject 1 (P001) should be ASD — group mapping is incorrect!');
assert(strcmp(T_unique.group{T_unique.subject_N == 32}, 'Control'), ...
    'Subject 32 (P033) should be Control — group mapping is incorrect!');

fprintf('Group mapping verified correctly.\n');