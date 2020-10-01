function [g1, g2, in, fit] = gffun(echo_laplacian,Mask, weight, InPlanePhaseEncodingDirection)

CL=class(echo_laplacian);

if nargin<3
    weight=ones(size(echo_laplacian),CL);
end
if nargin < 4
    InPlanePhaseEncodingDirection='';
end
if strcmp(InPlanePhaseEncodingDirection,'ROW')
    dirs=2;
elseif strcmp(InPlanePhaseEncodingDirection,'COLUMN')
    dirs=1;
else
    dirs=[1 2];
end
ndirs=numel(dirs);

if (nargout>3)
    fit=echo_laplacian;
end

matrix_size = size(Mask);
% A = zeros(matrix_size,CL);
% B = zeros(matrix_size,CL);
A = ones([matrix_size ndirs]);

g1 = zeros([size(echo_laplacian,4), 1],CL);
g2 = zeros([size(echo_laplacian,4), 1],CL);
in = zeros([size(echo_laplacian,4), 1],CL);

% for i = 1 : matrix_size(1)
%     A(i,:,:) = i;
% end
% for i = 1 : matrix_size(2)
%     B(:,i,:) = i;
% end

for j=1:ndirs
    resarg=[1 1]; resarg(dirs(j))=matrix_size(dirs(j));
    idx=reshape(1:matrix_size(dirs(j)), resarg);
    A(:,:,:,j)=bsxfun(@times, idx, A(:,:,:,j));
end
A = reshape(A, [], ndirs);    

for jj = 1 : size(echo_laplacian,4)
    
    W = squeeze(weight(:,:,:,jj));
    W = W(Mask>0);
%     indX = A(Mask>0).*W;
%     indY = B(Mask>0).*W;
    ind = bsxfun(@times, W, A(Mask>0,:));
    V = squeeze(echo_laplacian(:,:,:,jj));
    V = V(Mask>0).*W;
  
    X = [ind W];
    b1 = X\V;
    
    for k=1:5
        if 0
            tmp=zeros(matrix_size, CL);
            tmp(Mask>0)=X*b1./W; vis([echo_laplacian tmp echo_laplacian-tmp]);
        end
%         vis(tmp,'Title',['iter ' num2str(k,'%02d')])
        wres=X*b1-V;
        wres = abs(wres - mean(wres));
        factor = std(wres);
        wres = wres/factor;
        wres(wres<1) = 1;
        X=X./wres; V=V./wres; W=W./wres;
        b1 = X\V;
        
    end
    
    for m=1:ndirs
        eval(['g' num2str(dirs(m)) '(jj) = b1(m);']);
    end
    in(jj) = b1(end);
    
    if nargout>3
        tmp=zeros(matrix_size, CL);
        tmp(Mask>0)=X*b1./W;
        fit(:,:,:,jj)=tmp;
    end 
    

end

end