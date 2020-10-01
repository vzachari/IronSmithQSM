██ ██████   ██████  ███    ██     ███████ ███    ███ ██ ████████ ██   ██ 
██ ██   ██ ██    ██ ████   ██     ██      ████  ████ ██    ██    ██   ██ 
██ ██████  ██    ██ ██ ██  ██     ███████ ██ ████ ██ ██    ██    ███████ 
██ ██   ██ ██    ██ ██  ██ ██          ██ ██  ██  ██ ██    ██    ██   ██ 
██ ██   ██  ██████  ██   ████     ███████ ██      ██ ██    ██    ██   ██ 

# IronSmith QSM Toolkit V1.0 (09/24/2020)		       
Created by Valentinos Zachariou	    		       
University of Kentucky


Syntax: Ironsmith [MyInputFile] [absolute path to output folder] 
	Example: Ironsmith File.csv /home/data/MyAmazingExp/QSM_Analysis"

1) The output folder does not need to exist
2) The output folder does not need to be empty but IronSmith will skip any participant specified in MyInputFile that has a corresponding folder inside the output folder:
		for instance, if S0001 is specified in MyInputFile and folder S0001 exists in output folder, S0001 will be skipped.

3) Freesurfer is a reserved folder name under output folder and may be used by Ironsmith.

4) *** MyInputFile ****

## MyInputFile format:  

1) File has to be CSV formatted (entries separated by commas ',')
2) File must have 5 columns  
3) Each row corresponds to a different participant  

## MyInputFile column formatting:  

### If MEDI is required to create QSM images/maps:  
  
Column1 = Subj (Nominal subject variable e.g. S0001 or 01 or Xanthar_The_Destroyer)  
Column2 = Absolute path to directory with MPRAGE/MEMPRAGE files (e.g. /home/subjecs/S01/MPR). MPR/MEMPR files can be:  

1) DICOMS (Only MPR/MEMPR DICOMS should be present in the MPR folder if you want IronSmith to process the DICOMS. If NIFTI files exist together with the DICOMS, they will be selected instead (see #2 below). 
2) Multiple .nii/.nii.gz files each corresponding to a different echo    
3) Single .nii/nii.gz file with multiple timepoints, each corresponding to a different echo    
4) Single .nii/nii.gz file with a single echo/timepoint <--- this can be rms/averaged across echos or just a single echo T1 MPRAGE
 
Column3 = Absolute path to folder with QSM DICOM files (e.g. /home/subjecs/S01/QSM_Dicom)
	Preferably only QSM DICOMS should be present in the QSM_Dicom folder. However, IronSmith can filter out the following filetypes .nii .json .txt .nii.gz .HEAD .BRIK .hdr .img
	
Column4 = N/A (column must exist even if empty)    
Column5 = MEDI_Yes <-- This is case sensitive  

### If MEDI is NOT required. That is QSM Maps, Phase and Magnitude images are already available then:  
Column1 = Subj (Nominal subject variable e.g. S0001 or 01 or Xanthar_The_Destroyer)  
Column2 = Absolute path to directory with MPRAGE/MEMPRAGE files (e.g. /home/subjecs/S01/MPR). MPR/MEMPR files can be:  

1) DICOMS (Only MPR/MEMPR DICOMS should be present in the MPR folder if you want IronSmith to process the DICOMS. If NIFTI files exist together with the DICOMS, they will be selected instead (see #2 below).  
2) Multiple .nii/.nii.gz files each corresponding to a different echo    
3) Single .nii/nii.gz file with multiple timepoints, each corresponding to a different echo    
4) Single .nii/nii.gz file with a single echo <--- this can be rms/averaged across echos or just a single echo T1 MPRAGE

Column3 = Absolute path including filename to QSM magnitude image (e.g. /home/subjecs/S01/QSM/QSM_Magnitude.nii.gz)  
Column4 = Absolute path including filename to QSM map (e.g. /home/subjects/S01/QSM/QSM_Map.nii.gz)  
Column5 = MEDI_No <-- This is case sensitive

# Quality of life features:  

### If a participant already has a completed freesurfer recon-all -all segmentation folder and you would like IronSmith to skip the segmentation step, do the following: 

1) copy the recon-all folder (the one containing the label, mri, scripts, stats, surf ... folders) into /OutputFolder/Freesurfer, where OutputFolder is the one required in the Ironsmith command syntax
		You can create the /OutputFolder/Freesurfer folder or Ironsmith will create it for you if you have run it at least once with that OutputFolder specified
 
2) rename the recon-all folder to Subj_Freesurfer_Skull . Subj should match the one provided in the MyInputFile and the one you want the segmentation step skipped

#********Outputs

Each participant processed by Ironsmith will have a corresponding folder in OutputFolder. For example, if QSM_Analysis is the OutputFolder 
and S0001 is one of the participants processed then /OutputFolder/S0001 will be created and populated with data

1) All masks/ROIs are placed under S0001/QSM/Freesurf_QSM_Masks/Cort_Masks_AL_QSM_RS_Erx1 and S0001/QSM/Freesurf_QSM_Masks/SubC_Masks_AL_QSM_RS_Erx1
2) All QSM maps/images created are under S0001/QSM/Freesurf_QSM_Masks and are labelled as Subj_QSM_Map_FSL.nii.gz
3) All QSM maps warped to MNI space are placed in S0001/QSM/Freesurf_QSM_Masks/MNI152_QSM
4) QSM per ROI means (87 ROIs) are under /OutputFolder/Group

	Group_QSM_Mean.csv
	Group_QSM_Adj_Mean.csv <--- Using only positive QSM voxels and adjusting for ROI size
	Group_QSM_SNR.csv <--- Per ROI SNR measures using the QSM Magnitude image



#   .-'  /           
# .'    /   /`.    
# |    /   /  |   
# |    \__/   |   
# `.         .'   
#   `.     .'    
#     | ][ |      
#     | ][ |
#     | ][ |
#     | ][ |    
#     | ][ |  
#     | ][ |      
#     | ][ |    
#     | ][ |    
#     | ][ |
#   .'  __  `.
#   |  /  \  | 
#   |  \__/  |
#   `.      .'
#     `----'

