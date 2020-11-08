#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 09/9/2020
#
#	Copyright (C) 2020 Valentinos Zachariou, University of Kentucky (see LICENSE file for more details)
#
#	Script evaluates QSM DICOM files and if all is good runs MEDI toolbox
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

#Passed varialbes to MEDI.sh 
#1) Subject
#2) Output Folder
#3) Path
#4) QSM DICOM Directory
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

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.MEDI.txt")
exec &> >(tee -a "$log_file")


#Font Name: Modular
echo ""
echo "---------------------------------------------------------------"
echo " __   __  _______  ______   ___  "
echo "|  |_|  ||       ||      | |   | "
echo "|       ||    ___||  _    ||   | "
echo "|       ||   |___ | | |   ||   | "
echo "|       ||    ___|| |_|   ||   | "
echo "| ||_|| ||   |___ |       ||   | "
echo "|_|   |_||_______||______| |___| "
echo ""
echo "MEDI processing script"
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

cd $OutFolder/$Subj
mkdir QSM
cd QSM
mkdir QSM_DICOM

#mkdir MEDI_Output
#mkdir MEDI_mat_Files

echo ""
echo "Copying DICOM files from $QSM_Dicom_Dir to $OutFolder/$Subj/QSM/QSM_DICOM"
echo ""


singularity run -e --bind $QSM_Dicom_Dir:/mnt $Path/Functions/QSM_Container.simg find /mnt -mindepth 1 -maxdepth 1 -type f ! \
		-regex '.*\(nii\|json\|txt\|nii.gz\|HEAD\|BRIK\|hdr\|img\)$' -exec cp '{}' 'QSM_DICOM/' ';'


echo ""
echo "Converting QSM DICOMS in $OutFolder/$Subj/QSM/QSM_DICOM/ to NIFTI (.nii.gz)"
echo ""

singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_Files -z i -b n -m 1 QSM_DICOM/

echo ""
echo "---------------------------------------------------------------"
echo "*** Looking for QSM PHASE and MAGNITUDE scans/files: ***"
echo "---------------------------------------------------------------"
echo ""

cd QSM_DICOM

#Figure out which nifti file is the Mag and which is the Phase and check if they exist and if correct

File1=$(singularity run -e $Path/Functions/QSM_Container.simg find ${Subj}_QSM_Files*.nii.gz -maxdepth 1 -printf "%s\t%p\n" | sort -nr | sed -n '1p' | awk 'FNR == 1 {print $2}') #presumably phase 
File2=$(singularity run -e $Path/Functions/QSM_Container.simg find ${Subj}_QSM_Files*.nii.gz -maxdepth 1 -printf "%s\t%p\n" | sort -nr | sed -n '2p' | awk 'FNR == 1 {print $2}') #presumably magnitude

echo ""
echo "Largest .nii.gz file in `pwd` is $File1, possibly the PHASE Scan"
echo ""
echo "Second largest .nii.gz file in `pwd` is $File2, possibly the MAGNITUDE Scan" 	
echo ""
echo "Evaluating files..."
echo ""

if [[ $File1 == "${Subj}_QSM_Files"*"_ph".nii.gz ]]; then

	QSM_Echos_File1=$(singularity run -e $Path/Functions/QSM_Container.simg 3dinfo -nv $File1)
	#QSM_Echos_File1=3	

	echo ""
	echo "$File1 has $QSM_Echos_File1 echos"
	echo ""

	if [[ $QSM_Echos_File1 < 2 ]]; then
	#if [ ! -z ${QSM_Echos_File1+x} ]; then
		
		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: QSM PHASE file $File1 has too few echos! "
		echo "Check whether the QSM DICOMs provided are indeed from the QSM scan"
		echo -e "----------------------------------------------\e[0m"
		echo ""
		exit 5
		
	elif (( "$QSM_Echos_File1" >= 8 )); then
		
		echo ""	
		echo "File $File1 has a valid number of echos"			
		echo ""
	
	elif [[ $QSM_Echos_File1 < 8 ]] && [[ $QSM_Echos_File1 > 2 ]]; then

		echo ""	
		echo -e "\e[93m----------------------------------------------"
		echo "WARNING: QSM PHASE scans usually have at least 8 echos! "
		echo "$File1 appears to only have $QSM_Echos_File1"
		echo "MEDI will continue but check QSM files for consistency"
		echo -e "----------------------------------------------\e[0m"	
		echo ""		
	
	else
		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Unexpected number of echos in QSM PHASE file $File1"
		echo "Or failed to read $File1"
		echo "Check if QSM DICOMs look correct"
		echo -e "----------------------------------------------\e[0m"
		echo ""
		exit 5	
	
	fi
else

	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: QSM PHASE NOT FOUND! "
	echo "Check whether the QSM DICOMs provided are indeed from the QSM scan"
	echo -e "----------------------------------------------\e[0m"
	echo ""
	exit 5

fi


if [[ $File2 == "${Subj}_QSM_Files"*.nii.gz ]]; then

	QSM_Echos_File2=$(singularity run -e $Path/Functions/QSM_Container.simg 3dinfo -nv $File2)
	#QSM_Echos_File2=3
	
	echo ""	
	echo "$File2 has $QSM_Echos_File2 echos"
	echo ""

	if [[ $QSM_Echos_File2 < 2 ]]; then
		
		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: QSM MAGNITUDE file $File2 has too few echos! "
		echo "Check whether the QSM DICOMs provided are indeed from the QSM scan"
		echo -e "----------------------------------------------\e[0m"
		echo ""
		exit 5
		
	elif (( "$QSM_Echos_File2" >= 8 )); then
		
		echo ""				
		echo "File $File2 has a valid number of echos"	
		echo ""			

	elif [[ $QSM_Echos_File2 < 8 ]] && [[ $QSM_Echos_File2 > 2 ]]; then

		echo ""	
		echo -e "\e[93m----------------------------------------------"
		echo "WARNING: QSM MAGNITUDE scans usually have at least 8 echos! "
		echo "$File2 appears to only have $QSM_Echos_File2"
		echo "MEDI will continue but check QSM files for consistency"
		echo -e "----------------------------------------------\e[0m"	
		echo ""		
	
	else

		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Unexpected number of echos in QSM MAGNITUDE file $File1"
		echo "Or failed to read $File2"
		echo "Check if QSM DICOMs look correct"
		echo -e "----------------------------------------------\e[0m"
		echo ""
		exit 5		

	fi

else
	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: QSM MAGNITUDE NOT FOUND! "
	echo "Check whether the QSM DICOMs provided are indeed from the QSM scan"
	echo -e "----------------------------------------------\e[0m"
	echo ""
	exit 5

fi

if [[ ! $QSM_Echos_File1 == $QSM_Echos_File2 ]]; then

	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "QSM PHASE and MAGNITUDE files have different number of echos! "
	echo "Check whether the QSM DICOMs provided are indeed from the QSM scan"
	echo -e "----------------------------------------------\e[0m"
	echo ""
	exit 5

elif [[ $QSM_Echos_File1 == $QSM_Echos_File2 ]] && (( "$QSM_Echos_File1" >= 8 )) ; then
	
	echo ""	
	echo "QSM PHASE scan verified as $File1"
	echo "$File1 will be renamed to ${Subj}_QSM_PHASE.nii.gz"
	mv $File1 ${Subj}_QSM_PHASE.nii.gz
	echo ""	
	echo "QSM MAGNITUDE scan verified as $File2"	
	echo "$File2 will be renamed to ${Subj}_QSM_Mag.nii.gz"	
	echo ""		
	mv $File2 ${Subj}_QSM_Mag.nii.gz

elif [[ $QSM_Echos_File1 == $QSM_Echos_File2 ]] && [[ $QSM_Echos_File1 < 8 ]] ; then
	
	echo -e "\e[93m"	
	echo "QSM PHASE scan NOT verifired. Proceed at own risk! "
	echo "$File1 will be renamed to ${Subj}_QSM_PHASE.nii.gz"
	mv $File1 ${Subj}_QSM_PHASE.nii.gz
	echo ""	
	echo "QSM MAGNITUDE scan NOT verified. Proceed at own risk! "	
	echo "$File2 will be renamed to ${Subj}_QSM_Mag.nii.gz"	
	echo -e "\e[0m"		
	mv $File2 ${Subj}_QSM_Mag.nii.gz

fi
	

cd $OutFolder/$Subj/QSM
mv QSM_DICOM/*.nii.gz .

#Create Custom MEDI pipeline file specific to each participant
echo ""
echo "---------------------------------------------------------------"
echo "Creating MEDI analysis file for ${Subj} --> ${Subj}_MEDI_QSM.m "
echo "in: `pwd`"
echo "---------------------------------------------------------------"
echo ""

echo "% MEDI QSM Script for $Subj" >> ${Subj}_MEDI_QSM.m
echo "% Script created automatically by MEDI.sh on `date`" >> ${Subj}_MEDI_QSM.m
echo "" >> ${Subj}_MEDI_QSM.m

echo "clear all" >> ${Subj}_MEDI_QSM.m
echo "run('$MEDIPath/MEDI_set_path.m');" >> ${Subj}_MEDI_QSM.m

echo "DICOM_dir = fullfile('$OutFolder/$Subj/QSM/QSM_DICOM');" >> ${Subj}_MEDI_QSM.m
echo "QSM_Output_dir = fullfile('$OutFolder/$Subj/QSM/MEDI_Output');" >> ${Subj}_MEDI_QSM.m
echo "CSF_Mask_Dir = fullfile('$OutFolder/$Subj/QSM/QSM_Orig_Mask_CSF');" >> ${Subj}_MEDI_QSM.m

# Use accelerated (for Siemens and GE only) reading of DICOMs
echo "[iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_DICOM(DICOM_dir);" >> ${Subj}_MEDI_QSM.m

# Estimate the frequency offset in each of the voxel using a complex
# fitting (even echo spacing)
echo "[iFreq_raw, N_std] = Fit_ppm_complex(iField);" >> ${Subj}_MEDI_QSM.m
# Compute magnitude image
echo "iMag = sqrt(sum(abs(iField).^2,4));" >> ${Subj}_MEDI_QSM.m

# Spatial phase unwrapping (region-growing)
echo "iFreq = unwrapPhase(iMag, iFreq_raw, matrix_size);" >> ${Subj}_MEDI_QSM.m

# Use FSL BET to extract brain mask
echo "Mask = BET(iMag,matrix_size,voxel_size);" >> ${Subj}_MEDI_QSM.m

# Background field removasl using Projection onto Dipole Fields
echo "RDF = PDF(iFreq, N_std, Mask,matrix_size,voxel_size, B0_dir);" >> ${Subj}_MEDI_QSM.m

# R2* map needed for ventricular CSF mask
echo "R2s = arlo(TE, abs(iField));" >> ${Subj}_MEDI_QSM.m

# Ventricular CSF mask for zero referencing 
#	Requirement:
#	R2s:	R2* map
echo "Mask_CSF = extract_CSF(R2s, Mask, voxel_size);" >> ${Subj}_MEDI_QSM.m
echo "save('$OutFolder/$Subj/QSM/RDF.mat','RDF','iFreq','iFreq_raw','iMag','N_std','Mask','matrix_size','voxel_size','delta_TE','CF','B0_dir','Mask_CSF');" >> ${Subj}_MEDI_QSM.m
echo "save('$OutFolder/$Subj/QSM/files.mat','files');" >> ${Subj}_MEDI_QSM.m

#Save original CSF mask to CSF_Mask_Dir
echo "write_QSM_dir(Mask_CSF, DICOM_dir, CSF_Mask_Dir);" >> ${Subj}_MEDI_QSM.m

# Morphology enabled dipole inversion with zero reference using CSF (MEDI+0)
echo "QSM = MEDI_L1('lambda',1000,'lambda_CSF',100,'merit','smv',5);" >> ${Subj}_MEDI_QSM.m

# export QSM variable as dicom files in the 'QSM' directory
echo "Write_DICOM(QSM, files, QSM_Output_dir)" >> ${Subj}_MEDI_QSM.m

echo ""
echo "Running MEDI analysis for ${Subj}..."
echo ""

	
#Run MEDI_QSM.m FILE to create a QSM map
#stty -tostop
#$MatPath -nodisplay -nosplash -nodesktop -batch <-- Matlab 2020 only
$MatPath -nodisplay -nosplash -nodesktop -r "try; ${Subj}_MEDI_QSM; catch warning('*ERROR*ERROR*ERROR*'); end; quit" > ${Subj}_MEDI_Matlab_Log.txt

if (grep -Fq "*ERROR*ERROR*ERROR*" ${Subj}_MEDI_Matlab_Log.txt); then
	
	echo ""		
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: MEDI.sh script FAILED! "
	echo "Look in $OutFolder/$Subj/QSM/${Subj}_MEDI_Matlab_Log.txt for details"
	echo "The main reason for this failure is non DICOM files present in the QSM DICOM folder"
	echo -e "----------------------------------------------\e[0m"
	echo ""
	exit 5
else
	
	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_Map -z i -b n MEDI_Output/
	mv MEDI_Output/${Subj}_QSM_Map*.nii.gz ${Subj}_QSM_Map.nii.gz

	singularity run -e --bind $OutFolder/$Subj/QSM $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_QSM_Orig_Mask_CSF -z i -b n QSM_Orig_Mask_CSF/
	#mv QSM_Orig_Mask_CSF/${Subj}_QSM_Orig_Mask_CSF*.nii.gz QSM_Orig_Mask_CSF/${Subj}_QSM_Orig_Mask_CSF.nii.gz

	echo ""		
	echo "---------------------------------------------------------------"	
	echo "MEDI.sh script finished running succesfully on `date`"
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
