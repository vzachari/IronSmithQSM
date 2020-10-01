#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 08/24/2020
#
# Script creates QSM masks from the freesurfer segmentations created in the previous script.
#
#
#       _---~~(~~-_.			
#     _{        )   )
#   ,   ) -~~- ( ,-' )_
#  (  `-,_..`., )-- '_,)
# ( ` _)  (  -~( -_ `,  }
# (_-  _  ~_-~~~~`,  ,' )
#   `~ -^(    __;-,((()))
#         ~~~~ {_ -_(())
#                `\  }
#                  { }
#

#Passed varialbes to 02_Create_QSM_Masks.sh
#1) Suject
#2) Output Folder
#3) Path
#4) MEDI Flag

#Subj="S0030"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/QSM_Test_Run"
#Path="/home/data3/vzachari/QSM_Toolkit/QSM_Std_Scripts"
#MEDIFlag="MEDI_No"

Subj=$1
OutFolder=$2
Path=$3
MEDIFlag=$4

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.02.Create.QSM.Mask.txt")
exec &> >(tee -a "$log_file")


echo ""
echo "---------------------------------------------------------------"
echo " _______  _______  __   __  "                                                                          
echo "|       ||       ||  |_|  | "                                                                         
echo "|   _   ||  _____||       | "                                                                          
echo "|  | |  || |_____ |       | "                                                                          
echo "|  |_|  ||_____  ||       | "                                                                          
echo "|      |  _____| || ||_|| | "                                                                          
echo "|____||_||_______||_|   |_| "                                                                          
echo " _______  ______    _______  _______  _______  _______    __   __  _______  _______  ___   _  _______ "
echo "|       ||    _ |  |       ||   _   ||       ||       |  |  |_|  ||   _   ||       ||   | | ||       |"
echo "|       ||   | ||  |    ___||  |_|  ||_     _||    ___|  |       ||  |_|  ||  _____||   |_| ||  _____|"
echo "|       ||   |_||_ |   |___ |       |  |   |  |   |___   |       ||       || |_____ |      _|| |_____ "
echo "|      _||    __  ||    ___||       |  |   |  |    ___|  |       ||       ||_____  ||     |_ |_____  |"
echo "|     |_ |   |  | ||   |___ |   _   |  |   |  |   |___   | ||_|| ||   _   | _____| ||    _  | _____| |"
echo "|_______||___|  |_||_______||__| |__|  |___|  |_______|  |_|   |_||__| |__||_______||___| |_||_______|"
echo ""
echo "---------------------------------------------------------------"
echo ""

cd $OutFolder/$Subj

if [[ $MEDIFlag == "MEDI_Yes" ]]; then
	
	cd QSM

elif [[ $MEDIFlag == "MEDI_No" ]]; then
	
	mkdir QSM
	cd QSM

else

	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo 'ERROR: MEDI Flag not set properly!'
	echo -e "----------------------------------------------\e[0m"
	echo ""		
	exit 5

fi


mkdir FreeSurf_QSM_Masks
cd FreeSurf_QSM_Masks
mkdir Cort_Mask_Orig
mkdir SubC_Mask_Orig

echo ""	
echo "Copying freesurfer files to $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks..."
echo ""	

#Copy Freesurfer Files to FreeSurf_QSM_Masks
cp $OutFolder/$Subj/MPR/${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz .
cp $OutFolder/$Subj/MPR/${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz .
cp $OutFolder/$Subj/MPR/${Subj}_FreeSurfSeg_Skull/mri/brain.mgz .
cp $OutFolder/$Subj/MPR/${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz .
cp $OutFolder/$Subj/MPR/${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz .

echo ""	
echo "Converting freesurfer files to NIFTI and orienting to FSL view"
echo ""	


#Convert .mgz files to .nii.gz files with orientation flip to view properly in FSL
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg mri_convert --out_orientation RAS brain.mgz ${Subj}_freesurfer_brain.nii.gz
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg mri_convert --out_orientation RAS brainmask.mgz ${Subj}_freesurfer_brainmask.nii.gz
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg mri_convert --out_orientation RAS aseg.mgz ${Subj}_freesurfer_aseg.nii.gz
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg mri_convert --out_orientation RAS aparc.DKTatlas+aseg.mgz ${Subj}_freesurfer_aseg_DKTatlas.nii.gz
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg mri_convert --out_orientation RAS wmparc.mgz ${Subj}_freesurfer_aseg_WM.nii.gz

echo ""
echo "---------------------------------------------------------------"	
echo "*** Creating QSM masks: ***"
echo "---------------------------------------------------------------"	
echo ""	

echo ""
echo "Creating left hemisphere subcortical masks"	
echo ""	
	
	#Generate LH subcortical masks
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 1.9 -uthr 2.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 2.9 -uthr 3.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 3.9 -uthr 4.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Lateral_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 4.9 -uthr 5.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Inf_Lateral_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 6.9 -uthr 7.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Cerebellum_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 7.9 -uthr 8.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Cerebellum_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 8.9 -uthr 9.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Thalamus.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 9.9 -uthr 10.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Thalamus_Proper.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 10.9 -uthr 11.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Caudate.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 11.9 -uthr 12.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Putamen.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 12.9 -uthr 13.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Pallidum.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 13.9 -uthr 14.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_Third_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 14.9 -uthr 15.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_Fourth_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 15.9 -uthr 16.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_Brain_Stem.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 16.9 -uthr 17.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Hipp.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 17.9 -uthr 18.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Amygdala.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 23.9 -uthr 24.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_CSF.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 25.9 -uthr 26.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_Accumbens_area.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 27.9 -uthr 28.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_VentralDC.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 77.9 -uthr 78.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_L_WM_Hypointensities.nii.gz

echo ""	
echo "Creating right hemisphere subcortical masks"	
echo ""	

	#Generate RH subcortical masks
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 40.9 -uthr 41.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 41.9 -uthr 42.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 42.9 -uthr 43.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Lateral_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 43.9 -uthr 44.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Inf_Lateral_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 45.9 -uthr 46.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Cerebellum_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 46.9 -uthr 47.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Cerebellum_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 47.9 -uthr 48.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Thalamus.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 48.9 -uthr 49.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Thalamus_Proper.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 49.9 -uthr 50.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Caudate.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 50.9 -uthr 51.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Putamen.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 51.9 -uthr 52.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Pallidum.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 52.9 -uthr 53.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Hipp.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 53.9 -uthr 54.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Amygdala.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 57.9 -uthr 58.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_Accumbens_area.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 59.9 -uthr 60.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_VentralDC.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 71.9 -uthr 72.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_Fifth_Ventricle.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 78.9 -uthr 79.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_R_WM_Hypointensities.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg.nii.gz -thr 76.9 -uthr 77.1 -bin SubC_Mask_Orig/${Subj}_freesurfer_WM_Hypointensities.nii.gz


echo ""
echo "Creating whole brain gray matter mask"	
echo ""	

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_Orig/${Subj}_freesurfer_LR_GM_Mask.nii.gz	\
			SubC_Mask_Orig/${Subj}_freesurfer_L_GM.nii.gz    	\
			SubC_Mask_Orig/${Subj}_freesurfer_R_GM.nii.gz


echo ""
echo "Creating whole brain white matter mask"
echo ""	

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_Orig/${Subj}_freesurfer_LR_WM_Mask.nii.gz	\
			SubC_Mask_Orig/${Subj}_freesurfer_L_WM.nii.gz    	\
			SubC_Mask_Orig/${Subj}_freesurfer_R_WM.nii.gz		\
			SubC_Mask_Orig/${Subj}_freesurfer_WM_Hypointensities.nii.gz

echo ""
echo "Creating lateral ventricle mask"
echo ""	

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_Orig/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask.nii.gz \
			SubC_Mask_Orig/${Subj}_freesurfer_L_Lateral_Ventricle.nii.gz    \
			SubC_Mask_Orig/${Subj}_freesurfer_R_Lateral_Ventricle.nii.gz


#Generate ROIs for lobar masks. These come from the DKTatlas

echo ""
echo "Creating frontal lobe gray matter masks"
echo ""	

	#Frontal Lobe

	#GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1027.9 -uthr 1028.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2027.9 -uthr 2028.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1026.9 -uthr 1027.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2026.9 -uthr 2027.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1002.9 -uthr 1003.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2002.9 -uthr 2003.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1017.9 -uthr 1018.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2017.9 -uthr 2018.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1019.9 -uthr 1020.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2019.9 -uthr 2020.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1018.9 -uthr 1019.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2018.9 -uthr 2019.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1011.9 -uthr 1012.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2011.9 -uthr 2012.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1013.9 -uthr 1014.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2013.9 -uthr 2014.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1023.9 -uthr 1024.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2023.9 -uthr 2024.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1016.9 -uthr 1017.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Paracentral_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2016.9 -uthr 2017.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Paracentral_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1031.9 -uthr 1032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2031.9 -uthr 2032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1031.9 -uthr 1032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2031.9 -uthr 2032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1025.9 -uthr 1026.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2025.9 -uthr 2026.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1001.9 -uthr 1002.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2001.9 -uthr 2002.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM.nii.gz


	
	#Combine structures together (with no overlap) to create Frontal Lobar Mask
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_GM.nii.gz    		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM.nii.gz


	#Combine structures together (with no overlap) to create Left Frontal Lobar Mask
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Frontal_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_GM.nii.gz    	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM.nii.gz
			


	#Combine structures together (with no overlap) to create right Frontal Lobar Mask
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Frontal_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM.nii.gz

#echo ""
#echo "Creating combined frontal lobe gray matter mask with subcortical structures included"
#echo ""		


	#Combine structures together (with no overlap) to create Frontal Lobar Mask with subcortical frontal structures included
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_GM_Mask_Plus_SubC.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_GM.nii.gz    		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM.nii.gz	\
			SubC_Mask_Orig/${Subj}_freesurfer_L_Caudate.nii.gz			\
			SubC_Mask_Orig/${Subj}_freesurfer_R_Caudate.nii.gz			\
			SubC_Mask_Orig/${Subj}_freesurfer_L_Putamen.nii.gz			\
			SubC_Mask_Orig/${Subj}_freesurfer_R_Putamen.nii.gz			\
			SubC_Mask_Orig/${Subj}_freesurfer_L_Pallidum.nii.gz			\
			SubC_Mask_Orig/${Subj}_freesurfer_R_Pallidum.nii.gz			\
			SubC_Mask_Orig/${Subj}_freesurfer_L_Accumbens_area.nii.gz		\
			SubC_Mask_Orig/${Subj}_freesurfer_R_Accumbens_area.nii.gz

#echo ""
#echo "Creating left/right hemisphere DLPFC gray matter masks"
#echo ""	
	
	#Create DLPFC
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_DLPFC.nii.gz	\
		Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_GM.nii.gz    	\
		Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_GM.nii.gz	

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_DLPFC.nii.gz	\
		Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_GM.nii.gz    	\
		Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_GM.nii.gz	


echo ""
echo "Creating frontal lobe white matter masks"
echo ""	

	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3027.9 -uthr 3028.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4027.9 -uthr 4028.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3026.9 -uthr 3027.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4026.9 -uthr 4027.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3002.9 -uthr 3003.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4002.9 -uthr 4003.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3017.9 -uthr 3018.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4017.9 -uthr 4018.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3019.9 -uthr 3020.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4019.9 -uthr 4020.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3018.9 -uthr 3019.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4018.9 -uthr 4019.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3011.9 -uthr 3012.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4011.9 -uthr 4012.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3013.9 -uthr 3014.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4013.9 -uthr 4014.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3023.9 -uthr 3024.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4023.9 -uthr 4024.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3016.9 -uthr 3017.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Paracentral_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4016.9 -uthr 4017.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Paracentral_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3031.9 -uthr 3032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4031.9 -uthr 4032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3031.9 -uthr 3032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4031.9 -uthr 4032.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3025.9 -uthr 3026.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4025.9 -uthr 4026.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3001.9 -uthr 3002.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4001.9 -uthr 4002.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM.nii.gz
			
	#Combine structures together (with no overlap) to create Frontal Lobar WM Mask	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_WM.nii.gz    		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM.nii.gz	

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_Frontal_Lobar_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_WM_Mask.nii.gz	    	\
			Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_GM_Mask.nii.gz





	#Combine structures together (with no overlap) to create Left Frontal Lobar WM Mask
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Frontal_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_WM.nii.gz    	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM.nii.gz
			


	#Combine structures together (with no overlap) to create right Frontal Lobar WM Mask
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Frontal_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM.nii.gz


#echo ""
#echo "Creating left/right hemisphere DLPFC white matter masks"
#echo ""	
	
	#Create DLPFC
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_DLPFC_WM.nii.gz	\
		Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_WM.nii.gz    	\
		Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_WM.nii.gz	

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_DLPFC_WM.nii.gz	\
		Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_WM.nii.gz    	\
		Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_WM.nii.gz	


#Parietal Lobe

echo ""
echo "Creating parietal lobe gray matter masks"
echo ""	
	
	#GM	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1028.9 -uthr 1029.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2028.9 -uthr 2029.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1007.9 -uthr 1008.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2007.9 -uthr 2008.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1030.9 -uthr 1031.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2030.9 -uthr 2031.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1021.9 -uthr 1022.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2021.9 -uthr 2022.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1024.9 -uthr 1025.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2024.9 -uthr 2025.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1022.9 -uthr 1023.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2022.9 -uthr 2023.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1009.9 -uthr 1010.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2009.9 -uthr 2010.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_GM.nii.gz
	

	#Combine structures together (with no overlap) to create Parietal Lobar Mask	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Parietal_GM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_GM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_GM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_GM.nii.gz



	#Combine structures together (with no overlap) to create left Parietal Lobar Mask	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Parietal_GM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_GM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_GM.nii.gz \
				Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_GM.nii.gz



	#Combine structures together (with no overlap) to create right Parietal Lobar Mask	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Parietal_GM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_GM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_GM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_GM.nii.gz \
				Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_GM.nii.gz



echo ""
echo "Creating parietal lobe white matter masks"
echo ""	
	

	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3028.9 -uthr 3029.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4028.9 -uthr 4029.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3007.9 -uthr 3008.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4007.9 -uthr 4008.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3030.9 -uthr 3031.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4030.9 -uthr 4031.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3021.9 -uthr 3022.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4021.9 -uthr 4022.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3024.9 -uthr 3025.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4024.9 -uthr 4025.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3022.9 -uthr 3023.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4022.9 -uthr 4023.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3009.9 -uthr 3010.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4009.9 -uthr 4010.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_WM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Parietal_WM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_WM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_WM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_WM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_WM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_WM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_Parietal_Lobar_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_LR_Parietal_WM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_LR_Parietal_GM_Mask.nii.gz



	#Combine structures together (with no overlap) to create left Parietal Lobar WM Mask	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Parietal_WM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_WM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_WM.nii.gz \
				Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_WM.nii.gz


	#Combine structures together (with no overlap) to create right Parietal Lobar WM Mask	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Parietal_WM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_WM.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_WM.nii.gz		\
				Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_WM.nii.gz \
				Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_WM.nii.gz


#Temporal Lobe
	
echo ""
echo "Creating temporal lobe gray matter masks"
echo ""		


	#GM	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1029.9 -uthr 1030.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2029.9 -uthr 2030.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1014.9 -uthr 1015.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2014.9 -uthr 2015.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1008.9 -uthr 1009.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2008.9 -uthr 2009.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1000.9 -uthr 1001.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2000.9 -uthr 2001.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1006.9 -uthr 1007.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2006.9 -uthr 2007.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1033.9 -uthr 1034.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2033.9 -uthr 2034.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1005.9 -uthr 1006.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2005.9 -uthr 2006.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1032.9 -uthr 1033.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2032.9 -uthr 2033.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1015.9 -uthr 1016.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2015.9 -uthr 2016.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_GM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_GM.nii.gz

#echo ""
#echo "Creating overall temporal lobe gray matter mask with subcortical structures included"
#echo ""	


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_GM_Mask_Plus_SubC.nii.gz \
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_GM.nii.gz		\
			SubC_Mask_Orig/${Subj}_freesurfer_L_Hipp.nii.gz				\
			SubC_Mask_Orig/${Subj}_freesurfer_R_Hipp.nii.gz			



	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Temporal_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_GM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Temporal_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_GM.nii.gz


echo ""
echo "Creating temporal lobe white matter masks"
echo ""	
		

	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3029.9 -uthr 3030.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4029.9 -uthr 4030.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3014.9 -uthr 3015.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4014.9 -uthr 4015.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3008.9 -uthr 3009.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4008.9 -uthr 4009.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3000.9 -uthr 3001.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4000.9 -uthr 4001.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3006.9 -uthr 3007.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4006.9 -uthr 4007.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3033.9 -uthr 3034.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4033.9 -uthr 4034.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3005.9 -uthr 3006.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4005.9 -uthr 4006.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3032.9 -uthr 3033.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4032.9 -uthr 4033.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3015.9 -uthr 3016.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4015.9 -uthr 4016.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_WM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_WM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_Temporal_Lobar_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_GM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_WM_Mask.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Temporal_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_GM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_WM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Temporal_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_WM.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_WM.nii.gz
	
echo ""
echo "Creating occipital lobe gray matter masks"
echo ""	

	#Occipital Lobe
	#GM	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1010.9 -uthr 1011.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2010.9 -uthr 2011.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1012.9 -uthr 1013.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2012.9 -uthr 2013.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1004.9 -uthr 1005.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2004.9 -uthr 2005.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_GM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1020.9 -uthr 1021.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2020.9 -uthr 2021.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_GM.nii.gz

	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Occipital_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_GM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Occipital_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_GM.nii.gz
			


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Occipital_GM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_GM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_GM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_GM.nii.gz


echo ""
echo "Creating occipital lobe white matter masks"
echo ""		


	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3010.9 -uthr 3011.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4010.9 -uthr 4011.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3012.9 -uthr 3013.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4012.9 -uthr 4013.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3004.9 -uthr 3005.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4004.9 -uthr 4005.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3020.9 -uthr 3021.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4020.9 -uthr 4021.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_WM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_LR_Occipital_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_WM.nii.gz


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_Occipital_Lobar_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_LR_Occipital_WM_Mask.nii.gz	\
				Cort_Mask_Orig/${Subj}_freesurfer_LR_Occipital_GM_Mask.nii.gz




	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_L_Occipital_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_WM.nii.gz
			


	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix Cort_Mask_Orig/${Subj}_freesurfer_R_Occipital_WM_Mask.nii.gz	\
			Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_WM.nii.gz		\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_WM.nii.gz			\
			Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_WM.nii.gz


	#Unsegmented white matter
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 5000.9 -uthr 5001.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Unseg_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 5001.9 -uthr 5002.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Unseg_WM.nii.gz
	
echo ""
echo "Creating insular cortex gray matter mask"
echo ""		


	#insular cortex GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 1034.9 -uthr 1035.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Insula_GM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_DKTatlas.nii.gz -thr 2034.9 -uthr 2035.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Insula_GM.nii.gz

echo ""
echo "Creating insular cortex white matter mask"
echo ""	


	#insular cortex WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 3034.9 -uthr 3035.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_L_Insula_WM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslmaths ${Subj}_freesurfer_aseg_WM.nii.gz -thr 4034.9 -uthr 4035.1 -bin Cort_Mask_Orig/${Subj}_freesurfer_R_Insula_WM.nii.gz

echo ""	
echo "---------------------------------------------------------------"	
echo "02_Create_QSM_Masks.sh script finished running succesfully on `date`"
echo "---------------------------------------------------------------"
echo ""	


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
