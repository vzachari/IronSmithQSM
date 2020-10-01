% for GE SWAN images consisting of magnitude, real and imaginary parts
%   [iField,voxel_size,matrix_size,CF,delta_TE,B0_dir] =Read_GE_DICOM(DicomFolder);
%
%   output
%   iField - the multi-echo complex MR image
%   voxel_size - size of the voxel in mm
%   matrix_size - dimension of the field of view
%   CF - central frequency in Hz
%   delta_TE - TE spacing in s
%   TE - echo times in s
%   B0_dir - direction of the B0 field
%   files - names of the dicom files arranged by slice and echo
%
%   input
%   DicomFloder: This folder should NOT contain anything else
%                except the DICOM images belonging to a particular
%                series that you want to process.
%
%   Apdated from Tian Liu
%   Created by Shuai Wang on 2011.03.08
%   Modified by Tian Liu on 2011.05.19
%   Last modified by Tian Liu on 2013.07.24

function [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir, files]=Read_GE_DICOM(DicomFolder)

files=struct;
filelist = dir(DicomFolder);
i=1;
while i<=length(filelist)
    if filelist(i).isdir==1
        filelist = filelist([1:i-1 i+1:end]);   % eliminate folders
    else
        i=i+1;
    end
end

fnTemp=[DicomFolder '/' filelist(1).name];



info = dicominfo(fnTemp);

matrix_size(1) = single(info.Width);
matrix_size(2) = single(info.Height);

voxel_size(1,1) = single(info.PixelSpacing(1));
voxel_size(2,1) = single(info.PixelSpacing(2));
voxel_size(3,1) = single(info.SpacingBetweenSlices);

if isfield(info,'Private_0021_104f')
    if isa(info.Private_0021_104f,'uint8')
        matrix_size(3) = single(typecast(info.Private_0021_104f,'uint16'));
    else
        matrix_size(3) = single(info.Private_0021_104f);
    end
else
    minSlice = 1e10;
    maxSlice = -1e10;
    NumEcho=0;
%     tags={'SliceLocation','ImagePositionPatient',...
%         'EchoTime','EchoNumber','InstanceNumber'};
    tags={'SliceLocation','ImagePositionPatient','EchoNumber'};
    for i = 1:length(filelist)
        filename=fullfile(DicomFolder,filelist(i).name);
        if isdicom(filename)
            %                         info = dicominfo(filename);
            info2 = Read_DICOM_get_tags(filename,tags);
            if info2.SliceLocation<minSlice
                minSlice = info2.SliceLocation;
                minLoc = info2.ImagePositionPatient;
            end
            if info2.SliceLocation>maxSlice
                maxSlice = info2.SliceLocation;
                maxLoc = info2.ImagePositionPatient;
            end
            if info2.EchoNumber>NumEcho
                NumEcho = info2.EchoNumber;
            end
        else
            disp([ filename ' is not a dicom file']);
        end
    end
    matrix_size(3) = round(norm(maxLoc - minLoc)/voxel_size(3)) + 1;
end
if isfield(info,'Private_0019_107e')
    if isa(info.Private_0019_107e,'uint8')
        NumEcho = single(typecast(info.Private_0019_107e,'uint16'));
    else
        NumEcho = single(info.Private_0019_107e);
    end
end

CF = info.ImagingFrequency *1e6;
isz=[matrix_size(1) matrix_size(2) matrix_size(3)*NumEcho];
iReal = single(zeros(isz));
iImag = single(zeros(isz));
filesR={};
filesI={};

TE = single(zeros([NumEcho 1]));
r_ImagePositionPatient = zeros(3, matrix_size(3)*NumEcho);
i_ImagePositionPatient = zeros(3, matrix_size(3)*NumEcho);
r_EchoNumber = zeros(matrix_size(3)*NumEcho,1);
minSlice = 1e10;
maxSlice = -1e10;


tags={'SliceLocation','ImagePositionPatient',...
        'EchoTime','EchoNumber','InstanceNumber'};
rctr = 0; ictr=0;
progress='';
for i = 1:length(filelist)
    filename=[DicomFolder '/' filelist(i).name];
    info2 = Read_DICOM_get_tags(filename, tags);
    
    if info2.SliceLocation<minSlice
        minSlice = info2.SliceLocation;
        minLoc = info2.ImagePositionPatient;
    end
    if info2.SliceLocation>maxSlice
        maxSlice = info2.SliceLocation;
        maxLoc = info2.ImagePositionPatient;
    end
    if info2.EchoNumber>NumEcho
        TE = [TE zeros([info2.EchoNumber - NumEcho 1])];
        NumEcho = info2.EchoNumber;
    end
    if TE(info2.EchoNumber)==0
        TE(info2.EchoNumber)=info2.EchoTime*1e-3;
    end
    if mod(info2.InstanceNumber,3)==2
        rctr = rctr + 1;
        for ii=1:length(progress); fprintf('\b'); end
        progress=sprintf('Reading file %d', rctr+ictr);
        fprintf(progress);
        r_ImagePositionPatient(:,rctr) = info2.ImagePositionPatient;
        r_EchoNumber(rctr) = info2.EchoNumber;
        filesR{rctr} = filename;
        iReal(:,:,rctr)  = single(dicomread(filename));%magnitude
    elseif mod(info2.InstanceNumber,3)==0
        ictr = ictr + 1;
        for ii=1:length(progress); fprintf('\b'); end
        progress=sprintf('Reading file %d', rctr+ictr);
        fprintf(progress);
        i_ImagePositionPatient(:,ictr) = info2.ImagePositionPatient;
        i_EchoNumber(ictr) = info2.EchoNumber;
        filesI{ictr} = filename;
        iImag(:,:,ictr)  = single(dicomread(filename));%magnitude
    end
end
fprintf('\n');

matrix_size(3) = round(norm(maxLoc - minLoc)/voxel_size(3))+1 ;

Affine2D = reshape(info.ImageOrientationPatient,[3 2]);
Affine3D = [Affine2D (maxLoc-minLoc)/( (matrix_size(3)-1)*voxel_size(3))];
B0_dir = Affine3D\[0 0 1]';
files.Affine3D=Affine3D;
files.minLoc=minLoc;
files.maxLoc=maxLoc;
n_exp=matrix_size(3)*NumEcho;

r_sz=size(r_ImagePositionPatient); r_sz(1)=1;
r_minLoc=repmat(minLoc, r_sz);
if n_exp ~= r_sz(2)
    warning(['Number of real images (' ... 
        num2str(r_sz(2)) ...
        ') is different from the expected number (' ...
        num2str(n_exp) ...
        ').'])
end

% 
% sz=size(r_ImagePositionPatient); sz(1)=1;
% minLoc=repmat(minLoc, sz);

r_slice = int32(round(sqrt(sum((r_ImagePositionPatient-r_minLoc).^2,1))/voxel_size(3)) +1);
r_ind = sub2ind([matrix_size(3) NumEcho], r_slice(:), int32(r_EchoNumber(:)));
iReal(:,:,r_ind)=iReal;
files.R=cell(matrix_size(3), NumEcho);
files.R(r_ind)=filesR;
if n_exp ~= size(iReal,3)
    iReal = padarray(iReal, [0 0 n_exp-size(iReal,3)], 'post');
    warning(['Some real images are missing']); 
end

i_sz=size(i_ImagePositionPatient); i_sz(1)=1;
i_minLoc=repmat(minLoc, i_sz);
if n_exp ~= i_sz(2)
    warning(['Number of imaginary images (' ... 
        num2str(i_sz(2)) ...
        ') is different from the expected number (' ...
        num2str(n_exp) ...
        ').'])
end
if i_sz(2) ~= r_sz(2)
    warning(['Number of imaginary images (' ... 
        num2str(i_sz(2)) ...
        ') is different from number of real images (' ...
        num2str(r_sz(2)) ...
        ').'])
end
i_minLoc=repmat(minLoc, i_sz);


i_slice = int32(round(sqrt(sum((i_ImagePositionPatient-i_minLoc).^2,1))/voxel_size(3)) +1);
i_ind = sub2ind([matrix_size(3) NumEcho], i_slice(:), int32(i_EchoNumber(:)));
iImag(:,:,i_ind)=iImag;
files.I=cell(matrix_size(3), NumEcho);
files.I(i_ind)=filesI;
if n_exp ~= size(iImag,3)
    iImag = padarray(iImag, [0 0 n_exp-size(iImag,3)], 'post');
    warning(['Some imaginary images are missing']); 
end


files.phasesign = 1;
files.zchop = 1;

%
%     for i = 1:length(filelist)
%         info = dicominfo([DicomFolder '/' filelist(i).name]);
%         slice = int32(round(sqrt(sum((info.ImagePositionPatient-minLoc).^2))/voxel_size(3)) +1);
%
%
%     end


iField = reshape(complex(iReal, iImag), ...
    [matrix_size(1) matrix_size(2) matrix_size(3) NumEcho]);
iField = permute(iField,[2 1 3 4 5]); %This is because the first dimension is row in DICOM but COLUMN in MATLAB
iField(:,:,1:2:end,:) = -iField(:,:,1:2:end,:);
if length(TE)==1
    delta_TE = TE;
else
    delta_TE = TE(2) - TE(1);
end

end

