%% LaBGAS_extract_confound_reg_fMRIprep
%
% This script will extract noise regressors from fMRIprep output for
% Nathalie's emotional modulation of visceral pain study, including
% a) CSF signal
% b) 24 head motion parameters (six directions, derivatives, and squared
% values)
% c) dummy spike regressors 
% 
% DEPENDENCIES
% a) CANlab Github repos on your Matlab path
% b) SPM12 on your Matlab path
% c) BIDS data organization
%
% INPUTS 
% confound_regressor.tsv files from fMRIprep output
%
% OUTPUT
% noise_regs & onsets files that can be loaded into CANlab DSGN structure
% or directly into SPM first level batch (for the latter, use
% LaBGAS_first_level_batch_fMRIprep_conf)
%
% NR_TASK_RUNS
% enter number of task-based runs (EXCLUDING RESTING STATE RUN)
%
% SPIKE_DEF - NOT CASE SENSITIVE
% 'fMRIprep' use spike regressors based on a combination of DVARS and FD thresholds 
% set in fMRIprep arguments --fd-spike-threshold and --dvars-spike-threshold
%
% 'CANlab' use spike regressors based on CANlab's spike detection algorithm
% (Mahalanobis distance)(function scn_session_spike_id) and DVARS
% cfr make_nuisance_covs_from_fmriprep_output.m script in CANlab's
% CanLabScripts Github repo 
% https://github.com/canlab/CanlabScripts/tree/master/Scripts/Preprocessing
%
% OMIT_SPIKE_TRIALS
% 'no' do not remove onsets of pain trials coinciding with a spike
% 'yes' do remove - THIS IS NOT RECOMMENDED
%
% SPIKE_ADDITIONAL_VOLS
% set how many volumes after the spike you want to additionally regress out
% be careful for task-based data since this quite aggressive approach is
% mostly based on rs-fMRI, and beware of omitting too many volumes as well
% as creating missingness not at random - THIS IS NOT RECOMMENDED
%
% SPIKES_PERCENT_THRESHOLD
% set the maximum number of spikes (% of total volumes expressed as 0-1) you want to
% tolerate
%__________________________________________________________________________
%
% author: lukas.vanoudenhove@kuleuven.be
% date:   May, 2020
%
%__________________________________________________________________________
% @(#)% LaBGAS_extract_confound_reg_fMRIprep.m         v1.2        
% last modified: 2020/05/12
%
% changes versus version 1.0
% 1) made omit_spike_trials optional
% 2) small optimizations
% changes versus version 1.1
% omitted unzipping and zipping if spike_def = fMRIprep

%% set paths, TR, and choose options
basedir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI';
derivdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\derivatives\fmriprep\sub-01\func'; % dir with fMRIprep output
rawdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\rawdata1\sub-01\func'; % dir with raw .nii files
outputdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\firstlevel\sub-01'; % dir where confound files for first level will be written
TR = 2;
nr_task_runs = 3;
spike_def = 'fMRIprep';
omit_spike_trials = 'no';
spike_additional_vols=0;
spikes_percent_threshold=0.05;

% DO NOT CHANGE CODE BELOW THIS LINE WITHOUT DISCUSSING WITH LUKAS
% ALWAYS MAKE A LOCAL COPY OF EXAMPLE SCRIPTS BEFORE MODIFYING

%% define filenames, and unzip raw images
% .nii.gz not supported in CANlab function 'scn_session_spike_id' which is
% called in this script if spike_def = 'CANlab'
cd(rawdir);
    if strcmpi(spike_def,'CANlab')==1
        rawimgs = dir('*bold.nii.gz');
        rawimgs = {rawimgs(1:nr_task_runs).name}';
            for i=1:length(rawimgs)
                gunzip(rawimgs{i});
            end
        rawimgs = dir('*bold.nii');
        rawimgs = {rawimgs(:).name}';
    end
onsetfiles = dir('*events.tsv');
onsetfiles = {onsetfiles(:).name}';
cd(derivdir);
tasks = dir('*task*.tsv');
taskfiles = {tasks(1:nr_task_runs).name}';
tasknames = char(taskfiles);
tasknames = tasknames(:,1:15);
    if length(onsetfiles) ~= length(taskfiles) 
        error('number of onset files does not match number of confound regressor files')
    end
    
%% calculate and extract confound regressors and onsets (with respect to movement!) and write to file

for task=1:length(taskfiles)
    % load confound regressor file generated by fMRIprep into Matlab table
    % variable
    cd(derivdir);
    R=readtable(taskfiles{task},'TreatAsEmpty','n/a','FileType', 'text', 'Delimiter', 'tab');
        
    % replace NaNs in first row with Os
    wh_replace = ismissing(R(1,:));
        if any(wh_replace)
            R{1, wh_replace} = zeros(1, sum(wh_replace)); % make array of zeros of the right size
        end
            
    % calculate and extract confound regressors
        if strcmpi(spike_def,'fMRIprep')==1
            
            % define regressors in fMRIprep output
            regs=R.Properties.VariableNames;
            spike_cols = contains(regs,'outlier');
            Rspikes=R(:,spike_cols);
            Rspikes.spikes=sum(Rspikes{:,1:end},2);
            idx=Rspikes.spikes==1;
            volume_idx = [1:height(R)]; 
            spikes = volume_idx(idx);
            
            % flag user-specified number of volumes after each spike
            % Motion can create artifacts lasting longer than the single image we
            % usually account for using spike id scripts. we're also going to flag the
            % following TRs, the number of which is defined by the user. If
            % 'spike_additional_vols' remains unspecified, everything will proceed as
            % it did before, meaning spikes will be identified and flagged in the
            % creation of nuisance regressors without considering the following TRs
            % Add them if user requested, for both nuisance_covs and dvars_spikes_regs
                if exist('spike_additional_vols')
                    nuisance_covs_additional_spikes = zeros(height(R),length(spikes)*spike_additional_vols);
                        % This loop will create a separate column with ones in each row (TR) 
                        % we would like to consider a nuisance regressor
                        for i = 1:length(spikes) 
                            nuisance_covs_additional_spikes(spikes(i)+1 : spikes(i)+spike_additional_vols,(i*spike_additional_vols-(spike_additional_vols-1)):(i*spike_additional_vols)) = eye(spike_additional_vols);
                        end
                    % if any spikes went beyond the end, trim it down
                    nuisance_covs_additional_spikes = nuisance_covs_additional_spikes(1:height(R),:);
                    % add the additional spikes to the larger matrix
                    R = [R array2table(nuisance_covs_additional_spikes)];
                end

            % remove redundant spike regressors
            regs = R.Properties.VariableNames;
            spike_cols = contains(regs,'outlier');
            additional_spike_cols = contains(regs,'additional_spikes'); 
            [duplicate_rows, ~] = find(sum(R{:, spike_cols | additional_spike_cols}, 2)>1);
                for i = 1:length(duplicate_rows) %This loop sets duplicate values to zero; drops them later (to keep indices the same during the loop)
                    [~,curr_cols] = find(R{duplicate_rows(i),:}==1);
                    R{duplicate_rows(i), curr_cols(2:end)} = 0;
                end
            R = R(1:height(R), any(table2array(R)));

        elseif strcmpi(spike_def,'CANlab')==1

            % load raw image file
            cd(rawdir);
            raw_img_fname = rawimgs{task};

            % add in canlab spike detection (Mahalanobis distance)
            [g, spikes, gtrim, nuisance_covs, snr] = scn_session_spike_id(raw_img_fname, 'doplot', 0);
            cd(derivdir);
            nuisance_covs(:,1) = []; %drop gtrim which is the global signal
            R = [R array2table(nuisance_covs)];

            % add in dvars spike regressors that are non-redundant with mahal spikes
            dvarsZ = [0; zscore(R.dvars(2:end))]; % first element of dvars always = 0, drop it from zscoring and set it to Z=0
            dvars_spikes = find(dvarsZ > 3); % arbitrary cutoff -- Z > 3
            same = ismember(dvars_spikes,spikes);
            dvars_spikes(same) = []; % drop the redundant ones
            dvars_spikes_regs = zeros(height(R),length(dvars_spikes));
                for i=1:length(dvars_spikes)
                    dvars_spikes_regs(dvars_spikes(i),i) = 1;
                end
            R = [R array2table(dvars_spikes_regs)];

            % flag user-specified number of volumes after each spike
            % Motion can create artifacts lasting longer than the single image we
            % usually account for using spike id scripts. we're also going to flag the
            % following TRs, the number of which is defined by the user. If
            % 'spike_additional_vols' remains unspecified, everything will proceed as
            % it did before, meaning spikes will be identified and flagged in the
            % creation of nuisance regressors without considering the following TRs
            % Add them if user requested, for both nuisance_covs and dvars_spikes_regs
                if exist('spike_additional_vols')
                    % concatenate generated spike and DVARS regs. We
                    % would like to flag subsequent TR's with respect to both of these
                    % measures.
                    spikes = [spikes;dvars_spikes];
                    nuisance_covs_additional_spikes = zeros(length(nuisance_covs),length(spikes)*spike_additional_vols);
                        % This loop will create a separate column with ones in each row (TR) 
                        % we would like to consider a nuisance regressor
                        % Performs this function for spikes and DVARS. From now on we'll
                        % consider the two as a single set of regressors
                        for i = 1:length(spikes) 
                            nuisance_covs_additional_spikes(spikes(i)+1 : spikes(i)+spike_additional_vols,(i*spike_additional_vols-(spike_additional_vols-1)):(i*spike_additional_vols)) = eye(spike_additional_vols);
                        end
                    % if any spikes went beyond the end, trim it down
                    nuisance_covs_additional_spikes = nuisance_covs_additional_spikes(1:height(R),:);
                    % add the additional spikes to the larger matrix
                    R = [R array2table(nuisance_covs_additional_spikes)];
                end

            % remove redundant spike regressors
            regs = R.Properties.VariableNames;
            spike_cols = contains(regs,'nuisance_covs'); 
            dvars_cols = contains(regs,'dvars_spikes'); 
            additional_spike_cols = contains(regs,'additional_spikes'); 

            [duplicate_rows, ~] = find(sum(R{:, spike_cols | dvars_cols | additional_spike_cols}, 2)>1);
                for i = 1:length(duplicate_rows) %This loop sets duplicate values to zero; drops them later (to keep indices the same during the loop)
                    [~,curr_cols] = find(R{duplicate_rows(i),:}==1);
                    R{duplicate_rows(i), curr_cols(2:end)} = 0;
                end
            R = R(1:length(nuisance_covs), any(table2array(R)));
        else
            error('invalid spike_def option')
        end
            
    % Select confound and spike regressors to return for use in GLM 
    regs = R.Properties.VariableNames;
    motion_cols = contains(regs,'rot') | contains(regs,'trans');
    spike_cols = contains(regs,'nuisance_covs') | contains(regs,'outlier'); 
    dvars_cols = contains(regs,'dvars_spikes'); 
    additional_spike_cols = contains(regs,'additional_spikes'); 
    Rselected = R(:,motion_cols | spike_cols | dvars_cols | additional_spike_cols);
    Rselected.csf = R.csf;
    Rspikes=R(:,spike_cols | dvars_cols | additional_spike_cols);
    Rspikes.spikes=sum(Rspikes{:,1:end},2);
    idx=Rspikes.spikes==1;
    volume_idx = [1:height(R)]; 
    spikes = volume_idx(idx)';
    
    % compute and output how many spikes total
    n_spike_regs = sum(dvars_cols | spike_cols | additional_spike_cols);
    n_spike_regs_percent = n_spike_regs / height(R);

    % print warning if #volumes identified as spikes exceeds
    % user-defined threshold
        if n_spike_regs_percent > spikes_percent_threshold
            warning('% of the volumes identified as spikes exceeds threshold - consider excluding run')
        end

    % save confound regressors as .txt file
    filename = strcat('noise_regs_',tasknames(task,1:15));
    rselected=table2struct(Rselected);
    cd(outputdir);
    writetable(Rselected,filename,'FileType','text','Delimiter','tab','WriteVariableNames',0);
    
    % read .tsv files with onsets, durations, and trial type, and omit pain
    % trials that coincide with spikes
    cd(rawdir);
    O=readtable(onsetfiles{task},'FileType', 'text', 'Delimiter', 'tab');
    O.onset_TR = round(O.onset/TR); % convert from seconds to TRs
    O.duration_TR = O.duration/TR;
    O.trial_type = categorical(O.trial_type);
        if strcmpi(omit_spike_trials,'yes')==1
            idx=O.trial_type ~='pain'; % identify pain trials
            same=ismember(O.onset_TR,spikes); % identify trials for which onset coincides with spike
            same(idx)=0; % apply only to pain trials
            O(same,:)=[]; % get rid of pain trials coinciding with spikes
        elseif strcmpi(omit_spike_trials,'no')==1
        else
            error('invalid omit_spike_trials option')
        end
    
    % save onsets file as .mat file
    filename = strcat('onsets_',tasknames(task,1:15));
    cd(outputdir);
    save(filename,'O');
end

%% delete unzipped images
    if strcmpi(spike_def,'CANlab')==1
        cd(rawdir);
            for i=1:length(rawimgs)
                delete(rawimgs{i});
            end
    end