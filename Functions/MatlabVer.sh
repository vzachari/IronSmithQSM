#!/bin/bash

set -e #Exit on error

#Passed varialbes to MatlabVer.sh 
#1) Path
#2) Matlab Path

#Path="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"
#MatPath="Same path as in Matlab_Config.txt"

Path=$1
MatPath=$2

#Authored by Valentinos Zachariou on 09/9/2020
#
# Script gets Matlab Version and writes it to MatTempFile.txt
# Saving Matlab Version in a varialbe breaks nohup and running Ironsmith with & (in the background)
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


MatVersion=$($MatPath -nodisplay -nosplash -nodesktop -r "try; v=version; disp(v); catch; end; quit;" | tail -n1 | head -c 3) # change matlab command

echo "${MatVersion:-ERROR}" > $Path/Functions/MatTempFile.txt


	


