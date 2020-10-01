function [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_DICOM_Philips_3D(DicomFolder, type)

if nargin<2
    type='MP';
end

files=struct;
files.info3D=struct;
files.info3D.slice2index={};

if ~isstruct(DicomFolder)
    filelist = dir(DicomFolder);
    i=1;
    while i<=length(filelist)
        if filelist(i).isdir==1
            filelist = filelist([1:i-1 i+1:end]);   % skip folders
            %         elseif ~isdicom(fullfile(DicomFolder, filelist(i).name))
            %             filelist = filelist([1:i-1 i+1:end]);   % skip folders
        else
            i=i+1;
        end
    end
    
    for i = 1:length(filelist)
        filename=fullfile(DicomFolder,filelist(i).name);
        fprintf('Reading header from %s...\n', filename);
        info=dicominfo(filename);
        if isfield(info, 'ImageType')
            break;
        end
    end
else
    info = DicomFolder;
    filename = info.Filename;
end

files.info3D.filename=filename;
files.InPlanePhaseEncodingDirection=info.SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.InPlanePhaseEncodingDirection;
files.Manufacturer = info.Manufacturer;
files.InstitutionName = info.InstitutionName;

% if ~contains(info.Manufacturer,'philips','IgnoreCase',true)
if ~contains(lower(info.Manufacturer), 'philips')
    error('This is not a Philips DICOM file')
end
fprintf('Reading pixel data from %s...\n', filename);
data=single(dicomread(filename));
% transpose X, Y to be consistent with Read_DICOM
permarg=1:numel(size(data));
permarg(1:2)=[2 1];
data=permute(data,permarg);

matrix_size(1) = single(info.Width);
matrix_size(2) = single(info.Height);
voxel_size(1,1) = single(info.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing(1));
voxel_size(2,1) = single(info.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing(2));
if isfield(info, 'SpacingBetweenSlices')
    voxel_size(3,1) = single(info.SpacingBetweenSlices);
elseif isfield(info.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1,'SpacingBetweenSlices')
    voxel_size(3,1) = single(info.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.SpacingBetweenSlices);
else
    voxel_size(3,1) = single(info.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.SpacingBetweenSlices);
end


CF = info.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.ImagingFrequency *1e6;

minSlice = 1e10;
maxSlice = -1e10;
if isfield(info, 'EchoTrainLength')
    NumEcho = info.EchoTrainLength;
else
    NumEcho = 0;
    EchoTimes=[];
end
f=fieldnames(info.PerFrameFunctionalGroupsSequence);
for i = 1:length(f)
    SliceLocation = info.PerFrameFunctionalGroupsSequence.(f{i}).FrameContentSequence.Item_1.InStackPositionNumber;
    ImagePositionPatient=info.PerFrameFunctionalGroupsSequence.(f{i}).PlanePositionSequence.Item_1.ImagePositionPatient;
    if SliceLocation<minSlice
       minSlice = SliceLocation;
       minLoc = ImagePositionPatient;
    end
    if SliceLocation>maxSlice
       maxSlice = SliceLocation;
       maxLoc = ImagePositionPatient;
    end
    if 0==NumEcho
        EchoTimes=[EchoTimes info.PerFrameFunctionalGroupsSequence.(f{i}).MREchoSequence.Item_1.EffectiveEchoTime];
        EchoTimes=unique(EchoTimes);
    end
end
matrix_size(3) = round(norm(maxLoc - minLoc)/voxel_size(3)) + 1;
if 0==NumEcho
    NumEcho=length(EchoTimes);
end

Affine2D = reshape(info.PerFrameFunctionalGroupsSequence.Item_1.PlaneOrientationSequence.Item_1.ImageOrientationPatient,[3 2]);
Affine3D = [Affine2D (maxLoc-minLoc)/( (matrix_size(3)-1)*voxel_size(3))];
B0_dir = Affine3D\[0 0 1]';
files.Affine3D=Affine3D;
files.minLoc=minLoc;
files.maxLoc=maxLoc;
%             iMag = single(zeros([matrix_size NumEcho]));
%             iPhase = single(zeros([matrix_size NumEcho]));
iMag = [];
iPhase = [];
iReal= [];
iImag= [];
TE = single(zeros([NumEcho 1]));

for i = 1:length(f)
    ImagePositionPatient=info.PerFrameFunctionalGroupsSequence.(f{i}).PlanePositionSequence.Item_1.ImagePositionPatient;
    EchoNumber=info.PerFrameFunctionalGroupsSequence.(f{i}).Private_2005_140f.Item_1.EchoNumber;
    EchoTime=info.PerFrameFunctionalGroupsSequence.(f{i}).Private_2005_140f.Item_1.EchoTime;
    RealWorldValueMappingSequence=info.PerFrameFunctionalGroupsSequence.(f{i}).RealWorldValueMappingSequence;
    ImageType=info.PerFrameFunctionalGroupsSequence.(f{i}).Private_2005_140f.Item_1.ImageType;
    slice = int32(round(norm(ImagePositionPatient-minLoc)/voxel_size(3)) +1);
    if NumEcho==EchoNumber
        files.info3D.slice2index{slice}=f{i};
    end
    
    if TE(EchoNumber)==0
        TE(EchoNumber)=EchoTime*1e-3;
    end
    slope=RealWorldValueMappingSequence.Item_1.RealWorldValueSlope;
    intercept=RealWorldValueMappingSequence.Item_1.RealWorldValueIntercept;
    if (ImageType(18)=='P')||(ImageType(18)=='p')
%         files.P{slice,EchoNumber}=filename;
        if isempty(iPhase); iPhase = single(zeros([matrix_size NumEcho])); end
        iPhase(:,:,slice,EchoNumber)  = 1e-3*(data(:,:,1,i)*slope+intercept);%phase
    elseif (ImageType(18)=='M')||(ImageType(18)=='m')
%         files.M{slice,EchoNumber}=filename;
        if isempty(iMag); iMag = single(zeros([matrix_size NumEcho])); end
        iMag(:,:,slice,EchoNumber)  = data(:,:,1,i);%magnitude
    elseif (ImageType(18)=='R')||(ImageType(18)=='r')
%         files.R{slice,EchoNumber}=filename;
        if isempty(iReal); iReal = single(zeros([matrix_size NumEcho])); end
        iReal(:,:,slice,EchoNumber)  = data(:,:,1,i)*slope+intercept;%real
    elseif (ImageType(18)=='I')||(ImageType(18)=='i')
%         files.I{slice,EchoNumber}=filename;
        if isempty(iImag); iImag = single(zeros([matrix_size NumEcho])); end
        iImag(:,:,slice,EchoNumber)  = data(:,:,1,i)*slope+intercept;%imaginary
    end
end
files.phasesign = -1;
files.zchop = 0;
clear('data');
if ~isempty(iMag) && ~isempty(iPhase) && strcmp(type,'MP')
    iField = iMag.*exp(complex(0,-iPhase));
    clear iMag iPhase;
elseif ~isempty(iReal) && ~isempty(iImag) 
    iField = complex(iReal, -iImag);
    clear iReal iMag;
else
    error('No iField found');
end
if length(TE)==1
    delta_TE = TE;
else
    delta_TE = TE(2) - TE(1);
end

if 1==mod(matrix_size(3),2)
    files.slices_added=1;
    warning('Adding empty slice at bottom of volume');
    iField=padarray(iField, [0 0 1 0], 0, 'post');
    matrix_size=matrix_size+[0 0 1];
end
if ~isstruct(DicomFolder)
    disp('PHILIPS READ');
end


