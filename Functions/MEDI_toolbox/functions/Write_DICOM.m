function Write_DICOM(M,files,outdir,opts)
%WRITE_DICOM Summary of this function goes here
%   Detailed explanation goes here


defopts.SeriesDescription = 'QSM';
defopts.SeriesInstanceUID = [];
defopts.SeriesNumber = [];
defopts.Convert = @(x) convert(x);
defopts.Window = 0.500;
defopts.Level = 0;
defopts.flag3D = 0;
% defopts.EchoNumber = [];
% defopts.EchoTime = 0.0;
        
if nargin<4; opts=struct; end
deffields=fieldnames(defopts);
for i=1:length(deffields)
    if ~isfield(opts, deffields{i})
        opts.(deffields{i})=defopts.(deffields{i});
    end
end

if isfield(files,'M')
    filenames=files.M;
elseif isfield(files,'R')
    filenames=files.R;
elseif isfield(files, 'info3D')
    opts.flag3D=1;
else
    error('No filenames (M nor R) found.');
end
    
flag_signed=min(M(:))<0;

if ~opts.flag3D
    if size(M,3) ~= size(filenames,1)
        error([num2str(size(filenames,1)) ' filenames given for ' num2str(size(M,3)) ' slices.']);
    end
end

if isempty(opts.SeriesInstanceUID)
   opts.SeriesInstanceUID=dicomuid;
end
progress='';

mkdir(outdir);

warning('off','images:dicom_add_attr:invalidAttribChar');
load_flag=1;
insert_flag=~opts.flag3D;
for slice=1:size(M,3)
    if load_flag
        if opts.flag3D
            filename=files.info3D.filename;
        else
            filename=filenames{slice,end};
        end
        info = dicominfo(filename);
        info.SeriesDescription = opts.SeriesDescription;
        info.SeriesInstanceUID = opts.SeriesInstanceUID;
        if isempty(opts.SeriesNumber)
            opts.SeriesNumber=info.SeriesNumber*100;
        end
        info.SeriesNumber = opts.SeriesNumber;
        info.SOPInstanceUID = dicomuid;
        info.InstanceNumber = slice;
        if opts.flag3D
            load_flag=0;
        end
    end
    if opts.flag3D
        item=files.info3D.slice2index{slice};
%         info.PerFrameFunctionalGroupsSequence.(item).PlanePositionSequence.Item_1.ImagePositionPatient;
        info.PerFrameFunctionalGroupsSequence.(item).Private_2005_140f.Item_1.SOPInstanceUID = dicomuid;
    end
    im = M(:,:,slice);
    if (isfield(info, 'SmallestImagePixelValue'))
        info.SmallestImagePixelValue=opts.Convert(min(im(:)));
    end
    if (isfield(info, 'LargestImagePixelValue'))
        info.LargestImagePixelValue=opts.Convert(max(im(:)));
    end
    if (isfield(info, 'RescaleIntercept'))
        info.RescaleIntercept=0;
    end
    if (isfield(info, 'RescaleSlope'))
        info.RescaleSlope=1;
    end
    info.WindowCenter=opts.Convert(opts.Level);
    info.WindowWidth=opts.Convert(opts.Window);
%     if opts.flag3D
%         info.PerFrameFunctionalGroupsSequence.Item_1.PixelValueTransformationSequence.Item_1.RescaleIntercept=0;
%         info.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.RescaleIntercept=0;
%         info.PerFrameFunctionalGroupsSequence.Item_1.PixelValueTransformationSequence.Item_1.RescaleSlope=1;
%         info.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.RescaleSlope=1;
%         info.PerFrameFunctionalGroupsSequence.Item_1.FrameVOILUTSequence.Item_1.WindowCenter=opts.Convert(opts.Level);
%         info.PerFrameFunctionalGroupsSequence.Item_1.FrameVOILUTSequence.Item_1.WindowWidth=opts.Convert(opts.Window);
%     end
	info.SamplesPerPixel=1;
    info.BitsAllocated=16;
    info.BitsStored=16;
    info.HighBit=15;
    info.PixelRepresentation=flag_signed;
    if size(M,3)==slice
        insert_flag=1;
    end
    if insert_flag
        outfile=fullfile(outdir,sprintf('IM%05d.dcm', slice));
        print_progress(outfile);
        if opts.flag3D
           f=fieldnames(info.PerFrameFunctionalGroupsSequence);
           f=setdiff(f,files.info3D.slice2index,'stable');
           for i=1:length(f)
               info.PerFrameFunctionalGroupsSequence=rmfield(info.PerFrameFunctionalGroupsSequence, f{i});
           end
           for i=1:length(files.info3D.slice2index)
               item=files.info3D.slice2index{i};
               info.PerFrameFunctionalGroupsSequence.(item).Private_2005_140f.Item_1.InstanceNumber=1;
               info.PerFrameFunctionalGroupsSequence.(item).PixelValueTransformationSequence.Item_1.RescaleIntercept=0;
               info.PerFrameFunctionalGroupsSequence.(item).Private_2005_140f.Item_1.RescaleIntercept=0;
               info.PerFrameFunctionalGroupsSequence.(item).PixelValueTransformationSequence.Item_1.RescaleSlope=1;
               info.PerFrameFunctionalGroupsSequence.(item).Private_2005_140f.Item_1.RescaleSlope=1;
               info.PerFrameFunctionalGroupsSequence.(item).FrameVOILUTSequence.Item_1.WindowCenter=opts.Convert(opts.Level);
               info.PerFrameFunctionalGroupsSequence.(item).FrameVOILUTSequence.Item_1.WindowWidth=opts.Convert(opts.Window);   
           end
           info.NumberOfFrames=length(files.info3D.slice2index);
           sz=size(M);
           M=reshape(opts.Convert(M), sz(1), sz(2), 1, []);
           M=permute(M, [2 1 3 4]);
           if isfield(files, 'slices_added')
               if files.slices_added
                   warning('Removing empty slice at bottom of volume');
                   M=M(:,:,1:end-1);
               end
           end
           dicomwrite(M,outfile, ...
               'CreateMode', 'copy', 'WritePrivate', true, info);
        else
            if isfield(files, 'slices_added')
                if files.slices_added
                    warning('Removing empty slice at bottom of volume');
                    M=M(:,:,1:end-1);
                end
            end
            dicomwrite(opts.Convert(M(:,:,slice))',outfile, ...
                'CreateMode', 'copy', 'WritePrivate', true, info);
        end
    end
end
fprintf('\n');


    function print_progress(arg)
        num=length(progress);
        num=num-numel(regexp(progress, '\\\\'));
        for ii=1:num; fprintf('\b'); end
        progress=['Writing file ' arg];
        progress=regexprep(progress,'\','\\\\');
        fprintf(progress);
    end

    function y=convert(x)
        if flag_signed
            y=int16(x*1000);
        else
            y=uint16(x*1000);
        end
    end
end