function [panorama, overlapping_regions] = image_stitcher(path_name, descriptor_choice)
    % image_stitcher is the specific entry point for the image stitcher in MATLAB
    % that outputs AND shows the images stitched together
    %   Author : Zubeyir Bodur
    % 
    %   panorama = image_stitcher(path_name, "gra") stitches 
    %   images in the given file path using gradient based
    %   descriptor of SIFT
    %
    %   panorama = image_stitcher(path_name, "raw") 
    %   uses raw-pixel based descriptor instead
    %
    %   [panorama, overlapping_regions] = image_stitcher(path_name)
    %   also retrieves overlapping regions in the panorama
    %   where overlapping_regions is a MxNx(N_FILES - 1) 3D matrix
    %   assuming that panorama is MxN 2D matrix
    
    % 0. Input validation step
    has_param_error = false;
    if (~exist(path_name,"file"))
        disp("The input path is not an existing file." + newline);
        return;
    end
        
    if (descriptor_choice ~= "gra" && descriptor_choice ~= "raw")
        has_param_error = true;
        disp("Wrong descriptor parameter" + newline);
    end
    
    image_paths = readlines(path_name);
    n_files = size(image_paths, 1) - 1;
    for i= 1:n_files
        if (~exist(image_paths(i), "file") && image_paths(i) ~= "")
            disp("One if the image paths is not an existing file." + newline);
            return;
        end
    end
    
    if (has_param_error)
        return;
    end
    
    % Read the very first image
    img_1 = single(imread(image_paths(1)));
    
    % Initialize SIFT features for I(1)
    [key_points, descriptors] = vl_sift(img_1);
    
    if (descriptor_choice == "raw")
        % compute the raw pixel based descriptor
        % and replace it with SIFT descriptor
        clear descriptors;
        descriptors = rawpixel(img_1, key_points);
    end
    
    % Initialize all transforms to the identity matrix
    % Which are affine transformations
    transform(n_files) = affine2d(eye(3));
    
    % Initialize variable to hold image sizes.
    image_size = zeros(n_files,2);
    image_size(1,:) = size(img_1);
    
    % 1. Obtain a set of interest points using SIFT
    for i=2:n_files
        img_i = single(imread(image_paths(i)));
        img_i_minus_1 = single(imread(image_paths(i-1)));
    
        % Save image size
        image_size(i,:) = size(img_i);
        
        % KP's and descriptors for the previous image
        key_points_prev = key_points;
        descriptors_prev = descriptors;
    
        % Compute the SIFT keypoints and descriptors for img_i
        [key_points, descriptors] = vl_sift(img_i);
        
        % Plot the keypoints & descriptors for report
        
        % imshow(img_i, []);
        % h1 = vl_plotframe(key_points);
        % h2 = vl_plotframe(key_points);
        % set(h1,'color','k','linewidth',3);
        % set(h2,'color','y','linewidth',2);
        
        %imshow(img_i, []);
        %perm = randperm(size(key_points,2));
        %sel = perm(1:200);
        %h3 = vl_plotsiftdescriptor(descriptors(:,sel),key_points(:,sel));
        %set(h3,'color','g');
            
        if (descriptor_choice == "raw")
            % compute the raw pixel based descriptor
            % and replace it with SIFT descriptor
            clear descriptors;
            descriptors = rawpixel(img_i, key_points);
        end
        
        % Feature matching step:
        %
        % Using Lowe's method, called best-bin-first-search (BBF)
        % we can find the nearest neighbours of a keypoint in img_1
        % to img_2. The probability that a match is correct can 
        % be determined by taking the ratio of distance of the closest
        % neighbour to the second closest.
        %
        % Lowe rejected all matches w/ ratio > 0.8, eliminating % 90
        % of all false matches, and also accepting % 5 of the false matches.
        %    
        % Therefore, we will do some parameter tuning for this T value
        % Instead of finding minimum number of keypoints required to consider
        % a pair of keypoints as a match.
        %
        % Optimal T value was found as 2/3, smaller than the value Lowe used
        % equal to the value VLFeat uses.
        R = 2 / 3;
        % [matches, scores] = vl_ubcmatch(descriptors, descriptors_prev, R);
    
        % The implementation persists imperfections
        % but has high enough accuracy to use
        match_count = 0;
        matches_scratch = zeros(2, size(descriptors_prev, 2), 'double');
        for k1 = 1:size(descriptors, 2)
            nearest_neighbour_dist = double(intmax);
            second_nearest_neighbour_dist = double(intmax);
            nn_index = 0;
            for k2 = 1:size(descriptors_prev, 2)
                dist_sqrd = 0.0;
    
                % Calculate the Euclidean distance between k1 and k2
                for d = 1:size(descriptors, 1)
                    dist_sqrd = dist_sqrd + ...
                        (double(descriptors(d, k1)) ... 
                        - double(descriptors_prev(d, k2))) ^ 2;
                end
                % Commented out to make computation faster
                % dist = dist_sqrd^0.5;
    
                % Find the nearest & second nearest neighbour of k1 at set 2
                if (dist_sqrd < nearest_neighbour_dist)
                    second_nearest_neighbour_dist = nearest_neighbour_dist;
                    nearest_neighbour_dist = dist_sqrd;
                    nn_index = k2;
                elseif (dist_sqrd < second_nearest_neighbour_dist)
                    second_nearest_neighbour_dist = dist_sqrd;
                end
            end
            % If the nearest neighbour is distant enough from his second
            % neighbour, then it is a match
            if ( nearest_neighbour_dist < second_nearest_neighbour_dist * R ...
                    && nn_index ~= 0)
                match_count = match_count + 1;
                matches_scratch(1, match_count) = k1;
                matches_scratch(2, match_count) = nn_index;
            end
        end
    
        % If matches prime has the same size w/ matches
        % then implementation is a success
        matches_prime = matches_scratch(:, 1:match_count);
        
        % Store the matching coordinates
        match_locations = key_points(1:2, matches_prime(1, :));
        match_locations_prev = key_points_prev(1:2, matches_prime(2, :));
        
        % Uncomment to draw matches for this pair
%         if (i == 2)
%             figure; clf;
%             imshow([img_i img_i_minus_1], []);
%             hold on ;
%             h = line(...
%                 [match_locations(1, :) ; ...
%                 match_locations_prev(1, :) + size(img_i, 2)],...
%                 [match_locations(2, :); match_locations_prev(2, :)]);
%             set(h,'linewidth', 0.5, 'color', 'b');
%             
%             vl_plotframe(key_points(:,matches_prime(1,:)));
%             vl_plotframe([...
%                 key_points_prev(1,matches_prime(2,:)) + size(img_i, 2);...
%                 key_points_prev(2:4,matches_prime(2,:))]);
%             axis image off;
%         end
    
        
        % RANSAC step to estimate the transformation
        % use different parameters for gradient descriptor
        % and raw-pixel based descriptor
        if (descriptor_choice == "gra")
            transform(i) = estimateGeometricTransform2D(...
            transpose(match_locations), transpose(match_locations_prev), ...
            'affine', MaxNumTrials=50000, ...
            Confidence=99.99, MaxDistance=0.1);
        elseif (descriptor_choice == "raw")
            conf=80;
            max_dist=2.5;
            max_num_trials=1000000;
            status = -1;
            while status ~= 0
                [transform(i), ~, status] = estimateGeometricTransform2D(...
                transpose(match_locations), transpose(match_locations_prev), ...
                'affine', MaxNumTrials=max_num_trials, ...
                Confidence=conf, MaxDistance=max_dist);
    
                if (status ~= 0)
                    warning("Could not find enough inliers, now re-adjusting " ...
                        + " parameters to find enough inliers.");
                    max_dist = max_dist * 2;
                    conf = (conf / 3) * 2;
                    max_num_trials = max_num_trials * 3;
                end
            end
        end
    
        % Compute T(n) * T(n-1) * ... * T(1), 
        % as we are stitching multiple images together
        transform(i).T = transform(i).T * transform(i-1).T;
    end
    
    % At this point, all transformations are with respect to the first image
    % However, for better results, we need to find the center of the image.
    xlim = zeros(numel(transform), 2, 'double');
    ylim = zeros(numel(transform), 2, 'double');
    
    % Compute the output limits for each transform.
    for i = 1:numel(transform)           
        [xlim(i,:), ylim(i,:)] = outputLimits(transform(i), ...
            [1 image_size(i,2)], [1 image_size(i,1)]);    
    end
    
    % Find the image located n the center, based on the output limits
    avgXLim = mean(xlim, 2);
    [~,idx] = sort(avgXLim);
    centerIdx = floor((numel(transform)+1)/2);
    centerImageIdx = idx(centerIdx);
    
    % Apply the inverse of the center transform to get the
    % final series of affine transformations
    T_inverse = invert(transform(centerImageIdx));
    for i = 1:numel(transform)
        transform(i).T = transform(i).T * T_inverse.T;
    end
    
    max_img_size = max(image_size);
    
    % Compute the output limits for each transform again, as the
    % transformations have changed
    for i = 1:numel(transform)           
        [xlim(i,:), ylim(i,:)] = outputLimits(transform(i), ...
            [1 image_size(i,2)], [1 image_size(i,1)]);    
    end
    
    % Find the minimum and maximum output limits. 
    xMin = min([1; xlim(:)]);
    xMax = max([max_img_size(2); xlim(:)]);
    
    yMin = min([1; ylim(:)]);
    yMax = max([max_img_size(1); ylim(:)]);
    
    % Width and height of panorama.
    width  = round(xMax - xMin);
    height = round(yMax - yMin);
    
    % Initialize the "empty" panorama.
    panorama = zeros([height width], 'like', img_1);
    
    % Use a builtin blender for image registration
    % Does not smooth, a.k.a blend, the overlapping regions
    blender = vision.AlphaBlender('Operation', 'Binary mask', ...
        'MaskSource', 'Input port');
    
    % Create a 2-D spatial reference object defining the size of the panorama.
    xLimits = [xMin xMax];
    yLimits = [yMin yMax];
    panoramaView = imref2d([height width], xLimits, yLimits);
    
    % Create the panorama.
    % mask_prev = zeros([height width], 'like', img_1);
    overlapping_regions = zeros([height width n_files - 1], 'like', img_1);
    for i = 1:n_files
        
        img_i = single(imread(image_paths(i))); 
       
        % Transform img_i into the panorama.
        warpedImage = imwarp(img_i, transform(i), 'OutputView', panoramaView);
                      
        % Generate a binary mask.
        mask = imwarp(true(size(img_i,1),size(img_i,2)), transform(i), 'OutputView', panoramaView);
        
        % Uncomment to show the overlapping regions
        % figure(i); clf;
        % imshow(mask & mask_prev, []);
        % Register the overlapping regions TO DO
        % An overlapping region will be defined as Mask(N) & Mask(N-1)
        mask_prev = mask;
        overlapping_regions(:, :, i) = mask & mask_prev;
            
        % Overlay the warpedImage onto the panorama.
        panorama = step(blender, panorama, warpedImage, mask);

    end

    figure;
    imshow(panorama, []);
end