function descriptors = rawpixel(I, sift_keypoints)
    num_keypoints = size(sift_keypoints, 2);
    descriptors = zeros(256, num_keypoints, 'uint32');

    % For each keypoint
    for k=1:num_keypoints
        key_point = sift_keypoints(:, k);
        % Compute its rotated square window
        [mask, x_lim, y_lim] = generate_rot_sqr_window(I, key_point);
        for i=x_lim(1):x_lim(2)
            for j=y_lim(1):y_lim(2)
                if (mask(j, i))
                    % If the pixel is within the mask
                    % Increment the corresponding entry
                    % in the histogram
                    descriptors(uint32(floor(I(j, i))) + 1, k) = descriptors(uint32(floor(I(j, i))) + 1, k) + 1;
                end
            end
        end
    end
end