function [mask, x_lim, y_lim] = generate_rot_sqr_window(I, key_point)
    % Generates a squared window for a given
    % Key point in the given image
    
    a = key_point(1);
    b = key_point(2);
    scale = key_point(3);
    angle = key_point(4);

    x_max = size(I, 2);
    y_max = size(I, 1);
    mask = zeros(size(I), 'logical');

    % Find the limits of the squared window
    st_pt_x = a - scale;
    nd_pt_x = a + scale;
    st_pt_y = b - scale;
    nd_pt_y = b + scale;

    % Rotate each point around (a, b) angle degrees
    X = [st_pt_x nd_pt_x st_pt_x nd_pt_x];
    Y = [st_pt_y st_pt_y nd_pt_y nd_pt_y];
    
    degree = (180/ pi) * angle;

    X_rot =  (X-a)*cosd(degree) + (Y-b)*sind(degree) + a;
    Y_rot = -(X-a)*sind(degree) + (Y-b)*cosd(degree) + b;

    % Find the new boundaries
    st_pt_x_rot = min(X_rot);
    nd_pt_x_rot = max(X_rot);
    st_pt_y_rot = min(Y_rot);
    nd_pt_y_rot = max(Y_rot);

    % Adjust the boundaries for efficiency
    if (st_pt_x_rot <= 0)
        st_pt_x_rot = 1;
    elseif (st_pt_x_rot > x_max)
        st_pt_x_rot = x_max;
    end

    if (nd_pt_x_rot <= 0)
        nd_pt_x_rot = 1;
    elseif (nd_pt_x_rot > x_max)
        nd_pt_x_rot = x_max;
    end

    if (st_pt_y_rot <= 0)
        st_pt_y_rot = 1;
    elseif (st_pt_y_rot > y_max)
        st_pt_y_rot = y_max;
    end

    if (nd_pt_y_rot <= 0)
        nd_pt_y_rot = 1;
    elseif (nd_pt_y_rot > y_max)
        nd_pt_y_rot = y_max;
    end

    % find m1 & m2 slope values
    % and b1, b2, b3 and b4 values
    A = [X_rot(1) Y_rot(1)];
    B = [X_rot(2) Y_rot(2)];
    C = [X_rot(3) Y_rot(3)];
    D = [X_rot(4) Y_rot(4)];
    
    % Line AB
    m_1 = (B(2) - A(2)) / (B(1) - A(1));
    % Line AC
    m_2 = (C(2) - A(2)) / (C(1) - A(1));
    % Line CD
    m_3 = (D(2) - C(2)) / (D(1) - C(1));
    % Line BD
    m_4 = (D(2) - B(2)) / (D(1) - B(1));
    m = [m_1 m_2 m_3 m_4];

    b_1 = A(2) - m(1) * A(1);
    b_2 = A(2) - m(2) * A(1);
    b_3 = D(2) - m(3) * D(1);
    b_4 = D(2) - m(4) * D(1);
    b = [b_1 b_2 b_3 b_4];

    % Compute the histogram
    x_lim = [uint32(floor(st_pt_x_rot)) + 1 uint32(ceil(nd_pt_x_rot))];
    y_lim = [uint32(floor(st_pt_y_rot)) + 1 uint32(ceil(nd_pt_y_rot))];
    for i=(uint32(floor(st_pt_x_rot)) + 1):uint32(ceil(nd_pt_x_rot))
        for j=(uint32(floor(st_pt_y_rot)) + 1):uint32(ceil(nd_pt_y_rot))
            if m_1 == 0 || m_2 == 0
                mask(j, i) = true;
                continue;
            end
            contains = true;
            for n=1:2
                v = double((j-1)) - m(n) * double((i-1));
                if (v <= b(n) && v >= b(n+2) || v >= b(n) && v <= b(n+2))
                    %
                else 
                    contains = false;
                    break;
                end
            end
            if contains
                mask(j, i) = true;
            end
        end
    end
end