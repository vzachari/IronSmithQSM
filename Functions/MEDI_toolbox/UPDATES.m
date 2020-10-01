% This is an updated version of MEDI toolbox.

% Please post questions and suggestions to the medi-users group:
% https://groups.google.com/d/forum/medi-users
% or contact us at qsmreconstruction@gmail.com 
% Regards, Weill Cornell MRI lab

% Updates for 01/15/2020
1. Fixed Read_DICOM for Matlab 2019b
2. Fixed Read_DICOM bug after upgrading Matlab version
3. Improved support for Philips 3D dicom
4. Added support for Hitachi dicom
5. Improved Write_DICOM (including 3D dicom)
6. Added percetage as option for MEDI_L1 (for edge mask)
7. Fixed bug in store_QSM_results.m when 'result' exist somewhere else in path
8. Added MaskErode function
9. Added fractional_threshold, gradient_threshold, and radiusarg option to BET
10. Fixed sign bug in fit_IDEAL_R2
11. Update README.m to reflect currently recommended parameters/functions
12. Workaround for bug for odd number of slices.
13. Fixed TE bug in Read_DICOM for Siemens

% Updates for 03/27/2019

1. Added Fit_ppm_complex_bipolar.m for fitting of bipolar readout gradient echo 
2. Added warnings for DICOM directories that don't have the expected number
   of images
3. Added experimental support for reading Philips 3D DICOM
4. Fixed dicom reading bug for Matlab versions 2018a and newer
5. Added support for United Health DICOM images
6. Added fixes for various format with expected fields missing
7. Added support for Siemens VIDA images
8. Reduce memory usage for Fit_ppm_complex and Fit_ppm_complex_bipolar for large
   inputs


% Updates for 11/06/2017

1. GUI for MEDI renamed to MEDI_GUI.
2. Added MEDI+0 for ventricular CSF based zero-referencing. 
   MEDI_L1 will perform MEDI+0 when the Mask_CSF variable is present. 
   See for details Z. Liu et al. MRM 2017;DOI:10.1002/mrm.26946. 
3. Fixed Read_DICOM for various platforms/versions 
   (please report your experience for remaining testing/bug-fixing)
4. Added brain extraction using FSL BET using MEX (Mac/Win/Linux).
5. Added MEDI_set_path function.Run MEDI_set_path to set all necessary paths.

See README.m for updated instructions on how to run QSM from GRE dicom to QSM map.

% Updates for 02/02/2017

Minor changes:

1. Update to iField_correction - now fit a 2D linear component to phase



% Updates for 01/14/2017
Important changes:

1. New function to remove readout phase correction - iField_correction().
On some scanner platforms, a readout phase correction is performed that may lead to inconsistencies between echoes within a multiple echo 
acquisition, leading to an unphysical field map when estimated from all echoes together. Similar artifacts are sometimes observed when
bipolar readout is used on certain platforms. iField_correction() removes these phase inconsistencies from the complex data.
Please refer to README.m for details on how to call this function.

Minor changes:

1. Update to Read_Philips_DICOM

% Updates for 02/20/2016
Minor corrections to the previously published code


% Updates for 05/20/2016 
Minor changes:

1. Read_Siemens_DICOM has been updated to handle situations where number of echoes reported in DICOM header (.EchoTrainLength) is not correct.

Note: since the new function uses additional files which might potentially be a source of compatibility issues between different versions of Matlab, old function is still included in the toolbox as "Read_Siemens_DICOM_old".

% Updates for 05/16/2016
Important changes:

1. New faster function to read Siemens DICOMs. New function uses the same interface as the previous verision.

Note: since the new function uses additional files which might potentially be a source of compatibility issues between different versions of Matlab, old function is still included in the toolbox as "Read_Siemens_DICOM_old".


% Updates for 05/13/2016
Important changes:

1. New function to read GE DICOMs - significant speedup is achieved. Read_GE_DICOM now properly handles datasets acquired using ZIP option on scanner. New function uses the same interface as the previous verision.

Note: since the new function uses additional files which might potentially be a source of compatibility issues between different versions of Matlab, old function is still included in the toolbox as "Read_GE_DICOM_old".

2. Fit_ppm_complex allows estimation of field map from single echo datasets. Single echo data can now be processed with the same reconstruction pipeline.

3. Fixed bug in write_QSM_dir (used to generate DICOM series for reconstructed QSM) which previously caused improper slice location.


% Updates for 12/16/2015
Important changes:
1. Forward difference with Neuman boundary conditions and backward
difference with Dirichlet boundary conditions are now used to compute
discrete gradient and discrete divergence (functions fgrad and bdiv).
This approach suppresses "checkerboard pattern" artifact in final QSM.
2. GUI version is now available

New functions:
1. Read_Bruker_DICOM and Read_Bruker_raw functions are now available to
load Bruker data.
2. Fit_ppm_complex_TE function to estimate frequency offset for datasets
with uneven echo spacing
3. unwrap_gc - graph-cut based phase unwrapping
4. LBV - background field removal by solving Laplacian boundary value
problem
5. write_QSM_dir - outputs reconstructed QSM as a set of DICOM images