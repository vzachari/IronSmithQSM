function [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_United_DICOM(DicomFolder)

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

fnTemp = [DicomFolder '/' filelist(1).name];

info = dicominfo(fnTemp);
matrix_size(1) = single(info.Width);
matrix_size(2) = single(info.Height);
NumSlice = single(info.NumberOfSlices); % includes all echoes

matrix_size(3) = 1;

% NumEcho = single(info.EchoTrainLength);
NumEcho = 0;
voxel_size(1,1) = single(info.PixelSpacing(1));
voxel_size(2,1) = single(info.PixelSpacing(2));
voxel_size(3,1) = single(info.SliceThickness);

CF = info.ImagingFrequency;
isz=[matrix_size(1) matrix_size(2) NumSlice];
iPhase = zeros(isz,'single');
iMag = zeros(isz,'single');
filesM={};
filesP={};
filesPfun={};

% TE = single(zeros([NumEcho 1]));

TE = [];
p_ImagePositionPatient = zeros(3, matrix_size(3)*NumEcho);
m_ImagePositionPatient = zeros(3, matrix_size(3)*NumEcho);
r_EchoNumber = zeros(matrix_size(3)*NumEcho,1);
minSlice = 1e10;
maxSlice = -1e10;

rctr = 0; ictr=0;
progress='';
for i = 1:length(filelist)
    filename=[DicomFolder '/' filelist(i).name];
    info2 = get_dcm_tags(filename);
    
    if info2.SliceLocation<minSlice
        minSlice = info2.SliceLocation;
        minLoc = info2.ImagePositionPatient;
    end
    if info2.SliceLocation>maxSlice
        maxSlice = info2.SliceLocation;
        maxLoc = info2.ImagePositionPatient;
    end
    % this assumes we encounter our echo times
    % in increasing order as we loop through
    % the dicom files
    if isempty(find(TE==info2.EchoTime))
        TE = [TE; info2.EchoTime];
        TE = sort(TE);
        NumEcho = NumEcho + 1; 
    end
    info2.EchoNumber=find(TE==info2.EchoTime);
    if (info2.ImageType(18)=='P')||(info2.ImageType(18)=='p')
%         attrs=dicomattrs(filename);
        rctr = rctr + 1;
        print_progress(rctr+ictr);
        p_ImagePositionPatient(:,rctr) = info2.ImagePositionPatient;
        r_EchoNumber(rctr) = info2.EchoNumber;
        ph = transpose(single(dicomread(filename)));
        phmin = single(info2.SmallestImagePixelValue);
        phmax = single(info2.LargestImagePixelValue);
        iPhase(:,:,rctr)  = (ph-phmin)/(phmax-phmin)*2*pi - pi;
        filesP{rctr} = filename;
        filesPfun{rctr} = @(x) (x-phmin)/(phmax-phmin)*2*pi - pi;
    elseif (info2.ImageType(18)=='M')||(info2.ImageType(18)=='m')
        ictr = ictr + 1;
        print_progress(rctr+ictr);
        m_ImagePositionPatient(:,ictr) = info2.ImagePositionPatient;
        i_EchoNumber(ictr) = info2.EchoNumber;
        iMag(:,:,ictr)  = transpose(single(dicomread(filename)));%magnitude
        filesM{ictr} = filename;
    end
end
fprintf('\n');

TE = TE*1e-3;
matrix_size(3) = round(norm(maxLoc - minLoc)/voxel_size(3))+1 ;

Affine2D = reshape(info.ImageOrientationPatient,[3 2]);
Affine3D = [Affine2D (maxLoc-minLoc)/( (matrix_size(3)-1)*voxel_size(3))];
B0_dir = Affine3D\[0 0 1]';
files.Affine3D=Affine3D;
files.minLoc=minLoc;
files.maxLoc=maxLoc;
sz=size(p_ImagePositionPatient); sz(1)=1;
minLoc=repmat(minLoc, sz);

p_slice = int32(round(sqrt(sum((p_ImagePositionPatient-minLoc).^2,1))/voxel_size(3)) +1);
p_ind = sub2ind([matrix_size(3) NumEcho], p_slice(:), int32(r_EchoNumber(:)));
iPhase(:,:,p_ind) = iPhase;
files.P=cell(matrix_size(3), NumEcho);
files.P(p_ind)=filesP;
files.Pfun=cell(matrix_size(3), NumEcho);
files.Pfun(p_ind)=filesPfun;

m_slice = int32(round(sqrt(sum((m_ImagePositionPatient-minLoc).^2,1))/voxel_size(3)) +1);
m_ind = sub2ind([matrix_size(3) NumEcho], m_slice(:), int32(i_EchoNumber(:)));
iMag(:,:,m_ind) = iMag;
files.M=cell(matrix_size(3), NumEcho);
files.M(m_ind)=filesM;

files.phasesign=1;
files.zchop=0;

iField = reshape(iMag.*exp(1i*iPhase), ...
    [matrix_size(1) matrix_size(2) matrix_size(3) NumEcho]);
% iField = permute(iField,[2 1 3 4 5]); %This is because the first dimension is row in DICOM but COLUMN in MATLAB
% iField(:,:,1:2:end,:) = -iField(:,:,1:2:end,:);
if length(TE)==1
    delta_TE = TE;
else
    delta_TE = TE(2) - TE(1);
end

    function print_progress(ctr)
        for ii=1:length(progress); fprintf('\b'); end
        progress=sprintf('Reading file %d', ctr);
        fprintf(progress);
    end
end

function info = get_dcm_tags(filename)
attrs=dicomattrs(filename);
for t={'SliceLocation','ImagePositionPatient',...
        'EchoTime','ImageType','LargestImagePixelValue','SmallestImagePixelValue'}
    t=char(t);
    [gr, el] = dicomlookup(t);
    for i=1:length(attrs);
        if (attrs(i).Group==gr)&&(attrs(i).Element==el)
            switch(attrs(i).VR)
                case 'DS'
                    info.(t) = sscanf(char(attrs(i).Data), '%f\\');
                case 'CS'
                    info.(t) = char(attrs(i).Data);
                case 'SS'
                    info.(t) = typecast(attrs(i).Data,'int16');
                case 'US'
                    info.(t) = typecast(attrs(i).Data,'uint16');
                otherwise
                    error(['get_dcm_tags cannot deal with VR ' attrs(i).VR...
                           ' for tag ' t]); 
            end
        end
    end
    
end

end

