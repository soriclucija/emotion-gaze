# Gaze Patterns in ASD & SAD (emotion-gaze)

## How to run?
- Get Matlab (at least version R2025b)
- Install iMap4 toolbox (see [link](https://junpenglao.gitbooks.io/imap4_guidebook/content/Installation-and-running-the-GUI.html))

## How to prepare?
- Have data in correct format (see [link](https://junpenglao.gitbooks.io/imap4_guidebook/content/Pixel-Wise-Modeling-and-non-parametric-statistics.html))

## Where do I find the code used in the project?
- Go to MATLAB_analyses (or click [here](https://github.com/soriclucija/emotion-gaze/tree/main/MATLAB_analyses))

## What does the code there mean?
- In the *model_fits* folder you can find all the code needed to fit the model used for our data analysis, namely:
$Pixel Intensity = Group + Emotion + Group × Emotion + (1 | Participant) + (1 | Stimulus Identity)$
- In the *plots* folder you can find all the code for plots created for the visualization. You cannot run plots without the fitted models.

## Why would I do any of this?
- To spatially map gaze data (fixations) collected through eye-tracking measures.
- To test differences in gaze patterns between groups.
- To localize fixations, rather than just test durations.
- To get cool visuals!
