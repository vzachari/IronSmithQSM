function [slope1, slope2, intrcp]  = fitgrad(g1, g2, in)

CL=class(g1);

Ainv = zeros(length(g1)+1,CL);
Ainv(:,1) = ones(size(Ainv(:,1)),CL);
for j = 2 : size(Ainv,2)
    Ainv(j:end,j) = cast([1:1:length(Ainv(j:end,j))],CL);
end

g1 = cast([0;g1],CL);
g2 = cast([0;g2],CL);
in = cast([0;in],CL);

slope1 = Ainv*g1;
slope2 = Ainv*g2;
intrcp = Ainv*in;
end