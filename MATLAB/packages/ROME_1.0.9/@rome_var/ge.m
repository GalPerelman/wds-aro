function out_var_obj = ge(A, B)

% ROME_VAR\LE Implements greater than or equal to operator on rome_var objects
%
%   A >= B 
%
%   At least one of A, B must be a rome_var 
%
%   Returns a new rome_var object, A-B, constrained to be nonnegative. Also
%   registers the constraint with the current model
%
% Modification History: 
% 1. Joel 

% Not necessary to error check for size matching, since we will handle it
% implicitly upon calling the 'minus' operator

out_var_obj = A - B;
out_var_obj.Cone = rome_constants.NNOC;

% % registers constraint with model
% S.type = '()';
% S.subs = {':'};
% rome_constraint(out_var_obj.subsref(S));

% ROME: Copyright (C) 2009 by Joel Goh and Melvyn Sim
% See the file COPYING.txt for full copyright information.