%% LaBGAS_create_BIDS_structure_SERT_fMRI.m
%
% This script will convert raw PARREC data into .nii and organize them into
% BIDS structure
%
% THE SCRIPT REQUIRES dicm2nii ON YOUR MATLAB PATH (in addition to SPM12)!
% clone if from https://github.com/xiangruili/dicm2nii
%
% This script is based on the following tutorial: 
% LaBGAS_create_BIDS_structure_example2 (under 
% J:\GBW-0264_TARGID-Brain-Gut-Axis\LaBGAS_GENERAL\LaBGAS_code\
% LaBGAS_code_BIDS_fMRIprep\BIDS_fMRIprep_tutorials\
% BIDS_conversion_tutorial\scripts) 
%
% This script works on data from Nathalie's emotional
% modulation of visceral pain dataset. Each run represents a condition
% (positive, negative, and neutral emotion), which are collected in
% counterbalanced order
%
% This script organizes the functional data under a single /func
% subdirectory per subject, and automatically labels the functional runs
% with the right task- label corresponding to the conditions neu, neg, or
% pos. A simple .txt file with the order of conditions per subject is
% needed as input.
%
%__________________________________________________________________________
%
% author: Lukas Van Oudenhove
% date:   April, 2020
%
% modified by:  Nathalie Weltens
% date:         April, 2020
%__________________________________________________________________________
% @(#)% LaBGAS_create_BIDS_structure_SERT_fMRI.m         v1.2        
% last modified: 2020/04/28
% changes versus v1.0: corrected slicetiming to be written in .json files
% changes versus v1.1: 
% 1) adapted to write task-xxx.tsv files at the subject level since from 
% subject 09 onwards, onset times are shifted to allow more time for ratings
% 2) made naming of directories consistent with BIDS

%% set up folder structure
% define base and PARREC directories
% ADAPT THIS TO YOUR PATHS AND MAKE SURE YOUR SUBJECT FOLDERS WITH RAW DATA
% ARE NAMED 'sub-01' etc. PLACE THE RAW PARRECS DIRECTLY UNDER THE SUBJECT
% DIRECTORY OR ADAPT THE SCRIPT
basedir='C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI';
sourcedir='C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\sourcedata';
rawdir='C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\rawdata1';
TR=2;

warning('Make sure the functional runs in your PARREC folder are sorted in the order in which they were acquired!')

% write the dataset description .json file (mandatory in BIDS)
cd(rawdir);
authors={'Nathalie Weltens' 'Ilektra Takopoulou' 'Ali Gholamrezaei' 'Steven J. Coen' 'Lukas Van Oudenhove'};
authors=char(authors);
descr = struct('Name','Emotional Modulation of Visceral Pain','BIDSVersion','1.3.0','Authors',authors,'Acknowledgements','Special thanks to Ron Peeters');          
spm_jsonwrite('dataset_description.json',descr, struct('indent','  '));

% create list of subjectnames
cd (sourcedir);
subs=dir(char(sourcedir));
subs={subs(3:end).name}';

% create folder structure for all subjects in NIFTII directory
cd (rawdir);
for sub=1:length(subs)
    spm_mkdir(rawdir,subs(sub),'func');
    spm_mkdir(rawdir,subs(sub),'anat');
end

%% convert PARREC to NIFTII and create .json sidecar files as required by BIDS
for sub=1:length(subs)
    % define subjectdirs
    subsourcedir=char(fullfile(sourcedir,subs(sub)));
    subrawdir=char(fullfile(rawdir,subs(sub)));
    cd(subsourcedir)
    % convert PARREC to .nii and save .nii in subject folder under
    % NIFTII directory
    % type help dicm2nii in Matlab command window for more info
    dicm2nii(subsourcedir,subrawdir,1)
end

%% rename and move converted .nii and .json files
for sub=1:length(subs)
    subsourcedir=char(fullfile(sourcedir,subs(sub)));
    cd(subsourcedir);
    conditions=readtable('order_conditions.txt');
    subrawdir=char(fullfile(rawdir,subs(sub)));
    cd(subrawdir);
    anatdir=char(fullfile(subrawdir,'anat'));
    funcdir=char(fullfile(subrawdir,'func'));
    
    % move dcmHeaders.mat file (output of conversion) back to PARREC
    % directory (otherwise conflict when trying to validate BIDS)
    dirlist = dir('dcmHeaders.mat');
        for i = 1:size(dirlist,1)
            filename = dirlist(i).name;
            movefile(fullfile(subrawdir,filename),fullfile(subsourcedir,filename)); 
        end
        
    % rename .nii files and move to the correct folders
    % rename .json files, add mandatory taskname to .json files, and
    % anonymize .json files (i.e. clear SeriesDescription)
    dirlist = dir('*_3DTFE_ADNI_*.nii.gz');
        for i = 1:size(dirlist,1)
            filename = dirlist(i).name;
            newfilename = strcat(subs(sub),'_T1w.nii.gz');
            newfilename = char(newfilename);
            movefile(fullfile(subrawdir,filename),fullfile(anatdir,newfilename)); 
        end
    dirlist = dir('*_3DTFE_ADNI_*.json');
        for i = 1:size(dirlist,1)
            filename = dirlist(i).name;
            newfilename = strcat(subs(sub),'_T1w.json');
            newfilename = char(newfilename);
                json=spm_jsonread(dirlist(i).name);
                json.SeriesDescription=[];
                spm_jsonwrite(dirlist(i).name,json);
            movefile(fullfile(subrawdir,filename),fullfile(subrawdir,newfilename)); 
        end   
    dirlist = dir('*_fMRI_resting_std_*.nii.gz');
        for i = 1:size(dirlist,1)
            filename = dirlist(i).name;
            newfilename = strcat(subs(sub),'_task-rest_bold.nii.gz');
            newfilename = char(newfilename);
            movefile(fullfile(subrawdir,filename),fullfile(funcdir,newfilename)); 
        end
    dirlist = dir('*_fMRI_resting_std_*.json');
        for i = 1:size(dirlist,1)
            filename = dirlist(i).name;
            newfilename = strcat(subs(sub),'_task-rest_bold.json');
            newfilename = char(newfilename);
            n_slices=32;
            last_slice = TR - TR/n_slices;
            slicetime = linspace(0, last_slice, n_slices);
                json=spm_jsonread(dirlist(i).name);
                json.SeriesDescription=[];
                json.TaskName='rest';
                json.SliceTiming=slicetime;
                spm_jsonwrite(dirlist(i).name,json);
            movefile(fullfile(subrawdir,filename),fullfile(subrawdir,newfilename)); 
        end
    dirlist = dir('*_fmri_balloon_*.nii.gz');
        for run = 1:size(dirlist,1)
            filename = dirlist(run).name;
            taskname = char(conditions.order(run));
            newfilename = strcat(subs(sub),'_task-',taskname,'_bold.nii.gz');
            newfilename = char(newfilename);
            movefile(fullfile(subrawdir,filename),fullfile(funcdir,newfilename)); 
        end
    dirlist = dir('*_fmri_balloon_*.json');
        for run = 1:size(dirlist,1)
            filename = dirlist(run).name;
            taskname = char(conditions.order(run));
            newfilename = strcat(subs(sub),'_task-',taskname,'_bold.json');
            newfilename = char(newfilename);
            n_slices=36;
            last_slice = TR - TR/n_slices;
            slicetime = linspace(0, last_slice, n_slices);
                json=spm_jsonread(dirlist(run).name);
                json.SeriesDescription=[];
                json.TaskName=taskname;
                json.SliceTiming=slicetime;
                spm_jsonwrite(dirlist(run).name,json);
            movefile(fullfile(subrawdir,filename),fullfile(funcdir,newfilename)); 
        end
    cd(funcdir);
    negname=strcat(subs(sub),'_task-neg_events.tsv');
    neuname=strcat(subs(sub),'_task-neu_events.tsv');
    posname=strcat(subs(sub),'_task-pos_events.tsv');
        if sub < 8 % 8 rather than 9 because there is no sub-07 folder
            p = struct('onset',[0 30 44 334 403	431	453	471	488	511	526	551	577	591	604	631	647	671	690	711	731	751	768	783 791 840], 'duration',[30 14 290 14 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 49 30], 'trial_type',{{'fixation','rating','emotion','rating','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','rating','fixation'}});
            spm_save(negname{1},p);
            spm_save(neuname{1},p);
            spm_save(posname{1},p);
        else
            p = struct('onset',[0 30 46 336 407	435	457	475	492	515	530	555	581	595	608	635	651	675	694	715	735	755	772	787 795 851], 'duration',[30 16 290 16 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3 56 30], 'trial_type',{{'fixation','rating','emotion','rating','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','pain','rating','fixation'}});
            spm_save(negname{1},p);
            spm_save(neuname{1},p);
            spm_save(posname{1},p);
        end
end  
%% attempt at extracting onset times from .xlsx logfiles and write to .tsv file

% % if correctly and consistently named, .xlsx logfiles are always in the
% % same alphabetical order (neg, neu, pos)
% % I tried to extract onset and durations per condition and subject from the
% % .xlsx logfiles, but this is not easy due to the organisation of the
% % logfile, so I did not complete this for now (the current end result is a merged
% % table variable with onset times)

% warning ('Make sure your .xlsx logfiles are named correctly and hence in alphabetical order')
% pain_duration = 0.3; % in seconds
% for sub=1:length(subs)
%     subjparrecdir=char(fullfile(parrecdir,subs(sub)));
%     subjniidir=char(fullfile(niidir,subs(sub)));
%     anatdir=char(fullfile(subjniidir,'anat'));
%     funcdir=char(fullfile(subjniidir,'func'));
%     cd(subjparrecdir);
%     dirlist = dir(['*.xlsx']);
%         for cond = 1:size(dirlist,1)
%             filename = dirlist(cond).name;
%             condname = filename(end-7:end-5);
%             logfile = readtable(filename);
%             pain_onsets = table(logfile.Var13(21:40),'VariableNames',{'TimeAtStartOfTrial'});
%             pain_onsets.TimeAtStartOfTrial=duration(seconds(str2num(char(pain_onsets.TimeAtStartOfTrial))));
%             temp=cell(1:20);
%             temp(:,1)={'Pain_Stimulus'};
%             pain_onsets.Condition = temp;
%             pain_onsets.Condition = categorical(pain_onsets.Condition);
%             other_onsets = logfile(1:end-2,3:8);
%             other_onsets.Condition = categorical(other_onsets.Condition);
%             other_onsets.TimeAtStartOfTrial=duration(seconds(str2num(char(other_onsets.TimeAtStartOfTrial))));
%             onsets=outerjoin(pain_onsets,other_onsets);
%         end
% end