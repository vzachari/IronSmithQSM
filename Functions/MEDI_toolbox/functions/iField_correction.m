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

function [iField_corrected] = iField_correction(iField,voxel_size, Mask, InPlanePhaseEncodingDirection)
CL = class(iField);
sz=size(iField);
% hz=floor(sz(3)/2);
% zr=hz-4:hz+5;
zr=1:sz(3);
matrix_size = [sz(1:2) numel(zr)];
necho=sz(4);
if nargin < 3
    Mask = genMask(iField,voxel_size);
    
end
if nargin < 4
    InPlanePhaseEncodingDirection='';
end
Mask = Mask(:,:,zr);
% pha = angle(iField);
% mag = sqrt(sum(abs(iField).^2,4));

pha = @(x) angle(iField(:,:,zr,x));
mag = @(x) abs(iField(:,:,zr,x));


g1 = zeros([necho-1, 1],CL);
g2 = g1;
in = g1;

%Laplacian in echo direction
for i=1:necho-1
    if 1==i
        echo_laplacian = pha(2) - pha(1);
        mag_laplacian = sqrt(sum(abs(mag(1:2)).^2,4));
    else
        echo_laplacian = pha(i-1) - 2*pha(i) + pha(i+1);
        ftor=reshape([1 2 1], [1 1 1 3]);
        mag_laplacian = sqrt(sum(bsxfun(@times, ftor, mag(i-1:i+1).^2),4));
    end
%     mag_laplacian = mag_laplacian.*Mask2;
%     [gg1 gg2] = find_slope(echo_laplacian, Mask); 
    echo_laplacian = unwrapPhase(mag_laplacian,echo_laplacian,matrix_size);
    fprintf(' ');
    a=prctile(echo_laplacian(Mask>0), [25 75]);
    Mask2=(echo_laplacian>a(1)).*(echo_laplacian<a(2)).*Mask;
%     
%     %Estimate parameters of the gradient
    [g1(i), g2(i), in(i)] = gffun(echo_laplacian,Mask2, mag_laplacian,InPlanePhaseEncodingDirection);
%     [g1(i) g2(i)]=find_slope(echo_laplacian, Mask); 
end

[slope1, slope2, intrcp]  = fitgrad(g1, g2, in);

%Subtract artificially added phase
phasor = phasorprep(slope1, slope2, intrcp, sz(1:3));
iField_corrected = iField.*exp(-1i*phasor);
end

% matrix_size = size(squeeze(iField(:,:,:,1)));
% if nargin < 3
%     Mask = genMask(iField,voxel_size);
% end
% pha = angle(iField);
% mag = sqrt(sum(abs(iField).^2,4));
% 
% %Laplacian in echo direction
% echo_laplacian = zeros([matrix_size, size(iField,4)-2]);
% for i = 1 : size(echo_laplacian,4)
%     echo_laplacian(:,:,:,i) = pha(:,:,:,i) - 2*pha(:,:,:,i+1) + pha(:,:,:,i+2);
% end
% echo_laplacian = cat(4, pha(:,:,:,2) - pha(:,:,:,1), echo_laplacian);
% 
% %Quick and dirty unwrapping
% for i = 1 : size(echo_laplacian,4)
%     echo_laplacian(:,:,:,i) = unwrapPhase(mag,squeeze(echo_laplacian(:,:,:,i)),matrix_size);
% end
% 
% %Estimate parameters of the gradient
% [g1, g2, in] = gffun(echo_laplacian,Mask);
% [slope1, slope2, intrcp]  = fitgrad(g1, g2, in);
% 
% %Subtract artificially added phase
% phasor = phasorprep(slope1, slope2, intrcp, matrix_size);
% iField_corrected = iField.*exp(-1i*phasor);
% end