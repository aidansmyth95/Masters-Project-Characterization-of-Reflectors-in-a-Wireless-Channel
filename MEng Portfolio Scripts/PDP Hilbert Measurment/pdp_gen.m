%% Create impulse train
clear;clc;%close all;

%__________________________________
pos = 7;                

c = 3e8;                % m/s
freqStartGHz = 2.0;     % GHz
freqEndGHz = 2.4;       % GHz

posRx = 165+100j;       %position of fixed receiver in inches

% Testcase for Tx position
% requires Excel formatted frequency sweep results
switch pos
    case 1
        filename = 't61801.xlsx';
        posTx = 300+240j;
    case 3
        filename = 't61803.xlsx';
        posTx = 25+240j;
    case 5
        filename = 't61805.xlsx';
        posTx = 165+435j;
    case 7
        filename = 't61807.xlsx';
        posTx = 300+630j;
    case 9
        filename = 't61809.xlsx';
        posTx = 25+630j;
    otherwise
        error('PDP Generator:case#', ' invalid position number\n'); %#ok<CTPCT>
end

d = abs(posTx-posRx)*0.0254;                % distance of LoS path in meters
t_del = d/c;                                % time delay for direct path

f_all = xlsread(filename,'A2:A2003');       % GHz
s_all = xlsread(filename,'C2:C2003');       % dBm

figure(1)
plot(f_all,s_all)
grid on;
title('Frequency Sweep')
xlabel('Frequencies')
ylabel('PRx (dBm)')

% choose frequencies that avoid the interference in auditorium
f = f_all(find(f_all>=freqStartGHz,1,'first'):find(f_all<=freqEndGHz,1,'last'));
s = s_all(find(f_all>=freqStartGHz,1,'first'):find(f_all<=freqEndGHz,1,'last'));
clear f_all; clear s_all;
f = f*1e9;                              % represent in Hz

Tx = 14;                                % Transmission power in dBm


%% Hilbert filter to extract phase
fo  = 16;                                   % filter order
h = firpm(fo,[0.1 0.9],[1 1],'hilbert');    % Hilbert filter

grpdel_h = mean(grpdelay(h));           % Account for group delay - for flat
h_delay = zeros(size(h));
h_delay(grpdel_h+1) = 1;

abs_gain = abs(s - Tx);                 % channel gain = |S(jw)| - Tx = log10(|H(jw)|^2)    dBm
abs_Hfi = 10.^(abs_gain./(2*10));       % |H(jw)|
fx = log(abs_Hfi);                      % input to Hilbert: ln(|H(w)|)

phase = -conv(h,fx);                    % Apply filter to get phase
abs_del1 = conv(h_delay, fx);           % Apply filter to get absoloute delay

% synchronize phase and mag delays
phase = phase(grpdel_h + (1:length(fx)));
abs_del = abs_del1(grpdel_h + (1:length(fx)));

Hw = exp((abs_del + 1j*phase));         % H(w) reconstructed!

%% Frequency and time sampling parameters
Fl = f(1);
Fu = f(end);                
delta_f = f(2) - f(1);                  % frequency steps
B = Fu - Fl;                            % Bandwidth
Fs = 2*B;                               % Sampling frequency
SL = B/delta_f;                         % increase B or reduce delta_f

t_samples = 2*SL;
delta_t = 1/Fs;                         % ns
t_span = t_samples*delta_t;
t = delta_t:delta_t:t_span;             % starts on delta_t for strong first bin

%% Time Domain Representation
Hw2 = ifftshift(Hw);
% ramping to account for delay of direct path of signal
Hw2 = Hw2.*exp(-1j*2*pi*f*t_del);
Hw2 = ifftshift(Hw2);
hn = ifft(Hw2,length(t));

figure(4)
plot(t*1e6, abs(hn));
grid on;
title('Power delay profile')
xlabel('Time (micro seconds)')
ylabel('Relative path loss |h[n]|')
xlim([0,1])

% plot h[n]
figure(2)
plot(t*1e6, 10*log10(abs(hn).^2./sqrt(mean(abs(hn).^2))));
grid on;
title('Power delay profile')
xlabel('Time (micro seconds)')
ylabel('Relative path loss |h[n]|')
xlim([0,1])

% % Deconvolution of sinc to reduce Gibb's phenomenon
% Fs = 10e9;        % sampling frequency high enough for bandpass sinc
% Fc = (Fl+Fu)/2;   % centre frequency for bandpass sinc
% sc = Fs*sinc(pi*t*Fs) .* (cos(pi*t*Fc/Fs));   % sinc function is shifted to centre frequency
% [q,r] = deconv([abs(hn)' zeros(1,length(abs(hn))-1)],sc);   % deconvolution
% q = q.*sum(sc); r = r.*sum(sc);                             % adjust magnitude changes
% 
% figure(3);
% plot(t*1e6, abs(q));
% grid on;
% title('Power delay profile (deconvolved)')
% xlabel('Time (micro seconds)')
% ylabel('Relative path loss |h[n]|')
% xlim([0,1])
