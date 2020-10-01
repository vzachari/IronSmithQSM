% Mask generation
%   Mask = genMask(iField, voxel_size)
%
%   output
%   Mask - the biggest contiguous region that has decent SNR
%
%   input
%   iField - the complex MR image
%   voxel_size - the size of a voxel
%
%   Created by Tian Liu in 20013.07.24
%   Last modified by Tian Liu on 2013.07.24

function Mask = genMask(iField, voxel_size, opts)

defopts.erodeRadius = 10; % in mm
defopts.magThreshold = 5; % in percent
defopts.numRegions = 5;
if nargin<4; opts=struct; end
deffields=fieldnames(defopts);
for i=1:length(deffields)
    if ~isfield(opts, deffields{i})
        opts.(deffields{i})=defopts.(deffields{i});
    end
end

iMag = sqrt(sum(abs(iField).^2,4));
matrix_size = size(iMag);
m = iMag>(opts.magThreshold/100*max(iMag(:)));           % simple threshold
if opts.erodeRadius > 0
    m = SMV(m,matrix_size, voxel_size, opts.erodeRadius)>0.999;   % erode the boundary by 10mm
end
l = bwlabeln(m,opts.numRegions);                       % find the biggest contiguous region
Mask = (l==mode(l(l~=0)));
%     Mask1 = SMV(Mask, matrix_size, voxel_size, 10)>0.001; % restore the enrosion by 4mm
end
