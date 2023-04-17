function x = neg(x)

% PROF_VAR\POS Returns 0 if x > 0 and -x if x <= 0
%
%   x- = neg(x)
%
% Modification History: 
% 1. Joel 

% x(find(x >= 0)) = 0;
% x = -x;

x = max(-x, 0);


% ROME: Copyright (C) 2009 by Joel Goh and Melvyn Sim
% See the file COPYING.txt for full copyright information.
