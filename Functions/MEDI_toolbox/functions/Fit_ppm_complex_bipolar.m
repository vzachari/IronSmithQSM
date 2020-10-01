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
% -----------------------------------------------------------
%   Fit separate phase offsets for even/odd echoes
%
% ---- By Zhe Liu, 2018/1/3 ---------------------------------


function [p1, dp1, relres, p0, p0_o2e]=Fit_ppm_complex_bipolar(M)

bytes=whos('M');
bytes=bytes.bytes;
if (bytes>1e9)
    sz=size(M);
    arg_s='(:,:,rng)';
    p1=zeros(sz(1:3),class(M));
    out_s=['[p1' arg_s];
    if nargout>1
        dp1=zeros(sz(1:3),class(M));
        out_s=[out_s ', dp1' arg_s];
        if nargout>2
            relres=zeros(sz(1:3),class(M));
            out_s=[out_s ', relres' arg_s];
            if nargout>3
                p0=zeros(sz(1:3),class(M));
                out_s=[out_s ', p0' arg_s];
                if nargout>4
                    p0_o2e=zeros(sz(1:3),class(M));
                    out_s=[out_s ', p0_o2e' arg_s];
                end
            end
        end
    end
    out_s=[out_s ']'];
    n=ceil(bytes/1e9);
    ns=floor(sz(3)/n);
    for slice=1:ns:sz(3)
        rng=slice:min(slice+ns-1,sz(3));
        disp(['fitting slice ' num2str(rng(1)) ' through ' num2str(rng(end)) ' ...']);
         eval([out_s ' = Fit_ppm_complex_bipolar(M(:,:,rng,:,:));']);
%         [p1(:,:,rng), dp1(:,:,rng), relres(:,:,rng), p0(:,:,rng)]=Fit_ppm_complex_bipolar(M(:,:,rng,:,:));
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

s0=size(M);
L_s0=length(s0);
nechos=size(M,L_s0);
if nechos < 3
    warning('Number of echoes too low. Running Fit_ppm_complex instead.');
    [p1, dp1, relres, p0]=Fit_ppm_complex(M);
    p0_o2e = 0;
    return
end

M= conj(M);
M=reshape(M,[prod(s0(1:L_s0-1)),s0(L_s0)]);
s=size(M);

% Y=angle(M(:,1:min(3,nechos)));\
A_rows=min(3,nechos); A_cols=3;
% A_rows=min(6,nechos); A_cols=3;
Y_odd=angle(M(:,1:2:A_rows));  % first 3 odd echoes
if size(Y_odd,2)>1
    c=((Y_odd(:,2)-Y_odd(:,1)));
    [m ind]=min([abs(c-2*pi),abs(c),abs(c+2*pi)],[],2);
    c(ind==1)=c(ind==1)-2*pi;
    c(ind==3)=c(ind==3)+2*pi;
    for n=1:(size(Y_odd,2)-1)
        cd=((Y_odd(:,n+1)-Y_odd(:,n)))-c;
        Y_odd(cd<-pi,(n+1):end)=Y_odd(cd<-pi,n+1:end)+2*pi;
        Y_odd(cd>pi,(n+1):end)=Y_odd(cd>pi,n+1:end)-2*pi;
    end
    clear('c');
end
Y_even=angle(M(:,2:2:A_rows));  % first 3 even echoes
if size(Y_even,2)>1
    c=((Y_even(:,2)-Y_even(:,1)));
    [m ind]=min([abs(c-2*pi),abs(c),abs(c+2*pi)],[],2);
    c(ind==1)=c(ind==1)-2*pi;
    c(ind==3)=c(ind==3)+2*pi;
    for n=1:(size(Y_even,2)-1)
        cd=((Y_even(:,n+1)-Y_even(:,n)))-c;
        Y_even(cd<-pi,(n+1):end)=Y_even(cd<-pi,n+1:end)+2*pi;
        Y_even(cd>pi,(n+1):end)=Y_even(cd>pi,n+1:end)-2*pi;
    end
    clear('c');
end

% extra unknown, p0_o2e:    phase shift from odd to even echo
% A = [1  0  0;
%      1  1  1;
%      1  0  2;
%      1  1  3;
%      1  0  4;
%      1  1  5];
A = zeros(A_rows,A_cols);
A(:      ,1) = 1;          % intercept
A(2:2:end,2) = 1;          % intercept delta for even echoes
A(:      ,3) = 0:A_rows-1; % slope

Y = zeros([prod(s0(1:L_s0-1)),A_rows], class(M));
Y(:,1:2:A_rows)=Y_odd; Y(:,2:2:A_rows)=Y_even; clear('Y_odd','Y_even');
% Y = reshape(permute(cat(3, Y_odd, Y_even), [1,3,2]), [prod(s0(1:L_s0-1)),A_rows]); 
ip = A(:,:)\Y(:,:)'; 
p0 = ip(1,:)';
p0_o2e = ip(2,:)';
p1 = ip(3,:)';
clear('Y','ip');

dp1 = p1;
normp1=norm(p1(:));
tol = 1e-4;
iter = 0;
max_iter = 30;

% weigthed least square
% calculation of WA'*WA
v1=ones(1,nechos);
v2=zeros(1,nechos); v2(2:2:end) = 1;
v3=(0:(nechos-1));

% a11=sum(abs(M).^2.*(ones(s(1),1)*(v1.^2)),2);
% a12=sum(abs(M).^2.*(ones(s(1),1)*(v1.*v2)),2);
% a22=sum(abs(M).^2.*(ones(s(1),1)*(v2.^2)),2);
% % inversion
% d=a11.*a22-a12.^2;
% ai11=a22./d;
% ai12=-a12./d;
% ai22=a11./d;
a11=sum(abs(M).^2.*(ones(s(1),1)*(v1.^2)),2);
a12=sum(abs(M).^2.*(ones(s(1),1)*(v1.*v2)),2);
a13=sum(abs(M).^2.*(ones(s(1),1)*(v1.*v3)),2);
a22=sum(abs(M).^2.*(ones(s(1),1)*(v2.^2)),2);
a23=sum(abs(M).^2.*(ones(s(1),1)*(v2.*v3)),2);
a33=sum(abs(M).^2.*(ones(s(1),1)*(v3.^3)),2);
% co-factor
c11=(1)*(a22.*a33-a23.^2);
c12=(-1)*(a12.*a33-a23.*a13);
c13=(1)*(a12.*a23-a22.*a13);
c22=(1)*(a11.*a33-a13.^2);
c23=(-1)*(a11.*a23-a12.*a13);
c33=(1)*(a11.*a22-a12.^2);
% det
d=a11.*c11 + a12.*c12 + a13.*c13;
clear('a11','a12','a13','a22','a23','a33')
% inverse
ai11=c11./d;
ai12=c12./d;
ai13=c13./d;
ai22=c22./d;
ai23=c23./d;
ai33=c33./d;
clear('c11','c12','c13','c22','c23','c33')
clear('d')



progress='';
while ((norm(dp1)/normp1>tol) &&(iter<max_iter))
    iter = iter+1;
    for ii=1:length(progress); fprintf('\b'); end
    progress=sprintf('Iteration %d : reltol %f', iter, norm(dp1)/normp1);
    fprintf(progress); 
    W = abs(M).*exp(1i*(p0*v1 + p0_o2e*v2 + p1*v3) );

    % projection
    pr1=sum(conj(1i*W).*(ones(s(1),1)*v1).*(M-W),2);
    pr2=sum(conj(1i*W).*(ones(s(1),1)*v2).*(M-W),2);
    pr3=sum(conj(1i*W).*(ones(s(1),1)*v3).*(M-W),2);

    dp0=real(ai11.*pr1+ai12.*pr2+ai13.*pr3);
    dp0_o2e=real(ai12.*pr1+ai22.*pr2+ai23.*pr3);
    dp1=real(ai13.*pr1+ai23.*pr2+ai33.*pr3);
    dp0(isnan(dp0))=0;
    dp0_o2e(isnan(dp0_o2e))=0;
    dp1(isnan(dp1))=0;
    
    %update
    p0 = p0+dp0;
    p0_o2e = p0_o2e+dp0_o2e;
    p1 = p1+dp1;
    

end
fprintf('\n');

% field
w=pi;
p1(p1>w)=mod(p1(p1>w)+w,2*w)-w;
p1(p1<-w)=mod(p1(p1<-w)+w,2*w)-w;
p1=reshape(p1,s0(1:L_s0-1));

% error propagation
dp1=sqrt(ai33);
dp1(isnan(dp1)) = 0;
dp1(isinf(dp1)) = 0;
dp1=reshape(dp1,s0(1:L_s0-1));

% relative residual
if nargout>2
    res = M - abs(M).*exp(1i*(p0*v1 + p0_o2e*v2 + p1*v3) );
    relres = sum(abs(res).^2,2)./sum(abs(M).^2,2);
    relres(isnan(relres)) = 0;
    relres = reshape(relres,s0(1:L_s0-1));
    if nargout>3
        p0=reshape(p0,s0(1:L_s0-1));
        if nargout>4
            p0_o2e=reshape(p0_o2e,s0(1:L_s0-1));
        end
    end
end

    


