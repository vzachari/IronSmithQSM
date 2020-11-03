#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 09/9/2020
#
# Script calculates SNR (magnitude image based) for each structural ROI used for QSM
# SNR= [ average signal intensity of GRE magnitude image within an ROI / average standard deviation of pixel intensity from air outside the head (away from the frequency and phase axes) ] 
# SNR is then multiplied by the Rayleigh constant (0.655)
#
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


#Passed varialbes to 05_Extract_QSM.sh 
#1) Subject
#2) Output folder
#3) Path
#4) Rows

#Subj="S1090"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/QSM_Test_Run"
#Path="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"

Subj=$1
OutFolder=$2
Path=$3
Rows=$4

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.06.QSM.SNR.txt")
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
echo " _______  __    _  ______   "
echo "|       ||  |  | ||    _ |  "
echo "|  _____||   |_| ||   | ||  "
echo "| |_____ |       ||   |_||_ "
echo "|_____  ||  _    ||    __  |"
echo " _____| || | |   ||   |  | |"
echo "|_______||_|  |__||___|  |_|"
echo ""
echo "---------------------------------------------------------------"                                        
echo ""

Fold="QSM_ROI_Stats"

cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

#Check if required files are present

if [ ! -f "${Subj}_QSM_Mag_FSL.nii.gz" ]; then
	
	echo -e "\e[31m----------------------------------------------"	
	echo "ERROR: ${Subj}_QSM_Mag_FSL.nii.gz NOT FOUND! "
	echo -e "----------------------------------------------\e[0m"	
	exit 5
fi

echo ""
echo "Creating outside-the-head MASK for ${Subj}_QSM_Mag_FSL.nii.gz"
echo "This MASK will be used to extract the StdDeV of the QSM Magnitude signal outside the head"	
echo ""

singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	mri_concat ${Subj}_QSM_Mag_FSL.nii.gz --o ${Subj}_QSM_Mag_FSL_rms.nii.gz --rms


singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dAutomask -prefix ${Subj}_QSM_Mag_FSL_rms_IH_Mask.nii.gz -clfrac 0.2 -dilate 2 ${Subj}_QSM_Mag_FSL_rms.nii.gz


singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dcalc -a ${Subj}_QSM_Mag_FSL_rms_IH_Mask.nii.gz -expr 'iszero(a)*ispositive(z-0.167)' -prefix ${Subj}_QSM_Mag_FSL_rms_OH_Mask.nii.gz

echo ""
echo "Extracting StdDeV from outside-the-head MASK for ${Subj}... "
echo ""

unset SD

SD=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	fslstats ${Subj}_QSM_Mag_FSL_rms.nii.gz -k ${Subj}_QSM_Mag_FSL_rms_OH_Mask.nii.gz -s)

	
echo "---------------------------------------------------------------"	
echo "*** Extracting QSM SNR values from cortical/subcortical aligned/resampled freesurfer masks ***"
echo "---------------------------------------------------------------"	
echo ""


if [ -f "$OutFolder/Group/$Fold/CueSNR.txt" ]; then

	####1) Check for prior failure since CueSNR.txt exists in folder#####

	#Start/update LifeLine
	echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

	unset LifeLine
	LifeLine=$(cat $OutFolder/Group/$Fold/LifeLineSNR.txt)

	sleep 6 #Allow time for LifeLineSNR.txt to update if controlled by another Ironsmith instance

	if [[ $LifeLine == $(cat $OutFolder/Group/$Fold/LifeLineSNR.txt) ]]; then
 
		#LifeLine is not updating, Ironsmith has crashed recently and folder needs to be fixed
		echo ""
		echo -e "\e[93m----------------------------------------------"	
		echo "WARNING: Past Ironsmith failure/crash detected in $Fold for participant: $(cat $OutFolder/Group/$Fold/CueSNR.txt)"
		echo ""	
		echo "Initiating recovery procedure! DAMAGED SNR entries for participant: $(cat $OutFolder/Group/$Fold/CueSNR.txt) will be removed from Group! "
		echo -e "----------------------------------------------\e[0m"	
		echo ""

		#####Fix Failure####

		cd $OutFolder/Group/$Fold

		echo ""
		echo "Checking file consistency..."
		echo ""

		if [ -f "SubjectsSNR.txt" ]; then

			FileList=($(find . -maxdepth 1 -name "*_SNR*" -type f | awk -F'/' '{print $2}'))
			SubjectLines=$(wc -l SubjectsSNR.txt | awk '{print $1}')

			for i in ${FileList[@]} 
			do 
				FileLines=$(wc -l $i | awk '{print $1}')
			
				if [[ $FileLines > $SubjectLines ]]; then
		
					#echo ""
					echo "Inconsistency in $OutFolder/Group/$Fold/$i, Fixing..."
					#echo "" 			
				

					while [[ $FileLines > $SubjectLines ]]
					do
						sed -i '$d' $i
						FileLines=$(wc -l $i | awk '{print $1}')
					done
				
				elif [[ $FileLines < $SubjectLines ]]; then

					echo ""		
					echo -e "\e[31m----------------------------------------------"
					echo "ERROR: $OutFolder/Group is completely corrupt and beyond repair! "
					echo "Please manually delete $OutFolder/Group and start over"
					echo -e "----------------------------------------------\e[0m"
					echo ""	
					exit 20
				fi

				unset FileLines
		
			done
	
			echo ""
			echo "File consistency check complete! "
			echo ""

			unset FileList SubjectLines

		else
	
			echo ""
			echo "Previous run/s failed miserably! Cleaning $OutFolder/Group/$Fold... "
			echo ""

			find . -maxdepth 1 -name "*_SNR*" -type f -delete

			echo ""
			echo "File consistency check complete! "
			echo ""

		fi


		#rm $OutFolder/Group/$Fold/CueSNR.txt
		echo "$Subj" > $OutFolder/Group/$Fold/CueSNR.txt		

	else
		#All good, folder just occupied by another instance of ironsmith

		echo ""
		echo "$OutFolder/Group/$Fold" 
		echo "is currently occupied by another instance of Ironsmith! "
		#echo "Waiting for $(cat $OutFolder/Group/$Fold/CueSNR.txt) to finish processing... "
		echo ""
		echo -e "\t\t ((     ___	" 
		echo -e "\t\t  ))  \___/_ 	"
		echo -e "\t\t |~~| /~~~\ \	"
		echo -e "\t\tC|__| \___/	"
		echo ""
		echo ""	
	
		while [ -f $OutFolder/Group/$Fold/CueSNR.txt ]
	
		do
			 		
			echo -ne "Waiting for $(cat $OutFolder/Group/$Fold/CueSNR.txt) to finish processing...\\r"
			sleep $(( $RANDOM % 9 + 2 ))
			
		done

		echo "$Subj" > $OutFolder/Group/$Fold/CueSNR.txt	
		
		echo ""
		echo ""
		echo "The wait is over, rejoice! "
		echo ""	

	fi

	unset LifeLine
	
elif [ ! -f "$OutFolder/Group/$Fold/CueSNR.txt" ]; then

	echo "$Subj" > $OutFolder/Group/$Fold/CueSNR.txt
fi

set +e #Turn OFF exit on error

cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

unset Eval Mean SNR

#Cortical 

#BILATERAL

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt	

echo "LR_Frontal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Frontal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Parietal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Parietal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Occipital_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Occipital_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Temporal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Temporal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

#LEFT HEMISPHERE

#echo "L_BanksSTS_GM	(Mask does not exist at the moment)"

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

#Mean=$(echo "${Eval:-FAIL}") 

#

#


#
#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

#echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_BanksSTS_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

#unset Eval Mean SNR

echo "L_CaudalAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_CaudalAnteriorCingulate_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_CaudalMiddleFrontal_GM"

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_CaudalMiddleFrontal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Cuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Cuneus_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_DLPFC_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_DLPFC_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Entorhinal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Entorhinal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Frontal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Frontal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Fusiform_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Fusiform_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_InferiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_InferiorParietal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_InferiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_InferiorTemporal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Insula_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Insula_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_IsthmusCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_IsthmusCingulate_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_LateralOccipital_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_LateralOccipital_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_LateralOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_LateralOrbitofrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Lingual_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Lingual_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_MedialOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_MedialOrbitofrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_MiddleTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_MiddleTemporal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Occipital_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Occipital_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "L_Parietal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Parietal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Temporal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Temporal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Parahippocampal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Parahippocampal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Pericalcarine_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Pericalcarine_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Postcentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Postcentral_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_PosteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_PosteriorCingulate_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Precentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Precentral_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Precuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Precuneus_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_RostalMiddleFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_RostalMiddleFrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "L_RostralAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_RostralAnteriorCingulate_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_SuperiorFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_SuperiorFrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_SuperiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_SuperiorParietal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_SuperiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_SuperiorTemporal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_TransverseTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_TransverseTemporal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

#RIGHT HEMISPHERE

#echo "R_BanksSTS_GM (Mask does not exist at the moment)"

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

#Mean=$(echo "${Eval:-FAIL}") 

#

#


#
#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

#echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_BanksSTS_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

#unset Eval Mean SNR

echo "R_CaudalAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_CaudalAnteriorCingulate_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_CaudalMiddleFrontal_GM"

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_CaudalMiddleFrontal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Cuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Cuneus_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_DLPFC_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_DLPFC_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Entorhinal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Entorhinal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Frontal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Frontal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Fusiform_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Fusiform_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_InferiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_InferiorParietal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_InferiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_InferiorTemporal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Insula_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Insula_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_IsthmusCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_IsthmusCingulate_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_LateralOccipital_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_LateralOccipital_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_LateralOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_LateralOrbitofrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Lingual_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Lingual_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_MedialOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_MedialOrbitofrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_MiddleTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_MiddleTemporal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Occipital_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Occipital_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "R_Parietal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Parietal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Temporal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Temporal_GM_Mask_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Parahippocampal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Parahippocampal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Pericalcarine_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Pericalcarine_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Postcentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Postcentral_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_PosteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_PosteriorCingulate_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Precentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Precentral_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Precuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Precuneus_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_RostalMiddleFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_RostalMiddleFrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "R_RostralAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_RostralAnteriorCingulate_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_SuperiorFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_SuperiorFrontal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_SuperiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_SuperiorParietal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_SuperiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_SuperiorTemporal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_TransverseTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_TransverseTemporal_GM_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


#Subcortical Masks

#BILATERAL


echo "LR_Accumbens_area"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Accumbens_area_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Amygdala"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Amygdala_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Caudate"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Caudate_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Hipp"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Hipp_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "LR_Pallidum"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Pallidum_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Putamen"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Putamen_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "LR_Thalamus_Proper"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_LR_Thalamus_Proper_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


#Subcortical LEFT HEMISPHERE


echo "L_Accumbens_area"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Accumbens_area_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Amygdala"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Amygdala_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Caudate"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Caudate_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Hipp"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Hipp_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "L_Pallidum"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Pallidum_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Putamen"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Putamen_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "L_Thalamus_Proper"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_L_Thalamus_Proper_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

#Subcortical ROIs RIGHT HEMISPHERE


echo "R_Accumbens_area"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Accumbens_area_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Amygdala"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Amygdala_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Caudate"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Caudate_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Hipp"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Hipp_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR


echo "R_Pallidum"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Pallidum_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Putamen"

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Putamen_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "R_Thalamus_Proper"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${Subj}_QSM_Mag_FSL_rms.nii.gz) 

Mean=$(echo "${Eval:-FAIL}") 

SNR=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; ($Mean / $SD)*0.655 " | bc -l) 

echo "${SNR:-FAIL}" >> $OutFolder/Group/$Fold/Group_R_Thalamus_Proper_SNR.txt

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt

unset Eval Mean SNR

echo "$Subj" >> $OutFolder/Group/$Fold/SubjectsSNR.txt
echo "$Rows" >> $OutFolder/Group/$Fold/SubjOrderSNR.txt

cd $OutFolder/Group/$Fold

#List of files that should exist under $Fold

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt	

QSMSNRFileList="Group_LR_Frontal_GM_Mask_SNR.txt Group_L_DLPFC_GM_Mask_SNR.txt Group_L_InferiorTemporal_GM_Mask_SNR.txt Group_L_MedialOrbitofrontal_GM_SNR.txt Group_L_MiddleTemporal_GM_SNR.txt Group_L_Parietal_GM_Mask_SNR.txt Group_R_Postcentral_GM_SNR.txt Group_R_Precentral_GM_SNR.txt Group_R_Precuneus_GM_SNR.txt Group_R_RostralAnteriorCingulate_GM_SNR.txt Group_R_SuperiorParietal_GM_SNR.txt Group_LR_Accumbens_area_SNR.txt Group_LR_Thalamus_Proper_SNR.txt Group_L_Pallidum_SNR.txt Group_L_Putamen_SNR.txt Group_R_Accumbens_area_SNR.txt Group_R_Amygdala_SNR.txt Group_R_Caudate_SNR.txt Group_R_Putamen_SNR.txt Group_LR_Temporal_GM_Mask_SNR.txt Group_L_RostalMiddleFrontal_GM_SNR.txt Group_R_CaudalAnteriorCingulate_GM_Mask_SNR.txt Group_R_Cuneus_GM_Mask_SNR.txt Group_R_Fusiform_GM_Mask_SNR.txt Group_R_IsthmusCingulate_GM_SNR.txt Group_R_LateralOccipital_GM_SNR.txt Group_R_Occipital_GM_Mask_SNR.txt Group_LR_Amygdala_SNR.txt Group_L_Accumbens_area_SNR.txt Group_R_Pallidum_SNR.txt Group_L_CaudalAnteriorCingulate_GM_Mask_SNR.txt Group_L_Cuneus_GM_Mask_SNR.txt Group_L_IsthmusCingulate_GM_SNR.txt Group_L_LateralOccipital_GM_SNR.txt Group_L_Temporal_GM_Mask_SNR.txt Group_L_SuperiorFrontal_GM_SNR.txt Group_R_Entorhinal_GM_Mask_SNR.txt Group_R_Lingual_GM_SNR.txt Group_R_PosteriorCingulate_GM_SNR.txt Group_R_SuperiorFrontal_GM_SNR.txt Group_R_TransverseTemporal_GM_SNR.txt Group_LR_Putamen_SNR.txt Group_L_Amygdala_SNR.txt Group_L_Caudate_SNR.txt Group_L_Hipp_SNR.txt Group_L_CaudalMiddleFrontal_GM_Mask_SNR.txt Group_L_Entorhinal_GM_Mask_SNR.txt Group_L_InferiorParietal_GM_Mask_SNR.txt Group_L_Occipital_GM_Mask_SNR.txt Group_L_Parahippocampal_GM_SNR.txt Group_L_Precentral_GM_SNR.txt Group_L_SuperiorParietal_GM_SNR.txt Group_L_SuperiorTemporal_GM_SNR.txt Group_R_DLPFC_GM_Mask_SNR.txt Group_R_InferiorTemporal_GM_Mask_SNR.txt Group_R_Insula_GM_SNR.txt Group_R_MedialOrbitofrontal_GM_SNR.txt Group_R_Temporal_GM_Mask_SNR.txt Group_R_Parahippocampal_GM_SNR.txt Group_R_Pericalcarine_GM_SNR.txt Group_R_RostalMiddleFrontal_GM_SNR.txt Group_R_SuperiorTemporal_GM_SNR.txt Group_LR_Caudate_SNR.txt Group_LR_Pallidum_SNR.txt Group_L_Thalamus_Proper_SNR.txt Group_R_Hipp_SNR.txt Group_R_Thalamus_Proper_SNR.txt Group_LR_Parietal_GM_Mask_SNR.txt Group_LR_Occipital_GM_Mask_SNR.txt Group_L_LateralOrbitofrontal_GM_SNR.txt Group_L_Lingual_GM_SNR.txt Group_L_Pericalcarine_GM_SNR.txt Group_L_Postcentral_GM_SNR.txt Group_L_PosteriorCingulate_GM_SNR.txt Group_L_RostralAnteriorCingulate_GM_SNR.txt Group_R_Frontal_GM_Mask_SNR.txt Group_R_InferiorParietal_GM_Mask_SNR.txt Group_R_LateralOrbitofrontal_GM_SNR.txt Group_R_MiddleTemporal_GM_SNR.txt Group_L_Frontal_GM_Mask_SNR.txt Group_L_Fusiform_GM_Mask_SNR.txt Group_L_Insula_GM_SNR.txt Group_L_Precuneus_GM_SNR.txt Group_L_TransverseTemporal_GM_SNR.txt Group_R_CaudalMiddleFrontal_GM_Mask_SNR.txt Group_R_Parietal_GM_Mask_SNR.txt Group_LR_Hipp_SNR.txt SubjOrderSNR.txt SubjectsSNR.txt"

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt	

for i in $QSMSNRFileList; do ! test -f "$i" && echo "*FAIL*" >> $i && echo "$i NOT FOUND"; done

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt	

unset QSMSNRFileList


paste -d "," SubjOrderSNR.txt SubjectsSNR.txt \
	Group_L_Accumbens_area_SNR.txt \
	Group_L_Amygdala_SNR.txt \
	Group_L_CaudalAnteriorCingulate_GM_Mask_SNR.txt \
	Group_L_CaudalMiddleFrontal_GM_Mask_SNR.txt \
	Group_L_Caudate_SNR.txt \
	Group_L_Cuneus_GM_Mask_SNR.txt \
	Group_L_DLPFC_GM_Mask_SNR.txt \
	Group_L_Entorhinal_GM_Mask_SNR.txt \
	Group_L_Frontal_GM_Mask_SNR.txt \
	Group_L_Fusiform_GM_Mask_SNR.txt \
	Group_L_Hipp_SNR.txt \
	Group_L_InferiorParietal_GM_Mask_SNR.txt \
	Group_L_InferiorTemporal_GM_Mask_SNR.txt \
	Group_L_Insula_GM_SNR.txt \
	Group_L_IsthmusCingulate_GM_SNR.txt \
	Group_L_LateralOccipital_GM_SNR.txt \
	Group_L_LateralOrbitofrontal_GM_SNR.txt \
	Group_L_Lingual_GM_SNR.txt \
	Group_L_MedialOrbitofrontal_GM_SNR.txt \
	Group_L_MiddleTemporal_GM_SNR.txt \
	Group_L_Occipital_GM_Mask_SNR.txt \
	Group_L_Pallidum_SNR.txt \
	Group_L_Parahippocampal_GM_SNR.txt \
	Group_L_Parietal_GM_Mask_SNR.txt \
	Group_L_Pericalcarine_GM_SNR.txt \
	Group_L_Postcentral_GM_SNR.txt \
	Group_L_PosteriorCingulate_GM_SNR.txt \
	Group_L_Precentral_GM_SNR.txt \
	Group_L_Precuneus_GM_SNR.txt \
	Group_L_Putamen_SNR.txt \
	Group_L_RostalMiddleFrontal_GM_SNR.txt \
	Group_L_RostralAnteriorCingulate_GM_SNR.txt \
	Group_L_SuperiorFrontal_GM_SNR.txt \
	Group_L_SuperiorParietal_GM_SNR.txt \
	Group_L_SuperiorTemporal_GM_SNR.txt \
	Group_L_Temporal_GM_Mask_SNR.txt \
	Group_L_Thalamus_Proper_SNR.txt \
	Group_L_TransverseTemporal_GM_SNR.txt \
	Group_R_Accumbens_area_SNR.txt \
	Group_R_Amygdala_SNR.txt \
	Group_R_CaudalAnteriorCingulate_GM_Mask_SNR.txt \
	Group_R_CaudalMiddleFrontal_GM_Mask_SNR.txt \
	Group_R_Caudate_SNR.txt \
	Group_R_Cuneus_GM_Mask_SNR.txt \
	Group_R_DLPFC_GM_Mask_SNR.txt \
	Group_R_Entorhinal_GM_Mask_SNR.txt \
	Group_R_Frontal_GM_Mask_SNR.txt \
	Group_R_Fusiform_GM_Mask_SNR.txt \
	Group_R_Hipp_SNR.txt \
	Group_R_InferiorParietal_GM_Mask_SNR.txt \
	Group_R_InferiorTemporal_GM_Mask_SNR.txt \
	Group_R_Insula_GM_SNR.txt \
	Group_R_IsthmusCingulate_GM_SNR.txt \
	Group_R_LateralOccipital_GM_SNR.txt \
	Group_R_LateralOrbitofrontal_GM_SNR.txt \
	Group_R_Lingual_GM_SNR.txt \
	Group_R_MedialOrbitofrontal_GM_SNR.txt \
	Group_R_MiddleTemporal_GM_SNR.txt \
	Group_R_Occipital_GM_Mask_SNR.txt \
	Group_R_Pallidum_SNR.txt \
	Group_R_Parahippocampal_GM_SNR.txt \
	Group_R_Parietal_GM_Mask_SNR.txt \
	Group_R_Pericalcarine_GM_SNR.txt \
	Group_R_Postcentral_GM_SNR.txt \
	Group_R_PosteriorCingulate_GM_SNR.txt \
	Group_R_Precentral_GM_SNR.txt \
	Group_R_Precuneus_GM_SNR.txt \
	Group_R_Putamen_SNR.txt \
	Group_R_RostalMiddleFrontal_GM_SNR.txt \
	Group_R_RostralAnteriorCingulate_GM_SNR.txt \
	Group_R_SuperiorFrontal_GM_SNR.txt \
	Group_R_SuperiorParietal_GM_SNR.txt \
	Group_R_SuperiorTemporal_GM_SNR.txt \
	Group_R_Temporal_GM_Mask_SNR.txt \
	Group_R_Thalamus_Proper_SNR.txt \
	Group_R_TransverseTemporal_GM_SNR.txt \
	Group_LR_Accumbens_area_SNR.txt \
	Group_LR_Amygdala_SNR.txt \
	Group_LR_Caudate_SNR.txt \
	Group_LR_Frontal_GM_Mask_SNR.txt \
	Group_LR_Hipp_SNR.txt \
	Group_LR_Occipital_GM_Mask_SNR.txt \
	Group_LR_Pallidum_SNR.txt \
	Group_LR_Parietal_GM_Mask_SNR.txt \
	Group_LR_Putamen_SNR.txt \
	Group_LR_Temporal_GM_Mask_SNR.txt \
	Group_LR_Thalamus_Proper_SNR.txt | pr -t > Group_QSM_SNR_Columns.csv

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt	


echo "Number,Participant,L_Accumbens_area,L_Amygdala,L_CaudalAnteriorCingulate,L_CaudalMiddleFrontal,L_Caudate,L_Cuneus,L_DLPFC,L_Entorhinal,L_Frontal,L_Fusiform,L_Hipp,L_InferiorParietal,L_InferiorTemporal,L_Insula,L_IsthmusCingulate,L_LateralOccipital,L_LateralOrbitofrontal,L_Lingual,L_MedialOrbitofrontal,L_MiddleTemporal,L_Occipital,L_Pallidum,L_Parahippocampal,L_Parietal,L_Pericalcarine,L_Postcentral,L_PosteriorCingulate,L_Precentral,L_Precuneus,L_Putamen,L_RostalMiddleFrontal,L_RostralAnteriorCingulate,L_SuperiorFrontal,L_SuperiorParietal,L_SuperiorTemporal,L_Temporal,L_Thalamus_Proper,L_TransverseTemporal,R_Accumbens_area,R_Amygdala,R_CaudalAnteriorCingulate,R_CaudalMiddleFrontal,R_Caudate,R_Cuneus,R_DLPFC,R_Entorhinal,R_Frontal,R_Fusiform,R_Hipp,R_InferiorParietal,R_InferiorTemporal,R_Insula,R_IsthmusCingulate,R_LateralOccipital,R_LateralOrbitofrontal,R_Lingual,R_MedialOrbitofrontal,R_MiddleTemporal,R_Occipital,R_Pallidum,R_Parahippocampal,R_Parietal,R_Pericalcarine,R_Postcentral,R_PosteriorCingulate,R_Precentral,R_Precuneus,R_Putamen,R_RostalMiddleFrontal,R_RostralAnteriorCingulate,R_SuperiorFrontal,R_SuperiorParietal,R_SuperiorTemporal,R_Temporal,R_Thalamus_Proper,R_TransverseTemporal,LR_Accumbens_area,LR_Amygdala,LR_Caudate,LR_Frontal,LR_Hipp,LR_Occipital,LR_Pallidum,LR_Parietal,LR_Putamen,LR_Temporal,LR_Thalamus_Proper" > $OutFolder/Group/Group_QSM_SNR.csv

cat Group_QSM_SNR_Columns.csv >> $OutFolder/Group/Group_QSM_SNR.csv

singularity run -e --bind $OutFolder/Group:/mnt $Path/Functions/QSM_Container.simg \
	sort -k1 -n /mnt/Group_QSM_SNR.csv -o /mnt/Group_QSM_SNR.csv

#Update LifeLineSNR.txt
echo "$RANDOM" > $OutFolder/Group/$Fold/LifeLineSNR.txt


set -e #Turn ON exit on error

rm $OutFolder/Group/$Fold/CueSNR.txt

echo ""	
echo "---------------------------------------------------------------"	
echo "06_QSM_SNR.sh script finished running succesfully on `date`"
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
