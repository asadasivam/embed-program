close all;
clear all;
clc;

%   Following snippet is only for verifying rate of growth w.r.t input
%       n = 0:1:50;
%       fplot(@(n) [n, log(n), n*log(n)], [1 50]);
%       O(n), O(1), O(n^2), O(n^3), O(log(n)), O(n*log(n))
%   
%   Snippet is for rate of growth w.r.t input and constants C and n0;
%      f(n) = 6n+4; 
%   1. Simplify the function to get strict boundary(upper bound)
%      where constants C and n0 needed to meet C*g(n)>= f(n);
%   2. Extract integer co-efficient of symbolic polynomial in row vector
%   3. Find the constant 'C', by arr(1) != 0: Increment arr(1); save as C
%   4. Find the constant 'n0', where upper bound meet threshold and peaks 
%      to maximum on upper bound. Note: upper bound should not cross at  
%      tail end

%   x needs to be a symbol in context of sym2poly()
syms x;                 

p = x^3+x^2+x+2; %f(n)

%   Find the constant 'C'
poly = sym2poly(p);
fpoly = poly;
if length(poly) == 1
    disp 'polynomial has only constant val';
    c = 0;
else
    for n=2:1:length(fpoly)
        fpoly(n) = 0;   %assign 0 other than highest order polynomial        
    end
    c = fpoly(1)+1;     %increment the numeric value and store result
end

%Find the constant 'n0'
e = poly2sym(fpoly);
f = poly2sym(fpoly);
disp(f); 
for x=1:1:10
    fn = double(subs(p));    
    gn = c*double(subs(e));
    if gn>fn
        disp 'upper bound';
        %check if croses before attempt
        if ffn>=ggn
            n0 = x; 
        end
    else
        disp 'lower bound';       
    end
    ffn = fn;
    ggn = gn;
end
disp(n0);

%   2D slow motion plot of Big O analysis
free_var  = animatedline('color', [1, 0, 0], 'Linewidth', 1); %red
bound_var = animatedline('color', [0, 1, 0], 'Linewidth', 1); %green
free    = p;
bound   = e;
x = 1:1:50;
bound_fun           = c*double(subs(e));
free_fun            = double(subs(p)); %our algorithm                          

for k=1:length(x)
    axis([1 5 1 100]);
    addpoints(free_var, k, free_fun(k));
    addpoints(bound_var, k, bound_fun(k));
    drawnow limitrate;
    pause(0.008);
end