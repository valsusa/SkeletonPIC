%
% A simple skeleton PIC to run the 2-stream instability
% by Giovanni Lapenta, Feb 2008, KULeuven
%
%        Copyright 2007 KULeuven
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%        http://www.apache.org/licenses/LICENSE-2.0
%
%  Unless required by applicable law or agreed to in writing, software
%  distributed under the License is distributed on an "AS IS" BASIS,
%  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%  See the License for the specific language governing permissions and
%  limitations under the License.
%


#include <mpi.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "input_array.h"
#include "ipichdf5.h"
#include "Collective.h"
#include "ConfigFile.h"
#include "limits.h" // for INT_MAX
#include "MPIdata.h"
#incl

clear all
close all

% All units are SI
%den=1e10;
%TeV=1e5;
%T=1.16e4*TeV;
den=3e6;
T=1e4;
e=1.6e-19;
me=9.1e-31;
kB=1.38e-23;
eps0=8.85e-12;
c=3e8;

WP=sqrt(den*e^2/me/eps0)
QM=-e/me;
VT=sqrt(kB*T/me)
V0=c/100
Deb=VT/WP

L=180*Deb

NT=1500;
NPLOT=10;
NG=320;
N=10000;
bc='periodic';

dx=L/NG;
DT=.1/WP;
xn=0:dx:L;


XP1=0.0;
V1=.3;
mode=3;

Q=-den*e*L/N;
rho_back=-Q*N/L;

% Plasma waves
% xp=linspace(0,L-L/N,N)';
% vp=VT*randn(N,1);

% % 2 Stream instability
xp=linspace(0,L-L/N,N)';
vp=VT*randn(N,1);
pm=[1:N]';pm=1-2*mod(pm,2);
vp=vp+pm.*V0;

% Perturbation
vp=vp+V1*VT*cos(2*pi*xp/L*mode);
xp=xp+XP1*(L/NG)*cos(2*pi*xp/L*mode);

un=ones(NG-1,1)*eps0;
Poisson=spdiags([un -2*un un],[-1 0 1],NG-1,NG-1);
figure(1)
plot(xp,vp,'.')

Ep=[];

for it=1:NT
   
   % aggiornamento xp

   xp=xp+vp*DT;  
   switch(lower(bc))
      case 'periodic'
         out=(xp<0); xp(out)=xp(out)+L;
         out=(xp>=L);xp(out)=xp(out)-L;
	  case 'open-right'
	     out=(xp<0); xp(out)=-xp(out);vp(out)=-vp(out);
         in=(xp<=L); xp=xp(in);vp=vp(in);   
      otherwise
	     in=(xp>=0); xp=xp(in);vp=vp(in);
         in=(xp<=L); xp=xp(in);vp=vp(in);
   end
    		 
   % proiezione p->g

   g1=floor(xp/dx-.5)+1;g=[g1;g1+1];
   fraz1=1-abs(xp/dx-g1+.5);fraz=[fraz1;1-fraz1];	
   switch(lower(bc))
      case 'periodic'
	     out=(g<1);g(out)=g(out)+NG;
	     out=(g>NG);g(out)=g(out)-NG;
      otherwise
         out=(g<1);g(out)=1;
	     out=(g>NG);g(out)=NG;
   end
   
   N=max(size(xp));
   p=1:N;p=[p p];
   mat=sparse(p,g,fraz,N,NG);
   rho=full((Q/dx)*sum(mat))'+rho_back;

   % calcolo del campo

   Phi=Poisson\(-rho(1:NG-1)*dx^2);Phi=[Phi;0];
    switch(lower(bc))
      case 'periodic'
         Eg=([Phi(NG); Phi(1:NG-1)]-[Phi(2:NG);Phi(1)])/(2*dx);
	  otherwise
	     Eg=([0; Phi(1:NG-1)]-[Phi(2:NG);0])/(2*dx);
	  end
   
   % proiezione q->p e aggiornamento velocita'

   vp=vp+mat*QM*Eg*DT;
   Ep=[Ep;norm(Phi)];

if(mod(it,NPLOT)==0)  

figure(2)
plot(xp,vp,'.')
pause
end

end


figure(3)
semilogy(Ep)
title('potential')

figure(4)
hist(vp,30)
