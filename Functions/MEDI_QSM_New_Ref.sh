#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 09/9/2020
#
#	Copyright (C) 2020 Valentinos Zachariou, University of Kentucky (see LICENSE file for more details)
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
#MEDIVer="This just a label. It should match the version of MEDI toolbox you have"

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

#Create Custom MEDI pipeline file specific to each participant

echo ""
echo "---------------------------------------------------------------"
echo "Creating new CSF/WM reference MEDI analysis file for ${Subj} --> ${Subj}_MEDI_QSM_New_Ref.m"
echo "in: `pwd`"
echo "---------------------------------------------------------------"
echo ""

echo "% MEDI New Reference CSF/WM QSM Script For $Subj" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "% Script created automatically by MEDI_QSM_New_Ref.sh on `date`" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "clear all" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "run('$MEDIPath/MEDI_set_path.m');" >> ${Subj}_MEDI_QSM_New_Ref.m


echo "DICOM_dir = fullfile('$OutFolder/$Subj/QSM/QSM_DICOM');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_Output_New_CSF = fullfile('$OutFolder/$Subj/QSM/MEDI_Output_New_CSF');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_Output_New_WM = fullfile('$OutFolder/$Subj/QSM/MEDI_Output_New_WM');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "New_CSF_Mask_Dir = fullfile('$OutFolder/$Subj/QSM/QSM_New_Mask_CSF');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "New_WM_Mask_Dir = fullfile('$OutFolder/$Subj/QSM/QSM_New_Mask_WM');" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "Mask_CSF_New = niftiread(fullfile('$OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Lateral_Ventricle_Mask_AL_QSM_RS_Erx2.nii.gz'));" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_WM_New = niftiread(fullfile('$OutFolder/$Subj/QSM/FreeSurf_QSM_Masks/SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_WM_Mask_AL_QSM_RS_Erx1.nii.gz'));" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "load('RDF.mat');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "load('files.mat');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "movefile RDF.mat RDF.mat.QSM.Script;" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "Mask_CSF_New = double(Mask_CSF_New);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_WM_New = double(Mask_WM_New);" >> ${Subj}_MEDI_QSM_New_Ref.m
   

echo "Mask_CSF_New_Rot = permute(Mask_CSF_New,[2,3,1]);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_CSF_New_Rot_F1 = flip(Mask_CSF_New_Rot,1);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_CSF_New_Rot_F2 = flip(Mask_CSF_New_Rot_F1,2);" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "Mask_WM_New_Rot = permute(Mask_WM_New,[2,3,1]);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_WM_New_Rot_F1 = flip(Mask_WM_New_Rot,1);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_WM_New_Rot_F2 = flip(Mask_WM_New_Rot_F1,2);" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "write_QSM_dir(Mask_CSF_New_Rot_F2, DICOM_dir, New_CSF_Mask_Dir);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "write_QSM_dir(Mask_WM_New_Rot_F2, DICOM_dir, New_WM_Mask_Dir);" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "clear Mask_CSF;" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_CSF = Mask_CSF_New_Rot_F2;" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "save('$OutFolder/$Subj/QSM/RDF.mat','RDF','iFreq','iFreq_raw','iMag','N_std','Mask','matrix_size','voxel_size','delta_TE','CF','B0_dir','Mask_CSF');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_New_CSF = MEDI_L1('lambda',1000,'lambda_CSF',100,'merit','smv',5);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "delete RDF.mat;" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "clear Mask_CSF;" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Mask_CSF = Mask_WM_New_Rot_F2;" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "save('$OutFolder/$Subj/QSM/RDF.mat','RDF','iFreq','iFreq_raw','iMag','N_std','Mask','matrix_size','voxel_size','delta_TE','CF','B0_dir','Mask_CSF');" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "QSM_New_WM = MEDI_L1('lambda',1000,'lambda_CSF',100,'merit','smv',5);" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "delete RDF.mat;" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "Write_DICOM(QSM_New_CSF, files, QSM_Output_New_CSF)" >> ${Subj}_MEDI_QSM_New_Ref.m
echo "Write_DICOM(QSM_New_WM, files, QSM_Output_New_WM)" >> ${Subj}_MEDI_QSM_New_Ref.m

echo "movefile RDF.mat.QSM.Script RDF.mat;" >> ${Subj}_MEDI_QSM_New_Ref.m

echo ""
echo "Running MEDI analysis for ${Subj}..."
echo ""

#Run MEDI_QSM_New_Ref.m FILE to create QSM Maps with new CSF and new WM masks as reference
#stty -tostop
#$MatPath -nodisplay -nosplash -nodesktop -r "run('${Subj}_MEDI_QSM.m');exit;"
#$MatPath -nodisplay -nosplash -nodesktop -batch <-- Matlab 2020 only
$MatPath -nodisplay -nosplash -nodesktop -r "try; ${Subj}_MEDI_QSM_New_Ref; catch warning('*ERROR*ERROR*ERROR*'); end; quit" > ${Subj}_MEDI_New_Ref_Matlab_Log.txt

if (grep -Fq "*ERROR*ERROR*ERROR*" > ${Subj}_MEDI_New_Ref_Matlab_Log.txt); then
	
	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: MEDI_QSM_New_Ref.sh Script FAILED! "
	echo "Look in $OutFolder/$Subj/QSM/${Subj}_MEDI_New_Ref_Matlab_Log.txt for details"
	echo "The main reason for this failure is files (eg. RDF.mat or files.mat) moved out from $OutFolder/$Subj/QSM"
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
