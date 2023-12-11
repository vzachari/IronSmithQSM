#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 05/25/2023
#
#	Copyright (C) 2023 Valentinos Zachariou, University of Kentucky (see LICENSE file for more details)
#
#	Script runs MEDI with eroded WM and lateral ventricles as the QSM reference
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
#4) QSM DICOM Dir
#5) Matlab path
#6) MEDIVer

#Subj="S0031"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/QSM_Test_Run"
#Path="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"
#QSM_Dicom_Dir="/home/data3/vzachari/QSM_Toolkit/S0030/QSM/QSM_Dicom"
#MatPath="Same path as one used in Matlab_Config.txt"
#MEDIVer="This is just a label. It should match the version of MEDI toolbox you have"

#Subj="1301L2"
#OutFolder="/home/data3/vzachari/DaughertyQSM_Help/Iron_Output_Test"
#Path="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"
#QSM_Dicom_Dir="/home/data3/vzachari/DaughertyQSM_Help/Iron_Output_Test/1301L2/QSM/QSM_DICOM"
#MatPath="/usr/local/MATLAB/R2019b/bin/matlab"
#MEDIVer="This is just a label. It should match the version of MEDI toolbox you have"

Subj=$1
OutFolder=$2
Path=$3
QSM_Dicom_Dir=$4
MatPath=$5
MEDIVer=$6

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.MEDI.QSM.New.Ref.txt")
exec &> >(tee -a "$log_file")


#Font Name: Modular
echo ""
echo "---------------------------------------------------------------"
echo " __   __  _______  ______   ___                "          
echo "|  |_|  ||       ||      | |   |               "         
echo "|       ||    ___||  _    ||   |               "        
echo "|       ||   |___ | | |   ||   |               "        
echo "|       ||    ___|| |_|   ||   |               "        
echo "| ||_|| ||   |___ |       ||   |               "        
echo "|_|   |_||_______||______| |___|               "        
echo " __    _  _______  _     _    ______    _______  _______ "
echo "|  |  | ||       || | _ | |  |    _ |  |       ||       |"
echo "|   |_| ||    ___|| || || |  |   | ||  |    ___||    ___|"
echo "|       ||   |___ |       |  |   |_||_ |   |___ |   |___ "
echo "|  _    ||    ___||       |  |    __  ||    ___||    ___|"
echo "| | |   ||   |___ |   _   |  |   |  | ||   |___ |   |    "
echo "|_|  |__||_______||__| |__|  |___|  |_||_______||___|    "
echo ""
echo "MEDI processing with new CSF and WM masks as QSM reference structures"
echo "Using MEDI Toolbox version: $MEDIVer"
echo "http://pre.weill.cornell.edu/mri/pages/qsm.html"
echo ""
echo "For further information, please contact Dr. Yi Wang" 
echo "yiwang@med.cornell.edu"
echo "---------------------------------------------------------------"
echo ""

#Set MEDI Toolbox Path
#MEDIPath=$(echo "`echo $Path | awk -F 'QSM_Std_Scripts' '{print $1}'`MEDI_toolbox")
MEDIPath="$Path/Functions/MEDI_toolbox"

cd $OutFolder/$Subj/QSM

# Check if ${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx2.nii.gz has enough voxels after erosion

echo ""
echo "---------------------------------------------------------------"
echo "Selecting LR_Lateral_Ventricle_Mask erosion level suited for the QSM data provided"
echo "---------------------------------------------------------------"
echo ""

LatVent="$OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS.nii.gz"
LatVentErx1="$OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx1.nii.gz"
LatVentErx2="$OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx2.nii.gz"
WMErx1="$OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS_Erx1.nii.gz"

LatVentCount=$(singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
	3dBrickStat -non-zero -count $LatVent | awk '{$1=$1};1')

LatVentErx1Count=$(singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
	3dBrickStat -non-zero -count $LatVentErx1 | awk '{$1=$1};1')

LatVentErx2Count=$(singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
	3dBrickStat -non-zero -count $LatVentErx2 | awk '{$1=$1};1')

if [ "$LatVentErx2Count" -lt "100" ]; then

	if [ "$LatVentErx1Count" -lt "100" ]; then

		if [ "$LatVentCount" -lt "100" ]; then

			echo ""		
			echo -e "\e[31m----------------------------------------------"
			echo "ERROR: ${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS.nii.gz has too few voxels to be used as the QSM reference! "
			echo "Check $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS" 
			echo "Something might have gone wrong with the FS segmentation"
			echo -e "----------------------------------------------\e[0m"
			echo ""
			exit 5
		else
	
			echo ""	
			echo "${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS.nii.gz" 
			echo "will be used as the QSM reference. The _Erx1 and _Erx2 versions of the mask have too few voxels after erosion"			
			echo ""			
			
			WhatCSFMask=$LatVent

		fi
	else

		echo ""	
		echo "${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx1.nii.gz" 
		echo "will be used as the QSM reference. The _Erx2 version of the mask has too few voxels after erosion"			
		echo ""		
			
		WhatCSFMask=$LatVentErx1

	fi
else

	echo ""	
	echo "${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx2.nii.gz" 
	echo "will be used as the QSM reference"			
	echo ""			
			
	WhatCSFMask=$LatVentErx2

fi


if [ -f "${Subj}_QSM_Map_Obli.nii.gz" ]; then

	echo ""	
	echo "QSM scan appears to be oblique (collected at an angle). Adjusting csf reference masks accordingly"
	echo ""	

	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
		3dWarp -oblique_parent ${Subj}_QSM_Map_Obli.nii.gz -NN -gridset ${Subj}_QSM_Map_Obli.nii.gz -prefix ${Subj}_FS_LatVent_Mask_Obli.nii.gz $WhatCSFMask

	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
		3dWarp -oblique_parent ${Subj}_QSM_Map_Obli.nii.gz -NN -gridset ${Subj}_QSM_Map_Obli.nii.gz -prefix ${Subj}_FS_WM_Mask_Obli.nii.gz $WMErx1

	#singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
		#3dcalc -a ${Subj}_FS_LatVent_Mask_ReObliNB.nii.gz -expr 'step(a)' -prefix ${Subj}_FS_LatVent_Mask_ReObliBin.nii.gz

	#singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
		#3dcalc -a ${Subj}_FS_WM_Mask_ReObliNB.nii.gz -expr 'step(a)' -prefix ${Subj}_FS_WM_Mask_ReObliBin.nii.gz
		
	#singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
		#3dresample -master ${Subj}_QSM_Map_Obli.nii.gz -prefix ${Subj}_FS_LatVent_Mask_Obli.nii.gz -input ${Subj}_FS_LatVent_Mask_ReObliBin.nii.gz

	#singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
		#3dresample -master ${Subj}_QSM_Map_Obli.nii.gz -prefix ${Subj}_FS_WM_Mask_Obli.nii.gz -input ${Subj}_FS_WM_Mask_ReObliBin.nii.gz

	unset WhatCSFMask WMErx1
	WhatCSFMask="$OutFolder/$Subj/QSM/${Subj}_FS_LatVent_Mask_Obli.nii.gz"
	WMErx1="$OutFolder/$Subj/QSM/${Subj}_FS_WM_Mask_Obli.nii.gz"
fi

#Create Custom MEDI pipeline file specific to each participant

echo ""
echo "---------------------------------------------------------------"
echo "Creating new CSF/WM reference MEDI analysis file for ${Subj} --> Subj_${Subj}_MEDI_QSM_New_Ref.m"
echo "in: `pwd`"
echo "---------------------------------------------------------------"
echo ""

echo "% MEDI New Reference CSF/WM QSM Script For $Subj" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "% Script created automatically by MEDI_QSM_New_Ref.sh on `date`" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "clear all" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "run('$MEDIPath/MEDI_set_path.m');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m


echo "DICOM_dir = fullfile('$OutFolder/$Subj/QSM/QSM_DICOM');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_Output_New_CSF = fullfile('$OutFolder/$Subj/QSM/MEDI_Output_New_CSF');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_Output_New_WM = fullfile('$OutFolder/$Subj/QSM/MEDI_Output_New_WM');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "New_CSF_Mask_Dir = fullfile('$OutFolder/$Subj/QSM/QSM_New_Mask_CSF');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "New_WM_Mask_Dir = fullfile('$OutFolder/$Subj/QSM/QSM_New_Mask_WM');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "Mask_CSF_New = niftiread(fullfile('$WhatCSFMask'));" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_WM_New = niftiread(fullfile('$WMErx1'));" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "load('RDF.mat');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "load('files.mat');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "movefile RDF.mat RDF.mat.QSM.Script;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "Mask_CSF_New = double(Mask_CSF_New);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_WM_New = double(Mask_WM_New);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m   

echo "%Find if permute is needed for the CSF/WM masks" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "Affine3DR1=files.Affine3D(1,:);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Affine3DR2=files.Affine3D(2,:);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Affine3DR3=files.Affine3D(3,:);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
     
echo "MatOrder(1)=find(abs(Affine3DR1)>0.92 & abs(Affine3DR1)<=1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "MatOrder(2)=find(abs(Affine3DR2)>0.92 & abs(Affine3DR2)<=1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "MatOrder(3)=find(abs(Affine3DR3)>0.92 & abs(Affine3DR3)<=1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "if MatOrder==[1,2,3]" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Affine3D order is 1 2 3");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("No permute needed");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_CSF_New_Perm=Mask_CSF_New;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_WM_New_Perm=Mask_WM_New;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "elseif MatOrder==[1,3,2]" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Affine3D order is 1 3 2");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute needed");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute order 1, 3, 2");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_CSF_New_Perm=permute(Mask_CSF_New,[1,3,2]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_WM_New_Perm=permute(Mask_WM_New,[1,3,2]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "elseif MatOrder==[2,1,3]" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Affine3D order is 2 1 3");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute needed");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute order 2, 1, 3");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_CSF_New_Perm=permute(Mask_CSF_New,[2,1,3]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_WM_New_Perm=permute(Mask_WM_New,[2,1,3]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "elseif MatOrder==[2,3,1]" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Affine3D order is 2 3 1");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute needed");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute order 3, 1, 2");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_CSF_New_Perm=permute(Mask_CSF_New,[3,1,2]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_WM_New_Perm=permute(Mask_WM_New,[3,1,2]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "elseif MatOrder==[3,1,2]" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Affine3D order is 3 1 2");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute needed");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute order 2, 3, 1");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_CSF_New_Perm=permute(Mask_CSF_New,[2,3,1]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_WM_New_Perm=permute(Mask_WM_New,[2,3,1]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "elseif MatOrder==[3,2,1]" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Affine3D order is 3 2 1");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute needed");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '	disp("Permute order 3, 2, 1");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_CSF_New_Perm=permute(Mask_CSF_New,[3,2,1]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "	Mask_WM_New_Perm=permute(Mask_WM_New,[3,2,1]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "end" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "%Brute Force align" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "AlignTemplate=(Mask_CSF);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "TestAlign(1,1)=sum((AlignTemplate.*Mask_CSF_New_Perm),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(2,1)=sum((AlignTemplate.*(flip(Mask_CSF_New_Perm,1))),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(3,1)=sum((AlignTemplate.*(flip(Mask_CSF_New_Perm,2))),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(4,1)=sum((AlignTemplate.*(flip(Mask_CSF_New_Perm,3))),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(5,1)=sum(AlignTemplate.*(flip(flip(Mask_CSF_New_Perm,1),2)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(6,1)=sum(AlignTemplate.*(flip(flip(Mask_CSF_New_Perm,1),3)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(7,1)=sum(AlignTemplate.*(flip(flip(Mask_CSF_New_Perm,2),1)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(8,1)=sum(AlignTemplate.*(flip(flip(Mask_CSF_New_Perm,2),3)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(9,1)=sum(AlignTemplate.*(flip(flip(Mask_CSF_New_Perm,3),1)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(10,1)=sum(AlignTemplate.*(flip(flip(Mask_CSF_New_Perm,3),2)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(11,1)=sum(AlignTemplate.*(flip((flip(flip(Mask_CSF_New_Perm,1),2)),3)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(12,1)=sum(AlignTemplate.*(flip((flip(flip(Mask_CSF_New_Perm,1),3)),2)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(13,1)=sum(AlignTemplate.*(flip((flip(flip(Mask_CSF_New_Perm,2),1)),3)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(14,1)=sum(AlignTemplate.*(flip((flip(flip(Mask_CSF_New_Perm,2),3)),1)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(15,1)=sum(AlignTemplate.*(flip((flip(flip(Mask_CSF_New_Perm,3),1)),2)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "TestAlign(16,1)=sum(AlignTemplate.*(flip((flip(flip(Mask_CSF_New_Perm,3),2)),1)),'all');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "MaxAlign=find(TestAlign==max(TestAlign));" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "switch MaxAlign(1)" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 1" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("No Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=Mask_CSF_New_Perm;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=Mask_WM_New_Perm;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 2" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 1 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(Mask_CSF_New_Perm,1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(Mask_WM_New_Perm,1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 3" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 2 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(Mask_CSF_New_Perm,2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(Mask_WM_New_Perm,2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 4" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 3 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(Mask_CSF_New_Perm,3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(Mask_WM_New_Perm,3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 5" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 1,2 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(flip(Mask_CSF_New_Perm,1),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(flip(Mask_WM_New_Perm,1),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 6" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 1,3 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(flip(Mask_CSF_New_Perm,1),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(flip(Mask_WM_New_Perm,1),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 7" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 2,1 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(flip(Mask_CSF_New_Perm,2),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(flip(Mask_WM_New_Perm,2),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 8" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 2,3 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(flip(Mask_CSF_New_Perm,2),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(flip(Mask_WM_New_Perm,2),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 9" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 3,1 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(flip(Mask_CSF_New_Perm,3),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(flip(Mask_WM_New_Perm,3),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 10" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 3,2 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip(flip(Mask_CSF_New_Perm,3),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip(flip(Mask_WM_New_Perm,3),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 11" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 1,2,3 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip((flip(flip(Mask_CSF_New_Perm,1),2)),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip((flip(flip(Mask_WM_New_Perm,1),2)),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 12" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 1,3,2 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip((flip(flip(Mask_CSF_New_Perm,1),3)),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip((flip(flip(Mask_WM_New_Perm,1),3)),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 13" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 2,1,3 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip((flip(flip(Mask_CSF_New_Perm,2),1)),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip((flip(flip(Mask_WM_New_Perm,2),1)),3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 14" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 2,3,1 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip((flip(flip(Mask_CSF_New_Perm,2),3)),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip((flip(flip(Mask_WM_New_Perm,2),3)),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 15" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 3,1,2 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip((flip(flip(Mask_CSF_New_Perm,3),1)),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip((flip(flip(Mask_WM_New_Perm,3),1)),2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "    case 16" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo '        disp("flip 3,2,1 Transform required");' >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_CSF_New_Perm_Tran=flip((flip(flip(Mask_CSF_New_Perm,3),2)),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "        Mask_WM_New_Perm_Tran=flip((flip(flip(Mask_WM_New_Perm,3),2)),1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "end" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

#Old dumb way of aligning the freesurfer derived lateral ventricles mask to the QSM data inside Matlab
#echo "Mask_CSF_New_Rot = permute(Mask_CSF_New,[2,3,1]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
#echo "Mask_CSF_New_Rot_F1 = flip(Mask_CSF_New_Rot,1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
#echo "Mask_CSF_New_Rot_F2 = flip(Mask_CSF_New_Rot_F1,2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
#echo "Mask_CSF_New_Rot_F3 = flip(Mask_CSF_New_Rot_F2,3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

#echo "Mask_WM_New_Rot = permute(Mask_WM_New,[2,3,1]);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
#echo "Mask_WM_New_Rot_F1 = flip(Mask_WM_New_Rot,1);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
#echo "Mask_WM_New_Rot_F2 = flip(Mask_WM_New_Rot_F1,2);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
#echo "Mask_WM_New_Rot_F3 = flip(Mask_WM_New_Rot_F2,3);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

#echo "write_QSM_dir(Mask_CSF_New_Rot_F3, DICOM_dir, New_CSF_Mask_Dir);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m <--write_QSM_dir() does not work with Siemens XA30 DICOMs, not even in interoperability
#echo "write_QSM_dir(Mask_WM_New_Rot_F3, DICOM_dir, New_WM_Mask_Dir);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "disp('"Writing freesurfer derived CSF/WM QSM reference masks to $OutFolder/$Subj/QSM/QSM_New_Mask_CSF and QSM_New_Mask_WM"');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Write_DICOM(Mask_CSF_New_Perm_Tran, files, New_CSF_Mask_Dir);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Write_DICOM(Mask_WM_New_Perm_Tran, files, New_WM_Mask_Dir);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "clear Mask_CSF;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_CSF = Mask_CSF_New_Perm_Tran;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "save('$OutFolder/$Subj/QSM/RDF.mat','RDF','iFreq','iFreq_raw','iMag','N_std','Mask','matrix_size','voxel_size','delta_TE','CF','B0_dir','Mask_CSF');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_New_CSF = MEDI_L1('lambda',1000,'lambda_CSF',100,'merit','smv',5);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "delete RDF.mat;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "clear Mask_CSF;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_CSF = Mask_WM_New_Perm_Tran;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "save('$OutFolder/$Subj/QSM/RDF.mat','RDF','iFreq','iFreq_raw','iMag','N_std','Mask','matrix_size','voxel_size','delta_TE','CF','B0_dir','Mask_CSF');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_New_WM = MEDI_L1('lambda',1000,'lambda_CSF',100,'merit','smv',5);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "delete RDF.mat;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "disp('"Writing QSM_New_CSF map to $OutFolder/$Subj/QSM/MEDI_Output_New_CSF"');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Write_DICOM(QSM_New_CSF, files, QSM_Output_New_CSF);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "disp('"Writing QSM_New_WM map to $OutFolder/$Subj/QSM/MEDI_Output_New_WM"');" >> Subj_${Subj}_MEDI_QSM_New_Ref.m
echo "Write_DICOM(QSM_New_WM, files, QSM_Output_New_WM);" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo "movefile RDF.mat.QSM.Script RDF.mat;" >> Subj_${Subj}_MEDI_QSM_New_Ref.m

echo ""
echo "Running MEDI analysis for ${Subj}..."
echo ""

#Run MEDI_QSM_New_Ref.m FILE to create QSM Maps with new CSF and new WM masks as reference
#stty -tostop
#$MatPath -nodisplay -nosplash -nodesktop -batch <-- Matlab 2020 only
$MatPath -nodisplay -nosplash -nodesktop -r "try; Subj_${Subj}_MEDI_QSM_New_Ref; catch warning('*ERROR*ERROR*ERROR*'); end; quit" #> ${Subj}_MEDI_New_Ref_Matlab_Log.txt

if (grep -Fq "*ERROR*ERROR*ERROR*" $log_file); then #${Subj}_MEDI_New_Ref_Matlab_Log.txt
	
	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: MEDI_QSM_New_Ref.sh Script FAILED! "
	echo "Look in $OutFolder/$Subj/QSM/${Subj}_MEDI_New_Ref_Matlab_Log.txt for details"
	echo "The main reason for this failure is files (eg. RDF.mat or files.mat) moved out from $OutFolder/$Subj/QSM"
	echo -e "----------------------------------------------\e[0m"
	echo ""
	exit 5

elif (grep -Fq "Unknown manufacturer:" $log_file); then #${Subj}_MEDI_New_Ref_Matlab_Log.txt

	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: MEDI_QSM_New_Ref.sh script FAILED! The error provided by MEDI Toolbox was: "
	echo $(grep -Fq "Unknown manufacturer:" ${Subj}_MEDI_New_Ref_Matlab_Log.txt)
	echo "The main reason for this failure is the DICOM files provided are not from a MEDI Toolbox supported scanner manufacturer"
	echo "Supported manufacturers are Siemens, GE and Philips"
	echo -e "----------------------------------------------\e[0m"
	echo ""
	exit 5

else
	
	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_Map_New_CSF -z i -b n MEDI_Output_New_CSF
	mv MEDI_Output_New_CSF/${Subj}_QSM_Map_New_CSF*.nii.gz ${Subj}_QSM_Map_New_CSF.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_Map_New_WM -z i -b n MEDI_Output_New_WM
	mv MEDI_Output_New_WM/${Subj}_QSM_Map_New_WM*.nii.gz ${Subj}_QSM_Map_New_WM.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_New_Mask_CSF -z i -b n QSM_New_Mask_CSF/
	#mv QSM_New_Mask_CSF/${Subj}_QSM_New_Mask_CSF*.nii.gz QSM_New_Mask_CSF/${Subj}_QSM_New_Mask_CSF.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_New_Mask_WM -z i -b n QSM_New_Mask_WM/
	#mv QSM_New_Mask_WM/${Subj}_QSM_New_Mask_WM*.nii.gz QSM_New_Mask_WM/${Subj}_QSM_New_Mask_WM.nii.gz

	unset ObliFileQSM	
	ObliFileQSM=$(singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg 3dinfo -is_oblique ${Subj}_QSM_Map_New_CSF.nii.gz)

	if (( $ObliFileQSM == 1 )); then

		echo ""	
		echo "QSM Map (new CSF) appears to be oblique (QSM scan collected at an angle). Deoblique will be used..."
		echo ""	

		mv ${Subj}_QSM_Map_New_CSF.nii.gz ${Subj}_QSM_Map_New_CSF_Obli.nii.gz
		mv ${Subj}_QSM_Map_New_WM.nii.gz ${Subj}_QSM_Map_New_WM_Obli.nii.gz
		mv QSM_New_Mask_CSF/${Subj}_QSM_New_Mask_CSF*.nii.gz QSM_New_Mask_CSF/${Subj}_QSM_New_Mask_CSF_Obli.nii.gz
		mv QSM_New_Mask_WM/${Subj}_QSM_New_Mask_WM*.nii.gz QSM_New_Mask_WM/${Subj}_QSM_New_Mask_WM_Obli.nii.gz

		singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
			3dWarp -deoblique -wsinc5 -prefix ${Subj}_QSM_Map_New_CSF.nii.gz ${Subj}_QSM_Map_New_CSF_Obli.nii.gz

		singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
			3dWarp -deoblique -wsinc5 -prefix ${Subj}_QSM_Map_New_WM.nii.gz ${Subj}_QSM_Map_New_WM_Obli.nii.gz

		singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
			3dWarp -deoblique -NN -prefix QSM_New_Mask_CSF/${Subj}_QSM_New_Mask_CSF.nii.gz QSM_New_Mask_CSF/${Subj}_QSM_New_Mask_CSF_Obli.nii.gz

		singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg \
			3dWarp -deoblique -NN -prefix QSM_New_Mask_WM/${Subj}_QSM_New_Mask_WM.nii.gz QSM_New_Mask_WM/${Subj}_QSM_New_Mask_WM_Obli.nii.gz
		
	fi		

	echo ""		
	echo "---------------------------------------------------------------"	
	echo "MEDI_QSM_New_Ref.sh finished running succesfully on `date`"
	echo "---------------------------------------------------------------"
	echo ""	

fi


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
