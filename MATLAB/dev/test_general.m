clc
clear all

addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;

m=2; n=3;
dbar = 20000*ones(n,1);
dhat = 18000*ones(n,1);
c = 0.6*ones(m,1);
K = 100000*ones(m,1);
eta = [5.9, 5.6, 4.9; 5.6 5.9 4.9];
Gamma = 2;
M = 100000;

deltas = [0 0 0;  0 0 1; 1 0 0; 0 1 0; 1 1 0; 1 0 1; 0 1 1]';


bigM = 2*max(eta(:));
nI = m; nJ = n;
B1_ = [];
for k=1:nJ
    tmp = zeros(nI,nJ); tmp(:,k)=1;
    B1_ = [B1_; tmp(:)']; 
end;
B2_ = []; 
for k=1:nI
    tmp = zeros(nI,nJ); tmp(k,:)=1;
    B2_ = [B2_; tmp(:)']; 
end;
B = [B1_; B2_; -eye(nI*nJ)];
d = eta(:);


rome_begin; 
h_ = rome_model('AARC'); % Create Rome Model
h_.Solver = 'MOSEK';

newvar x(m,1);
newvar v(m,1) binary;
newvar deltan(n) uncertain;
newvar y(m,n,deltan') linearrule; 
d = dbar+diag(dhat)*(-deltan);
rome_maximize(-c'*x -K'*v + eta(:)'*y(:));
rome_constraint(deltan<=1);
rome_constraint(deltan>=0);
rome_constraint(sum(deltan)<= Gamma);
rome_constraint(y(:)>=0);
rome_constraint(sum(y,1)'<=d);
rome_constraint(sum(y,2)<=x);
rome_constraint(x>=0);
rome_constraint(x<=M*v);
h_.solve;
aarc.x = h_.eval(x);
aarc.v = h_.eval(v);
aarc.fval = h_.objective;
rome_end;
aarc.fval_true = evalWorstCase(aarc.x,aarc.v,n,m,c,K,eta,dbar,dhat,deltas);



%%%%%%%%%%
rome_begin; 
h_ = rome_model('AARC One Warehouse'); % Create Rome Model
h_.Solver = 'MOSEK';
newvar x(m,1);
newvar v(m,1) binary;
newvar deltan(n) uncertain;
newvar y(m,n,deltan') linearrule; 
d = dbar+diag(dhat)*(-deltan);
rome_maximize(-c'*x -K'*v + eta(:)'*y(:));
rome_constraint(deltan<=1);
rome_constraint(deltan>=0);
rome_constraint(sum(deltan)<= Gamma);
rome_constraint(y(:)>=0);
rome_constraint(sum(y,1)'<=d);
rome_constraint(sum(y,2)<=x);
rome_constraint(x>=0);
rome_constraint(x<=M*v);
rome_constraint(v(1)==1);
h_.solve;
aarc2.x = h_.eval(x);
aarc2.fval = h_.objective;
rome_end;
%%%%%%%%%%%%%%%





















function fval = evalWorstCase(x,v,n,m,c,K,eta,dbar,dhat,deltas)
rome_begin; 
h_ = rome_model('Optimal'); % Create Rome Model
h_.Solver = 'MOSEK';
newvar y(m,n,size(deltas,2)); 
newvar t(1);
ds = dbar*ones(1,size(deltas,2))-diag(dhat)*deltas;
rome_maximize(-c'*x -K'*v + t);
rome_constraint(y(:)>=0);
for k=1:size(deltas,2)
    rome_constraint(t<= eta(:)'*reshape(y(:,:,k),[m*n 1]));
    rome_constraint(sum(y(:,:,k),1)'<=ds(:,k));
    rome_constraint(sum(y(:,:,k),2)<=x);
end
h_.solve;
fval = h_.objective;
rome_end;
end