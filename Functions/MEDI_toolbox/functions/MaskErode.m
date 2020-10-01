function y = MaskErode( m,matrix_size,voxel_size, radius)
%MASKERODE 
% y = MaskErode( m,matrix_size,voxel_size, radius)
% erode the boundary by radius (mm)
y = SMV(m,matrix_size, voxel_size, radius)>0.999;   % erode the boundary by radius (mm)

end

