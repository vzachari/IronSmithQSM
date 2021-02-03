#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 08/24/2020
#
#	Copyright (C) 2020 Valentinos Zachariou, University of Kentucky (see LICENSE file for more details)
#
# 	Script creates MPR folder in output path 
# 	Script creates RMS MPRAGE .nii.gz file if multi-echos exist
# 	Script runs freesurfer segmentation and evaluates outputs for correctness
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
#


#Passed varialbes to 01_MPRAGE.sh 
#1) Subject
#2) Output Folder
#3) MPRAGE Directory
#4) MPRAGE Type
#5) Path

#Subj="S1030"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/QSM_Test_Run"
#MPRDir="/home/data3/vzachari/QSM_Toolkit/S0030/MPR"
#MPRType=2
#Path="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"

Subj=$1
OutFolder=$2
MPRDir=$3
MPRType=$4
Path=$5

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.01.MPRAGE.txt")
exec &> >(tee -a "$log_file")


#Font Name: Modular
echo ""
echo "---------------------------------------------------------------"
echo " __   __  _______  ______    _______  _______  _______ "
echo "|  |_|  ||       ||    _ |  |   _   ||       ||       |"
echo "|       ||    _  ||   | ||  |  |_|  ||    ___||    ___|"
echo "|       ||   |_| ||   |_||_ |       ||   | __ |   |___ "
echo "|       ||    ___||    __  ||       ||   ||  ||    ___|"
echo "| ||_|| ||   |    |   |  | ||   _   ||   |_| ||   |___ "
echo "|_|   |_||___|    |___|  |_||__| |__||_______||_______|"
echo ""
echo "---------------------------------------------------------------"                                        
echo ""     

#Get number of cores. Use half of the cores for freesurfer:
CoreNum=$((`singularity run -e $Path/Functions/QSM_Container.simg lscpu | awk 'FNR == 4 {print $2}'` / 2))


echo ""
echo "---------------------------------------------------------------"	
echo "*** Processing MPR/MEMPR scans for freesurfer segmentation: ***"
echo "---------------------------------------------------------------"	
echo ""	


echo ""
echo "$CoreNum cores will be used for freesurfer segmentation"
echo ""

cd $Path

#Debug
#echo $Subj
#echo $OutFolder
#echo $MPRDir
#echo $MPRType
#echo $Path

cd $OutFolder/$Subj
mkdir MPR
cd MPR

#Check state of MPRType
if [[ $MPRType == 1 ]]; then
	
	echo ""		
	echo "Processing multiple echos as separate NIFTI files..."
	echo ""	

	echo ""	
	echo "Copying .nii* files:"
	echo "`ls $MPRDir/*.nii* | awk -F "/" '{print $NF}'`" 	
	echo "from $MPRDir to $OutFolder/$Subj/MPR"
	echo ""	
	
	cp $MPRDir/*.nii* .	

	echo ""	
	echo "Catenating .nii* files and calculating RMS. Output file will be ----> ${Subj}_mempr_rms.nii.gz"	
	echo ""	

	singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg \
		mri_concat *_e*.nii* --o $Subj'_'mempr_cat.nii.gz

	singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg \
		mri_concat $Subj'_'mempr_cat.nii.gz --o $Subj'_'mempr_rms.nii.gz --rms
	


	if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

		echo ""	
		echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
		echo ""		
		echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
		echo ""			

		cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .
		#cp -r $OutFolder/S0030/MPR/S0030_FreeSurfSeg_Skull ${Subj}_FreeSurfSeg_Skull

		echo ""		
		echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
		echo "---------------------------------------------------------------"	
		echo ""
		
	else
		

		echo ""	
		echo "Running freesurfer. This could take up to 8 hours (´∀｀；) "	
		echo ""	
	
		singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr_rms.nii.gz -sd .
	fi

	
	echo ""		
	echo "---------------------------------------------------------------"		
	echo "*** Evaluating freesurfer segmentation... ***"	
	echo "---------------------------------------------------------------"	
	echo ""

	#check if freesurfer finished correctly:
	if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		echo ""				
		echo "Freesurfer finished successfully on `date` d(-_^)"	
		echo ""
	else
		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Freesurfer DID NOT segment MEMPR data properly"
		echo "Things to do that might help:"
		echo "1. Visually check the MEMPR data for excessive motion or artifacts (e.g. stroke, lesions etc)" 
		echo "Sometimes freesurfer cannot handle these cases."
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	fi


elif [[ $MPRType == 2 ]]; then
	
	echo ""		
	echo "Processing multiple echos in single NIFTI file:"
	echo ""	

	echo ""	
	echo "Copying `ls $MPRDir/*.nii* | awk -F "/" '{print $NF}'` from $MPRDir to $OutFolder/$Subj/MPR"	
	echo ""	

	cp $MPRDir/*.nii* .
	
	echo ""	
	echo "Calculating RMS. Output file will be ----> ${Subj}_mempr_rms.nii.gz"	
	echo ""	


	singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg mri_concat *.nii* --o $Subj'_'mempr_rms.nii.gz --rms

	if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

		echo ""	
		echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
		echo ""		
		echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
		echo ""

		cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .
		#cp -r $OutFolder/S0030/MPR/S0030_FreeSurfSeg_Skull ${Subj}_FreeSurfSeg_Skull

		echo ""		
		echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
		echo "---------------------------------------------------------------"			
		echo ""
		
	else

		echo ""	
		echo "Running freesurfer. This could take up to 8 hours (´∀｀；)"	
		echo ""			

		singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr_rms.nii.gz -sd .

	fi

	echo ""		
	echo "---------------------------------------------------------------"		
	echo "*** Evaluating freesurfer segmentation... ***"	
	echo "---------------------------------------------------------------"	
	echo ""


	#check if freesurfer finished correctly:	
	if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		
		echo ""			
		echo "Freesurfer finished successfully on `date` d(-_^)"	
		echo ""	
	else
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Freesurfer DID NOT segment MEMPR data properly"
		echo "Things to do that might help:"
		echo "1. Visually check the MEMPR data for excessive motion or artifacts (e.g. stroke, lesion etc)" 
		echo "Sometimes freesurfer cannot handle these cases."
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	fi
	

elif [[ $MPRType == 3 ]]; then

	echo ""
	echo "Single echo in single NIFTI file, NO RMS PROCESSING"
	echo ""

	echo ""	
	echo "Copying `ls $MPRDir/*.nii* | awk -F "/" '{print $NF}'` from $MPRDir to $OutFolder/$Subj/MPR"
	echo "`ls $MPRDir/*.nii* | awk -F "/" '{print $NF}'` will be renamed to ${Subj}_mempr.nii.gz" 	
	echo ""	


	cp $MPRDir/*.nii* $Subj'_'mempr.nii.gz
	
	
	if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

		echo ""	
		echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
		echo ""		
		echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
		echo ""

		cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .
		#cp -r $OutFolder/S0030/MPR/S0030_FreeSurfSeg_Skull ${Subj}_FreeSurfSeg_Skull

		echo ""		
		echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
		echo "---------------------------------------------------------------"			
		echo ""
	else

		echo ""	
		echo "Running freesurfer. This could take up to 8 hours (´∀｀；) "	
		echo ""	

		singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr.nii.gz -sd .

	fi


	echo ""		
	echo "---------------------------------------------------------------"		
	echo "*** Evaluating freesurfer segmentation... ***"	
	echo "---------------------------------------------------------------"	
	echo ""
	
	
	#check if freesurfer finished correctly:	
	if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		
		echo ""			
		echo "Freesurfer finished successfully on `date` d(-_^)"	
		echo ""	
	else
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Freesurfer DID NOT segment MPR data properly"
		echo "Things to do that might help:"
		echo "1. Visually check the MPR data for excessive motion or artifacts (e.g. stroke, lesion etc)" 
		echo "Sometimes freesurfer cannot handle these cases."
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	fi
	
elif [[ $MPRType == 5 ]]; then

	echo ""		
	echo "Processing multiple echos in single NIFTI file:"
	echo ""	

	MPRDirPath=$(echo $MPRDir | awk -F '/' '{OFS = FS} {$NF=""; print $0}')
	MPRDirFile=$(echo $MPRDir | awk -F '/' '{print $NF}')

	echo ""	
	echo "Copying $MPRDirFile from $MPRDirPath to $OutFolder/$Subj/MPR"	
	echo ""	

	cp $MPRDir .
	
	echo ""	
	echo "Calculating RMS. Output file will be ----> ${Subj}_mempr_rms.nii.gz"	
	echo ""	


	singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg mri_concat *.nii* --o $Subj'_'mempr_rms.nii.gz --rms

	if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

		echo ""	
		echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
		echo ""		
		echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
		echo ""

		cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .
		#cp -r $OutFolder/S0030/MPR/S0030_FreeSurfSeg_Skull ${Subj}_FreeSurfSeg_Skull

		echo ""		
		echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
		echo "---------------------------------------------------------------"			
		echo ""
		
	else

		echo ""	
		echo "Running freesurfer. This could take up to 8 hours (´∀｀；)"	
		echo ""			

		singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr_rms.nii.gz -sd .

	fi

	echo ""		
	echo "---------------------------------------------------------------"		
	echo "*** Evaluating freesurfer segmentation... ***"	
	echo "---------------------------------------------------------------"	
	echo ""


	#check if freesurfer finished correctly:	
	if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		
		echo ""			
		echo "Freesurfer finished successfully on `date` d(-_^)"	
		echo ""	
	else
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Freesurfer DID NOT segment MEMPR data properly"
		echo "Things to do that might help:"
		echo "1. Visually check the MEMPR data for excessive motion or artifacts (e.g. stroke, lesion etc)" 
		echo "Sometimes freesurfer cannot handle these cases."
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	fi

	unset MPRDirPath MPRDirFile

elif [[ $MPRType == 6 ]]; then

	echo ""
	echo "Single echo in single NIFTI file, NO RMS PROCESSING"
	echo ""

	MPRDirPath=$(echo $MPRDir | awk -F '/' '{OFS = FS} {$NF=""; print $0}')
	MPRDirFile=$(echo $MPRDir | awk -F '/' '{print $NF}')

	echo ""	
	echo "Copying $MPRDirFile from $MPRDirPath to $OutFolder/$Subj/MPR"
	echo "$MPRDirFile will be renamed to ${Subj}_mempr.nii.gz" 	
	echo ""	

	cp $MPRDir $Subj'_'mempr.nii.gz
	
	
	if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

		echo ""	
		echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
		echo ""		
		echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
		echo ""

		cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .
		#cp -r $OutFolder/S0030/MPR/S0030_FreeSurfSeg_Skull ${Subj}_FreeSurfSeg_Skull

		echo ""		
		echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
		echo "---------------------------------------------------------------"			
		echo ""
	else

		echo ""	
		echo "Running freesurfer. This could take up to 8 hours (´∀｀；) "	
		echo ""	

		singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr.nii.gz -sd .

	fi


	echo ""		
	echo "---------------------------------------------------------------"		
	echo "*** Evaluating freesurfer segmentation... ***"	
	echo "---------------------------------------------------------------"	
	echo ""
	
	
	#check if freesurfer finished correctly:	
	if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		
		echo ""			
		echo "Freesurfer finished successfully on `date` d(-_^)"	
		echo ""	
	else
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: Freesurfer DID NOT segment MPR data properly"
		echo "Things to do that might help:"
		echo "1. Visually check the MPR data for excessive motion or artifacts (e.g. stroke, lesion etc)" 
		echo "Sometimes freesurfer cannot handle these cases."
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	fi

	unset MPRDirPath MPRDirFile


elif [[ $MPRType == 4 ]]; then

	echo ""
	echo "DICOMS found in MPR directory! "
	echo ""
	echo "Converting DICOMS in $MPRDir to NIFTI (.nii.gz)..."
	echo ""


	MPRDirTrim=$(echo $MPRDir | awk -F'/' '{OFS = FS} {$NF=""; print $0}')

	singularity run -e --bind $MPRDirTrim $Path/Functions/QSM_Container.simg dcm2niix -f ${Subj}_MPR_File -z i -b n -m 1 $MPRDir/
	
	echo ""
	echo "Moving $(basename $(ls $MPRDir/${Subj}_MPR_File*.nii.gz)) from $MPRDir to $OutFolder/$Subj/MPR"
	echo ""

	mv $MPRDir/${Subj}_MPR_File*.nii.gz .

	TimePoints=$(singularity run -e --bind $OutFolder/$Subj/MPR:/mnt $Path/Functions/QSM_Container.simg 3dinfo -nv /mnt/${Subj}_MPR_File*.nii.gz)
	
	if [[ $TimePoints > 1 ]]; then

		echo ""			
		echo "$TimePoints echos found in `ls ${Subj}_MPR_File*.nii.gz`" 			
		echo ""
		echo "Calculating RMS. Output file will be ----> ${Subj}_mempr_rms.nii.gz"	
		echo ""	
	
		singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg mri_concat ${Subj}_MPR_File*.nii* --o $Subj'_'mempr_rms.nii.gz --rms
		
		if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

			echo ""	
			echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
			echo ""		
			echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
			echo ""

			cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .

			echo ""		
			echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
			echo "---------------------------------------------------------------"			
			echo ""
		
		else

			echo ""	
			echo "Running freesurfer. This could take up to 8 hours (´∀｀；) "	
			echo ""			

			singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr_rms.nii.gz -sd .

		fi

		echo ""		
		echo "---------------------------------------------------------------"		
		echo "*** Evaluating freesurfer segmentation... ***"	
		echo "---------------------------------------------------------------"	
		echo ""


		#check if freesurfer finished correctly:	
		if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		
			echo ""			
			echo "Freesurfer finished successfully on `date` d(-_^)"	
			echo ""	
		else
			echo -e "\e[31m----------------------------------------------"
			echo "ERROR: Freesurfer DID NOT segment MEMPR data properly"
			echo "Things to do that might help:"
			echo "1. Visually check the MEMPR data for excessive motion or artifacts (e.g. stroke, lesion etc)" 
			echo "Sometimes freesurfer cannot handle these cases."
			echo -e "----------------------------------------------\e[0m"
			echo ""		
			exit 5
		fi	


	elif [[ $TimePoints == 1 ]]; then

								
		echo ""			
		echo "$TimePoints echo found in `ls ${Subj}_MPR_File*.nii.gz`" 			
		echo ""
		echo "NO RMS PROCESSING. `ls ${Subj}_MPR_File*.nii.gz` will be renamed to ${Subj}_mempr.nii.gz "	
		echo ""	
	
		mv ${Subj}_MPR_File*.nii.gz ${Subj}_mempr.nii.gz

		if [ -d "$OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull" ]; then

			echo ""	
			echo "${Subj}_FreeSurfSeg_Skull folder found under $OutFolder/Freesurfer_Skip"	
			echo ""		
			echo "Copying ${Subj}_FreeSurfSeg_Skull to $OutFolder/$Subj/MPR..."
			echo ""

			cp -r $OutFolder/Freesurfer_Skip/${Subj}_FreeSurfSeg_Skull .
		

			echo ""		
			echo "*** Skipping freesurfer segmentation ☜(ﾟヮﾟ☜) ***"
			echo "---------------------------------------------------------------"			
			echo ""
		else

			echo ""	
			echo "Running freesurfer. This could take up to 8 hours (´∀｀；) "	
			echo ""	

			singularity run -e --bind $OutFolder/$Subj/MPR $Path/Functions/QSM_Container.simg recon-all -all -openmp $CoreNum -subjid $Subj'_'FreeSurfSeg_Skull -i $Subj'_'mempr.nii.gz -sd .

		fi


		echo ""		
		echo "---------------------------------------------------------------"		
		echo "*** Evaluating freesurfer segmentation... ***"	
		echo "---------------------------------------------------------------"	
		echo ""
	
	
		#check if freesurfer finished correctly:	
		if [ -f "${Subj}_FreeSurfSeg_Skull/mri/aseg.mgz" ] &&  [ -f "${Subj}_FreeSurfSeg_Skull/mri/brain.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/brainmask.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/aparc.DKTatlas+aseg.mgz" ] && [ -f "${Subj}_FreeSurfSeg_Skull/mri/wmparc.mgz" ]; then
		
			echo ""			
			echo "Freesurfer finished successfully on `date` d(-_^)"	
			echo ""	
		else
			echo -e "\e[31m----------------------------------------------"
			echo "ERROR: Freesurfer DID NOT segment MPR data properly"
			echo "Things to do that might help:"
			echo "1. Visually check the MPR data for excessive motion or artifacts (e.g. stroke, lesion etc)" 
			echo "Sometimes freesurfer cannot handle these cases."
			echo -e "----------------------------------------------\e[0m"
			echo ""		
			exit 5
		fi


	fi

	unset TimePoints			

else
	
	echo -e "\e[31m----------------------------------------------"
	echo "ERROR: Unexpected MPR/MEMPR type. Something went wrong with the MEMPR/MPR input files"
	echo "Please check files"
	echo -e "----------------------------------------------\e[0m"
	echo ""		
	exit 5
	

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
