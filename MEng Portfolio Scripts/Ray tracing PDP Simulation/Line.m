classdef Line < handle
    properties (SetAccess = private)
        m = 0           % slope
        c = 0           % y-intercept
        x_min = NaN     % x of left-bottom point
        x_max = NaN     % x of right top point
        
        alpha = 0       % angle from x-axis
        d = 0           % x-intercept
        ejalpha = 1     % exp(1j * alpha)
        ej2alpha = 1    % exp(1j * 2 * alpha)
        z_strt = NaN    % starting point
        z_end = NaN     % ending point
        z_min = NaN     % left-bottom point
        z_max = NaN     % right top point
        
        is_vertical = 0 % flag to indicate that the line is vertical
    end
    
    properties (Constant, Hidden)
        EPS = 1e-3
    end
    
    methods
        % define with y = m x + c
        % strt_in, end_in : starting and ending points of the line.
        % also used to get x(y)_min and x(y)_max
        function obj = Line(m_in, c_in, strt_in, end_in)
            if ( (nargin >= 2) && isreal(m_in) && isreal(c_in) ) % input is m and c
                obj.m = m_in;
                
                if (abs(obj.m) > tan(pi/2 - obj.EPS) ) % vertical
                    obj.m = Inf;
                    obj.is_vertical = 1;
                    obj.c = NaN;
                    obj.d = c_in;   % input corresponds to x intercept
                else                % not vertical
                    obj.is_vertical = 0;
                    obj.c = c_in;                    
                    obj.d = obj.c/obj.m;
                end
                
                % dependent varaibles
                obj.alpha = atan(obj.m); % will possibly be updated later!
                obj.ejalpha = exp(1j*obj.alpha);
                obj.ej2alpha = exp(1j*2*obj.alpha);

                % the edge points
                if ( (nargin == 4) && isreal(strt_in) && isreal(end_in) ) % input also has x_min and x_max
                    % store the starting and ending points
                    if (obj.is_vertical == 0) % not vertical
                        obj.z_strt = strt_in + 1j*(obj.m*strt_in + obj.c);
                        obj.z_end = end_in + 1j*(obj.m*end_in + obj.c);
                    else
                        obj.z_strt = obj.d + 1j*(strt_in);
                        obj.z_end = obj.d + 1j*(end_in);
                    end
                    
                    % update alpha, since atan only has (-pi/2, pi/2)
                    if (strt_in > end_in) % the starting point is on the right!                    
                        if (obj.m>0)
                            obj.alpha = -pi + obj.alpha;
                        end
                        if (obj.m<0)
                            obj.alpha = pi + obj.alpha;
                        end                        
                    end
                    % store the min and max along x and z
                    if (obj.is_vertical == 0) % not vertical
                        obj.x_min = min(strt_in, end_in);
                        obj.x_max = max(strt_in, end_in);
                        obj.z_min = obj.x_min + 1j * (obj.m*obj.x_min + obj.c);
                        obj.z_max = obj.x_max + 1j * (obj.m*obj.x_max + obj.c);                        
                    else % input is actually y_min and y_max and will use x-intercept
                        obj.z_min = obj.d + 1j*min(strt_in, end_in);
                        obj.z_max = obj.d + 1j*max(strt_in, end_in);
                    end
                else
                    warning('Line:construct', ' start and end are not defined!\n');
                end
            else
                error('Line:construct', 'invalid number/type of inputs (m, c)\n');
            end
        end
        
        % draw the line for the ROOM
        function h = draw(this, plt_clr, Npts)
            if (nargin <= 1)
                plt_clr = struct('Color', 'b', 'LineWidth', 4, 'LineStyle', '-');
            end
            if ( ~isnan(this.z_strt) && ~isnan(this.z_end) ) % start and end known
                h = plot( real([this.z_strt this.z_end]), imag([this.z_strt this.z_end]), plt_clr);
            elseif ( ~isnan(this.z_min) && ~isnan(this.z_max) ) % use min and max
                h = plot( real([this.z_min this.z_max]), imag([this.z_min this.z_max]), plt_clr);
            else % many points
                if (nargin <= 2)
                    Npts = 1024;
                end
                tmp = (0:Npts-1)/Npts * (this.z_max - this.z_min) + this.z_min;
                h = plot(real(tmp), imag(tmp), plt_clr);
            end
        end
        
        % intersection with a line L2
        function [z_intersect, within_limits] = intersect(this, L2)
            % 11=both vertical, 10=this is vertical, 01=L2 is vertical, 00=neither
            tmp = this.is_vertical*10 + L2.is_vertical ;
            if ( tmp == 0 ) % neither
                if ( abs(this.m-L2.m) < (this.EPS+L2.EPS)/2) % parallel or almost parallel
                    z_intersect = NaN + 1j*NaN; % no intersect
                else
                    tmp = [-this.m 1; -L2.m 1]\[this.c; L2.c]; %??
                    z_intersect = tmp(1) + 1j* tmp(2); % old tmp with a new imag part
                end
            elseif (tmp == 1) % only L2 vertical
                % x intercept of L2 + imag of (y = m*xint + c) for L2
                z_intersect = L2.d + 1j*(this.m*L2.d+this.c);
            elseif (tmp == 10) % only this vertical
                % x intercept of this + imag of (y = m*xint + c) for L2
                z_intersect = this.d + 1j*(L2.m*this.d+L2.c);
            else % both vertical
                % no reflection
                z_intersect = NaN + 1j*NaN;
            end
            clear tmp
            
            if (nargout > 1) %number of outputs specified
                if ( abs(this.m-L2.m) < (this.EPS+L2.EPS)/2) % parallel or almost parallel
                    within_limits(1:2) = 0;
                    warning('Line:intersect', 'input lines are almost parallel! need to code this part.\n');
                    %[TBD] almost same slope. is there a better way to handle it?
                else
                    
                    if (this.is_vertical==0)
                        tmp_test = (real(z_intersect) >= this.x_min) && (real(z_intersect) <= this.x_max);
                    else
                        tmp_test = (imag(z_intersect) >= min(imag(this.z_min), imag(this.z_max))) && (imag(z_intersect) <= max( imag(this.z_min), imag(this.z_max)));
                    end
                    
                    if ( tmp_test )
                        within_limits(1) = 1;
                    else
                        within_limits(1) = 0;
                    end
                
                    if (L2.is_vertical==0)
                        tmp_test = (real(z_intersect) >= L2.x_min) && (real(z_intersect) <= L2.x_max);
                    else
                        tmp_test = (imag(z_intersect) >= min( imag(L2.z_min), imag(L2.z_max))) && (imag(z_intersect) <= max( imag(L2.z_min), imag(L2.z_max)));
                    end
                    
                    if ( tmp_test )    
                        within_limits(2) = 1;
                    else
                        within_limits(2) = 0;
                    end
                end
            end            
        end
        
        %% reflection of a point z_in
        function [z_refl, is_valid] = reflect(this, z_in)
            if (this.is_vertical == 0)
                z_refl = this.ej2alpha * conj(z_in) + 1j*this.c * (1 + this.ej2alpha);
            else
                z_refl = 2*this.d-real(z_in) + 1j*imag(z_in);
            end
            
            if (nargout > 1)
                tmp_r = real((z_in+z_refl))/2;
                if (this.is_vertical == 0)
                    if ( (tmp_r>=this.x_min) && (tmp_r<=this.x_max) )
                        is_valid = 1;
                    else
                        is_valid = 0;
                    end
                else
                    if ( (tmp_r>=imag(this.z_min)) && (tmp_r<=imag(this.z_max)) )
                        is_valid = 1;
                    else
                        is_valid = 0;
                    end
                end
            end
        end
        
        %% angles subtended
        function end_angles = view(this, z_in)
            end_angles(1) = angle(this.z_strt - z_in);
            end_angles(2) = angle(this.z_end - z_in);
        end
       
        %% perpendiclar distance
        function [d, d2] = perpendicular_distance(this, z_in)
            % create a line of perp slope
            if (this.m< this.EPS) % horizontal
                tmp_l = create_line(z_in, z_in + (0+1j));
            elseif (this.is_vertical) % vertical
                tmp_l = create_line(z_in, z_in + (1+0j));
            else % all else
                tmp_m = -1/this.m;
                tmp_l = create_line(z_in, z_in + (1+1j*tmp_m));
            end
            
            %% intersection
            [tmp_int, tmp_vld] = this.intersect(tmp_l);
            % within limits of line?
            if (tmp_vld(1) == 1)
                d = abs(z_in - tmp_int);
                d2 = NaN;
            else
                d = NaN;
                d2 = min( abs(z_in - this.z_min), abs(z_in - this.z_max) );
            end
        end
    end
end
