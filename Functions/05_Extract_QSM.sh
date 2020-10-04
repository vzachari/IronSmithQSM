#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 09/9/2020
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

#Passed varialbes to 05_Extract_QSM.sh 
#1) Subject
#2) Output folder
#3) Path
#4) MEDI Flag

#Subj="S1032"
#OutFolder="/home/data3/vzachari/QSM_Toolkit/QSM_Test_Run"
#Path="/home/data3/vzachari/QSM_Toolkit/QSM_Std_Scripts"
#MEDIFlag="MEDI_Yes"

Subj=$1
OutFolder=$2
Path=$3
MEDIFlag=$4

log_file=$(echo "$OutFolder/$Subj/LogFiles/$Subj.Output.05.Extract.QSM.txt")
exec &> >(tee -a "$log_file")

#Font = modular
echo ""
echo "---------------------------------------------------------------"
echo " _______  _______  __   __    "                                                                                          
echo "|       ||       ||  |_|  |   "                                                                                          
echo "|   _   ||  _____||       |   "                                                                                          
echo "|  | |  || |_____ |       |   "                                                                                          
echo "|  |_|  ||_____  ||       |   "                                                                                          
echo "|      |  _____| || ||_|| |   "                                                                                          
echo "|____||_||_______||_|   |_|   "                                                                                          
echo " _______  __   __  _______  ______    _______  _______  _______    __   __  _______  ___      __   __  _______  _______ "
echo "|       ||  |_|  ||       ||    _ |  |   _   ||       ||       |  |  | |  ||   _   ||   |    |  | |  ||       ||       |"
echo "|    ___||       ||_     _||   | ||  |  |_|  ||       ||_     _|  |  |_|  ||  |_|  ||   |    |  | |  ||    ___||  _____|"
echo "|   |___ |       |  |   |  |   |_||_ |       ||       |  |   |    |       ||       ||   |    |  |_|  ||   |___ | |_____ "
echo "|    ___| |     |   |   |  |    __  ||       ||      _|  |   |    |       ||       ||   |___ |       ||    ___||_____  |"
echo "|   |___ |   _   |  |   |  |   |  | ||   _   ||     |_   |   |     |     | |   _   ||       ||       ||   |___  _____| |"
echo "|_______||__| |__|  |___|  |___|  |_||__| |__||_______|  |___|      |___|  |__| |__||_______||_______||_______||_______|"
echo ""
echo "---------------------------------------------------------------"                                        
echo ""

LoopCounter=0
StatsFolder=""
MasterQSM=""
OutStatFile=""
OutStatFileADJ=""

if [[ $MEDIFlag == "MEDI_Yes" ]]; then
	
	cd $OutFolder

	if [ ! -d "Group" ]; then
		
		echo ""		
		echo "Creating Group folder in $OutFolder"
		echo ""	

		mkdir Group
		cd Group

	elif [ -d "Group" ]; then

		echo ""		
		echo "Group folder already exists in $OutFolder"		
		echo ""	

		cd Group

	fi

	
	if [ ! -d "QSM_ROI_Stats" ]; then
	
		mkdir QSM_ROI_Stats
	fi

	if [ ! -d "QSM_ROI_Stats_CSF_Ref" ]; then
	
		mkdir QSM_ROI_Stats_CSF_Ref
	fi

	if [ ! -d "QSM_ROI_Stats_WM_Ref" ]; then
	
		mkdir QSM_ROI_Stats_WM_Ref
	fi
	

	cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

	if [ ! -f "$OutFolder/$Subj/QSM/${Subj}_QSM_Map_New_CSF.nii.gz" ]; then 

		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: $OutFolder/$Subj/QSM/${Subj}_QSM_Map_New_CSF.nii.gz NOT FOUND! "
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	
	else 
		echo ""
		cp $OutFolder/$Subj/QSM/${Subj}_QSM_Map_New_CSF.nii.gz .
		
	fi

	if [ ! -f "$OutFolder/$Subj/QSM/${Subj}_QSM_Map_New_WM.nii.gz" ]; then 

		echo ""		
		echo -e "\e[31m----------------------------------------------"
		echo "ERROR: $OutFolder/$Subj/QSM/${Subj}_QSM_Map_New_WM.nii.gz NOT FOUND! "
		echo -e "----------------------------------------------\e[0m"
		echo ""		
		exit 5
	
	else 
		echo ""
		cp $OutFolder/$Subj/QSM/${Subj}_QSM_Map_New_WM.nii.gz .
		
	fi

	#Re-orients QSM_Map and QSM_Mag image to FSL standard view
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		fslreorient2std ${Subj}_QSM_Map_New_CSF.nii.gz ${Subj}_QSM_Map_New_CSF_FSL.nii.gz
	
	singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
		fslreorient2std ${Subj}_QSM_Map_New_WM.nii.gz ${Subj}_QSM_Map_New_WM_FSL.nii.gz

	StatsFolder=(QSM_ROI_Stats QSM_ROI_Stats_CSF_Ref QSM_ROI_Stats_WM_Ref)
	OutStatFile=(Group_QSM_Mean.csv Group_QSM_Mean_CSF.csv Group_QSM_Mean_WM.csv)
	OutStatFileADJ=(Group_QSM_ADJ_Mean.csv Group_QSM_ADJ_Mean_CSF.csv Group_QSM_ADJ_Mean_WM.csv)

	MasterQSM=(${Subj}_QSM_Map_FSL.nii.gz ${Subj}_QSM_Map_New_CSF_FSL.nii.gz ${Subj}_QSM_Map_New_WM_FSL.nii.gz)


elif [[ $MEDIFlag == "MEDI_No" ]]; then
	
	cd $OutFolder

	if [ ! -d "Group" ]; then
		
		echo ""		
		echo "Creating Group folder in $OutFolder"
		echo ""	

		mkdir Group
		cd Group
		

	elif [ -d "Group" ]; then

		echo ""		
		echo "Group folder already exists in $OutFolder"		
		echo ""	

		cd Group

	fi
	

	if [ ! -d "QSM_ROI_Stats" ]; then
	
		mkdir QSM_ROI_Stats
	fi

	#cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks
	
	StatsFolder=(QSM_ROI_Stats)	
	MasterQSM=(${Subj}_QSM_Map_FSL.nii.gz)
	OutStatFile=(Group_QSM_Mean.csv)
	OutStatFileADJ=(Group_QSM_ADJ_Mean.csv)

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
echo "*** Extractsing QSM values from cortical/subcortical aligned/resampled freesurfer masks ***"
echo "---------------------------------------------------------------"	
echo ""

for Fold in ${StatsFolder[@]}

do

echo ""
echo "Processing: ${MasterQSM[$LoopCounter]}"
echo "---------------------------------------------------------------"
echo ""	

cd $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks

#echo "LoopCounter is: $LoopCounter"

Sum=0
ROISize=0

#Cortical 

#BILATERAL

echo "LR_Frontal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Frontal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Frontal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Frontal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Frontal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "LR_Parietal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Parietal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Parietal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Parietal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Parietal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "LR_Occipital_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Occipital_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Occipital_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Occipital_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Occipital_GM_Mask_ADJ.txt

unset ROISize Sum

echo "LR_Temporal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Temporal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Temporal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Temporal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Temporal_GM_Mask_ADJ.txt

unset ROISize Sum

#LEFT HEMISPHERE

#echo "L_BanksSTS_GM	(Mask does not exist at the moment)"

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]}) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_BanksSTS_GM_Mask_Mean.txt

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]}) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_BanksSTS_GM_Mask_Sum.txt

#Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]})

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]}) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_BanksSTS_GM_Mask_Count.txt


#ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]})

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	echo "scale=2; $Sum / $ROISize " | bc -l) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_BanksSTS_GM_Mask_ADJ.txt

#unset ROISize Sum

echo "L_CaudalAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalAnteriorCingulate_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalAnteriorCingulate_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalAnteriorCingulate_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalAnteriorCingulate_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_CaudalMiddleFrontal_GM"

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalMiddleFrontal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalMiddleFrontal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalMiddleFrontal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_CaudalMiddleFrontal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Cuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Cuneus_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Cuneus_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Cuneus_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Cuneus_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_DLPFC_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_DLPFC_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_DLPFC_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_DLPFC_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_DLPFC_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Entorhinal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Entorhinal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Entorhinal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Entorhinal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Entorhinal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Frontal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Frontal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Frontal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Frontal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Frontal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Fusiform_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Fusiform_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Fusiform_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Fusiform_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Fusiform_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_InferiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorParietal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorParietal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorParietal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorParietal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_InferiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorTemporal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorTemporal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorTemporal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_InferiorTemporal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Insula_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Insula_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Insula_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Insula_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Insula_GM_ADJ.txt

unset ROISize Sum

echo "L_IsthmusCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_IsthmusCingulate_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_IsthmusCingulate_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_IsthmusCingulate_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_IsthmusCingulate_GM_ADJ.txt

unset ROISize Sum

echo "L_LateralOccipital_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOccipital_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOccipital_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOccipital_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOccipital_GM_ADJ.txt

unset ROISize Sum

echo "L_LateralOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOrbitofrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOrbitofrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOrbitofrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_LateralOrbitofrontal_GM_ADJ.txt

unset ROISize Sum

echo "L_Lingual_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Lingual_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Lingual_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Lingual_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Lingual_GM_ADJ.txt

unset ROISize Sum

echo "L_MedialOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MedialOrbitofrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MedialOrbitofrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MedialOrbitofrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MedialOrbitofrontal_GM_ADJ.txt

unset ROISize Sum

echo "L_MiddleTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MiddleTemporal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MiddleTemporal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MiddleTemporal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_MiddleTemporal_GM_ADJ.txt

unset ROISize Sum

echo "L_Occipital_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Occipital_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Occipital_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Occipital_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Occipital_GM_Mask_ADJ.txt

unset ROISize Sum


echo "L_Parietal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parietal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parietal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parietal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parietal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Temporal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Temporal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Temporal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Temporal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Temporal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "L_Parahippocampal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parahippocampal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parahippocampal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parahippocampal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Parahippocampal_GM_ADJ.txt

unset ROISize Sum

echo "L_Pericalcarine_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pericalcarine_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pericalcarine_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pericalcarine_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pericalcarine_GM_ADJ.txt

unset ROISize Sum

echo "L_Postcentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Postcentral_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Postcentral_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Postcentral_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Postcentral_GM_ADJ.txt

unset ROISize Sum

echo "L_PosteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_PosteriorCingulate_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_PosteriorCingulate_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_PosteriorCingulate_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_PosteriorCingulate_GM_ADJ.txt

unset ROISize Sum

echo "L_Precentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precentral_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precentral_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precentral_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precentral_GM_ADJ.txt

unset ROISize Sum

echo "L_Precuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precuneus_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precuneus_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precuneus_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Precuneus_GM_ADJ.txt

unset ROISize Sum

echo "L_RostalMiddleFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostalMiddleFrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostalMiddleFrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostalMiddleFrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostalMiddleFrontal_GM_ADJ.txt

unset ROISize Sum


echo "L_RostralAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostralAnteriorCingulate_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostralAnteriorCingulate_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostralAnteriorCingulate_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_RostralAnteriorCingulate_GM_ADJ.txt

unset ROISize Sum

echo "L_SuperiorFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorFrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorFrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorFrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorFrontal_GM_ADJ.txt

unset ROISize Sum

echo "L_SuperiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorParietal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorParietal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorParietal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorParietal_GM_ADJ.txt

unset ROISize Sum

echo "L_SuperiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorTemporal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorTemporal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorTemporal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_SuperiorTemporal_GM_ADJ.txt

unset ROISize Sum

echo "L_TransverseTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_TransverseTemporal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_TransverseTemporal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_TransverseTemporal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_TransverseTemporal_GM_ADJ.txt

unset ROISize Sum

#RIGHT HEMISPHERE

#echo "R_BanksSTS_GM (Mask does not exist at the moment)"

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]}) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_BanksSTS_GM_Mask_Mean.txt

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]}) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_BanksSTS_GM_Mask_Sum.txt

#Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]})

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]}) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_BanksSTS_GM_Mask_Count.txt


#ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_BanksSTS_GM_AL_QSM_RS_Erx1.nii.gz \
#	${MasterQSM[$LoopCounter]})

#Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
#	echo "scale=2; $Sum / $ROISize " | bc -l) 

#echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_BanksSTS_GM_Mask_ADJ.txt

#unset ROISize Sum

echo "R_CaudalAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalAnteriorCingulate_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalAnteriorCingulate_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalAnteriorCingulate_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalAnteriorCingulate_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_CaudalMiddleFrontal_GM"

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalMiddleFrontal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalMiddleFrontal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalMiddleFrontal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_CaudalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_CaudalMiddleFrontal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Cuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Cuneus_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Cuneus_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Cuneus_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Cuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Cuneus_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_DLPFC_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_DLPFC_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_DLPFC_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_DLPFC_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_DLPFC_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_DLPFC_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Entorhinal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Entorhinal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Entorhinal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Entorhinal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Entorhinal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Entorhinal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Frontal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Frontal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Frontal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Frontal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Frontal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Frontal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Fusiform_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Fusiform_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Fusiform_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Fusiform_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Fusiform_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Fusiform_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_InferiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorParietal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorParietal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorParietal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorParietal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_InferiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorTemporal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorTemporal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorTemporal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_InferiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_InferiorTemporal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Insula_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Insula_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Insula_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Insula_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Insula_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Insula_GM_ADJ.txt

unset ROISize Sum

echo "R_IsthmusCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_IsthmusCingulate_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_IsthmusCingulate_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_IsthmusCingulate_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_IsthmusCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_IsthmusCingulate_GM_ADJ.txt

unset ROISize Sum

echo "R_LateralOccipital_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOccipital_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOccipital_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOccipital_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOccipital_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOccipital_GM_ADJ.txt

unset ROISize Sum

echo "R_LateralOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOrbitofrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOrbitofrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOrbitofrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_LateralOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_LateralOrbitofrontal_GM_ADJ.txt

unset ROISize Sum

echo "R_Lingual_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Lingual_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Lingual_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Lingual_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Lingual_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Lingual_GM_ADJ.txt

unset ROISize Sum

echo "R_MedialOrbitofrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MedialOrbitofrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MedialOrbitofrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MedialOrbitofrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MedialOrbitofrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MedialOrbitofrontal_GM_ADJ.txt

unset ROISize Sum

echo "R_MiddleTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MiddleTemporal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MiddleTemporal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MiddleTemporal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_MiddleTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_MiddleTemporal_GM_ADJ.txt

unset ROISize Sum

echo "R_Occipital_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Occipital_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Occipital_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Occipital_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Occipital_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Occipital_GM_Mask_ADJ.txt

unset ROISize Sum


echo "R_Parietal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parietal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parietal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parietal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parietal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parietal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Temporal_GM_Mask"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Temporal_GM_Mask_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Temporal_GM_Mask_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Temporal_GM_Mask_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Temporal_GM_Mask_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Temporal_GM_Mask_ADJ.txt

unset ROISize Sum

echo "R_Parahippocampal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parahippocampal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parahippocampal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parahippocampal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Parahippocampal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Parahippocampal_GM_ADJ.txt

unset ROISize Sum

echo "R_Pericalcarine_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pericalcarine_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pericalcarine_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pericalcarine_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pericalcarine_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pericalcarine_GM_ADJ.txt

unset ROISize Sum

echo "R_Postcentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Postcentral_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Postcentral_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Postcentral_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Postcentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Postcentral_GM_ADJ.txt

unset ROISize Sum

echo "R_PosteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_PosteriorCingulate_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_PosteriorCingulate_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_PosteriorCingulate_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_PosteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_PosteriorCingulate_GM_ADJ.txt

unset ROISize Sum

echo "R_Precentral_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precentral_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precentral_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precentral_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precentral_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precentral_GM_ADJ.txt

unset ROISize Sum

echo "R_Precuneus_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precuneus_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precuneus_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precuneus_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Precuneus_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Precuneus_GM_ADJ.txt

unset ROISize Sum

echo "R_RostalMiddleFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostalMiddleFrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostalMiddleFrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostalMiddleFrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostalMiddleFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostalMiddleFrontal_GM_ADJ.txt

unset ROISize Sum


echo "R_RostralAnteriorCingulate_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostralAnteriorCingulate_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostralAnteriorCingulate_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostralAnteriorCingulate_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_RostralAnteriorCingulate_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_RostralAnteriorCingulate_GM_ADJ.txt

unset ROISize Sum

echo "R_SuperiorFrontal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorFrontal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorFrontal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorFrontal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorFrontal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorFrontal_GM_ADJ.txt

unset ROISize Sum

echo "R_SuperiorParietal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorParietal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorParietal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorParietal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorParietal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorParietal_GM_ADJ.txt

unset ROISize Sum

echo "R_SuperiorTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorTemporal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorTemporal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorTemporal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_SuperiorTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_SuperiorTemporal_GM_ADJ.txt

unset ROISize Sum

echo "R_TransverseTemporal_GM"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_TransverseTemporal_GM_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_TransverseTemporal_GM_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_TransverseTemporal_GM_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask Cort_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_TransverseTemporal_GM_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_TransverseTemporal_GM_ADJ.txt

unset ROISize Sum


#Subcortical Masks

#BILATERAL


echo "LR_Accumbens_area"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Accumbens_area_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Accumbens_area_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Accumbens_area_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Accumbens_area_ADJ.txt

unset ROISize Sum

echo "LR_Amygdala"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Amygdala_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Amygdala_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Amygdala_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Amygdala_ADJ.txt

unset ROISize Sum

echo "LR_Caudate"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Caudate_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Caudate_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Caudate_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Caudate_ADJ.txt

unset ROISize Sum

echo "LR_Hipp"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Hipp_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Hipp_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Hipp_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Hipp_ADJ.txt

unset ROISize Sum


echo "LR_Pallidum"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Pallidum_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Pallidum_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Pallidum_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Pallidum_ADJ.txt

unset ROISize Sum

echo "LR_Putamen"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Putamen_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Putamen_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Putamen_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Putamen_ADJ.txt

unset ROISize Sum

echo "LR_Thalamus_Proper"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Thalamus_Proper_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Thalamus_Proper_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Thalamus_Proper_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_LR_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_LR_Thalamus_Proper_ADJ.txt

unset ROISize Sum


#Subcortical LEFT HEMISPHERE


echo "L_Accumbens_area"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Accumbens_area_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Accumbens_area_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Accumbens_area_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Accumbens_area_ADJ.txt

unset ROISize Sum

echo "L_Amygdala"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Amygdala_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Amygdala_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Amygdala_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Amygdala_ADJ.txt

unset ROISize Sum

echo "L_Caudate"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Caudate_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Caudate_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Caudate_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Caudate_ADJ.txt

unset ROISize Sum

echo "L_Hipp"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Hipp_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Hipp_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Hipp_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Hipp_ADJ.txt

unset ROISize Sum


echo "L_Pallidum"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pallidum_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pallidum_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pallidum_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Pallidum_ADJ.txt

unset ROISize Sum

echo "L_Putamen"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Putamen_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Putamen_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Putamen_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Putamen_ADJ.txt

unset ROISize Sum

echo "L_Thalamus_Proper"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Thalamus_Proper_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Thalamus_Proper_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Thalamus_Proper_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_L_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_L_Thalamus_Proper_ADJ.txt

unset ROISize Sum

#Subcortical ROIs RIGHT HEMISPHERE


echo "R_Accumbens_area"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Accumbens_area_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Accumbens_area_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Accumbens_area_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Accumbens_area_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Accumbens_area_ADJ.txt

unset ROISize Sum

echo "R_Amygdala"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Amygdala_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Amygdala_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Amygdala_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Amygdala_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Amygdala_ADJ.txt

unset ROISize Sum

echo "R_Caudate"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Caudate_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Caudate_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Caudate_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Caudate_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Caudate_ADJ.txt

unset ROISize Sum

echo "R_Hipp"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Hipp_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Hipp_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Hipp_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Hipp_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Hipp_ADJ.txt

unset ROISize Sum


echo "R_Pallidum"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pallidum_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pallidum_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pallidum_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Pallidum_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Pallidum_ADJ.txt

unset ROISize Sum

echo "R_Putamen"

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Putamen_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Putamen_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Putamen_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Putamen_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Putamen_ADJ.txt

unset ROISize Sum

echo "R_Thalamus_Proper"	

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -mean -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Thalamus_Proper_Mean.txt

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Thalamus_Proper_Sum.txt

Sum=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -positive -sum -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]}) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Thalamus_Proper_Count.txt


ROISize=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	3dBrickStat -count -mask SubC_Mask_AL_QSM_RS_Erx1/${Subj}_freesurfer_R_Thalamus_Proper_AL_QSM_RS_Erx1.nii.gz \
	${MasterQSM[$LoopCounter]})

Eval=$(singularity run -e --bind $OutFolder/$Subj/QSM/FreeSurf_QSM_Masks $Path/Functions/QSM_Container.simg \
	echo "scale=2; $Sum / $ROISize " | bc -l) 

echo "${Eval:-FAIL}"  >> $OutFolder/Group/$Fold/Group_R_Thalamus_Proper_ADJ.txt

unset ROISize Sum

echo "$Subj" >> $OutFolder/Group/$Fold/Subjects.txt

cd $OutFolder/Group/$Fold

#List of files that should exist under $Fold

QSMMeanFileList="Group_LR_Frontal_GM_Mask_Mean.txt Group_L_DLPFC_GM_Mask_Mean.txt Group_L_InferiorTemporal_GM_Mask_Mean.txt Group_L_MedialOrbitofrontal_GM_Mean.txt Group_L_MiddleTemporal_GM_Mean.txt Group_L_Parietal_GM_Mask_Mean.txt Group_R_Postcentral_GM_Mean.txt Group_R_Precentral_GM_Mean.txt Group_R_Precuneus_GM_Mean.txt Group_R_RostralAnteriorCingulate_GM_Mean.txt Group_R_SuperiorParietal_GM_Mean.txt Group_LR_Accumbens_area_Mean.txt Group_LR_Thalamus_Proper_Mean.txt Group_L_Pallidum_Mean.txt Group_L_Putamen_Mean.txt Group_R_Accumbens_area_Mean.txt Group_R_Amygdala_Mean.txt Group_R_Caudate_Mean.txt Group_R_Putamen_Mean.txt Group_LR_Temporal_GM_Mask_Mean.txt Group_L_RostalMiddleFrontal_GM_Mean.txt Group_R_CaudalAnteriorCingulate_GM_Mask_Mean.txt Group_R_Cuneus_GM_Mask_Mean.txt Group_R_Fusiform_GM_Mask_Mean.txt Group_R_IsthmusCingulate_GM_Mean.txt Group_R_LateralOccipital_GM_Mean.txt Group_R_Occipital_GM_Mask_Mean.txt Group_LR_Amygdala_Mean.txt Group_L_Accumbens_area_Mean.txt Group_R_Pallidum_Mean.txt Group_L_CaudalAnteriorCingulate_GM_Mask_Mean.txt Group_L_Cuneus_GM_Mask_Mean.txt Group_L_IsthmusCingulate_GM_Mean.txt Group_L_LateralOccipital_GM_Mean.txt Group_L_Temporal_GM_Mask_Mean.txt Group_L_SuperiorFrontal_GM_Mean.txt Group_R_Entorhinal_GM_Mask_Mean.txt Group_R_Lingual_GM_Mean.txt Group_R_PosteriorCingulate_GM_Mean.txt Group_R_SuperiorFrontal_GM_Mean.txt Group_R_TransverseTemporal_GM_Mean.txt Group_LR_Putamen_Mean.txt Group_L_Amygdala_Mean.txt Group_L_Caudate_Mean.txt Group_L_Hipp_Mean.txt Group_L_CaudalMiddleFrontal_GM_Mask_Mean.txt Group_L_Entorhinal_GM_Mask_Mean.txt Group_L_InferiorParietal_GM_Mask_Mean.txt Group_L_Occipital_GM_Mask_Mean.txt Group_L_Parahippocampal_GM_Mean.txt Group_L_Precentral_GM_Mean.txt Group_L_SuperiorParietal_GM_Mean.txt Group_L_SuperiorTemporal_GM_Mean.txt Group_R_DLPFC_GM_Mask_Mean.txt Group_R_InferiorTemporal_GM_Mask_Mean.txt Group_R_Insula_GM_Mean.txt Group_R_MedialOrbitofrontal_GM_Mean.txt Group_R_Temporal_GM_Mask_Mean.txt Group_R_Parahippocampal_GM_Mean.txt Group_R_Pericalcarine_GM_Mean.txt Group_R_RostalMiddleFrontal_GM_Mean.txt Group_R_SuperiorTemporal_GM_Mean.txt Group_LR_Caudate_Mean.txt Group_LR_Pallidum_Mean.txt Group_L_Thalamus_Proper_Mean.txt Group_R_Hipp_Mean.txt Group_R_Thalamus_Proper_Mean.txt Group_LR_Parietal_GM_Mask_Mean.txt Group_LR_Occipital_GM_Mask_Mean.txt Group_L_LateralOrbitofrontal_GM_Mean.txt Group_L_Lingual_GM_Mean.txt Group_L_Pericalcarine_GM_Mean.txt Group_L_Postcentral_GM_Mean.txt Group_L_PosteriorCingulate_GM_Mean.txt Group_L_RostralAnteriorCingulate_GM_Mean.txt Group_R_Frontal_GM_Mask_Mean.txt Group_R_InferiorParietal_GM_Mask_Mean.txt Group_R_LateralOrbitofrontal_GM_Mean.txt Group_R_MiddleTemporal_GM_Mean.txt Group_L_Frontal_GM_Mask_Mean.txt Group_L_Fusiform_GM_Mask_Mean.txt Group_L_Insula_GM_Mean.txt Group_L_Precuneus_GM_Mean.txt Group_L_TransverseTemporal_GM_Mean.txt Group_R_CaudalMiddleFrontal_GM_Mask_Mean.txt Group_R_Parietal_GM_Mask_Mean.txt Group_LR_Hipp_Mean.txt Subjects.txt"

QSMADJFileList="Group_LR_Frontal_GM_Mask_ADJ.txt Group_L_DLPFC_GM_Mask_ADJ.txt Group_L_InferiorTemporal_GM_Mask_ADJ.txt Group_L_MedialOrbitofrontal_GM_ADJ.txt Group_L_MiddleTemporal_GM_ADJ.txt Group_L_Parietal_GM_Mask_ADJ.txt Group_R_Postcentral_GM_ADJ.txt Group_R_Precentral_GM_ADJ.txt Group_R_Precuneus_GM_ADJ.txt Group_R_RostralAnteriorCingulate_GM_ADJ.txt Group_R_SuperiorParietal_GM_ADJ.txt Group_LR_Accumbens_area_ADJ.txt Group_LR_Thalamus_Proper_ADJ.txt Group_L_Pallidum_ADJ.txt Group_L_Putamen_ADJ.txt Group_R_Accumbens_area_ADJ.txt Group_R_Amygdala_ADJ.txt Group_R_Caudate_ADJ.txt Group_R_Putamen_ADJ.txt Group_LR_Temporal_GM_Mask_ADJ.txt Group_L_RostalMiddleFrontal_GM_ADJ.txt Group_R_CaudalAnteriorCingulate_GM_Mask_ADJ.txt Group_R_Cuneus_GM_Mask_ADJ.txt Group_R_Fusiform_GM_Mask_ADJ.txt Group_R_IsthmusCingulate_GM_ADJ.txt Group_R_LateralOccipital_GM_ADJ.txt Group_R_Occipital_GM_Mask_ADJ.txt Group_LR_Amygdala_ADJ.txt Group_L_Accumbens_area_ADJ.txt Group_R_Pallidum_ADJ.txt Group_L_CaudalAnteriorCingulate_GM_Mask_ADJ.txt Group_L_Cuneus_GM_Mask_ADJ.txt Group_L_IsthmusCingulate_GM_ADJ.txt Group_L_LateralOccipital_GM_ADJ.txt Group_L_Temporal_GM_Mask_ADJ.txt Group_L_SuperiorFrontal_GM_ADJ.txt Group_R_Entorhinal_GM_Mask_ADJ.txt Group_R_Lingual_GM_ADJ.txt Group_R_PosteriorCingulate_GM_ADJ.txt Group_R_SuperiorFrontal_GM_ADJ.txt Group_R_TransverseTemporal_GM_ADJ.txt Group_LR_Putamen_ADJ.txt Group_L_Amygdala_ADJ.txt Group_L_Caudate_ADJ.txt Group_L_Hipp_ADJ.txt Group_L_CaudalMiddleFrontal_GM_Mask_ADJ.txt Group_L_Entorhinal_GM_Mask_ADJ.txt Group_L_InferiorParietal_GM_Mask_ADJ.txt Group_L_Occipital_GM_Mask_ADJ.txt Group_L_Parahippocampal_GM_ADJ.txt Group_L_Precentral_GM_ADJ.txt Group_L_SuperiorParietal_GM_ADJ.txt Group_L_SuperiorTemporal_GM_ADJ.txt Group_R_DLPFC_GM_Mask_ADJ.txt Group_R_InferiorTemporal_GM_Mask_ADJ.txt Group_R_Insula_GM_ADJ.txt Group_R_MedialOrbitofrontal_GM_ADJ.txt Group_R_Temporal_GM_Mask_ADJ.txt Group_R_Parahippocampal_GM_ADJ.txt Group_R_Pericalcarine_GM_ADJ.txt Group_R_RostalMiddleFrontal_GM_ADJ.txt Group_R_SuperiorTemporal_GM_ADJ.txt Group_LR_Caudate_ADJ.txt Group_LR_Pallidum_ADJ.txt Group_L_Thalamus_Proper_ADJ.txt Group_R_Hipp_ADJ.txt Group_R_Thalamus_Proper_ADJ.txt Group_LR_Parietal_GM_Mask_ADJ.txt Group_LR_Occipital_GM_Mask_ADJ.txt Group_L_LateralOrbitofrontal_GM_ADJ.txt Group_L_Lingual_GM_ADJ.txt Group_L_Pericalcarine_GM_ADJ.txt Group_L_Postcentral_GM_ADJ.txt Group_L_PosteriorCingulate_GM_ADJ.txt Group_L_RostralAnteriorCingulate_GM_ADJ.txt Group_R_Frontal_GM_Mask_ADJ.txt Group_R_InferiorParietal_GM_Mask_ADJ.txt Group_R_LateralOrbitofrontal_GM_ADJ.txt Group_R_MiddleTemporal_GM_ADJ.txt Group_L_Frontal_GM_Mask_ADJ.txt Group_L_Fusiform_GM_Mask_ADJ.txt Group_L_Insula_GM_ADJ.txt Group_L_Precuneus_GM_ADJ.txt Group_L_TransverseTemporal_GM_ADJ.txt Group_R_CaudalMiddleFrontal_GM_Mask_ADJ.txt Group_R_Parietal_GM_Mask_ADJ.txt Group_LR_Hipp_ADJ.txt"

for i in $QSMMeanFileList; do ! test -f "$i" && echo "*FAIL*" >> $i && echo "$i NOT FOUND"; done
for i in $QSMADJFileList; do ! test -f "$i" && echo "*FAIL*" >> $i && echo "$i NOT FOUND"; done

unset QSMMeanFileList QSMADJFileList

paste -d "," Subjects.txt \
	Group_L_Accumbens_area_Mean.txt \
	Group_L_Amygdala_Mean.txt \
	Group_L_CaudalAnteriorCingulate_GM_Mask_Mean.txt \
	Group_L_CaudalMiddleFrontal_GM_Mask_Mean.txt \
	Group_L_Caudate_Mean.txt \
	Group_L_Cuneus_GM_Mask_Mean.txt \
	Group_L_DLPFC_GM_Mask_Mean.txt \
	Group_L_Entorhinal_GM_Mask_Mean.txt \
	Group_L_Frontal_GM_Mask_Mean.txt \
	Group_L_Fusiform_GM_Mask_Mean.txt \
	Group_L_Hipp_Mean.txt \
	Group_L_InferiorParietal_GM_Mask_Mean.txt \
	Group_L_InferiorTemporal_GM_Mask_Mean.txt \
	Group_L_Insula_GM_Mean.txt \
	Group_L_IsthmusCingulate_GM_Mean.txt \
	Group_L_LateralOccipital_GM_Mean.txt \
	Group_L_LateralOrbitofrontal_GM_Mean.txt \
	Group_L_Lingual_GM_Mean.txt \
	Group_L_MedialOrbitofrontal_GM_Mean.txt \
	Group_L_MiddleTemporal_GM_Mean.txt \
	Group_L_Occipital_GM_Mask_Mean.txt \
	Group_L_Pallidum_Mean.txt \
	Group_L_Parahippocampal_GM_Mean.txt \
	Group_L_Parietal_GM_Mask_Mean.txt \
	Group_L_Pericalcarine_GM_Mean.txt \
	Group_L_Postcentral_GM_Mean.txt \
	Group_L_PosteriorCingulate_GM_Mean.txt \
	Group_L_Precentral_GM_Mean.txt \
	Group_L_Precuneus_GM_Mean.txt \
	Group_L_Putamen_Mean.txt \
	Group_L_RostalMiddleFrontal_GM_Mean.txt \
	Group_L_RostralAnteriorCingulate_GM_Mean.txt \
	Group_L_SuperiorFrontal_GM_Mean.txt \
	Group_L_SuperiorParietal_GM_Mean.txt \
	Group_L_SuperiorTemporal_GM_Mean.txt \
	Group_L_Temporal_GM_Mask_Mean.txt \
	Group_L_Thalamus_Proper_Mean.txt \
	Group_L_TransverseTemporal_GM_Mean.txt \
	Group_R_Accumbens_area_Mean.txt \
	Group_R_Amygdala_Mean.txt \
	Group_R_CaudalAnteriorCingulate_GM_Mask_Mean.txt \
	Group_R_CaudalMiddleFrontal_GM_Mask_Mean.txt \
	Group_R_Caudate_Mean.txt \
	Group_R_Cuneus_GM_Mask_Mean.txt \
	Group_R_DLPFC_GM_Mask_Mean.txt \
	Group_R_Entorhinal_GM_Mask_Mean.txt \
	Group_R_Frontal_GM_Mask_Mean.txt \
	Group_R_Fusiform_GM_Mask_Mean.txt \
	Group_R_Hipp_Mean.txt \
	Group_R_InferiorParietal_GM_Mask_Mean.txt \
	Group_R_InferiorTemporal_GM_Mask_Mean.txt \
	Group_R_Insula_GM_Mean.txt \
	Group_R_IsthmusCingulate_GM_Mean.txt \
	Group_R_LateralOccipital_GM_Mean.txt \
	Group_R_LateralOrbitofrontal_GM_Mean.txt \
	Group_R_Lingual_GM_Mean.txt \
	Group_R_MedialOrbitofrontal_GM_Mean.txt \
	Group_R_MiddleTemporal_GM_Mean.txt \
	Group_R_Occipital_GM_Mask_Mean.txt \
	Group_R_Pallidum_Mean.txt \
	Group_R_Parahippocampal_GM_Mean.txt \
	Group_R_Parietal_GM_Mask_Mean.txt \
	Group_R_Pericalcarine_GM_Mean.txt \
	Group_R_Postcentral_GM_Mean.txt \
	Group_R_PosteriorCingulate_GM_Mean.txt \
	Group_R_Precentral_GM_Mean.txt \
	Group_R_Precuneus_GM_Mean.txt \
	Group_R_Putamen_Mean.txt \
	Group_R_RostalMiddleFrontal_GM_Mean.txt \
	Group_R_RostralAnteriorCingulate_GM_Mean.txt \
	Group_R_SuperiorFrontal_GM_Mean.txt \
	Group_R_SuperiorParietal_GM_Mean.txt \
	Group_R_SuperiorTemporal_GM_Mean.txt \
	Group_R_Temporal_GM_Mask_Mean.txt \
	Group_R_Thalamus_Proper_Mean.txt \
	Group_R_TransverseTemporal_GM_Mean.txt \
	Group_LR_Accumbens_area_Mean.txt \
	Group_LR_Amygdala_Mean.txt \
	Group_LR_Caudate_Mean.txt \
	Group_LR_Frontal_GM_Mask_Mean.txt \
	Group_LR_Hipp_Mean.txt \
	Group_LR_Occipital_GM_Mask_Mean.txt \
	Group_LR_Pallidum_Mean.txt \
	Group_LR_Parietal_GM_Mask_Mean.txt \
	Group_LR_Putamen_Mean.txt \
	Group_LR_Temporal_GM_Mask_Mean.txt \
	Group_LR_Thalamus_Proper_Mean.txt | pr -t > Group_QSM_Mean_Columns.csv

paste -d "," Subjects.txt \
	Group_L_Accumbens_area_ADJ.txt \
	Group_L_Amygdala_ADJ.txt \
	Group_L_CaudalAnteriorCingulate_GM_Mask_ADJ.txt \
	Group_L_CaudalMiddleFrontal_GM_Mask_ADJ.txt \
	Group_L_Caudate_ADJ.txt \
	Group_L_Cuneus_GM_Mask_ADJ.txt \
	Group_L_DLPFC_GM_Mask_ADJ.txt \
	Group_L_Entorhinal_GM_Mask_ADJ.txt \
	Group_L_Frontal_GM_Mask_ADJ.txt \
	Group_L_Fusiform_GM_Mask_ADJ.txt \
	Group_L_Hipp_ADJ.txt \
	Group_L_InferiorParietal_GM_Mask_ADJ.txt \
	Group_L_InferiorTemporal_GM_Mask_ADJ.txt \
	Group_L_Insula_GM_ADJ.txt \
	Group_L_IsthmusCingulate_GM_ADJ.txt \
	Group_L_LateralOccipital_GM_ADJ.txt \
	Group_L_LateralOrbitofrontal_GM_ADJ.txt \
	Group_L_Lingual_GM_ADJ.txt \
	Group_L_MedialOrbitofrontal_GM_ADJ.txt \
	Group_L_MiddleTemporal_GM_ADJ.txt \
	Group_L_Occipital_GM_Mask_ADJ.txt \
	Group_L_Pallidum_ADJ.txt \
	Group_L_Parahippocampal_GM_ADJ.txt \
	Group_L_Parietal_GM_Mask_ADJ.txt \
	Group_L_Pericalcarine_GM_ADJ.txt \
	Group_L_Postcentral_GM_ADJ.txt \
	Group_L_PosteriorCingulate_GM_ADJ.txt \
	Group_L_Precentral_GM_ADJ.txt \
	Group_L_Precuneus_GM_ADJ.txt \
	Group_L_Putamen_ADJ.txt \
	Group_L_RostalMiddleFrontal_GM_ADJ.txt \
	Group_L_RostralAnteriorCingulate_GM_ADJ.txt \
	Group_L_SuperiorFrontal_GM_ADJ.txt \
	Group_L_SuperiorParietal_GM_ADJ.txt \
	Group_L_SuperiorTemporal_GM_ADJ.txt \
	Group_L_Temporal_GM_Mask_ADJ.txt \
	Group_L_Thalamus_Proper_ADJ.txt \
	Group_L_TransverseTemporal_GM_ADJ.txt \
	Group_R_Accumbens_area_ADJ.txt \
	Group_R_Amygdala_ADJ.txt \
	Group_R_CaudalAnteriorCingulate_GM_Mask_ADJ.txt \
	Group_R_CaudalMiddleFrontal_GM_Mask_ADJ.txt \
	Group_R_Caudate_ADJ.txt \
	Group_R_Cuneus_GM_Mask_ADJ.txt \
	Group_R_DLPFC_GM_Mask_ADJ.txt \
	Group_R_Entorhinal_GM_Mask_ADJ.txt \
	Group_R_Frontal_GM_Mask_ADJ.txt \
	Group_R_Fusiform_GM_Mask_ADJ.txt \
	Group_R_Hipp_ADJ.txt \
	Group_R_InferiorParietal_GM_Mask_ADJ.txt \
	Group_R_InferiorTemporal_GM_Mask_ADJ.txt \
	Group_R_Insula_GM_ADJ.txt \
	Group_R_IsthmusCingulate_GM_ADJ.txt \
	Group_R_LateralOccipital_GM_ADJ.txt \
	Group_R_LateralOrbitofrontal_GM_ADJ.txt \
	Group_R_Lingual_GM_ADJ.txt \
	Group_R_MedialOrbitofrontal_GM_ADJ.txt \
	Group_R_MiddleTemporal_GM_ADJ.txt \
	Group_R_Occipital_GM_Mask_ADJ.txt \
	Group_R_Pallidum_ADJ.txt \
	Group_R_Parahippocampal_GM_ADJ.txt \
	Group_R_Parietal_GM_Mask_ADJ.txt \
	Group_R_Pericalcarine_GM_ADJ.txt \
	Group_R_Postcentral_GM_ADJ.txt \
	Group_R_PosteriorCingulate_GM_ADJ.txt \
	Group_R_Precentral_GM_ADJ.txt \
	Group_R_Precuneus_GM_ADJ.txt \
	Group_R_Putamen_ADJ.txt \
	Group_R_RostalMiddleFrontal_GM_ADJ.txt \
	Group_R_RostralAnteriorCingulate_GM_ADJ.txt \
	Group_R_SuperiorFrontal_GM_ADJ.txt \
	Group_R_SuperiorParietal_GM_ADJ.txt \
	Group_R_SuperiorTemporal_GM_ADJ.txt \
	Group_R_Temporal_GM_Mask_ADJ.txt \
	Group_R_Thalamus_Proper_ADJ.txt \
	Group_R_TransverseTemporal_GM_ADJ.txt \
	Group_LR_Accumbens_area_ADJ.txt \
	Group_LR_Amygdala_ADJ.txt \
	Group_LR_Caudate_ADJ.txt \
	Group_LR_Frontal_GM_Mask_ADJ.txt \
	Group_LR_Hipp_ADJ.txt \
	Group_LR_Occipital_GM_Mask_ADJ.txt \
	Group_LR_Pallidum_ADJ.txt \
	Group_LR_Parietal_GM_Mask_ADJ.txt \
	Group_LR_Putamen_ADJ.txt \
	Group_LR_Temporal_GM_Mask_ADJ.txt \
	Group_LR_Thalamus_Proper_ADJ.txt | pr -t > Group_QSM_ADJ_Mean_Columns.csv


echo "Participant,L_Accumbens_area,L_Amygdala,L_CaudalAnteriorCingulate,L_CaudalMiddleFrontal,L_Caudate,L_Cuneus,L_DLPFC,L_Entorhinal,L_Frontal,L_Fusiform,L_Hipp,L_InferiorParietal,L_InferiorTemporal,L_Insula,L_IsthmusCingulate,L_LateralOccipital,L_LateralOrbitofrontal,L_Lingual,L_MedialOrbitofrontal,L_MiddleTemporal,L_Occipital,L_Pallidum,L_Parahippocampal,L_Parietal,L_Pericalcarine,L_Postcentral,L_PosteriorCingulate,L_Precentral,L_Precuneus,L_Putamen,L_RostalMiddleFrontal,L_RostralAnteriorCingulate,L_SuperiorFrontal,L_SuperiorParietal,L_SuperiorTemporal,L_Temporal,L_Thalamus_Proper,L_TransverseTemporal,R_Accumbens_area,R_Amygdala,R_CaudalAnteriorCingulate,R_CaudalMiddleFrontal,R_Caudate,R_Cuneus,R_DLPFC,R_Entorhinal,R_Frontal,R_Fusiform,R_Hipp,R_InferiorParietal,R_InferiorTemporal,R_Insula,R_IsthmusCingulate,R_LateralOccipital,R_LateralOrbitofrontal,R_Lingual,R_MedialOrbitofrontal,R_MiddleTemporal,R_Occipital,R_Pallidum,R_Parahippocampal,R_Parietal,R_Pericalcarine,R_Postcentral,R_PosteriorCingulate,R_Precentral,R_Precuneus,R_Putamen,R_RostalMiddleFrontal,R_RostralAnteriorCingulate,R_SuperiorFrontal,R_SuperiorParietal,R_SuperiorTemporal,R_Temporal,R_Thalamus_Proper,R_TransverseTemporal,LR_Accumbens_area,LR_Amygdala,LR_Caudate,LR_Frontal,LR_Hipp,LR_Occipital,LR_Pallidum,LR_Parietal,LR_Putamen,LR_Temporal,LR_Thalamus_Proper" > $OutFolder/Group/${OutStatFile[$LoopCounter]}

cat Group_QSM_Mean_Columns.csv >> $OutFolder/Group/${OutStatFile[$LoopCounter]}

echo "Participant,L_Accumbens_area,L_Amygdala,L_CaudalAnteriorCingulate,L_CaudalMiddleFrontal,L_Caudate,L_Cuneus,L_DLPFC,L_Entorhinal,L_Frontal,L_Fusiform,L_Hipp,L_InferiorParietal,L_InferiorTemporal,L_Insula,L_IsthmusCingulate,L_LateralOccipital,L_LateralOrbitofrontal,L_Lingual,L_MedialOrbitofrontal,L_MiddleTemporal,L_Occipital,L_Pallidum,L_Parahippocampal,L_Parietal,L_Pericalcarine,L_Postcentral,L_PosteriorCingulate,L_Precentral,L_Precuneus,L_Putamen,L_RostalMiddleFrontal,L_RostralAnteriorCingulate,L_SuperiorFrontal,L_SuperiorParietal,L_SuperiorTemporal,L_Temporal,L_Thalamus_Proper,L_TransverseTemporal,R_Accumbens_area,R_Amygdala,R_CaudalAnteriorCingulate,R_CaudalMiddleFrontal,R_Caudate,R_Cuneus,R_DLPFC,R_Entorhinal,R_Frontal,R_Fusiform,R_Hipp,R_InferiorParietal,R_InferiorTemporal,R_Insula,R_IsthmusCingulate,R_LateralOccipital,R_LateralOrbitofrontal,R_Lingual,R_MedialOrbitofrontal,R_MiddleTemporal,R_Occipital,R_Pallidum,R_Parahippocampal,R_Parietal,R_Pericalcarine,R_Postcentral,R_PosteriorCingulate,R_Precentral,R_Precuneus,R_Putamen,R_RostalMiddleFrontal,R_RostralAnteriorCingulate,R_SuperiorFrontal,R_SuperiorParietal,R_SuperiorTemporal,R_Temporal,R_Thalamus_Proper,R_TransverseTemporal,LR_Accumbens_area,LR_Amygdala,LR_Caudate,LR_Frontal,LR_Hipp,LR_Occipital,LR_Pallidum,LR_Parietal,LR_Putamen,LR_Temporal,LR_Thalamus_Proper" > $OutFolder/Group/${OutStatFileADJ[$LoopCounter]}

cat Group_QSM_ADJ_Mean_Columns.csv >> $OutFolder/Group/${OutStatFileADJ[$LoopCounter]}

LoopCounter=$((LoopCounter+1))

done

echo ""	
echo "---------------------------------------------------------------"	
echo "05_Extract_QSM.sh script finished running succesfully on `date`"
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
