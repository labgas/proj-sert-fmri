%% LaBGAS_2_spm_fit_single_trial_models
%
% This script runs first level single trial analysis from 
% a CANlab style first level DSGN structure array and
% CANlab/spm style onset/duration and noise regressor files 
% using CANlab's canlab_glm_subject_levels function
% for Nathalie's emotional modulation of visceral pain/SERT study
%
% THIS SCRIPT IS IDENTICAL TO LaBGAS_2_spm_fit_firstlvl_models.m except
% calling the function LaBGAS_get_single_trial_dsgn_obj() rather than 
% LaBGAS_get_firstlvl_dsgn_obj()
%
% See canlab_glm_single_subject('dsgninfo'), or documentation in 
% Github\CanlabCore\CanlabCore\GLM_Batch_tools for details on first level
% analysis using CANlab tools
%
% This script is adapted by @lukasvo76 from the script
% 1) 2_spm_fit_single_trial_models.m by @bogpetre on Google Drive\CANlab\
% CANLAB Lab Member Documents\GLM_batch_tools\bogdan_paingen
% 2) MPA2_set_design_model1_blanca.m by @martaceko on
% Google Drive\CANlab\CANLAB Lab Member Documents\GLM_batch_tools\
% Marta_MPA2\MPA2code_1stlevel\Code
% contact @lukasvo76 if you need those original scripts
%
% DEPENDENCIES ON YOUR MATLAB PATH
% a) SPM12
% b) CANlab tools cloned from Github (see canlab.github.io)
% 
% INPUTS 
% 1. DSGN structure array generated by the function 
% LaBGAS_get_firstlvl_dsgn_obj called from this script
%
% OUTPUT
% 1. estimated first level models in DSGN.modeldir
% 2. a directory and settings for diagnostics obtained by calling
% LaBGAS_3_spm_diagnose_single_trial_models.m
%__________________________________________________________________________
%
% authors: 
% lukas.van.oudenhove@dartmouth.edu, lukas.vanoudenhove@kuleuven.be
% bogdan.petre@dartmouth.edu,
% marta.ceko@colorado.edu
%
% date:   October, 2020
%
%__________________________________________________________________________
% @(#)% LaBGAS_2_spm_fit_single_trial_models.m         v1.0        
% last modified: 2020/10/20
%
%% settings
% addpath(genpath('C:\Users\lukas\Documents\GitHub\CanlabCore')); % add relevant CANlab tools folders and spm to Matlab path if they are not there yet - I have saved them on my Matlab path permanently hence do not need this
% addpath(genpath('C:\Users\lukas\Documents\GitHub\CanlabPrivate'));
% addpath(genpath('C:\Users\lukas\Documents\MATLAB\spm12'));

DSGN = LaBGAS_get_single_trial_dsgn_obj(); % calls function to write DSGN structure array to your Matlab workspace

%% code
for i = 1:length(DSGN.subjects) % iter over subj
%% fit first levels
fprintf('Running on subject directory %s\n',DSGN.subjects{i});
canlab_glm_subject_levels(DSGN,'subjects',DSGN.subjects(i));

%% setup for diagnosis
sid = DSGN.subjects{i}(end-5:end);
logDir=[DSGN.modeldir, '\', sid, '\diagnostics'];
mkdir(logDir);

p = struct('useNewFigure', false, 'maxHeight', 800, 'maxWidth', 1600, ...
    'format', 'html', 'outputDir', logDir, ...
    'showCode', true);

%% run diagnosis by calling LaBGAS_3_spm_diagnose_firstlvl_models.m
publish('LaBGAS_3_spm_diagnose_single_trial_models.m',p)
end