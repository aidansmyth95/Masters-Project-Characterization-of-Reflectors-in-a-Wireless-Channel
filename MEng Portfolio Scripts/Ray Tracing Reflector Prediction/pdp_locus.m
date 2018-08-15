%% Create impulse train
clear;clc;close all;

% Define path arrival times from PDPs
c = 3e8;
my_expected_max_dist_elevator = sqrt(500^2 + 550^2)*0.0254;  % meters

% These dimensions use ray tracer inches, also used in plotting
rx = 165+100j;
tx1 = 300+240j;
tx3 = 25+240j;
tx5 = 165+435j;
tx7 = 300+630j;
tx9 = 25+630j;

tx = [tx1;tx3;tx5;tx7;tx9];
dimag = imag(tx-rx);
dreal = real(tx-rx);
% angles of tx's relative to rx
phi = atan2d(dimag,dreal);

% MUST BE TO THREE DECIMAL POINTS
% delay time observations
t = {}; % [ LOS | MP1 ]
t{1,1} = 0.019;
t{1,2} = NaN;
t{3,1} = 0.019;
t{3,2} = NaN;
t{5,1} = 0.029;
t{5,2} = 0.063;
t{7,1} = 0.049;
t{7,2} = 0.069;
t{9,1} = 0.049;
t{9,2} = 0.068;

% d = c*t       % these dimensions are in meters, convert to inches at end!
d = cellfun(@(x) c.*(x.*(1e-6)), t, 'un', 0);
d = cell2mat(d);

d1 = d(:,1);                    % direct LoS path distance
d2 = d(:,2);                    % distance travelled by first reflection MP
delta_d = d2 - d1;              % difference in distance travelled

% d2 = a - b
%   -> a = distance from Rx to reflector
%   -> b = distance from Tx to reflector

% knowing delta_d, here are all combinations for a,b

% locus
steps = 0.1;
% step time of 0.1
% generate all possible vals up to d2, for all positions
Combos_tmp = allcomb(steps:steps:max(d2),steps:steps:max(d2));
a=zeros(1000,5);
b=zeros(1000,5);

for tmp = 1:length(d1)              % for each Tx position
    count_tmp = 1;
    for i = 1:length(Combos_tmp)    % for each a b combo
        cmb_d2 = Combos_tmp(i,2) + Combos_tmp(i,1);             % d2 = a + b
        cmb_delta_d = cmb_d2 - d1(tmp);                         % delta_d = d2 - d1
        if (delta_d(tmp)==cmb_delta_d && Combos_tmp(i,1)~=0 && Combos_tmp(i,2)~=0)
            a(count_tmp,tmp) = Combos_tmp(i,2);
            b(count_tmp,tmp)= Combos_tmp(i,1);
            count_tmp = count_tmp + 1;
        end
    end
end

% theta from Rx
d1m = repmat(d1',size(a,1),1);      % duplicate rows of array

cosTheta = (a.^2 + d1m.^2 - b.^2)./(2.*a.*d1m);
theta = real(acosd((a.^2 + d1m.^2 - b.^2)./(2.*a.*d1m)));    % all theta values for valid setups

ind1 = find(theta(:,1)~=0); 
ind3 = find(theta(:,2)~=0);
ind5 = find(theta(:,3)~=0);
ind7 = find(theta(:,4)~=0);
ind9 = find(theta(:,5)~= 0);

% angle to draw line a to reflector
ang1 = phi(1) - theta(ind1,1);
ang3 = phi(2) - theta(ind3,2);
ang5 = phi(3) - theta(ind5,3);
ang7 = phi(4) - theta(ind7,4);
ang9 = phi(5) - theta(ind9,5);

% x2 = x1 + r*Cos(theta)...
ref1x = real(rx) + a(ind1,1) .* 39.3701 .* cosd(ang1);
ref1y = imag(rx) + a(ind1,1) .* 39.3701 .* sind(ang1);
ref3x = real(rx) + a(ind3,2) .* 39.3701 .* cosd(ang3);
ref3y = imag(rx) + a(ind3,2) .* 39.3701 .* sind(ang3);
ref5x = real(rx) + a(ind5,3) .* 39.3701 .* cosd(ang5);  % from meters to inches
ref5y = imag(rx) + a(ind5,3) .* 39.3701 .* sind(ang5);
ref7x = real(rx) + a(ind7,4) .* 39.3701 .* cosd(ang7);
ref7y = imag(rx) + a(ind7,4) .* 39.3701 .* sind(ang7);
ref9x = real(rx) + a(ind9,5) .* 39.3701 .* cosd(ang9);
ref9y = imag(rx) + a(ind9,5) .* 39.3701 .* sind(ang9);

% draw Tx, Rx
zall_tx = [300+240j,165+240j,25+240j,300+435j,165+435j,25+435j,300+630j,165+630j,25+630j];
%plot(real(z_tx), imag(z_tx), 'r*');

figure(1)
hold on;
lbl = 1;
for i=1:length(tx)
    plot(real(tx(i)), imag(tx(i)), 'r*');
    text(real(tx(i))+3, imag(tx(i))-1, strcat('Tx',int2str(lbl)), 'Color', 'r');
    lbl = lbl+2;
end

%plot Rx
plot(real(rx),imag(rx),'rx','Linewidth',3);

%plot locus
plot(ref1x,ref1y,'bx');
plot(ref3x,ref3y,'vx');
plot(ref5x,ref5y,'gx');
plot(ref7x,ref7y,'kx');
plot(ref9x,ref9y,'yx');

%plot walls
plot([525 525], [0 760],'b--');
plot([-800 525], [0 0],'b--');
plot([-800 525], [760 760],'b--');
plot([0 0], [0 760],'b--');
plot([-800 -800], [0 760],'b--')
xlim([-1000 800])
hold off;
