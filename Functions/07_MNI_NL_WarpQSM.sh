#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 09/9/2020
#
# Script non-linearly warps anatomical data and QSM maps to the MNI152 1mm template
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

#Passed varialbes to 07_MNI_NL_WarpQSM.sh 
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

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.07.MNI.NL.Warp.QSM.txt")
exec &> >(tee -a "$log_file")

echo ""
echo "---------------------------------------------------------------"
echo " _______  _______  __   __                							"                   
echo "|       ||       ||  |_|  |    ___________________        ____....-----....____              	"                  
echo "|   _   ||  _____||       |   (________________LL_)   ==============================              "                   
echo "|  | |  || |_____ |       |       ______\   \_______.--'.  '---..._____...---'              	"                   
echo "|  |_|  ||_____  ||       |       '-------..__            ' ,/              			"                   
echo "|      |  _____| || ||_|| |                   '-._ -  -  - |              			"                   
echo "|____||_||_______||_|   |_|                       '-------'              				"                   
echo " __   __  __    _  ___     _     _  _______  ______    _______ "
echo "|  |_|  ||  |  | ||   |   | | _ | ||   _   ||    _ |  |       |"
echo "|       ||   |_| ||   |   | || || ||  |_|  ||   | ||  |    _  |"
echo "|       ||       ||   |   |       ||       ||   |_||_ |   |_| |"
echo "|       ||  _    ||   |   |       ||       ||    __  ||    ___|"
echo "| ||_|| || | |   ||   |   |   _   ||   _   ||   |  | ||   |    "
echo "|_|   |_||_|  |__||___|   |__| |__||__| |__||___|  |_||___|    "
echo ""
echo "---------------------------------------------------------------"

echo ""
echo "Non-linear warp of QSM Map/Maps to MNI space using the FSL MNI152 1 mm Template:"
echo ""
echo "MNI outputs will be placed in $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM"
echo ""
echo "This script is useful for:" 
echo ""
echo "1) Voxelwise QSM analyses" 
echo "2) For aligning your own MNI ROIs and/or masks on the QSM Maps" 
echo ""
echo "Example code for aligning a mask in MNI space to the QSM Maps."
echo ""
echo "		#Your mask in MNI space needs to be in $Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM"
echo "		singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM \ "
echo "			$Path/Functions/QSM_Container.simg \ "
echo "			3dNwarpApply -source YOUR_MASK_IN_MNI_GOES_HERE.nii.gz \ "
echo "			  -master ${Subj}_freesurfer_brain_AL_Mag_MNI152+tlrc \ "
echo "			  -ainterp NN -iwarp -nwarp "anat.un.aff.qw_WARP.nii anat.un.aff.Xat.1D" \ "
echo "			  -prefix NAME_FOR_YOUR_MASK_IN_NATIVE_SPACE_GOES_HERE.nii.gz"
echo ""
echo "---------------------------------------------------------------"	

if [[ $MEDIFlag == "MEDI_Yes" ]]; then

	cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

	if [ ! -f "${Subj}_QSM_Map_FSL.nii.gz" ] || [ ! -f "${Subj}_QSM_Map_New_CSF_FSL.nii.gz" ] || [ ! -f "${Subj}_QSM_Map_New_WM_FSL.nii.gz" ]; then
	
		echo -e "\e[31m----------------------------------------------"	
		echo "ERROR: Required files missing:"
		echo "`ls ${Subj}_QSM_Map_FSL.nii.gz`"
		echo "`ls ${Subj}_QSM_Map_New_CSF_FSL.nii.gz`"
		echo "`ls ${Subj}_QSM_Map_New_WM_FSL.nii.gz`"
		echo -e "----------------------------------------------\e[0m"	
		exit 5
	fi

	mkdir MNI152_QSM
	cd MNI152_QSM

	echo ""
	echo "Warping ${Subj}_freesurfer_brain_AL_Mag+orig to MNI152_T1_1mm" 
	echo ""	

	#Warp the Mag-aligned freesurfer brain to standard space (non-linear warp)

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		python3 /opt/afni-latest/auto_warp.py -base /opt/fsl-6.0.1/data/standard/MNI152_T1_1mm_brain.nii.gz -input ../${Subj}_freesurfer_brain_AL_Mag+orig \
	        -skull_strip_input no

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM $Path/Functions/QSM_Container.simg \
		3dbucket -prefix ${Subj}_freesurfer_brain_AL_Mag_MNI152 awpy/${Subj}_freesurfer_brain_AL_Mag.aw.nii*

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM $Path/Functions/QSM_Container.simg \
		3dbucket -prefix ${Subj}_freesurfer_brain_AL_Mag_MNI152.nii.gz awpy/${Subj}_freesurfer_brain_AL_Mag.aw.nii*
	
	mv awpy/anat.un.aff.Xat.1D .
	mv awpy/anat.un.aff.qw_WARP.nii .

	echo ""
	echo "Warping ${Subj}_QSM_Map_FSL.nii.gz to MNI152_T1_1mm" 
	echo ""	

	#Warp the Mag and QSM map images to standard space (non-linear warp) using the matrices from the previous step
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		3dNwarpApply -source ../${Subj}_QSM_Map_FSL.nii.gz	     			\
        	     -master ${Subj}_freesurfer_brain_AL_Mag_MNI152+tlrc                   	\
        	     -ainterp wsinc5 -nwarp "anat.un.aff.qw_WARP.nii anat.un.aff.Xat.1D"	\
        	     -prefix ${Subj}_QSM_Map_FSL_MNI152.nii.gz
	
	echo ""
	echo "Warping ${Subj}_QSM_Map_New_CSF_FSL.nii.gz to MNI152_T1_1mm" 
	echo ""	
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		3dNwarpApply -source ../${Subj}_QSM_Map_New_CSF_FSL.nii.gz		     	\
        	     -master ${Subj}_freesurfer_brain_AL_Mag_MNI152+tlrc                   	\
        	     -ainterp wsinc5 -nwarp "anat.un.aff.qw_WARP.nii anat.un.aff.Xat.1D"	\
        	     -prefix ${Subj}_QSM_Map_New_CSF_FSL_MNI152.nii.gz

	echo ""
	echo "Warping ${Subj}_QSM_Map_New_WM_FSL.nii.gz to MNI152_T1_1mm" 
	echo ""		

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		3dNwarpApply -source ../${Subj}_QSM_Map_New_WM_FSL.nii.gz		     	\
        	     -master ${Subj}_freesurfer_brain_AL_Mag_MNI152+tlrc                   	\
        	     -ainterp wsinc5 -nwarp "anat.un.aff.qw_WARP.nii anat.un.aff.Xat.1D"	\
        	     -prefix ${Subj}_QSM_Map_New_WM_FSL_MNI152.nii.gz

elif [[ $MEDIFlag == "MEDI_No" ]]; then

	cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

	if [ ! -f "${Subj}_QSM_Map_FSL.nii.gz" ]; then
	
		echo -e "\e[31m----------------------------------------------"	
		echo "ERROR: Required file ${Subj}_QSM_Map_FSL.nii.gz is missing! "
		echo -e "----------------------------------------------\e[0m"	
		exit 5
	fi


	mkdir MNI152_QSM
	cd MNI152_QSM

	echo ""
	echo "Warping ${Subj}_freesurfer_brain_AL_Mag+orig to MNI152_T1_1mm" 
	echo ""		

	#Warp the Mag-aligned freesurfer brain to standard space (non-linear warp)

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		python3 /opt/afni-latest/auto_warp.py -base /opt/fsl-6.0.1/data/standard/MNI152_T1_1mm_brain.nii.gz -input ../${Subj}_freesurfer_brain_AL_Mag+orig \
	        -skull_strip_input no

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM $Path/Functions/QSM_Container.simg \
		3dbucket -prefix ${Subj}_freesurfer_brain_AL_Mag_MNI152 awpy/${Subj}_freesurfer_brain_AL_Mag.aw.nii*

	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/MNI152_QSM $Path/Functions/QSM_Container.simg \
		3dbucket -prefix ${Subj}_freesurfer_brain_AL_Mag_MNI152.nii.gz awpy/${Subj}_freesurfer_brain_AL_Mag.aw.nii*
	
	mv awpy/anat.un.aff.Xat.1D .
	mv awpy/anat.un.aff.qw_WARP.nii .

	echo ""
	echo "Warping ${Subj}_QSM_Map_FSL.nii.gz to MNI152_T1_1mm" 
	echo ""		

	#Warp the Mag and QSM map images to standard space (non-linear warp) using the matrices from the previous step
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		3dNwarpApply -source ../${Subj}_QSM_Map_FSL.nii.gz	     			\
        	     -master ${Subj}_freesurfer_brain_AL_Mag_MNI152+tlrc                   	\
        	     -ainterp wsinc5 -nwarp "anat.un.aff.qw_WARP.nii anat.un.aff.Xat.1D"	\
        	     -prefix ${Subj}_QSM_Map_FSL_MNI152.nii.gz

else

	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo 'ERROR: MEDI Flag not set properly!'
	echo -e "----------------------------------------------\e[0m"
	echo ""		
	exit 5

fi


echo ""	
echo "---------------------------------------------------------------"	
echo "07_MNI_NL_WarpQSM.sh script finished running succesfully on `date`"
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
