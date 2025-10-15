clc;
clear;
close all;

img = imread('C:\Users\oluse\OneDrive\Desktop\MatMedi\fractures\Fracture 1.jpg');

ImgBlurSigma = 1.8; % Amount to denoise input image
MinHoughPeakDistance = 5; % Distance between peaks in Hough transform angle detection
HoughConvolutionLength = 40; % Length of line to use to detect bone regions
HoughConvolutionDilate = 2; % Amount to dilate kernel for bone detection
BreakLineTolerance = 0.25; % Tolerance for bone end detection
breakPointDilate = 6; % Amount to dilate detected bone end points

%%%%%%%%%%%%%%%%%%%%%%%
try
    img = (rgb2gray(img)); % Load image
catch
end
img = imfilter(img, fspecial('gaussian', 10, ImgBlurSigma), 'symmetric'); % Denoise

% Do edge detection to find bone edges in image
% Filter out all but the two longest lines
% This feature may need to be changed if break is not in middle of bone
boneEdges = edge(img, 'canny');
boneEdges = bwmorph(boneEdges, 'close');
edgeRegs = regionprops(boneEdges, 'Area', 'PixelIdxList');
AreaList = sort(vertcat(edgeRegs.Area), 'descend');
edgeRegs(~ismember(vertcat(edgeRegs.Area), AreaList(1:2))) = [];
edgeImg = zeros(size(img, 1), size(img,2));
edgeImg(vertcat(edgeRegs.PixelIdxList)) = 1;

% Do hough transform on edge image to find angles at which bone pieces are
% found
% Use max value of Hough transform vs angle to find angles at which lines
% are oriented.  If there is more than one major angle contribution there
% will be two peaks detected but only one peak if there is only one major
% angle contribution (ie peaks here = number of located bones = Number of
% breaks + 1)
[H,T,R] = hough(edgeImg,'RhoResolution',1,'Theta',-90:2:89.5);
maxHough = max(H, [], 1);
HoughThresh = (max(maxHough) - min(maxHough))/2 + min(maxHough);
[~, HoughPeaks] = findpeaks(maxHough,'MINPEAKHEIGHT',HoughThresh, 'MinPeakDistance', MinHoughPeakDistance);

% Plot Hough detection results
figure(1)
plot(T, maxHough);
hold on
plot([min(T) max(T)], [HoughThresh, HoughThresh], 'r');
plot(T(HoughPeaks), maxHough(HoughPeaks), 'rx', 'MarkerSize', 12, 'LineWidth', 2);
hold off
xlabel('Theta Value'); ylabel('Max Hough Transform');
legend({'Max Hough Transform', 'Hough Peak Threshold', 'Detected Peak'});



%%DETECTING WETHER OR NOT A LONG BONE FRACTURE HAS OCCURED
maxPeak = maxHough(HoughPeaks); %The peak value
primePeak = maxHough(1); %The Max Hough at -90 Theta

if numel(maxPeak)>= 3
    disp('This X-ray contains multiple bone fractures');
    
elseif numel(maxPeak) >=2
    disp('This X-Ray contains a bone fracture');
    
elseif numel(maxPeak) == 1 && maxPeak >= 190 && primePeak > maxPeak
    disp('This X-ray Contains a bone Fracture');

elseif primePeak < maxPeak
    disp("The bone in this X-Ray doesn't have a fracture");
    
else
    disp("The bone in this X-Ray doesn't have a fracture");
end


% Locate site of break
if numel(HoughPeaks) > 1;
    BreakStack = zeros(size(img, 1), size(img, 2), numel(HoughPeaks));
    % Convolute edge image with line of detected angle from hough transform
    for m = 1:numel(HoughPeaks);

        boneKernel = strel('line', HoughConvolutionLength, T(HoughPeaks(m)));
        kern = double(bwmorph(boneKernel.getnhood(), 'dilate', HoughConvolutionDilate));
        BreakStack(:,:,m) = imfilter(edgeImg, kern).*edgeImg;
    end

    % Take difference between convolution images.  Where this crosses zero
    % (within tolerance) should be where the break is.  Have to filter out
    % regions elsewhere where the bone simply ends.
    brImg = abs(diff(BreakStack, 1, 3)) < BreakLineTolerance*max(BreakStack(:)) & edgeImg > 0;
    [BpY, BpX] = find(abs(diff(BreakStack, 1, 3)) < BreakLineTolerance*max(BreakStack(:)) & edgeImg > 0);
    
    %Error Handling
    try
        brImg = bwmorph(brImg, 'dilate', breakPointDilate);
    catch
    end
    
    
    brReg = regionprops(brImg, 'Area', 'MajorAxisLength', 'MinorAxisLength', ...
        'Orientation', 'Centroid');
    brReg(vertcat(brReg.Area) ~= max(vertcat(brReg.Area))) = [];

   
else
    brReg = [];

end

% Draw ellipse around break location
figure(2)
imshow(img)
hold on
colormap('gray')

hold off