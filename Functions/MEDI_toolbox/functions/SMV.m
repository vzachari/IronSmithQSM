% Spherical Mean Value operator
%   y=SMV(iFreq,matrix_size,voxel_size,radius)
%   
%   output
%   y - reulstant image after SMV
% 
%   input
%   iFreq - input image
%   matrix_size - dimension of the field of view
%   voxel_size - the size of the voxel
%   radius - radius of the sphere in mm
%
%   Created by Tian Liu in 2010
%   Last modified by Tian Liu on 2013.07.24

function [y, K] = SMV(iFreq,varargin)

if 1==length(varargin)
    K=varargin{1};
else
    matrix_size=varargin{1};
    voxel_size=varargin{2};
    if (length(varargin)<3)
        radius=round(6/max(voxel_size)) * max(voxel_size);     % default radisu is 6mm
    else
        radius=varargin{3};
    end
    K=sphere_kernel(matrix_size, voxel_size,radius);
end

y = ifftn( fftn(iFreq).*K);