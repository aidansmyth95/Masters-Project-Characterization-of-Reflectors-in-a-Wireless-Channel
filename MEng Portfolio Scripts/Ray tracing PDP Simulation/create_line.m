function L = create_line(z_strt, z_end)
%% create a line with two complex numbers as end points
EPS = 1e-3;

tmp = z_end - z_strt;
m = imag(tmp)/real(tmp); %m=y/x

if ( abs(m) <= tan(pi/2 - EPS) ) % not vertical
    c = imag(z_strt) - m*real(z_strt);  % c = y - mx
    x_min = real(z_strt);   %x1
    x_max = real(z_end);    %x2
else % vertical
    c = real( (z_strt+z_end)/2);       % c = (x1+x2)/ 2 
    x_min = imag(z_strt);   %y1
    x_max = imag(z_end);    %y2
end

L = Line(m, c, x_min, x_max); % return m,c,x1,x2, enough to draw line

return
