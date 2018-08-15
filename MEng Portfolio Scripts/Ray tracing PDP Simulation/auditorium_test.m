clear; close all; fclose all; clc;

%________________________________________________________________________________________________

tx_pos = 9; % options 1->9
z_rx = 165+100j;

% Testcase for Tx positioning
switch tx_pos
    case 1
        z_tx = 300+240j;
    case 2
        z_tx = 165+240j;
    case 3
        z_tx = 25+240j;
    case 4
        z_tx = 300+435j;
    case 5
        z_tx = 165+435j;
    case 6
        z_tx = 25+435j;
    case 7
        z_tx = 300+630j;
    case 8
        z_tx = 165+630j;
    case 9
        z_tx = 25+630j;
    otherwise
        error('TxRx_testcase:case#', ' invalid case number\n'); %#ok<CTPCT>
end

%%________________________________________________________________________________________________

% escalator indent
L{1}=create_line(425+240j, 425+470j);
L{2}=create_line(425+240j, 525+240j);
L{3}=create_line(425+470j, 525+470j);

% Keep lines reflections after 2nd path
tmp_lines_idx = 1;

figure(1);
% draw the geometry of ROOM
for i=1:length(L)
    % Tx, Rx and reflector
    L{i}.draw;
    %text(real((L{i}.z_min+L{i}.z_max)/2), imag((L{i}.z_min+L{i}.z_max)/2), num2str(i));
    if (i==1)
        hold on
    end
end

% 4 walls
plot([-780 525], [760 760],'b--');
plot([-780 525], [0 0],'b--');
plot([525 525], [0 760],'b--');
plot([-780 -780], [0 760],'b--');
plot([0 0], [0 760], 'b--')

plot([465 500], [630 630],'b--'); 
plot([465 465], [470 630],'b--'); 

% draw Tx, Rx
zall_tx = [300+240j,165+240j,25+240j,300+435j,165+435j,25+435j,300+630j,165+630j,25+630j];
plot(real(z_tx), imag(z_tx), 'r*');
for i=1:length(zall_tx)
    plot(real(zall_tx(i)), imag(zall_tx(i)), 'r*');
    text(real(zall_tx(i))+3, imag(zall_tx(i))-1, strcat('Tx',int2str(i)), 'Color', 'r');
%plot(real(zall_tx), imag(zall_tx), 'r*');
end
plot(real(z_rx), imag(z_rx), 'g*');
text(real(z_rx)+3, imag(z_rx)-1, 'Rx', 'Color', 'g');

% LoS
L_LoS = create_line(z_tx, z_rx); % create line from Tx to Rx
LoS_valid = NaN(length(L),1); % NaN values for number of walls
AoA.LoS = struct('r', NaN, 'theta', NaN); %specify LoS for object AoA
AoD.LoS = struct('r', NaN, 'theta', NaN); % dito for AoD

for i=1:length(L)   % for all walls
    [~,tmp_v] = L{i}.intersect(L_LoS);  
    LoS_valid(i) = tmp_v(1) && tmp_v(2);    %  needs to sum to 0
end

if (sum(LoS_valid) == 0) % LoS is valid
    % assign AoA & AoD angle and distance values
    AoA.LoS.theta = L_LoS.alpha;
    AoD.LoS.theta = L_LoS.alpha;
    AoA.LoS.r = abs(z_rx - z_tx);
    AoD.LoS.r = abs(z_rx - z_tx);
    L_LoS.draw('g-');
else
    % doesn't reach here hopefully
    tmp_l(tmp_lines_idx) = L_LoS.draw('r-.');
    tmp_lines_idx = tmp_lines_idx + 1;
end

%% 1R
z_1refl = NaN(length(L), 1);
%fill tmp with L number of NaNs
tmp = cell(length(L), 1); for i=1:length(L), tmp{i} = NaN; end
% structured arrays for AoA AoD
AoA.refl_1 = struct('r', tmp, 'theta', tmp);
AoD.refl_1 = struct('r', tmp, 'theta', tmp);
clear tmp;
for i=1:length(L) % every wall
    [tmp_aoa, tmp_aod, tmp_z] = multiple_reflections(L, i, z_tx, z_rx);
    if ( ~isnan(tmp_aoa.theta) && ~isnan(tmp_aod.theta) )
        AoA.refl_1(i) = tmp_aoa;
        AoD.refl_1(i) = tmp_aod;
        z_1refl(i) = tmp_z;
        plot(real([z_tx; tmp_z; z_rx]), imag([z_tx; tmp_z; z_rx]), 'r-')
    else
        tmp_idx = find(~isnan(tmp_z));
        if (length(tmp_idx) >= 1)
            tmp_l(tmp_lines_idx)=plot(real([z_tx tmp_z(tmp_idx)]), imag([z_tx tmp_z(tmp_idx)]), 'r--');
            tmp_lines_idx = tmp_lines_idx + 1;
        end
    end
end

%% two reflections
z_2refl = NaN(length(L), length(L), 2);
tmp = cell(length(L), length(L)); for i=1:length(L), for j=1:length(L), tmp{i,j} = NaN; end; end
AoA.refl_2 = struct('r', tmp, 'theta', tmp);
AoD.refl_2 = struct('r', tmp, 'theta', tmp);
clear tmp;
for i=1:length(L)
    for j=setdiff(1:length(L), i)
        [tmp_aoa, tmp_aod, tmp_z] = multiple_reflections(L, [i, j], z_tx, z_rx);
        if ( ~isnan(tmp_aoa.theta) && ~isnan(tmp_aod.theta) )
            AoA.refl_2(i,j) = tmp_aoa;
            AoD.refl_2(i,j) = tmp_aod;
            z_2refl(i,j,:) = tmp_z;
            plot(real([z_tx; tmp_z; z_rx]), imag([z_tx; tmp_z; z_rx]), 'c-')
        else
            tmp_idx = find(~isnan(tmp_z));
            if (length(tmp_idx) >= 1)
                tmp_l(tmp_lines_idx)=plot(real([z_tx; tmp_z(tmp_idx)]), imag([z_tx; tmp_z(tmp_idx)]), 'r--');
                tmp_lines_idx = tmp_lines_idx + 1;
            end
        end
    end
end

axis([-830 600 -40 800])
hold off
title('Ray Tracing in Auditorium');
pause(4); delete(tmp_l);

x_ref = real(z_1refl); y_ref = imag(z_1refl);
x_ref = x_ref(1);
y_ref = y_ref(1);
dr1 = sqrt( (real(z_tx)-x_ref)^2 + (imag(z_tx)-y_ref)^2 ); % inches
dr2 = sqrt( (real(z_rx)-x_ref)^2 + (imag(z_rx)-y_ref)^2 ); % inches
dr = dr1 + dr2;
c=3e8;
t_los = 0.0254*abs(z_tx-z_rx)/c
t_r = 0.0254*dr/c   % seconds

%%________________________________________________________________________________________________
