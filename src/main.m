disp("Important: Please enter quotes while entering input!");
disp("E.G.: Use " + '"' + "test1.txt" + '"' + " instead of test1.txt");
disp(newline + "In addition, in each run, it is important to clear the workspace as well" + newline);
disp(newline + "If vl_sift or any function is not defined, you can refer to README.txt to install necessary tools." + newline);
disp(newline + "Image stitching in MATLAB." + newline);
disp("To use it, enter two parameters," + newline ...
    + "first one being the text file listing the image paths,");
disp("the second one is the option for descriptors in algorithm.");
disp("Type " + '"' + "gra" + '"' ...
    + "(Gradient based descriptor) or " ...
    + '"' + "raw" + '"' ...
    + " (Raw-pixel based descriptor)." + newline);
path_name_main = input("Enter file name or full path: ");
descriptor_choice_main = input("Descriptor choice, gradient or raw: ");
[panorama, overlapping_regions] = image_stitcher(path_name_main, descriptor_choice_main);
% imshow(panorama, []);
% panorama_prime = blend(panorama, overlapping_regions, "avg");
% panorama_w_prime = blend(panorama, overlapping_regions, "wavg");