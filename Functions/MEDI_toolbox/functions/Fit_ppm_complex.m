 % Projection onto Dipole Fields (PDF)
%   [p1, dp1, relres, p0]=Fit_ppm_complex(M)
%    
%   output
%   p1 - field map, may need further unwrapping
%   dp1 - a priori error estimate
%   relres - relative residual
%   p0 - initial phase
%
%   input
%   M - a multi-echo and could be a multi-channel dataset
%       echo needs to be the 4th dimension
%       channel needs to be the 5th dimension
%
%   When using the code, please cite 
%   T. Liu et al. MRM 2013;69(2):467-76
%   B. Kressler et al. IEEE TMI 2010;29(2):273-81
%   de Rochefort et al. MRM 2008;60(4):1003-1009
%
%   The coil combination method is similar to
%   MA. Bernstein et al. MRM 1994;32:330-334
%
%   Adapted from a linear fitting created by Ludovic de Rochefort
%   Modified by Tian Liu on 2011.06.01
%   Last modified by Alexey Dimov on 2016.05.12


function [p1, dp1, relres, p0]=Fit_ppm_complex(M, opts)

defopts.reltol=1e-4;
defopts.max_iter=30;

if nargin<2
    opts=defopts;
else
    deffn=fieldnames(defopts);
    for i=1:length(deffn)
        if ~isfield(opts, deffn{i})
            opts.(deffn{i})=defopts.(deffn{i});
        end
    end
end

bytes=whos('M');
bytes=bytes.bytes;
if (bytes>1e9)
    sz=size(M);
    p1=zeros(sz(1:3),class(M));
    dp1=zeros(sz(1:3),class(M));
    relres=zeros(sz(1:3),class(M));
    p0=zeros(sz(1:3),class(M));
    n=ceil(bytes/1e9);
    ns=floor(sz(3)/n);
    for slice=1:ns:sz(3)
        rng=slice:min(slice+ns-1,sz(3));
        disp(['fitting slice ' num2str(rng(1)) ' through ' num2str(rng(end)) ' ...']);
        [p1(:,:,rng), dp1(:,:,rng), relres(:,:,rng), p0(:,:,rng)]=Fit_ppm_complex(M(:,:,rng,:,:),opts);
    end
    return
end


%Modification to handle one echo datasets - assuming zero phase at TE = 0;
%- AD, 05/12/2016
if size(M,4) == 1
    M = cat(4,abs(M),M);
end

if size(M,5)>1
% combine multiple coils together, assuming the coil is the fifth dimension
    M = sum(M.*conj( repmat(M(:,:,:,1,:),[1 1 1 size(M,4) 1])),5);  
    M = sqrt(abs(M)).*exp(1i*angle(M));
end


M= conj(M);
s0=size(M);
L_s0=length(s0);
nechos=size(M,L_s0);

M=reshape(M,[prod(s0(1:L_s0-1)),s0(L_s0)]);
s=size(M);

Y=angle(M(:,1:min(3,nechos)));
c=((Y(:,2)-Y(:,1)));
[m ind]=min([abs(c-2*pi),abs(c),abs(c+2*pi)],[],2);
c(ind==1)=c(ind==1)-2*pi;
c(ind==3)=c(ind==3)+2*pi;

for n=1:min(2,nechos-1)
    cd=((Y(:,n+1)-Y(:,n)))-c;
    Y(cd<-pi,(n+1):end)=Y(cd<-pi,n+1:end)+2*pi;
    Y(cd>pi,(n+1):end)=Y(cd>pi,n+1:end)-2*pi;
end
A = cast([1  0 ;1 1; 1 2 ],class(M));
ip = A(1:min(3,nechos),:)\Y(:,1:min(3,nechos))';
p0 = ip(1,:)';
p1 = ip(2,:)';

dp1 = p1;
tol = norm(p1(:))*opts.reltol;
iter = 0;
% max_iter = 30;

% weigthed least square
% calculation of WA'*WA
v1=ones(1,nechos,class(M));
v2=cast((0:(nechos-1)),class(M));
a11=sum(abs(M).^2.*(ones(s(1),1,class(M))*(v1.^2)),2);
a12=sum(abs(M).^2.*(ones(s(1),1,class(M))*(v1.*v2)),2);
a22=sum(abs(M).^2.*(ones(s(1),1,class(M))*(v2.^2)),2);
% inversion
d=a11.*a22-a12.^2;
ai11=a22./d;
ai12=-a12./d;
ai22=a11./d;

while ((norm(dp1)>tol) &&(iter<opts.max_iter))
    iter = iter+1;
    W = abs(M).*exp(1i*(p0*v1 + p1*v2) );

    % projection
    pr1=sum(conj(1i*W).*(ones(s(1),1,class(M))*v1).*(M-W),2);
    pr2=sum(conj(1i*W).*(ones(s(1),1,class(M))*v2).*(M-W),2);

    dp0=real(ai11.*pr1+ai12.*pr2);
    dp1=real(ai12.*pr1+ai22.*pr2);
    dp1(isnan(dp1))=0;
    dp0(isnan(dp0))=0;
    
    %update
    p1 = p1+dp1;
    p0 = p0+dp0;
    

end

% error propagation
dp1=sqrt(real(ai22));
dp1(isnan(dp1)) = 0;
dp1(isinf(dp1)) = 0;

% relative residual
res = M - abs(M).*exp(1i*(p0*v1 + p1*v2) );
relres = sum(abs(res).^2,2)./sum(abs(M).^2,2);
relres(isnan(relres)) = 0;

p1(p1>pi)=mod(p1(p1>pi)+pi,2*pi)-pi;
p1(p1<-pi)=mod(p1(p1<-pi)+pi,2*pi)-pi;

p0=reshape(p0,s0(1:L_s0-1));
p1=reshape(p1,s0(1:L_s0-1));
dp1=reshape(real(dp1),s0(1:L_s0-1));
relres = reshape(relres,s0(1:L_s0-1));
    

