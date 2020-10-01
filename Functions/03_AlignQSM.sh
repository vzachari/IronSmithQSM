#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 08/24/2020
#
# Script aligns QSM masks to MAG image
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

#Passed varialbes to 03_Align_QSM.sh 
#1) Suject
#2) Output Folder
#3) Path
#4) QSM File
#5) QSM Mag
#6) MEDI Flag

#Subj="S0030"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/QSM_Test_Run"
#Path="/home/data3/vzachari/QSM_Toolkit/QSM_Std_Scripts"
#QSMFile="/home/data3/vzachari/QSM_Toolkit/S0030/QSM/QSM_Final_Map_New_CSF/S0030_QSM_Final_Map_New_CSF.nii.gz"
#MAG="/home/data3/vzachari/QSM_Toolkit/S0030/QSM/QSM_nii/20190218_142131UKYT2QSMUSCs010a1001.nii.gz"
#MEDIFlag="MEDI_No"

Subj=$1
OutFolder=$2
Path=$3
QSMFile=$4
MAG=$5
MEDIFlag=$6

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.03.Align.QSM.txt")
exec &> >(tee -a "$log_file")

#Font Name: Modular
echo ""
echo "---------------------------------------------------------------"
echo " _______  _______  __   __         "                                                      
echo "|       ||       ||  |_|  |        "                                                      
echo "|   _   ||  _____||       |        "                                                      
echo "|  | |  || |_____ |       |        "                                                      
echo "|  |_|  ||_____  ||       |        "                                                      
echo "|      |  _____| || ||_|| |        "                                                      
echo "|____||_||_______||_|   |_|        "                                                      
echo " _______  ___      ___   _______  __    _    __   __  _______  _______  ___   _  _______ "
echo "|   _   ||   |    |   | |       ||  |  | |  |  |_|  ||   _   ||       ||   | | ||       |"
echo "|  |_|  ||   |    |   | |    ___||   |_| |  |       ||  |_|  ||  _____||   |_| ||  _____|"
echo "|       ||   |    |   | |   | __ |       |  |       ||       || |_____ |      _|| |_____ "
echo "|       ||   |___ |   | |   ||  ||  _    |  |       ||       ||_____  ||     |_ |_____  |"
echo "|   _   ||       ||   | |   |_| || | |   |  | ||_|| ||   _   | _____| ||    _  | _____| |"
echo "|__| |__||_______||___| |_______||_|  |__|  |_|   |_||__| |__||_______||___| |_||_______|"
echo ""
echo "---------------------------------------------------------------"
echo ""

echo ""
echo "---------------------------------------------------------------"	
echo "*** Aligning freesurfer cortical/subcortical masks to QSM MAP ***"
echo "---------------------------------------------------------------"	
echo ""

cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

#Create directories for aligned and rescaled ROIs/Masks
mkdir Cort_Mask_AL_QSM
mkdir Cort_Mask_AL_QSM_RS	
mkdir SubC_Mask_AL_QSM
mkdir SubC_Mask_AL_QSM_RS

echo ""
echo "Copying/moving QSM Map and QSM MAGNITUDE to $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks"
echo ""

if [[ $MEDIFlag == "MEDI_Yes" ]]; then

	#Moves QSM_Final_Map and Mag images to FreeSurf_QSM_Masks directory	
	cp $QSMFile .
	cp $MAG .

elif [[ $MEDIFlag == "MEDI_No" ]]; then

	#Moves QSM_Final_Map and Mag images to Masks directory	
	cp $QSMFile ${Subj}_QSM_Map.nii.gz
	cp $MAG ${Subj}_QSM_Mag.nii.gz
fi

echo ""	
echo "Re-orienting QSM Map and QSM MAGNITUDE to FSL standard view"
echo ""

#Re-orients QSM_Map and QSM_Mag image to FSL standard view
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslreorient2std ${Subj}_QSM_Map.nii.gz ${Subj}_QSM_Map_FSL.nii.gz
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg fslreorient2std ${Subj}_QSM_Mag.nii.gz ${Subj}_QSM_Mag_FSL.nii.gz

echo ""	
echo "Aligning freesurfer skull-stripped brain to QSM MAGNITUDE image"
echo ""

#Aligns the freesurfer skull-stripped brain to the QSM Magnitude image
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	python3 /opt/afni-latest/align_epi_anat.py -dset1 ${Subj}_freesurfer_brain.nii.gz -dset1_strip None -dset2 ${Subj}_QSM_Mag_FSL.nii.gz \
	-dset2_strip None -dset1to2 -cost lpa -feature_size 0.5 -prep_off -big_move -suffix _AL_Mag

#Creates a .nii.gz variant of the Mag-aligned T1 so that FSL can view it	
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAFNItoNIFTI ${Subj}_freesurfer_brain_AL_Mag+orig -prefix ${Subj}_freesurfer_brain_AL_Mag.nii
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg gzip ${Subj}_freesurfer_brain_AL_Mag.nii

echo ""	
echo "Creating whole brain mask of the freesurfer skull-stripped brain at the resolution of the QSM Map"
echo ""	

#Create a whole brain mask for overall QSM
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dAutomask -prefix ${Subj}_freesurfer_brain_AL_Mag_Mask.nii.gz ${Subj}_freesurfer_brain_AL_Mag.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_brain_AL_Mag_Mask_RS.nii.gz \
	-input ${Subj}_freesurfer_brain_AL_Mag_Mask.nii.gz

echo ""	
echo "---------------------------------------------------------------"
echo "*** Aligning all masks to QSM Map... ***"
echo "---------------------------------------------------------------"
echo ""	

	#Alignment of left hemisphere subcortical freesurfer masks to QSM_Final_Map
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_WM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_GM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Lateral_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Lateral_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Inf_Lateral_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Inf_Lateral_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Cerebellum_WM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Cerebellum_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Cerebellum_GM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Cerebellum_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Thalamus.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Thalamus_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Thalamus_Proper.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Caudate.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Caudate_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Putamen.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Putamen_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Pallidum.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Pallidum_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_Third_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_Third_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_Fourth_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_Fourth_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_Fifth_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_Fifth_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_Brain_Stem.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_Brain_Stem_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Hipp.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Hipp_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Amygdala.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Amygdala_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_CSF.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_CSF_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_Accumbens_area.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Accumbens_area_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_VentralDC.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_VentralDC_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_L_WM_Hypointensities.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_L_WM_Hypointensities_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_WM_Hypointensities.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_WM_Hypointensities_AL_QSM.nii.gz

	#Alignment of right hemisphere subcortical freesurfer masks to QSM_Final_Map

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_WM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_GM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Lateral_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Lateral_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Inf_Lateral_Ventricle.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Inf_Lateral_Ventricle_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Cerebellum_WM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Cerebellum_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Cerebellum_GM.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Cerebellum_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Thalamus.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Thalamus_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Thalamus_Proper.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Caudate.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Caudate_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Putamen.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Putamen_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Pallidum.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Pallidum_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Hipp.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Hipp_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Amygdala.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Amygdala_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_Accumbens_area.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Accumbens_area_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_VentralDC.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_VentralDC_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_R_WM_Hypointensities.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_R_WM_Hypointensities_AL_QSM.nii.gz

# Gray matter, white matter and lateral ventricle mask
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_LR_WM_Mask.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_LR_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_LR_GM_Mask.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_LR_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input SubC_Mask_Orig/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask.nii.gz -final NN -prefix SubC_Mask_AL_QSM/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM.nii.gz


#Alignment of cortical masks
	
	#Frontal Lobe GM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_GM.nii.gz  -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOpercularis_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOpercularis_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsTriangularis_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsTriangularis_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOrbitalis_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOrbitalis_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precentral_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precentral_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_FrontalPole_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_FrontalPole_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM.nii.gz

	
	#DLPFC GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_DLPFC.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_DLPFC.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM.nii.gz


	#DLPFC WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_DLPFC_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_DLPFC_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_DLPFC_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_DLPFC_WM_AL_QSM.nii.gz


	#Frontal Lobe WM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorFrontal_WM.nii.gz  -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorFrontal_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorFrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorFrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_RostalMiddleFrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostalMiddleFrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_RostalMiddleFrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostalMiddleFrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOpercularis_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOpercularis_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOpercularis_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOpercularis_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_ParsTriangularis_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsTriangularis_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_ParsTriangularis_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsTriangularis_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_ParsOrbitalis_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOrbitalis_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_ParsOrbitalis_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOrbitalis_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOrbitofrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOrbitofrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOrbitofrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOrbitofrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_MedialOrbitofrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MedialOrbitofrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_MedialOrbitofrontal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MedialOrbitofrontal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Precentral_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precentral_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Precentral_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precentral_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_FrontalPole_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_FrontalPole_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_FrontalPole_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_FrontalPole_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM_AL_QSM.nii.gz

	#Frontal lobar masks

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_GM_Mask_Plus_SubC.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Frontal_GM_Mask_Plus_SubC_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Frontal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM.nii.gz	

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_Frontal_Lobar_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_Frontal_Lobar_Mask_AL_QSM.nii.gz


singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Frontal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Frontal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Frontal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Frontal_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Frontal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Frontal_WM_Mask_AL_QSM.nii.gz



	#Parietal Lobe
	
	#GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Supramarginal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Supramarginal_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM.nii.gz

	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorParietal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorParietal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorParietal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorParietal_WM_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorParietal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorParietal_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorParietal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorParietal_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Supramarginal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Supramarginal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Supramarginal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Supramarginal_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Postcentral_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Postcentral_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Postcentral_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Postcentral_WM_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Precuneus_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precuneus_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Precuneus_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precuneus_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_PosteriorCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_PosteriorCingulate_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_PosteriorCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_PosteriorCingulate_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_IsthmusCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_IsthmusCingulate_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_IsthmusCingulate_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_IsthmusCingulate_WM_AL_QSM.nii.gz

	#Parietal lobar masks
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Parietal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Parietal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_Parietal_Lobar_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_Parietal_Lobar_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Parietal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Parietal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Parietal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parietal_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Parietal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parietal_WM_Mask_AL_QSM.nii.gz




	#Temporal Lobe

	#GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TemporalPole_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TemporalPole_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM.nii.gz
	

	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_SuperiorTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_SuperiorTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_MiddleTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MiddleTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_MiddleTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MiddleTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_InferiorTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_InferiorTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_BanksSTS_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_BanksSTS_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_BanksSTS_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_BanksSTS_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Fusiform_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Fusiform_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Fusiform_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Fusiform_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_TransverseTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TransverseTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_TransverseTemporal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TransverseTemporal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Entorhinal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Entorhinal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Entorhinal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Entorhinal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_TemporalPole_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TemporalPole_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_TemporalPole_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TemporalPole_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Parahippocampal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parahippocampal_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Parahippocampal_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parahippocampal_WM_AL_QSM.nii.gz

	#Temporal lobar masks
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_GM_Mask_Plus_SubC.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Temporal_GM_Mask_Plus_SubC_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Temporal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_Temporal_Lobar_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_Temporal_Lobar_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Temporal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Temporal_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Temporal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Temporal_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Temporal_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Temporal_WM_Mask_AL_QSM.nii.gz

	
	#Occipital Lobe
	
	#GM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Lingual_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Lingual_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM.nii.gz

	#WM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_LateralOccipital_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOccipital_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_LateralOccipital_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOccipital_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Lingual_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Lingual_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Lingual_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Lingual_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Cuneus_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Cuneus_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Cuneus_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Cuneus_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Pericalcarine_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Pericalcarine_WM_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Pericalcarine_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Pericalcarine_WM_AL_QSM.nii.gz

	#Occipital lobar masks

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Occipital_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_LR_Occipital_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM.nii.gz 

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_Occipital_Lobar_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_Occipital_Lobar_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Occipital_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Occipital_GM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Occipital_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Occipital_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Occipital_WM_Mask.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Occipital_WM_Mask_AL_QSM.nii.gz  


# Insular cortex

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Insula_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Insula_GM_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Insula_GM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Insula_GM_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_L_Insula_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Insula_WM_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dAllineate -master ${Subj}_freesurfer_brain_AL_Mag+orig -1Dmatrix_apply ${Subj}_freesurfer_brain_AL_Mag_mat.aff12.1D \
		-input Cort_Mask_Orig/${Subj}_freesurfer_R_Insula_WM.nii.gz -final NN -prefix Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Insula_WM_AL_QSM.nii.gz

	
echo ""
echo "---------------------------------------------------------------"
echo "*** Resampling all masks to QSM Map resolution... ***"
echo "---------------------------------------------------------------"
echo ""	

	#Rescale all ROIs to be ready for stats
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_Brain_Stem_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_Brain_Stem_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_CSF_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_CSF_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_Fifth_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_Fifth_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_Fourth_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_Fourth_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Accumbens_area_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Amygdala_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Caudate_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Caudate_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Cerebellum_GM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Cerebellum_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Cerebellum_WM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Cerebellum_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_GM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Hipp_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Hipp_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Inf_Lateral_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Inf_Lateral_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Lateral_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Lateral_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Pallidum_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Putamen_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Putamen_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Thalamus_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Thalamus_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_VentralDC_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_VentralDC_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_WM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_WM_Hypointensities_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_L_WM_Hypointensities_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Accumbens_area_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Amygdala_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Caudate_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Caudate_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Cerebellum_GM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Cerebellum_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Cerebellum_WM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Cerebellum_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_GM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Hipp_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Hipp_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Inf_Lateral_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Inf_Lateral_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Lateral_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Lateral_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Pallidum_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Putamen_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Putamen_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Thalamus_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Thalamus_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_VentralDC_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_VentralDC_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_WM_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_WM_Hypointensities_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_R_WM_Hypointensities_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_Third_Ventricle_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_Third_Ventricle_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_WM_Hypointensities_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_WM_Hypointensities_AL_QSM.nii.gz

	
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_GM_Mask_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_LR_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_LR_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS.nii.gz -input SubC_Mask_AL_QSM/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM.nii.gz




#Rescale all cortical ROIs for stats
	
	#Frontal Lobe	

	#GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_ParsOpercularis_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOpercularis_GM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_ParsOpercularis_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOpercularis_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_ParsTriangularis_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsTriangularis_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_ParsTriangularis_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsTriangularis_GM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_ParsOrbitalis_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOrbitalis_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_ParsOrbitalis_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOrbitalis_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precentral_GM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precentral_GM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_FrontalPole_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_FrontalPole_GM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_FrontalPole_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_FrontalPole_GM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM.nii.gz

	
	#DLPFC GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM.nii.gz

	#DLPFC WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_DLPFC_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_DLPFC_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_DLPFC_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_DLPFC_WM_AL_QSM.nii.gz	
	
	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_SuperiorFrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorFrontal_WM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_SuperiorFrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorFrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_RostalMiddleFrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostalMiddleFrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_RostalMiddleFrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostalMiddleFrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalMiddleFrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalMiddleFrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_ParsOpercularis_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOpercularis_WM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_ParsOpercularis_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOpercularis_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_ParsTriangularis_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsTriangularis_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_ParsTriangularis_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsTriangularis_WM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_ParsOrbitalis_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_ParsOrbitalis_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_ParsOrbitalis_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_ParsOrbitalis_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_LateralOrbitofrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOrbitofrontal_WM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_LateralOrbitofrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOrbitofrontal_WM_AL_QSM.nii.gz	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_MedialOrbitofrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MedialOrbitofrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_MedialOrbitofrontal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MedialOrbitofrontal_WM_AL_QSM.nii.gz		
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Precentral_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precentral_WM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Precentral_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precentral_WM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_FrontalPole_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_FrontalPole_WM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_FrontalPole_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_FrontalPole_WM_AL_QSM.nii.gz			
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_RostralAnteriorCingulate_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_RostralAnteriorCingulate_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM_AL_QSM.nii.gz


	#Frontal Lobar masks Resample
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Frontal_GM_Mask_Plus_SubC_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Frontal_GM_Mask_Plus_SubC_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_Frontal_Lobar_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_Frontal_Lobar_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Frontal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Frontal_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Frontal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Frontal_WM_Mask_AL_QSM.nii.gz

	#Parietal lobe
	
	#GM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Supramarginal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Supramarginal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Supramarginal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Supramarginal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM.nii.gz

	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_SuperiorParietal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorParietal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_SuperiorParietal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorParietal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_InferiorParietal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorParietal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_InferiorParietal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorParietal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Supramarginal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Supramarginal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Supramarginal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Supramarginal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Postcentral_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Postcentral_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Postcentral_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Postcentral_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Precuneus_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Precuneus_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Precuneus_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Precuneus_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_PosteriorCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_PosteriorCingulate_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_PosteriorCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_PosteriorCingulate_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_IsthmusCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_IsthmusCingulate_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_IsthmusCingulate_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_IsthmusCingulate_WM_AL_QSM.nii.gz

	#Parietal Lobar masks Resample

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_Parietal_Lobar_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_Parietal_Lobar_Mask_AL_QSM.nii.gz


singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Parietal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parietal_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Parietal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parietal_WM_Mask_AL_QSM.nii.gz
	
	#Temporal Lobe
	
	#GM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_TemporalPole_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TemporalPole_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_TemporalPole_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TemporalPole_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM.nii.gz
	
	#WM
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_SuperiorTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_SuperiorTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_SuperiorTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_SuperiorTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_MiddleTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_MiddleTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_MiddleTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_MiddleTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_InferiorTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_InferiorTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_InferiorTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_InferiorTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_BanksSTS_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_BanksSTS_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_BanksSTS_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_BanksSTS_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Fusiform_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Fusiform_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Fusiform_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Fusiform_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_TransverseTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TransverseTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_TransverseTemporal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TransverseTemporal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Entorhinal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Entorhinal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Entorhinal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Entorhinal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_TemporalPole_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_TemporalPole_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_TemporalPole_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_TemporalPole_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Parahippocampal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Parahippocampal_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Parahippocampal_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Parahippocampal_WM_AL_QSM.nii.gz

	#Temporal Lobar masks Resample
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Temporal_GM_Mask_Plus_SubC_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Temporal_GM_Mask_Plus_SubC_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_Temporal_Lobar_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_Temporal_Lobar_Mask_AL_QSM.nii.gz


singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Temporal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Temporal_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Temporal_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Temporal_WM_Mask_AL_QSM.nii.gz

	#Occipital Lobe

	#GM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM.nii.gz
	
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Lingual_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Lingual_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM.nii.gz

	#WM

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_LateralOccipital_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_LateralOccipital_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_LateralOccipital_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_LateralOccipital_WM_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Lingual_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Lingual_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Lingual_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Lingual_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Cuneus_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Cuneus_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Cuneus_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Cuneus_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Pericalcarine_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Pericalcarine_WM_AL_QSM.nii.gz
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Pericalcarine_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Pericalcarine_WM_AL_QSM.nii.gz	

	
	#Occipital Lobar masks Resample
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_Occipital_Lobar_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_Occipital_Lobar_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Occipital_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Occipital_WM_Mask_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Occipital_WM_Mask_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Occipital_WM_Mask_AL_QSM.nii.gz


#Insular Cortex masks resample

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Insula_GM_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Insula_GM_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Insula_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_L_Insula_WM_AL_QSM.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dresample -master ${Subj}_QSM_Map_FSL.nii.gz -prefix Cort_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Insula_WM_AL_QSM_RS.nii.gz -input Cort_Mask_AL_QSM/${Subj}_freesurfer_R_Insula_WM_AL_QSM.nii.gz




echo ""
echo "---------------------------------------------------------------"	
echo "*** Creating bilateral subcortical masks at QSM Map resolution... ***"
echo "---------------------------------------------------------------"
echo ""	

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS.nii.gz		\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Caudate_AL_QSM_RS.nii.gz		\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Caudate_AL_QSM_RS.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Hipp_AL_QSM_RS.nii.gz			\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Hipp_AL_QSM_RS.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS.nii.gz		\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Putamen_AL_QSM_RS.nii.gz			\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Putamen_AL_QSM_RS.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS.nii.gz		\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmerge -gorder -prefix SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS.nii.gz	\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS.nii.gz		\
			SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS.nii.gz



echo ""	
echo "---------------------------------------------------------------"	
echo "03_AlignQSM.sh script finished running succesfully on `date`"
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
