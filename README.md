# Ironsmith QSM Toolkit		       

Copyright (c) 2020 Valentinos Zachariou, University of Kentucky. All rights reserved (see LICENSE file for more details).

#### This software has been developed for research purposes only and is not a clinical tool.  

## 1) Software requirements:

#### a) MATLAB

Ironsmith requires Matlab to run MEDI and supports versions R2017b to R2019b.  
Matlab is not needed if MEDI is not required.  

#### b) Singularity

Ironsmith tested on Singularity versions 3.5.2 and 3.5.3  
Installation guide:  
https://sylabs.io/guides/3.5/admin-guide/installation.html

#### c) Bash unix shell version 4.2.46(2) or later.

## 2) Installation:

a) Download Ironsmith QSM Toolkit

Option 1: download from github  
https://github.com/vzachari/IronSmithQSM

Option 2: using git  
`git clone https://github.com/vzachari/IronSmithQSM.git && cd IronSmithQSM && git checkout v1.0`

b) Download QSM_Container.simg (8.8GB) from:  
https://drive.google.com/file/d/1wPdd2Xa0oLV2wwpHneXZ7nlIZB3XoKFb/view?usp=sharing

c) Place QSM_Container.simg in IronSmithQSM/Functions

d) Edit IronSmithQSM/Matlab_Config.txt with the path to the matlab executable on your system.  
*(e.g. /usr/local/MATLAB/R2019b/bin/matlab)*  
Supported versions R2017b to R2019b.  

e) Add the IronSmithQSM directory to $PATH  
Guide: https://opensource.com/article/17/6/set-path-linux

## 3) Syntax:

**Ironsmith [MyInputFile] [absolute path to output folder]**

*Example: Ironsmith File.csv /home/data/MyAmazingExp/QSM_Analysis"*

a) The output folder does not need to exist.

b) The output folder does not need to be empty but Ironsmith will skip any participant specified in MyInputFile that has a corresponding folder inside the output folder.

*Ex. if S0001 is specified in MyInputFile and folder S0001 exists in output folder, S0001 will be skipped.*

c) Freesurfer is a reserved folder name under output folder and may be used by Ironsmith. See section #5 on quality of life features below.

## 4) MyInputFile format:  

a) MyInputFile has to be CSV formatted (entries separated by commas ',').

b) Each row corresponds to a different participant.  

*see Example_File.csv in IronSmithQSM folder:*  

### If MEDI is required to create QSM images/maps:  

**Column1** = Subj (nominal subject variable e.g. S0001 or 01 or Xanthar_The_Destroyer)  
**Column2** = MEDI_Yes <-- this is case sensitive  
**Column3** = Absolute path to directory with MPR/MEMPR files  
*(e.g. /home/subjecs/S01/MPR).*

**MPR/MEMPR files can be:**  

a) DICOMS

Only MPR/MEMPR DICOMS should be present in the MPR folder if you want Ironsmith to process DICOMS. If NIFTI files exist together with DICOMS, they will be selected instead (see "b" below).

b) Multiple .nii/.nii.gz files each corresponding to a different echo.

To make sure the correct files are selected, each NIFTI file needs to have _e# in the file name, where # is the echo number.  
*(e.g. S0001_MEMPR_e1.nii.gz, S0001_MEMPR_e2.nii.gz...)*   
This is the default **dcm2niix** output format for multiple echos.

c) Single .nii/nii.gz file with multiple timepoints, each corresponding to a different echo.  
This single NIFTI file can have any name.

d) Single .nii/nii.gz file with a single echo/timepoint.  
This can be rms/averaged across echos or just a single echo T1 MPRAGE.  
This single NIFTI file can have any name.

**Column4** = Absolute path to folder with QSM DICOM files  
*(e.g. /home/subjecs/S01/QSM_Dicom)*

Preferably only QSM DICOMS should be present in the QSM_Dicom folder. However, Ironsmith can filter out the following filetypes .nii .json .txt .nii.gz .HEAD .BRIK .hdr .img

All 4 columns need to be provided, otherwise Ironsmith will exit with errors.

### If MEDI is NOT required. That is QSM Maps and GRE Magnitude images are already available:  

**Column1** = Subj (nominal subject variable e.g. S0001 or 01 or Xanthar_The_Destroyer)  
**Column2** = MEDI_No <-- This is case sensitive  
**Column3** = Absolute path to directory with MPR/MEMPR files  
*(e.g. /home/subjecs/S01/MPR)*

**MPR/MEMPR files can be:**  

a) DICOMS

Only MPR/MEMPR DICOMS should be present in the MPR folder if you want Ironsmith to process DICOMS. If NIFTI files exist together with DICOMS, they will be selected instead (see "b" below).

b) Multiple .nii/.nii.gz files each corresponding to a different echo.

To make sure the correct files are selected, each NIFTI file needs to have _e# in the file name, where # is the echo number.  
*(e.g. S0001_MEMPR_e1.nii.gz, S0001_MEMPR_e2.nii.gz...)*   
This is the default **dcm2niix** output format for multiple echos.

c) Single .nii/nii.gz file with multiple timepoints, each corresponding to a different echo.  
This single NIFTI file can have any name.

d) Single .nii/nii.gz file with a single echo/timepoint.  
This can be rms/averaged across echos or just a single echo T1 MPRAGE.  
This single NIFTI file can have any name.

**Column4** = Absolute path including filename to QSM magnitude image  
*(e.g. /home/subjecs/S01/QSM/QSM_Magnitude.nii.gz)*  

**Column5** = Absolute path including filename to QSM map  
*(e.g. /home/subjects/S01/QSM/QSM_Map.nii.gz)*  

All 5 columns need to be provided, otherwise Ironsmith will exit with errors

## 5) Quality of life features:  

### Skipping freesurfer segmentation

If a participant already has a completed freesurfer recon-all -all segmentation folder and you would like Ironsmith to skip the freesurfer segmentation step, do the following:

a) Copy the freesurfer recon-all folder (the one containing the *label*, *mri*, *scripts*, *stats*, *surf*... folders) into **/OutputFolder/Freesurfer**, where **OutputFolder** is the one specified/to be specified in the Ironsmith command.

You can create the /OutputFolder/Freesurfer folder or Ironsmith will create it for you if you have run it at least once previously for OutputFolder.

b) Rename the recon-all folder to **Subj_FreeSurfSeg_Skull**. Subj should match the one provided in MyInputFile and should correspond to the participant you want the segmentation step skipped.

### Viewing output NIFTI files

If you do not have a NIFTI viewer, AFNI can be launched from within the QSM_Container.simg by using the *Ironsmith_AFNI* command. Just type *Ironsmith_AFNI* from within the folder you would like to view NIFTI files from.

AFNI viewer documentation:  
https://afni.nimh.nih.gov/pub/dist/edu/latest/afni_handouts/afni03_interactive.pdf

## 6) Outputs:

Each participant processed by Ironsmith will have a corresponding folder in **OutputFolder**. For example, if "**/home/QSM_Analysis**" is the OutputFolder and "**S0001**" is one of the participants processed, then **/home/QSM_Analysis/S0001** will be created and populated with data.

a) All masks/ROIs are placed under:

**S0001/QSM/Freesurf_QSM_Masks/Cort_Masks_AL_QSM_RS_Erx1  
S0001/QSM/Freesurf_QSM_Masks/SubC_Masks_AL_QSM_RS_Erx1**

b) All QSM maps/images created are placed under S0001/QSM/Freesurf_QSM_Masks and are labelled as:

**Subj_QSM_Map_FSL.nii.gz**	<-- Default MEDI  
**Subj_QSM_Map_New_CSF_FSL.nii.gz** <-- Lateral ventricles as the QSM reference structure  
**Subj_QSM_Map_New_WM_FSL.nii.gz** <-- White matter as the QSM reference structure  

c) All QSM maps warped to MNI space are placed under

**S0001/QSM/Freesurf_QSM_Masks/MNI152_QSM**

d) QSM per ROI means (87 ROIs) are under **/QSM_Analysis/Group** as follows:

**Group_QSM_Mean.csv**  
**Group_QSM_Mean_CSF.csv**  
**Group_QSM_Mean_WM.csv**  
**Group_QSM_ADJ_Mean.csv**  
**Group_QSM_ADJ_Mean_CSF.csv**  
**Group_QSM_ADJ_Mean_WM.csv**  
**Group_QSM_SNR.csv**  

_Mean = Using only positive QSM voxels  
_ADJ_Mean = Using only positive QSM voxels and adjusting for ROI size  
_CSF = Lateral ventricles as the QSM reference structure  
_WM = White matter as the QSM reference structure  

SNR is calculated as follows:  
mean signal intensity of magnitude image within an ROI / standard deviation of magnitude signal outside the head.

The outside the head mask can be found here:  
**/QSM_Analysis/S0001/QSM/Freesurf_QSM_Masks/Subj_QSM_Mag_FSL_rms_OH_Mask.nii.gz**


## Ironsmith uses the following software, provided in the form of a singularity image:

### 1.AFNI

RW Cox. AFNI: Software for analysis and visualization of functional magnetic resonance neuroimages. Computers and Biomedical Research, 29:162-173, 1996.

RW Cox and JS Hyde. Software tools for analysis and visualization of FMRI Data. NMR in Biomedicine, 10:171-178, 1997.

S Gold, B Christian, S Arndt, G Zeien, T Cizadlo, DL Johnson, M Flaum, and NC Andreasen. Functional MRI statistical software packages: a comparative analysis. Human Brain Mapping, 6:73-84, 1998.

### 2.dcm2niix  

Li, Xiangrui, et al. "The first step for neuroimaging data analysis: DICOM to NIFTI conversion." Journal of neuroscience methods 264 (2016): 47-56.

### 3.Freesurfer  

Dale, A.M., Fischl, B., Sereno, M.I., 1999. Cortical surface-based analysis. I. Segmentation and surface reconstruction. Neuroimage 9, 179-194.

Dale, A.M., Sereno, M.I., 1993. Improved localization of cortical activity by combining EEG and MEG with MRI cortical surface reconstruction: a linear approach. J Cogn Neurosci 5, 162-176.

Desikan, R.S., Segonne, F., Fischl, B., Quinn, B.T., Dickerson, B.C., Blacker, D., Buckner, R.L., Dale, A.M., Maguire, R.P., Hyman, B.T., Albert, M.S., Killiany, R.J., 2006. An automated labeling system for subdividing the human cerebral cortex on MRI scans into gyral based regions of interest. Neuroimage 31, 968-980.

### 4.FSL

M.W. Woolrich, S. Jbabdi, B. Patenaude, M. Chappell, S. Makni, T. Behrens, C. Beckmann, M. Jenkinson, S.M. Smith. Bayesian analysis of neuroimaging data in FSL. NeuroImage, 45:S173-86, 2009

S.M. Smith, M. Jenkinson, M.W. Woolrich, C.F. Beckmann, T.E.J. Behrens, H. Johansen-Berg, P.R. Bannister, M. De Luca, I. Drobnjak, D.E. Flitney, R. Niazy, J. Saunders, J. Vickers, Y. Zhang, N. De Stefano, J.M. Brady, and P.M. Matthews. Advances in functional and structural MR image analysis and implementation as FSL. NeuroImage, 23(S1):208-19, 2004

M. Jenkinson, C.F. Beckmann, T.E. Behrens, M.W. Woolrich, S.M. Smith. FSL. NeuroImage, 62:782-90, 2012

### 5.MEDI Toolbox  

de Rochefort, L., Liu, T., Kressler, B., Liu, J., Spincemaille, P., Lebon, V., ... & Wang, Y. (2010). Quantitative susceptibility map reconstruction from MR phase data using bayesian regularization: validation and application to brain imaging. Magnetic Resonance in Medicine: An Official Journal of the International Society for Magnetic Resonance in Medicine, 63(1), 194-206.

http://pre.weill.cornell.edu/mri/pages/qsm.html
