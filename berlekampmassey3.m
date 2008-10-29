function [Lambda, B, L] = berlekampmassey3( v, Lambda, B, L, r )
%BERLEKAMPMASSEY  Berlekamp-Massey algorithm.
%
%  LAMBDA = BERLEKAMPMASSEY( V ) solves the Newton identity given by V and
%  LAMBDA:
% 
%   [  V(N)   V(N-1)  ...   V(1)  ] [  LAMBDA(2)  ]  = [ -V(N+1)  ]
%   [ V(N+1)   V(N)   ...   V(2)  ] [  LAMBDA(3)  ]  = [ -V(N+2)  ]
%   [   .       .      .     .    ] [      .      ]  = [    .     ]
%   [ V(2N-2) V(2N-1)  ... V(N-1) ] [  LAMBDA(N)  ]  = [ -V(2N-1) ]
%   [ V(2N-1) V(2N-2) ...   V(N)  ] [ LAMBDA(N+1) ]  = [  -V(2N)  ]
%
%  V has a length of 2*N. The returned column vector LAMBDA has N+1
%  elements with the first component set to one, LAMBDA(1) = 1.
%  
%
%  For further details have a look at:
%  Blahut, R.E.: Algebraic methods for signal processing and communications
%  coding, 1992, Springer
%
%
%  Version 1.1
%
%  Copyright 2004 Stefan Nikolaus
%

%
%  [LAMBDA,B,L] = BERLEKAMPMASSEY( V, LAMBDA, B, L ) is only used for
%  internal recursion.
%

n = length(v) / 2;

Lambda = [zeros(n,1);1]; % one index extra for Lambda_0
B = Lambda;
L = 0;

for r=1:2*n
    if r <= n + 1
	Delta = v(1:r) * Lambda(end-r+1:end);
    else
	Delta = v(r-n:r) * Lambda;
	v(r-n:r)' .* Lambda
    end

    if (abs(Delta) < 1e-5)
	Delta = 0;
    end

    Lambda
    B
    Delta 
    [L r]

    
    if Delta & 2*L <= r-1
	L = r - L;
	Lambda0 = Lambda;
	Lambda = Lambda - Delta*[B(2:end);0];
        B = Lambda0/Delta;
    else
	Lambda = Lambda - Delta*[B(2:end);0];
        B = [B(2:end);0];
    end
end
