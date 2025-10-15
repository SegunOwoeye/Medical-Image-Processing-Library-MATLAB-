%% Read Me

%This Program detects the presence of brain tumors on MRi Images%

    % This projects does so by assuming the brain tumor to be the most
    % dense part of the MRI Scan
    
    
close all;
clear;
clc;

mri_img = imread('pictures/brainA.jpg'); %Makes the inputted picture usable in the program
mri_img = imresize(mri_img,[300, 300]);
bw_mri_scan = im2bw(mri_img, 0.7); %Changes the image to black and white, also changes saturation

label = bwlabel(bw_mri_scan);

stats = regionprops(label,'Solidity', 'Area');

density = [stats.Solidity]; %Takes the desnity at all the different points in the image
area = [stats.Area]; %Takes the area at all the different points in the image

high_density_area = density > 0.5; %Defines all high dense areas (high desnse areas are indications of tumors on MRI)
%The 0.5 value can change to a smaller percentage such that it can detect
%early stage tumors
max_area = max(area(high_density_area)); %Defines the border of the tumor given by high density points
tumor_label = find(area == max_area);
tumor = ismember(label, tumor_label); %Checks to see if info is valid

%Checks to make sure that what is detected is a tumor and not a cyst, by
%making sure the mass all has the same consistency in terms of density
se = strel('square',5);
tumor = imdilate(tumor, se);

figure(2)

%Image of the origional MRI scan
subplot(1,3,1)
imshow(mri_img,[])
title('MRI Brain Scan')

%isolated image of only the Tumor
subplot(1,3,2)
imshow(tumor,[])
title('Brain Tumor')

%Drawing boundry around tumor
[B,L] = bwboundaries(tumor,'noholes');
subplot(1,3,3)
imshow(mri_img,[])
hold on
    %for loop to create to boundry of the tumor
for i =1:length(B)
    plot(B{i}(:,2), B{i}(:,i), 'y','linewidth',1.45)
end

title('Detected Tumors')
hold off


