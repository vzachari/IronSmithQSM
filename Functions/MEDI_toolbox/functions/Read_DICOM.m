function [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_DICOM(DicomFolder, varargin)

manufacturer='';
if nargin>1
    for k=1:size(varargin,2)
        if strcmpi(varargin{k},'manufacturer')
            manufacturer=varargin{k+1};
        end
    end
end


create_dicomattrs;

files=struct;

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

fnTemp=fullfile(DicomFolder, filelist(1).name);


info = dicominfo(fnTemp);
if isempty(manufacturer)
    manufacturer = info.Manufacturer;
end
if isfield(info, 'InstitutionName')
    institute = info.InstitutionName;
else
    institute = '';
end

if isfield(info, 'InPlanePhaseEncodingDirection')
    files.InPlanePhaseEncodingDirection=info.InPlanePhaseEncodingDirection;
end
files.Manufacturer = manufacturer;
files.InstitutionName = institute;

switch lower(manufacturer)
    
    case {'siemens','siemens healthcare gmbh'}
        [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_Siemens_DICOM(DicomFolder);
        
        disp('SIEMENS READ');
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%GE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%PART%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'ge medical systems'
        
        if ~isempty(strfind(lower(institute), 'tongji')) || ~isempty(strfind(lower(institute), 'zju')) || ~isempty(strfind(lower(institute), 'aff2'))
            warning('Please checking dicom intensity to phase conversion');
            %                 if ~isempty(strfind(lower(institute), 'mw02'))
            %                     phase_scale = @(info) 4096;
            %                 else
            phase_scale = @(info) single(info.LargestImagePixelValue);
            %                 end
            
            matrix_size(1) = single(info.Width);
            matrix_size(2) = single(info.Height);
            %                 tmp = single(info.Private_0021_104f);
            %                 matrix_size(3) = tmp(1);
            if isa(info.Private_0019_107e,'uint8')
                NumEcho = single(typecast(info.Private_0019_107e,'uint16'));
            else
                NumEcho = single(info.Private_0019_107e);
            end
            voxel_size(1,1) = single(info.PixelSpacing(1));
            voxel_size(2,1) = single(info.PixelSpacing(2));
            voxel_size(3,1) = single(info.SpacingBetweenSlices);
            CF = info.ImagingFrequency *1e6;
            
            TE = single(zeros([NumEcho 1]));
            
            minSlice = 1e10;
            maxSlice = -1e10;
            
            for i = 1:length(filelist)
                filename=fullfile(DicomFolder,filelist(i).name);
                if isdicom(filename)
                    %                         info = dicominfo(filename);
                    info = Read_DICOM_get_tags(filename, ...
                        {'SliceLocation','ImagePositionPatient','ImageOrientationPatient'});
                    if info.SliceLocation<minSlice
                        minSlice = info.SliceLocation;
                        minLoc = info.ImagePositionPatient;
                    end
                    if info.SliceLocation>maxSlice
                        maxSlice = info.SliceLocation;
                        maxLoc = info.ImagePositionPatient;
                    end
                else
                    disp([ filename ' is not a dicom file']);
                end
            end
            matrix_size(3) = round(norm(maxLoc - minLoc)/voxel_size(3)) + 1;
            iMag = single(zeros([matrix_size NumEcho]));
            iPhase = single(zeros([matrix_size NumEcho]));
            
            Affine2D = reshape(info.ImageOrientationPatient,[3 2]);
            Affine3D = [Affine2D (maxLoc-minLoc)/( (matrix_size(3)-1)*voxel_size(3))];
            B0_dir = Affine3D\[0 0 1]';
            files.Affine3D=Affine3D;
            files.minLoc=minLoc;
            files.maxLoc=maxLoc;
            for i = 1:length(filelist)
                filename=fullfile(DicomFolder, filelist(i).name);
                if isdicom(filename)
                    %                         info = dicominfo(filename);
                    info = Read_DICOM_get_tags(filename, ...
                        {'SliceLocation','ImagePositionPatient', 'EchoNumber','InstanceNumber',...
                        'EchoTime','LargestImagePixelValue'});
                    slice = int32(round(sqrt(sum((info.ImagePositionPatient-minLoc).^2))/voxel_size(3)) +1);
                    if TE(info.EchoNumber)==0
                        TE(info.EchoNumber)=info.EchoTime*1e-3;
                    end
                    if mod(info.InstanceNumber,2)==1
                        files.M{slice,info.EchoNumber}=filename;
                        iMag(:,:,slice,info.EchoNumber)  = single(dicomread(filename)');%magnitude
                    elseif mod(info.InstanceNumber,2)==0
                        files.P{slice,info.EchoNumber}=filename;
                        %                             largestImagePixelValue = single(info.LargestImagePixelValue);
                        %                             largestImagePixelValue = 4096;
                        iPhase(:,:,slice,info.EchoNumber)  = single(dicomread(filename)')/phase_scale(info)*pi;%phase
                    end
                end
            end
            files.phasesign=1;
            files.zchop=1;
            
            iField = iMag .* exp(sqrt(-1)*iPhase);
            clear iMag iPhase;
            for echo = 1:NumEcho
                iField(:,:,:,echo) = ifft( fftshift( fft(iField(:,:,:,echo),[],3),3),[],3);
            end
            if length(TE)==1
                delta_TE = TE;
            else
                delta_TE = TE(2) - TE(1);
            end
            
            
            disp('GE READ other');
            
        else
            
            
            [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_GE_DICOM(DicomFolder);
            
            disp('GE READ');
            
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%PHILIPS NEED
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%MOD
    case {'philips', 'philips medical systems'}
        i=1;
        while ~isfield(info, 'ImageType')
            i=1+1;
            filename=fullfile(DicomFolder,filelist(i).name);
            info=dicominfo(filename);
        end
        if isfield(info, 'PerFrameFunctionalGroupsSequence')
            [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir, files]=Read_DICOM_Philips_3D(info);
        else         
            matrix_size(1) = single(info.Width);
            matrix_size(2) = single(info.Height);
            voxel_size(1,1) = single(info.PixelSpacing(1));
            voxel_size(2,1) = single(info.PixelSpacing(2));
            %         voxel_size(3,1) = single(info.SliceThickness);
            voxel_size(3,1) = single(info.SpacingBetweenSlices);
            CF = info.ImagingFrequency *1e6;
            Affine2D = reshape(info.ImageOrientationPatient,[3 2]);
            NumEcho=0;
            matrix_size(3)=0;
            %         if isfield(info, 'Private_2001_1014')
            %             NumEcho=info.Private_2001_1014;
            %         end
            %         if isfield(info, 'Private_2001_1014')
            %             matrix_size(3)=info.Private_2001_1014;
            %         end
            
            minSlice = 1e10;
            maxSlice = -1e10;
            progress='';
            i=1;
            while i<=length(filelist)
                %             info = dicominfo([DicomFolder '/' filelist(i).name]);
                filename=fullfile(DicomFolder,filelist(i).name);
                if isdicom(filename)
                    info = Read_DICOM_get_tags(filename, ...
                        {'SliceLocation','ImagePositionPatient',...
                        'EchoNumber','ImageOrientationPatient'});
                    if ~isfield(info, 'SliceLocation')
                        continue
                    end
                    if info.SliceLocation<minSlice
                        minSlice = info.SliceLocation;
                        minLoc = info.ImagePositionPatient;
                    end
                    if info.SliceLocation>maxSlice
                        maxSlice = info.SliceLocation;
                        maxLoc = info.ImagePositionPatient;
                    end
                    if info.EchoNumber>NumEcho
                        NumEcho = info.EchoNumber;
                    end
                    if 0==mod(length(filelist)-i,10)
                        for ii=1:length(progress); fprintf('\b'); end
                        progress=sprintf('Reading file %d', i);
                        fprintf(progress);
                    end
                    i=i+1;
                else
                    filelist = filelist([1:i-1 i+1:end]);
                end
            end
            fprintf('\n');
            matrix_size(3) = round(norm(maxLoc - minLoc)/voxel_size(3)) + 1;
            
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
            
            progress='';
            tags={'ImagePositionPatient', 'EchoNumber','ImageType',...
                'RealWorldValueMappingSequence','RescaleSlope','RescaleIntercept',...
                'EchoTime','RealWorldValueSlope','RealWorldValueIntercept',};
            for i = 1:length(filelist)
                filename = fullfile(DicomFolder,filelist(i).name);
                %             info = dicominfo(filename);
                info = Read_DICOM_get_tags(filename, tags);
                if 0==length(fieldnames(info))
                    continue
                end
                %             slice = matrix_size(3)-info.Private_2001_100a+1;
                slice = int32(round(norm(info.ImagePositionPatient-minLoc)/voxel_size(3)) +1);
                if TE(info.EchoNumber)==0
                    TE(info.EchoNumber)=info.EchoTime*1e-3;
                end
                if isfield(info, 'RescaleSlope')
                    slope=info.RescaleSlope;
                    intercept=info.RescaleIntercept;
                    %                 tags=setdiff(tags,{'RealWorldValueMappingSequence',...
                    %                     'RealWorldValueSlope','RealWorldValueIntercept'});
                else
                    slope=info.RealWorldValueMappingSequence.Item_1.RealWorldValueSlope;
                    intercept=info.RealWorldValueMappingSequence.Item_1.RealWorldValueIntercept;
                    %                 tags=setdiff(tags,{'RescaleSlope','RescaleIntercept'});
                end
                if (info.ImageType(18)=='P')||(info.ImageType(18)=='p')
                    files.P{slice,info.EchoNumber}=filename;
                    if isempty(iPhase); iPhase = single(zeros([matrix_size NumEcho])); end
                    iPhase(:,:,slice,info.EchoNumber)  = 1e-3*(single(dicomread(filename)')*slope+intercept);%phase
                elseif (info.ImageType(18)=='M')||(info.ImageType(18)=='m')
                    files.M{slice,info.EchoNumber}=filename;
                    if isempty(iMag); iMag = single(zeros([matrix_size NumEcho])); end
                    iMag(:,:,slice,info.EchoNumber)  = single(dicomread(filename)');%magnitude
                elseif (info.ImageType(18)=='R')||(info.ImageType(18)=='r')
                    files.R{slice,info.EchoNumber}=filename;
                    if isempty(iReal); iReal = single(zeros([matrix_size NumEcho])); end
                    iReal(:,:,slice,info.EchoNumber)  = single(dicomread(filename)')*slope+intercept;%real
                elseif (info.ImageType(18)=='I')||(info.ImageType(18)=='i')
                    files.I{slice,info.EchoNumber}=filename;
                    if isempty(iImag); iImag = single(zeros([matrix_size NumEcho])); end
                    iImag(:,:,slice,info.EchoNumber)  = single(dicomread(filename)')*slope+intercept;%imaginary
                end
                if 0==mod(length(filelist)-i,10)
                    for ii=1:length(progress); fprintf('\b'); end
                    progress=sprintf('Reading file %d', i);
                    fprintf(progress);
                end
            end
            fprintf('\n');
            files.phasesign = -1;
            files.zchop = 0;
            
            if ~isempty(iMag) && ~isempty(iPhase)
                iField = iMag.*exp(-1i*iPhase);
                clear iMag iPhase;
            elseif ~isempty(iReal) && ~isempty(iImag)
                iField = complex(iReal, iImag);
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
        end
        disp('PHILIPS READ');
        
    case 'uih'
        [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_United_DICOM(DicomFolder);
        
        disp('UNITEDIMAGING READ');
        
    case 'hitachi medical corporation'
        [iField,voxel_size,matrix_size,CF,delta_TE,TE,B0_dir,files]=Read_Hitachi_DICOM(DicomFolder);
        
        disp('HITACHI READ');
    otherwise
        disp(['Unknown manufacturer:' manufacturer '. Please set using manufacturer option'])
        disp('LOADING FAILED');
        
        
        
        
        
end

end
