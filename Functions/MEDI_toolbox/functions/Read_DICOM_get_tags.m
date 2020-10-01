function info = Read_DICOM_get_tags(filename, tags)
if isempty(filename)
    info=[];
    return
elseif isstruct(filename)
    attrs=filename;
else
    attrs=dicomattrs(filename);
end
info=struct;
num_found=0;
for t=tags
    t=char(t);
    [gr, el] = dicomlookup(t);
    for k=1:length(attrs);
        if (attrs(k).Group==gr)&&(attrs(k).Element==el)
            num_found = num_found + 1;
            switch(attrs(k).VR)
                case 'DS'
                    info.(t) = sscanf(char(attrs(k).Data), '%f\\');
                case 'IS'
                    info.(t) = sscanf(char(attrs(k).Data), '%d\\');
                case 'CS'
                    info.(t) = char(attrs(k).Data);
                case 'LO'
                    info.(t) = char(attrs(k).Data);
                case 'SS'
                    info.(t) = typecast(attrs(k).Data,'int16');
                case 'US'
                    info.(t) = typecast(attrs(k).Data,'uint16');
                case 'FD'
                    info.(t) = typecast(attrs(k).Data,'double');
                case 'SQ'
                    for j=1:length(attrs(k).Data)
                        info.(t).(['Item_' num2str(j)])=...
                            Read_DICOM_get_tags(attrs(k).Data(j).Data, tags);
                    end
                otherwise
                    error(['Read_DICOM_get_tags cannot deal with VR ' attrs(k).VR...
                        ' for tag ' t]);
                    %                             if isstruct(attrs(k).Data)
                    %                                 info.(t)=attrs(k).Data;
                    %                             else
                    %                                 info.(t)=get_dcm_tags(attrs(k).Data, tags);
                    %                             end
                    
            end
        end
        if num_found == length(tags)
            return
        end
    end
    
end

end