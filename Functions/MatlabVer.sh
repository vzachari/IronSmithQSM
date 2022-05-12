#!/bin/bash

set -e #Exit on error

#Authored by Valentinos Zachariou on 06/22/2021
#
#	Copyright (C) 2022 Valentinos Zachariou, University of Kentucky (see LICENSE file for more details)
#
#	Script gets Matlab Version and writes it to MatTempFile.txt
#	Saving Matlab Version in a varialbe breaks nohup and running Ironsmith with & (in the background)
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

#Passed varialbes to MatlabVer.sh 
#1) Path
#2) Matlab Path

#Path="/home/data3/vzachari/QSM_Toolkit/IronSmithQSM"
#MatPath="/usr/local/MATLAB/R2019b/bin/matlab"

Path=$1
MatPath=$2

MatVersion=$($MatPath -nodisplay -nosplash -nodesktop -r "try; v=version; disp(v); catch; end; quit;" | tail -n1 | head -c 3) # change matlab command
ImToolLicTest=$($MatPath -nodisplay -nosplash -nodesktop -r "try; v=license('test','image_toolbox'); disp(v); catch; end; quit;" | tail -n -2 | sed -e 's/^[[:space:]]*//')
ImToolTest=$($MatPath -nodisplay -nosplash -nodesktop -r "try; v = ver; Index = find(strcmp({v.Name}, 'Image Processing Toolbox')==1); disp(~isempty(Index)); catch; end; quit;" | tail -n -2 | sed -e 's/^[[:space:]]*//')

echo "${MatVersion:-ERROR},${ImToolTest:-ERROR},${ImToolLicTest:-ERROR}" > $Path/Functions/MatTempFile.txt


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
