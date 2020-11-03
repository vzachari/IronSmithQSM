#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 09/9/2020
#
# Script erodes aligned and rescaled freesurfer QSM masks by one voxel
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

#Passed varialbes to 04_MNI_NL_WarpQSM.sh 
#1) Subject
#2) Output folder
#3) Path

#Subj="S0030"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"
#Path="/home/data3/vzachari/QSM_Toolkit/QSM_Std_Scripts"

Subj=$1
OutFolder=$2
Path=$3

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.04.Erode.QSM.Masks.txt")
exec &> >(tee -a "$log_file")

#Font Name: Modular
echo ""
echo "---------------------------------------------------------------"
echo " _______  _______  __   __       "                                                             
echo "|       ||       ||  |_|  |      "                                                            
echo "|   _   ||  _____||       |      "                                                            
echo "|  | |  || |_____ |       |      "                                                            
echo "|  |_|  ||_____  ||       |      "                                                            
echo "|      |  _____| || ||_|| |      "                                                            
echo "|____||_||_______||_|   |_|      "                                                            
echo " _______  ______    _______  ______   _______    __   __  _______  _______  ___   _  _______ "
echo "|       ||    _ |  |       ||      | |       |  |  |_|  ||   _   ||       ||   | | ||       |"
echo "|    ___||   | ||  |   _   ||  _    ||    ___|  |       ||  |_|  ||  _____||   |_| ||  _____|"
echo "|   |___ |   |_||_ |  | |  || | |   ||   |___   |       ||       || |_____ |      _|| |_____ "
echo "|    ___||    __  ||  |_|  || |_|   ||    ___|  |       ||       ||_____  ||     |_ |_____  |"
echo "|   |___ |   |  | ||       ||       ||   |___   | ||_|| ||   _   | _____| ||    _  | _____| |"
echo "|_______||___|  |_||_______||______| |_______|  |_|   |_||__| |__||_______||___| |_||_______|"
echo ""
echo "---------------------------------------------------------------"


echo ""
echo "---------------------------------------------------------------"	
echo "*** Eroding aligned and resampled freesurfer QSM masks by one voxel... ***"
echo "---------------------------------------------------------------"	
echo ""


cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/
mkdir SubC_Mask_AL_QSM_RS_Erx1
mkdir Cort_Mask_AL_QSM_RS_Erx1

cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS


#Erodes the pallidum (this includes both the ventral pallidum and the globus pallidus	
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Pallidum_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Pallidum_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz -dilate_input -1
	
#Erodes the Putamen
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Putamen_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Putamen_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Putamen_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

#Erodes the Caudate	
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Caudate_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Caudate_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Caudate_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz -dilate_input -1


#Erodes the Area Accumbens
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

#Erodes the Amygdala
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Amygdala_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Amygdala_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz -dilate_input -1


#Erodes the Thalamus
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

#Erodes the Hippocampus
singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_Hipp_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_L_Hipp_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_R_Hipp_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

#Erodes the Lateral Ventricles Mask

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		3dcalc -a ${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS.nii.gz -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
	 	-expr 'a*(1-amongst(0,b,c,d,e,f,g))' -prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx1.nii.gz

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		3dcalc -a ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx1.nii.gz -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
	 	-expr 'a*(1-amongst(0,b,c,d,e,f,g))' -prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx2.nii.gz

#Erodes the white matter mask

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS_Erx1.nii.gz -dilate_input -1

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg 3dmask_tool -input ${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS.nii.gz \
	-prefix ../SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS_Erx2.nii.gz -dilate_input -2



cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS/


# Erodes the frontal lobe	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

	#Left frontal lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

	#Right frontal lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Frontal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

	
# Erodes the parietal lobe	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz


	#Left parietal lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

	#Right parietal lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz

	#Left Angular Gyrus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_AngularGyrus_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_AngularGyrus_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_AngularGyrus_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_AngularGyrus_GM_AL_QSM_RS_Erx1.nii.gz

	#Right Angular Gyrus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_AngularGyrus_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Parietal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_AngularGyrus_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_AngularGyrus_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_AngularGyrus_GM_AL_QSM_RS_Erx1.nii.gz
	

# Erodes the Occipital lobe	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz

	#Left occipital lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

	#Right occipital lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Occipital_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

# Erodes the temporal lobe	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz

	#Left temporal lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz	

	#Right temporal lobe
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_LR_Temporal_WM_Mask_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz	


# Erodes CaudalAnteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	#Left CaudalAnteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_CaudalAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz	

	#right CaudalAnteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_CaudalAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes BanksSTS
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_BanksSTS_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_BanksSTS_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_BanksSTS_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_BanksSTS_WM_AL_QSM_RS_Dilated.nii.gz

	#Left BanksSTS
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_BanksSTS_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz	

	#right BanksSTS
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_BanksSTS_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes DLPFC
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_DLPFC_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_DLPFC_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_DLPFC_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_DLPFC_WM_AL_QSM_RS_Dilated.nii.gz

	#Left DLPFC
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_DLPFC_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz	

	#right DLPFC
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_DLPFC_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz	

	
# Erodes Fusiform gyrus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Fusiform_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Fusiform_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Fusiform_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Fusiform_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Fusiform
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Fusiform_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Fusiform
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Fusiform_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes InferiorParietal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_InferiorParietal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_InferiorParietal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_InferiorParietal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_InferiorParietal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left InferiorParietal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_InferiorParietal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right InferiorParietal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_InferiorParietal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz



# Erodes InferiorTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_InferiorTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_InferiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_InferiorTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_InferiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left InferiorTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_InferiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right InferiorTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_InferiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes LateralOccipital
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_LateralOccipital_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_LateralOccipital_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_LateralOccipital_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_LateralOccipital_WM_AL_QSM_RS_Dilated.nii.gz

	#Left LateralOccipital
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_LateralOccipital_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz	

	#right LateralOccipital
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_LateralOccipital_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes LateralOrbitofrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_LateralOrbitofrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_LateralOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_LateralOrbitofrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_LateralOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left LateralOrbitofrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_LateralOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right LateralOrbitofrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_LateralOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes Lingual
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Lingual_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Lingual_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Lingual_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Lingual_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Lingual
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Lingual_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Lingual
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Lingual_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes MedialOrbitofrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_MedialOrbitofrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_MedialOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_MedialOrbitofrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_MedialOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left MedialOrbitofrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_MedialOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right MedialOrbitofrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_MedialOrbitofrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes MiddleTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_MiddleTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_MiddleTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_MiddleTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_MiddleTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left MiddleTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_MiddleTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right MiddleTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_MiddleTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes Parahippocampal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Parahippocampal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Parahippocampal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Parahippocampal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Parahippocampal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Parahippocampal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Parahippocampal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Parahippocampal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Parahippocampal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes Pericalcarine
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Pericalcarine_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Pericalcarine_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Pericalcarine_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Pericalcarine_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Pericalcarine
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Pericalcarine_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Pericalcarine
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Pericalcarine_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes Postcentral
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Postcentral_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Postcentral_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Postcentral_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Postcentral_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Postcentral
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Postcentral_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Postcentral
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Postcentral_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes PosteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_PosteriorCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_PosteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_PosteriorCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_PosteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	#Left PosteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_PosteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz	

	#right PosteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_PosteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes Precentral
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Precentral_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Precentral_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Precentral_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Precentral_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Precentral
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Precentral_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Precentral
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Precentral_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz

# Erodes Precuneus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Precuneus_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Precuneus_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Precuneus_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Precuneus_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Precuneus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Precuneus_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Precuneus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Precuneus_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes RostalMiddleFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_RostalMiddleFrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_RostalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_RostalMiddleFrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_RostalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left RostalMiddleFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_RostalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right RostalMiddleFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_RostalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes RostralAnteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_RostralAnteriorCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_RostralAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_RostralAnteriorCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_RostralAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	#Left RostralAnteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_RostralAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz	

	#right RostralAnteriorCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_RostralAnteriorCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes SuperiorFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorFrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_SuperiorFrontal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorFrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_SuperiorFrontal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left SuperiorFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_SuperiorFrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right SuperiorFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_SuperiorFrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes SuperiorParietal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorParietal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_SuperiorParietal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorParietal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_SuperiorParietal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left SuperiorParietal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_SuperiorParietal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right SuperiorParietal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_SuperiorParietal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz	


# Erodes SuperiorTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_SuperiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_SuperiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left SuperiorTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_SuperiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right SuperiorTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_SuperiorTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes Insula
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Insula_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Insula_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Insula_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Insula_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Insula
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Insula_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Insula
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Insula_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz

# Erodes CaudalMiddleFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_CaudalMiddleFrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_CaudalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_CaudalMiddleFrontal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_CaudalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left CaudalMiddleFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_CaudalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right CaudalMiddleFrontal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_CaudalMiddleFrontal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz	

# Erodes Cuneus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Cuneus_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Cuneus_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Cuneus_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Cuneus_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Cuneus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Cuneus_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Cuneus
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Cuneus_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes Entorhinal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Entorhinal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_Entorhinal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Entorhinal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_Entorhinal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left Entorhinal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_Entorhinal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right Entorhinal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_Entorhinal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes TransverseTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_TransverseTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_TransverseTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_TransverseTemporal_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_TransverseTemporal_WM_AL_QSM_RS_Dilated.nii.gz

	#Left TransverseTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_TransverseTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz	

	#right TransverseTemporal
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_TransverseTemporal_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz


# Erodes IsthmusCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_IsthmusCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_L_IsthmusCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_IsthmusCingulate_WM_AL_QSM_RS.nii.gz \
		-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'\
		-prefix ${Subj}_freesurfer_R_IsthmusCingulate_WM_AL_QSM_RS_Dilated.nii.gz

	#Left IsthmusCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_L_IsthmusCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz	

	#right IsthmusCingulate
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS.nii.gz -b \
		${Subj}_freesurfer_R_IsthmusCingulate_WM_AL_QSM_RS_Dilated.nii.gz \
		-expr a-b -prefix ${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Step1.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/Cort_Mask_AL_QSM_RS $Path/Functions/QSM_Container.simg 3dcalc -a ${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Step1.nii.gz \
		-expr 'equals(a,1)' -prefix ${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz												
	
mv *Dilated.nii.gz ../Cort_Mask_AL_QSM_RS_Erx1
mv *Step1.nii.gz ../Cort_Mask_AL_QSM_RS_Erx1
mv *Erx1.nii.gz ../Cort_Mask_AL_QSM_RS_Erx1

					
echo ""	
echo "---------------------------------------------------------------"	
echo "04_Erode_QSM_Masks.sh script finished running succesfully on `date`"
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
