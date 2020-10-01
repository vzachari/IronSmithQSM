% Correction of the iField - removal of the echo-dependent linear phase
%   gradient to avoid non-2pi wrap-like artifacts in iFreq_raw 
%
%   [iField_corrected] = iField_correction(iField,voxel_size)
% 
%   output
%   iField_corrected - iField with echo-dependent linear gradient
%   removed from the phase
%
%   input
%   iField - the complex MR image
%   voxel_size - the size of a voxel
%
%   Created by Alexey V. Dimov and Pascal Spincemaille in 2017.01.13
%   Updated by Alexey V. Dimov on 2017.02.02

function [iField_corrected] = iField_correction_new(iField,voxel_size, Mask, InPlanePhaseEncodingDirection)

CL=class(iField);

matrix_size = size(squeeze(iField(:,:,:,1)));
if nargin < 3
    Mask = genMask(iField,voxel_size);
end
if nargin < 4
    InPlanePhaseEncodingDirection='';
end
pha = zeros(size(iField),CL);
% mag = abs(iField);
for i = 1 : size(pha,4)
    fprintf('.');
    pha(:,:,:,i) = unwrapPhase(squeeze(abs(iField(:,:,:,i))),squeeze(angle(iField(:,:,:,i))),matrix_size);
end
fprintf('\n');


%Laplacian in echo direction
% echo_laplacian = zeros([matrix_size, size(iField,4)-2],CL);
g1 = zeros([size(iField,4)-1, 1],CL);
g2 = zeros([size(iField,4)-1, 1],CL);
in = zeros([size(iField,4)-1, 1],CL);

echo_laplacian = pha(:,:,:,2) - pha(:,:,:,1);
mag = sqrt(sum(abs(iField(:,:,:,1:2)).^2,4));
[g1(1), g2(1), in(1)] = gffun(echo_laplacian,Mask,mag);
for i = 1:size(iField,4)-2
    disp(num2str(i));
    echo_laplacian = pha(:,:,:,i) - 2*pha(:,:,:,i+1) + pha(:,:,:,i+2);
    mag = sqrt(sum(abs(iField(:,:,:,i:i+2)).^2,4));
    a=prctile(echo_laplacian(Mask>0), [5 95]);
    Mask2=(echo_laplacian>a(1)).*(echo_laplacian<a(2)).*Mask;
    [g1(i+1), g2(i+1), in(i+1), fit] = gffun(echo_laplacian,Mask2,mag,InPlanePhaseEncodingDirection);
end


%Estimate parameters of the gradient
% [g1, g2, in] = gffun(echo_laplacian,Mask,mag);
[slope1, slope2, intrcp]  = fitgrad(g1, g2, in);

%Subtract artificially added phase
phasor = phasorprep(slope1, slope2, intrcp, matrix_size);
iField_corrected = iField.*exp(-1i*phasor);
end