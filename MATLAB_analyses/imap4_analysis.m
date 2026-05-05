clear all
clc

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


%% paths

data_folder   = 'imap_matfiles'; %the individual files
imap_folder   = 'iMap4'; 
bg_image_path = 'reference_picture.png';

addpath(genpath(imap_folder));


%% smoothing parameters

screen_y_pixel       = 1080;
distance_y_cm        = 32.2; %this should be the height of the computer screen
participant_distance = 50; 

xSize_orig = 834; %image size
ySize_orig = 480; %image size 
scale      = 0.5;
xSize      = round(xSize_orig * scale);   % 417
ySize      = round(ySize_orig * scale);   % 240

fprintf('Map size: %d x %d pixels\n', xSize, ySize);

% smoothing: 0.75 degree of visual angle
smoothing_value   = 0.75;
user_visual_angle = smoothing_value / (2 * sqrt(log(2)));
smoothingpic_full = round( ...
    user_visual_angle / ...
    (atan(distance_y_cm / 2 / participant_distance) / pi * 180) * ...
    (screen_y_pixel / 2));
smoothingpic = round(smoothingpic_full * scale);

fprintf('Smoothing: %.2f deg = %dpx (full) = %dpx (half res)\n', ...
    smoothing_value, smoothingpic_full, smoothingpic);

% Gaussian kernel
[x, y]     = meshgrid( ...
    -floor(xSize/2)+.5 : floor(xSize/2)-.5, ...
    -floor(ySize/2)+.5 : floor(ySize/2)-.5);
gaussienne = exp(-(x.^2 / smoothingpic^2) - (y.^2 / smoothingpic^2));
gaussienne = (gaussienne - min(gaussienne(:))) / ...
             (max(gaussienne(:)) - min(gaussienne(:)));


%% load condition table

load('imap_condition_table.mat');

% Force column vectors
file_idx  = file_idx(:);
subject_N = subject_N(:);
stim_idx  = stim_idx(:);
actor_id  = actor_id(:);
group     = group(:);
emotion   = emotion(:);

Nitem = length(file_idx);   % 4011

groupVec   = nominal(group, {'Control', 'ASD', 'SAD'});  % Control = reference/intercept
emotionVec = nominal(emotion);
sbjVec     = subject_N;
actorVec   = actor_id;

Tbl = dataset(sbjVec, groupVec, emotionVec, actorVec);
Tbl.Properties.VarNames = {'sbj', 'group', 'emotion', 'actor'};

assert(size(Tbl,1) == Nitem, ...
    'Mismatch: Tbl has %d rows but Nitem = %d', size(Tbl,1), Nitem);

fprintf('Condition table: %d trials, %d subjects, %d actors\n', ...
    Nitem, length(unique(sbjVec)), length(unique(actorVec)));


%% build fixation maps (4011 maps)

fixmapMat = zeros(Nitem, ySize, xSize);
stDur     = zeros(Nitem, 1);

fprintf('Building fixation maps...\n');
cd(data_folder);

for item = 1:Nitem
    load(['data' num2str(item) '.mat']);

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

cd('..');
Tbl.stDur = stDur;
fprintf('DONE: Fixation maps built.\n');


%% generate mask - pixels with mean fixation intensity above threshold (0.0045) across all trials, excluding the grey background from analysis

meanMap = squeeze(mean(fixmapMat, 1));
masktmp = meanMap > 0.0045;

fprintf('Mask: %d / %d pixels (%.1f%%)\n', ...
    sum(masktmp(:)), numel(masktmp), 100*mean(masktmp(:)));

figure('Name', 'Mean map + mask');
subplot(1,2,1); imagesc(meanMap); axis equal off; colorbar;
title('Mean fixation map — check face region is bright');
subplot(1,2,2); imagesc(masktmp); axis equal off;
title('Mask — should cover eyes/nose/mouth');

bg_raw = imread(bg_image_path);
bg     = imresize(bg_raw, [ySize, xSize]);


%% fit LMM model per pixel
%
%  PixelIntensity ~ group*emotion + (1|sbj) + (1|actor)
%
%  group   = ASD / Control / SAD      (between subjects)
%  emotion = 5 categories             (within subjects)
%  sbj     = random effect            (repeated measures)
%  actor   = random effect

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

% save immediately — skip steps above next time by loading this file
save('LMMmap_results.mat', 'LMMmap', 'lmexample', 'fixmapMat', ...
     'Tbl', 'masktmp', 'bg', '-v7.3');
fprintf('DONE: Saved to LMMmap_results.mat\n');

%%
load('LMMmap_results.mat');   % <-- uncomment to reload without re-running

% !! IMPORTANT: check coefficient order before running next steps !!
fprintf('\nCoefficient names — verify order before building contrasts:\n');
disp(lmexample.CoefficientNames);

nCoef = length(lmexample.CoefficientNames);

% Expected order with reference coding, Control as intercept:
%   1:  Intercept                (= Control grand mean)
%   2:  groupASD                 (ASD - Control)
%   3:  groupSAD                 (SAD - Control)
%       (Control = reference, absorbed into intercept)
%   4:  emotionAnger
%   5:  emotionFear
%   6:  emotionHappiness
%   7:  emotionNeutral
%       (emotionSadness = reference)
%   8:  groupASD:emotionAnger
%   9:  groupASD:emotionFear
%   10: groupASD:emotionHappiness
%   11: groupASD:emotionNeutral
%   12: groupSAD:emotionAnger
%   13: groupSAD:emotionFear
%   14: groupSAD:emotionHappiness
%   15: groupSAD:emotionNeutral


%% pairwise group contrasts — visualized per emotion 
%
%  contrast vectors extract emotion-specific group differences
%  using the main effects + interaction terms combined
%
%  For ASD vs Control at Anger:
%    (groupASD - groupControl) + (groupASD:Anger - groupControl:Anger)
%    = col2 - col3 + col8 - col12
%
%  Red  = first group fixates MORE
%  Blue = second group fixates MORE
%  Black outline = significant region

emotions_list = {'Anger', 'Fear', 'Happiness', 'Neutral', 'Sadness'};
%                  col4     col5    col6          col7      (reference)
% interaction cols:
%   ASD:   Anger=8,  Fear=9,  Happiness=10, Neutral=11
%   Ctrl:  Anger=12, Fear=13, Happiness=14, Neutral=15

emo_cols = [ 0  0;   % Anger     (reference — no interaction terms)
             8  9;   % Fear
            10 11;   % Happiness
            12 13;   % Neutral
            14 15];  % Sadness

for e = 1:length(emotions_list)
    emo     = emotions_list{e};
    asd_col = emo_cols(e, 1);
    sad_col = emo_cols(e, 2);

    % ASD vs Control at this emotion
    % = groupASD + groupASD:emotion
    c_ASDvsC = zeros(1, nCoef);
    c_ASDvsC(2) = 1;
    if asd_col > 0, c_ASDvsC(asd_col) = 1; end

    % SAD vs Control at this emotion
    % = groupSAD + groupSAD:emotion
    c_SADvsC = zeros(1, nCoef);
    c_SADvsC(3) = 1;
    if sad_col > 0, c_SADvsC(sad_col) = 1; end

    % ASD vs SAD at this emotion
    % = (groupASD + groupASD:emotion) - (groupSAD + groupSAD:emotion)
    c_ASDvsS = zeros(1, nCoef);
    c_ASDvsS(2) = 1; c_ASDvsS(3) = -1;
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
    colormap(jet);
    imapLMMdisplay(StatMap_c, 1, bg);
end




%% mean fixation maps per group x emotion ───────────────────────
%  Layout: rows = groups (ASD, Control, SAD)
%          columns = emotions (Anger, Fear, Happiness, Neutral, Sadness)

groups_u   = {'Control', 'ASD', 'SAD'};
nG         = length(groups_u);
nE         = length(emotions_list);

% compute all maps first to get shared colour scale
allMaps = zeros(nG, nE, ySize, xSize);
for ig = 1:nG
    for ie = 1:nE
        idx = strcmp(cellstr(char(groupVec)), groups_u{ig}) & ...
              strcmp(cellstr(char(emotionVec)), emotions_list{ie});
        allMaps(ig, ie, :, :) = squeeze(mean(fixmapMat(idx,:,:), 1));
    end
end

% shared colour limits across all maps so groups are directly comparable
clim_min = min(allMaps(:));
clim_max = max(allMaps(:));

figure('Name',     'Mean fixation maps: Group x Emotion', ...
       'Color',    'white', ...
       'Position', [50 50 1600 700]);

for ig = 1:nG
    for ie = 1:nE
        ax = subplot(nG, nE, (ig-1)*nE + ie);

        % overlay fixation map on reference face
        map = squeeze(allMaps(ig, ie, :, :));

        % show background face
        imshow(bg, 'Parent', ax);
        hold(ax, 'on');

        % overlay fixation map with transparency
        h = imagesc(ax, map, [clim_min clim_max]);
        set(h, 'AlphaData', 0.6);   % semi-transparent so face shows through
        axis(ax, 'equal', 'off');
        colormap(ax, batlow);

        % row labels (group names) on leftmost column only
        if ie == 1
            ylabel(ax, groups_u{ig}, ...
                'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 90);
        end

        % column labels (emotion names) on top row only
        if ig == 1
            title(ax, emotions_list{ie}, 'FontSize', 13, 'FontWeight', 'bold');
        end
    end
end

% single shared colorbar on the right
cb = colorbar('Position', [0.92 0.15 0.015 0.7]);
colormap(jet);
cb.Label.String   = 'Mean fixation intensity (Z-scored)';
cb.Label.FontSize = 12;
clim([clim_min clim_max]);

% overall title
sgtitle('Mean Fixation Maps by Group and Emotion', ...
        'FontSize', 16, 'FontWeight', 'bold');


%% mean fixation maps per group (collapsed across emotions) 
 
allMaps_group = zeros(nG, ySize, xSize);
for ig = 1:nG
    idx = strcmp(cellstr(char(groupVec)), groups_u{ig});
    allMaps_group(ig, :, :) = squeeze(mean(fixmapMat(idx,:,:), 1));
end

clim_min_g = min(allMaps_group(:));
clim_max_g = max(allMaps_group(:));
 
figure('Name',     'Mean fixation maps: Group (all emotions)', ...
       'Color',    'white', ...
       'Position', [50 50 1200 450]);
 
for ig = 1:nG
    ax = subplot(1, nG, ig);
 
    map = squeeze(allMaps_group(ig, :, :));
 
    imshow(bg, 'Parent', ax);
    hold(ax, 'on');
 
    h = imagesc(ax, map, [clim_min_g clim_max_g]);
    set(h, 'AlphaData', 0.6);
    axis(ax, 'equal', 'off');
    colormap(ax, batlow);
 
    title(ax, groups_u{ig}, 'FontSize', 16, 'FontWeight', 'bold');
end
 
% shared colorbar
cb = colorbar('Position', [0.92 0.15 0.015 0.7]);
colormap(jet);
cb.Label.String   = 'Mean fixation intensity (Z-scored)';
cb.Label.FontSize = 12;
clim([clim_min_g clim_max_g]);
 
sgtitle('Mean Fixation Maps by Group (All Emotions)', ...
        'FontSize', 16, 'FontWeight', 'bold');

%% end
fprintf('\n COMPLETED.\n');
