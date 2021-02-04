%% LaBGAS_create_first_level_folder_structure
%
% This simple script creates the folder structure for first level analysis
% for Nathalie's emotional modulation of visceral pain study
% Should be self-explanatory, but contact lukas.vanoudenhove@kuleuven.be if
% you have questions
% 
% Lukas note to self: 
% 1) may be better to adapt LaBGAS_extract_confound_reg_fMRIprep.m 
% to write confound regressors to dir 'derivatives' for future purposes
% 2) may be better to work with hierarchical folder structure for future
% purposes, for example firstlevel/model1, /model2, etc
%
%__________________________________________________________________________
%
% author: lukas.vanoudenhove@kuleuven.be
% date:   October, 2020
%__________________________________________________________________________
% @(#)% LaBGAS_create_first_level_folder_structure.m     v1.1        
% last modified: 2020/10/13
% 
% changes versus previous version: added comments to explain code
%
%% define directories and make new first level directory
rootdir='C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI';
cd(rootdir);
mkdir('firstlevel');
firstleveldir=fullfile(rootdir,'firstlevel');
fmriprepdir=fullfile(rootdir,'derivatives\fmriprep');

%% get subject folder names from derivatives\fmriprep
cd(fmriprepdir);
subjs=dir('sub-*');
idx=[subjs.isdir]';
subjs={subjs(idx).name}';

%% write folder structure in new first level directory
cd(firstleveldir);
sm=@(x)spm_mkdir(x); % defines spm_mkdir as a function sm
cellfun(sm,subjs); % applies function sm to all cells of subjs


