#!/bin/bash

set -e #Exit on error

Path=$1

#Authored by Valentinos Zachariou on 09/9/2020
#
# Script gets Matlab Version and writes it to MatTempFile.txt
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


MatVersion=$(matlab -nodisplay -nosplash -nodesktop -r "try; v=version; disp(v); catch; end; quit;" | tail -n1 | head -c 3) # change matlab command

echo "${MatVersion:-ERROR}" > $Path/Functions/MatTempFile.txt


	


