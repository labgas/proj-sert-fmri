%% LaBGAS_first_level_batch_fMRIprep_conf
%
% This script will write the following to an spm first level batch file
% A. noise regressors extracted from fMRIprep output
% using the script LaBGAS_extract_confound_reg_fMRIprep, including
% a) CSF signal
% b) 24 head motion parameters (six directions, derivatives, and squared
% values)
% c) dummy spike regressors
% B. regressors of interest (onsets & durations) 
% 
% DEPENDENCIES
% a) SPM12 on your Matlab path
% 
% INPUTS 
% 1. regressor files generated by LaBGAS_extract_confound_reg_fMRIprep.m
% a) noise_regs files (.mat, .txt) for each run in derivatives/sub-xx/func folder
% b) onsets_ files (.mat, .txt) for each run in rawdata/sub-xx/func folder
% 2. smoothed fMRIprepped files generated by
% LaBGAS_deriv_unzip_nii_smooth.m
%
% OUTPUT
% a) SPM first level batch file
% b) run the batch file to generate beta's
% c) run contrast manager to define contrasts to be used in second level
%
% NR_TASK_RUNS
% enter number of task-based runs (EXCLUDING RESTING STATE RUN)
% 
% CONDS2MODEL
% enter cell array with names of conditions from onset file you want to
% include in your first level model
% COMMENT OUT IF YOU WANT TO MODEL ALL CONDITIONS
% IF YOU CHANGE THIS OPTION, CONTRASTS NEED TO BE ADAPTED ACCORDINGLY!
%
% BASIS_SET
% 'can' canonical HRF w/o derivatives (one regressor per trial)
% 'derivs' canonical HRF with first-order time and dispersion derivatives
% (three regressors per trial)
%
% HPF
% high-pass filter (in seconds)
%__________________________________________________________________________
%
% author: lukas.vanoudenhove@kuleuven.be
% date:   May, 2020
%
%__________________________________________________________________________
% @(#)% LaBGAS_first_level_batch_fMRIprep_conf.m         v1.1        
% last modified: 2020/05/12
%
% changes versus version 1.0
% 1) adapted filters to select smoothed files with s6_ prefix
% 2) added main effect of pain contrast
% 3) adapted to decisions made during meeting with Tor
%   a) built in option to model different conditions
%   b) built in option for different basis sets
%   c) adapted constrasts to the above
% 4) built in checks & balances erroring out when needed
%

%% set paths, and TR
basedir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI';
derivdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\derivatives\fmriprep\sub-01\func'; % dir with fMRIprep output
rawdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\rawdata1\sub-01\func'; % dir with raw .nii files
outputdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\firstlevel\sub-01'; % dir where confound files for first level will be written
TR = 2;
nr_slices = 36;
nr_task_runs = 3;
conds2model = {'fixation','pain','rating'};
basis_set = 'can';
hpf = 128;

% DO NOT CHANGE CODE BELOW THIS LINE
% ALWAYS MAKE A LOCAL COPY OF EXAMPLE SCRIPTS BEFORE MODIFYING

%% define filenames

cd(derivdir);
imgs = dir('s6_*preproc_bold.nii.gz');
imgfiles = {imgs(1:nr_task_runs).name}'; % excluding rs run
    for i=1:length(imgfiles)
        gunzip(imgfiles{i});
    end
cd(outputdir);
onsetfiles = dir('onsets_*.mat');
onsetfiles = {onsetfiles(:).name}';
noisefiles = dir('noise_*.txt');
noisefiles = {noisefiles(:).name}';
noisenames = char(noisefiles);
runnames = noisenames(:,end-6:end-4); % names of runs/conditions
    if ne(length(onsetfiles),length(noisefiles)) || ne(length(onsetfiles),nr_task_runs) || ne(length(runnames),nr_task_runs)
        error('number of raw images does not match number of confound regressor files')
    end
    
%% create spm batches, save, and run

clear matlabbatch;
matlabbatch = struct([]); % create empty structure matlabbatch

% FIRST BATCH: MODEL SPECIFICATION
matlabbatch{1}.spm.stats.fmri_spec.dir = {outputdir};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'scans';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = nr_slices;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = nr_slices/2;
    for i=1:length(runnames) % loop over runs - order remains alphabetical neg neu pos
        cd(outputdir);
        load (onsetfiles{i});
        scans = spm_select('ExtFPList',derivdir,strcat('^s6_.*',runnames(i,:),'.*\.nii$'),Inf); % spm_select uses regular expressions as filter . is wildcard, not *!
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).scans = cellstr(scans);
            if exist('conds2model')
                c=conds2model;
            else
                c=categories(O.trial_type);
            end
        % loop over conditions
            for j=1:length(c)
                idx=O.trial_type==c{j};
                onsets_TR = O.onset_TR(idx);
                durations_TR = O.duration_TR(idx);
                matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond(j).name = c{j};
                matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond(j).onset = onsets_TR;
                matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond(j).duration = durations_TR;
                matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond(j).tmod = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond(j).pmod = struct('name', {}, 'param', {}, 'poly', {});
                matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond(j).orth = 1;
            end
        % continue filling the rest of the batch
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).hpf = hpf;
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi_reg = noisefiles(i);
            if strcmpi(basis_set,'can')==1
                matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
            elseif strcmpi (basis_set,'derivs')==1
                matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [1 1];
            else
                error('invalid basis_set option')
            end
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'none';
    end
    
% SECOND BATCH: ESTIMATION

matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;  

% THIRD BATCH: CONTRASTS

% load noise regressors per condition
noise_neg = importdata(noisefiles{1});
noise_neu = importdata(noisefiles{2});
noise_pos = importdata(noisefiles{3});

% check whether conds2model is matching currently defined contrasts, error
% out if not
    if ismember('fixation',conds2model) && ismember('pain',conds2model) && ismember('rating',conds2model)
    else
        error('conds2model option does not match contrasts currently defined in script - adapt contrasts accordingly before running script')
    end

% create contrasts in spm contrast manager batch
% NEEDS TO BE ADAPTED IF CONDS2MODEL OPTION CHANGES!
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    if strcmpi(basis_set,'can')==1
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = ['main effect of pain'];
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [zeros(1,1) ones(1,1) zeros(1,1) zeros(1,size(noise_neg,2)) zeros(1,1) ones(1,1) zeros(1,1) zeros(1,size(noise_neu,2)) zeros(1,1) ones(1,1)]; % condition order fixation pain rating, then noise regs
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = ['pain in negative'];
        matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [zeros(1,1) ones(1,1)]; 
        matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = ['pain in neutral'];
        matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [zeros(1,3) zeros(1,size(noise_neg,2)) zeros(1,1) ones(1,1)]; 
        matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = ['pain in positive'];
        matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [zeros(1,3) zeros(1,size(noise_neg,2)) zeros(1,3) zeros(1,size(noise_neu,2)) zeros(1,1) ones(1,1)]; 
        matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = ['pain in negative vs neutral'];
        matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [zeros(1,1) ones(1,1) zeros(1,1) zeros(1,size(noise_neg,2)) zeros(1,1) -ones(1,1)]; 
        matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = ['pain in negative vs positive'];
        matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [zeros(1,1) ones(1,1) zeros(1,1) zeros(1,size(noise_neg,2)) zeros(1,3) zeros(1,size(noise_neu,2)) zeros(1,1) -ones(1,1)]; 
        matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = ['pain in neutral vs positive'];
        matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [zeros(1,3) zeros(1,size(noise_neg,2)) zeros(1,1) ones(1,1) zeros(1,1) zeros(1,size(noise_neu,2)) zeros(1,1) -ones(1,1)]; 
        matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'none';
    elseif strcmpi(basis_set,'derivs')==1
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = ['main effect of pain'];
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = [zeros(3,3) eye(3) zeros(3,3) zeros(3,size(noise_neg,2)) zeros(3,3) eye(3) zeros(3,3) zeros(3,size(noise_neu,2)) zeros(3,3) eye(3)]; 
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{2}.fcon.name = ['pain in negative'];
        matlabbatch{3}.spm.stats.con.consess{2}.fcon.weights = [zeros(3,3) eye(3)];
        matlabbatch{3}.spm.stats.con.consess{2}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{3}.fcon.name = ['pain in neutral'];
        matlabbatch{3}.spm.stats.con.consess{3}.fcon.weights = [zeros(3,9) zeros(3,size(noise_neg,2)) zeros(3,3) eye(3)]; 
        matlabbatch{3}.spm.stats.con.consess{3}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{4}.fcon.name = ['pain in positive'];
        matlabbatch{3}.spm.stats.con.consess{4}.fcon.weights = [zeros(3,9) zeros(3,size(noise_neg,2)) zeros(3,9) zeros(3,size(noise_neu,2)) zeros(3,3) eye(3)]; 
        matlabbatch{3}.spm.stats.con.consess{4}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{5}.fcon.name = ['pain in negative vs neutral'];
        matlabbatch{3}.spm.stats.con.consess{5}.fcon.weights = [zeros(3,3) eye(3) zeros(3,3) zeros(3,size(noise_neg,2)) zeros(3,3) -eye(3)]; 
        matlabbatch{3}.spm.stats.con.consess{5}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{6}.fcon.name = ['pain in negative vs positive'];
        matlabbatch{3}.spm.stats.con.consess{6}.fcon.weights = [zeros(3,3) eye(3) zeros(3,3) zeros(3,size(noise_neg,2)) zeros(3,9) zeros(3,size(noise_neu,2)) zeros(3,3) -eye(3)]; 
        matlabbatch{3}.spm.stats.con.consess{6}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.consess{7}.fcon.name = ['pain in neutral vs positive'];
        matlabbatch{3}.spm.stats.con.consess{7}.fcon.weights = [zeros(3,9) zeros(3,size(noise_neg,2)) zeros(3,3) eye(3) zeros(3,3) zeros(3,size(noise_neu,2)) zeros(3,3) -eye(3)]; 
        matlabbatch{3}.spm.stats.con.consess{7}.fcon.sessrep = 'none';
    else 
        error('invalid basis_set option')
    end
matlabbatch{3}.spm.stats.con.delete = 0;

% SAVE BATCHES AND RUN

cd(outputdir);
eval(['save ' outputdir(1,end-5:end) '_' basis_set '_first_level.mat matlabbatch']); 
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

%% delete unzipped images
cd(derivdir);
imgs = dir('s6_*preproc_bold.nii');
imgfiles = {imgs(1:nr_task_runs).name}';
    for i=1:length(imgfiles)
        delete(imgfiles{i});
    end
cd(outputdir);