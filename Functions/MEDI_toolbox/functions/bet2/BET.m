% BET.m
%   [Mask] = BET(iMag,matrix_size,voxel_size,fractional_threshold,
%                gradient_threshold,radiusarg)
% 
%   output
%   Mask - the brain mask
% 
%   input
%   iMag - magnitude image
%   matrix_size - dimension of the 3D image stack
%   voxel_size - dimensions of the voxels
%   
%   optional input arguments
%   fractional_threshold is used to set a fractional intensity threshold 
%       which determines where the edge of the final segmented brain is 
%       located. The default value is 0.5 and the valid range is 0 to 1. 
%       A smaller value for this threshold will cause the segmented brain
%       to be larger and should be used when the overall result from BET is
%       too small (inside the brain boundary). Obviously, larger values for
%       this threshold have the opposite effect (making the segmented brain
%       smaller). This parameter does not normally need to be used, but 
%       sometimes requires tuning for specific scanners/sequences to get 
%       the best results. It is not advisable to tune it for each 
%       individual image in general.
%   gradient_threshold causes a gradient change to be applied to the 
%       previous threshold value. That is, the value of the 
%       fractional_threshold intensity threshold will vary from the top to
%       the bottom of the image, centred around the fractional_threshold 
%       value specified. The default value for this gradient option is 0, 
%       and the valid range is -1 to +1. A positive value will cause the 
%       intensity threshold to be smaller at the bottom of the image and 
%       larger at the top of the image. This will have the effect of 
%       increasing the estimated brain size in the bottom slices and 
%       reducing it in the top slices. 
%   radiusarg is the thead radius (mm not voxels); initial surface sphere
%       is set to half of this

function Mask = BET(iMag,matrix_size,voxel_size,varargin)
    % data type conversion
    matrix_size = double(matrix_size);
    voxel_size = double(voxel_size);
    n_vox = matrix_size(1)*matrix_size(2)*matrix_size(3);
    fM = double(reshape(iMag, [1,n_vox]));

try
    % c++ interface
    tmp = bet2(fM,matrix_size,voxel_size,varargin{:});
    Mask = reshape(tmp,matrix_size);
catch
    [STR, NAM, EXT] = fileparts(mfilename('fullpath'));
    error(['bet2.' mexext ' not found. Please run ''runmex'' in ' STR])
end

end

