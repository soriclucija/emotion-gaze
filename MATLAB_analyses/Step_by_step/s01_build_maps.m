clear all
clc

%% SET THIS — folder containing your scripts, data, and iMap4
project_root = 'C:\Users\lucij\Desktop\Leiden\Year 2\Internship\imap4_results';

data_folder   = fullfile(project_root, 'imap_matfiles');
imap_folder   = fullfile(project_root, 'iMap4');
bg_image_path = fullfile(project_root, 'reference_picture.png');
cond_table    = fullfile(project_root, 'imap_condition_table.mat');
save_path     = fullfile(project_root, 'fixmap_data.mat');

addpath(genpath(imap_folder));


%% SMOOTHING PARAMETERS
screen_y_pixel       = 1080;
distance_y_cm        = 32.2;
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

% Neutral = reference emotion, Control = reference group
groupVec   = nominal(group,   {'Control', 'ASD', 'SAD'});
emotionVec = nominal(emotion, {'Neutral', 'Anger', 'Fear', 'Happiness', 'Sadness'});
sbjVec     = subject_N;
actorVec   = actor_id;

Tbl = dataset(sbjVec, groupVec, emotionVec, actorVec);
Tbl.Properties.VarNames = {'sbj', 'group', 'emotion', 'actor'};

assert(size(Tbl,1) == Nitem, ...
    'Mismatch: Tbl has %d rows but Nitem = %d', size(Tbl,1), Nitem);

groups_u      = {'Control', 'ASD', 'SAD'};
emotions_list = {'Anger', 'Fear', 'Happiness', 'Neutral', 'Sadness'};
nG            = length(groups_u);
nE            = length(emotions_list);

fprintf('Condition table: %d trials, %d subjects, %d actors\n', ...
    Nitem, length(unique(sbjVec)), length(unique(actorVec)));


%% BUILD FIXATION MAPS
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

    stDur(item) = sum(indx1);

    if mod(item, 500) == 0
        fprintf('  %d / %d done\n', item, Nitem);
    end
end

Tbl.stDur = stDur;
fprintf('DONE: Fixation maps built.\n');


%% GENERATE MASK
bg_raw  = imread(bg_image_path);
bg      = imresize(bg_raw, [ySize, xSize]);
meanMap = squeeze(mean(fixmapMat, 1));
masktmp = meanMap > 0.0045;

fprintf('Mask: %d / %d pixels (%.1f%%)\n', ...
    sum(masktmp(:)), numel(masktmp), 100*mean(masktmp(:)));

figure('Name', 'Mean map + mask', 'Color', 'white', 'Position', [50 50 900 340]);
tl = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Mask diagnostic', 'FontSize', 13, 'FontWeight', 'bold');

ax1 = nexttile(1);
imshow(bg, 'Parent', ax1);
title(ax1, 'Reference face', 'FontSize', 11);

ax2 = nexttile(2);
imshow(bg, 'Parent', ax2); hold(ax2, 'on');
h2 = imagesc(ax2, meanMap);
set(h2, 'AlphaData', 0.6);
colormap(ax2, navia);
axis(ax2, 'equal', 'off');
cb2 = colorbar(ax2);
cb2.Label.String = 'Mean fixation (Z)';
cb2.FontSize = 8;
title(ax2, 'Mean fixation map', 'FontSize', 11);

ax3 = nexttile(3);
imshow(bg, 'Parent', ax3); hold(ax3, 'on');
green_overlay        = zeros(ySize, xSize, 3);
green_overlay(:,:,2) = 1;
h3 = image(ax3, green_overlay);
set(h3, 'AlphaData', double(masktmp) * 0.45);
axis(ax3, 'equal', 'off');
title(ax3, sprintf('Mask — %d px (%.1f%%)', ...
    sum(masktmp(:)), 100*mean(masktmp(:))), 'FontSize', 11);


%% SAVE
save(save_path, ...
    'fixmapMat', 'masktmp', 'Tbl', 'bg', ...
    'groupVec', 'emotionVec', 'sbjVec', 'actorVec', ...
    'xSize', 'ySize', 'Nitem', ...
    'groups_u', 'emotions_list', 'nG', 'nE', ...
    '-v7.3');
fprintf('DONE: Saved to %s\n', save_path);