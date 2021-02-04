%% LaBGAS_deriv_unzip_nii_smooth
%
% This script will unzip fMRIprep output images, smooth them, zip the
% smoothed images, and delete all the unzipped images again
% 
% DEPENDENCIES
% SPM12 on your Matlab path
% 
% INPUTS
% preprocessed .nii.gz images outputted by fMRIprep
%
% OUTPUT
% smoothed .nii.gz images
%
%__________________________________________________________________________
%
% author: Lukas Van Oudenhove
% date:   May, 2020
%
%__________________________________________________________________________
% @(#)% LaBGAS_deriv_unzip_nii_smooth.m         v1.0        
% last modified: 2020/05/10

%% define directory and smoothing options
derivdir = 'C:\Users\lukas\Dropbox (Personal)\proj-SERT-fMRI\derivatives\fmriprep'; % derivatives directory with fMRIprep output
fwhm = 6; % kernel width in mm
prefix = 's6-'; % prefix for name of smoothed images

% DO NOT CHANGE CODE BELOW THIS LINE
% ALWAYS MAKE A LOCAL COPY OF EXAMPLE SCRIPTS BEFORE MODIFYING

%% unzip images
cd(derivdir);
d=dir('sub-*');
d2={d(:).name}';
idx={d(:).isdir}';
idx2=cell2mat(idx);
d3=d2(idx2);
    for i=1:length(d3)
        cd(d3{i});
        cd('func');
        % unzip .nii.gz files
        gunzip('*preproc_bold*.nii.gz');
        % write smoothing spm batch
        clear matlabbatch;
        matlabbatch = struct([]);
        scans=spm_select('ExtFPList',pwd,'.*\.nii$',Inf);
        kernel = ones(1,3).*fwhm;
        matlabbatch{1}.spm.spatial.smooth.data = cellstr(scans);
        matlabbatch{1}.spm.spatial.smooth.fwhm = kernel;
        matlabbatch{1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1}.spm.spatial.smooth.im = 0;
        matlabbatch{1}.spm.spatial.smooth.prefix = prefix;
        % save batch and run
        eval(['save ' d3{i} '_smooth.mat matlabbatch']); 
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
        % zip smoothed files
        gzip('s6*');
        % delete all unzipped files
        delete('*.nii');
        cd(derivdir);
    end