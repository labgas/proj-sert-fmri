%% LaBGAS_get_firstlvl_dsgn_obj
%
% This script contains a function that defines a number of fields of 
% the CANlab style first level DSGN structure array
% for Nathalie's emotional modulation of visceral pain study.
% This function is used in LaBGAS_1_spm_fit_firstlvl_models.m to
% run first level analysis using CANlab tools
%
% IMPORTANT NOTE: function and script are study-specific!
%
% See canlab_glm_single_subject('dsgninfo')
% OR Github\CanlabCore\CanlabCore\GLM_Batch_tools\canlab_glm_dsgninfo.txt 
% for details on first level analysis using CANlab tools, 
% including options and defaults
%
% This script is adapted by @lukasvo76 from the scripts
% 1) get_firslvl_dsgn_obj.m and get_single_trial_dsgn_obj.m by @bogpetre on
% Google Drive\CANlab\CANLAB Lab Member Documents\GLM_batch_tools\
% bogdan_paingen\classic_glm_contrasts
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
% none - you need to adapt the function script below to your study
%
% OUTPUT
% CANlab style first level DSGN structure array in your Matlab workspace, 
% to be used by LaBGAS_1_spm_fit_firstlvl_models.m
%
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
% @(#)% LaBGAS_get_firstlvl_dsgn_obj.m         v1.0        
% last modified: 2020/10/19
%
%% function code
function DSGN = LaBGAS_get_firstlvl_dsgn_obj()
    % INPUT
    % required fields
    DSGN.metadata = "SERT study first level analysis using CANlab tools"; % field for annotation with study info, or whatever you like
    DSGN.modeldir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\firstlevel_CANlab_tools'; % directory where you want to write first level results
    DSGN.subjects = {}; % sets up empty cell array field for subjects in structural array DSGN
    fnames = dir('C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\derivatives\fmriprep\sub*'); % get subject names from root directory with subject data
    idx=[fnames.isdir]'; % duplicate names because of .html files with same subject names as folders
    fnames=fnames(idx);
    for i = 1:length(fnames)
        this_f = fnames(i);
            runs = dir([this_f.folder, '\', this_f.name, '\func\s6_*_task-*_*.nii.gz']);
            if length(runs) > 2 % only include subject if it has more than two runs, which implies not only resting state run
                DSGN.subjects = [DSGN.subjects, [this_f.folder, '\', this_f.name]];
            end
    end
    DSGN.funcnames{1} = 'func\neg\s6_*_task-neg_*.nii'; % cell array of subject directories (absolute paths)	
    DSGN.funcnames{2} = 'func\neu\s6_*_task-neu_*.nii';
    DSGN.funcnames{3} = 'func\pos\s6_*_task-pos_*.nii';
    % optional fields
    DSGN.concatenation = {}; % default: none; cell array of arrays of runs to concatenate; see documentation for when to concatenate, and how it works exactly
    DSGN.allowmissingfunc = false; % default; true will prevent erroring out when functional file is missing
    DSGN.customrunintercepts = {}; % default: none; will only work if DSGN.concatenation is specified; cell array of vectors specifying custom intercepts
    
    % PARAMETERS
    DSGN.tr = 2; % repetition time (TR) in seconds
    DSGN.hpf = 128; % high pass filter in seconds; SPM default is 128, CANlab default is 180 since the brain response to pain stimuli last long and variance may be lost at shorter lengths, use scn_spm_design_check output for diagnostics; STUDY-SPECIFIC
    DSGN.fmri_t = 36; % microtime resolution - t=number of slices since we did slice timing; spm (and CANlab) default 16 can be kept for multiband w/o slice timing
    DSGN.fmri_t0 = 18; % microtime onset - reference slice used in slice timing correction; spm (and CANlab) default 1 can be kept for multiband w/o slice timing
    
    % MODELING
    % required fields
    DSGN.conditions{1} = {'fixation' 'pain_neg' 'rating'}; % cell array (one cell per session) of cell arrays (one cell per condition) of MAT-file names; if only one session is specified, it will be applied to all sessions
    DSGN.conditions{2} = {'fixation' 'pain_neu' 'rating'};
    DSGN.conditions{3} = {'fixation' 'pain_pos' 'rating'};
    % optional fields
%     DSGN.pmods = {{}}; % cell array (one cell per session) of cell arrays (one cell per condition) of cell arrays (one cell per modulator) of MAT-file names
%     DSGN.convolution; default hrf.derivs = [0 0]; structure specifying the convolution to use for conditions different fields required depending on convolution type; 
%     DSGN.ar1 = false; % autoregressive AR(1) to model serial correlations; SPM default is true, CANlab default is false, Tor recommends turning autocorrelation off, because this algorithm pools across the whole brain, and does not perform well in some situations; if you are performing a group analysis, the autocorrelation problem is not as concerning
    DSGN.notimemod = true; % default: false; if true, turn off time modulation of conditions, i.e. when you do not expect linear trends over time
%     DSGN.singletrials = {{}}; % a cell array (1 cell per session) of cell arrays (1 cell per condition) of (corresponding to DSGN.conditions) of true/false values indicating whether to convert specified condition to set of single trial conditions
%     DSGN.singletrialsall = false; % default: false; if true, set DSGN.singletrials to true for all conditions
    DSGN.modelingfilesdir = 'firstlevel_CANlab_tools'; % name of subfolder which will be created within directory containing functional files where .mat files containing fields of DSGN structure will be saved
%     DSGN.allowemptycond = false; % default:false; if true, allow empty conditions
%     DSGN.allowmissingcondfiles = false; % default:false; if true, throw warning instead of error when no file(s) are found corresponding to a MAT-file name/wildcard
    DSGN.multireg = 'noise_regs'; % specify name for matfile with noise parameters you want to save
    
    % CONTRASTS
    % required fields
    % cell array (one cell per contrast) of contrast definitions
    DSGN.contrasts{1} = {{'pain_neg'} {'pain_neu'} {'pain_pos'}};
    DSGN.contrasts{2} = {{'pain_neg'}};
    DSGN.contrasts{3} = {{'pain_neu'}};
    DSGN.contrasts{4} = {{'pain_pos'}};
    DSGN.contrasts{5} = {{'pain_neg'} {'pain_neu'}};
    DSGN.contrasts{6} = {{'pain_neg'} {'pain_pos'}};
    DSGN.contrasts{7} = {{'pain_neu'} {'pain_pos'}};
    % optional fields
    DSGN.contrastnames{1} = 'main effect of pain'; % default: automatic names from canlab_spm_contrast_job; cell array (one cell per contrast) containing strings to name contrasts
    DSGN.contrastweights{1} = [1 1 1]; % default: [1] or [1 -1] as needed; cell array (one cell per contrast) containing matrices with custom weights
    DSGN.contrastnames{2} = 'pain in negative'; 
    DSGN.contrastweights{2} = [1]; 
    DSGN.contrastnames{3} = 'pain in neutral'; 
    DSGN.contrastweights{3} = [1]; 
    DSGN.contrastnames{4} = 'pain in positive'; 
    DSGN.contrastweights{4} = [1];
    DSGN.contrastnames{5} = 'pain in negative versus neutral'; 
    DSGN.contrastweights{5} = [1 -1];
    DSGN.contrastnames{6} = 'pain in negative versus positive'; 
    DSGN.contrastweights{6} = [1 -1];
    DSGN.contrastnames{7} = 'pain in neutral versus positive'; 
    DSGN.contrastweights{7} = [1 -1];
end