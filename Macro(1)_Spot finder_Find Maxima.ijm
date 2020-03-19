/*
for stained cell spot detection
File preparation: 
prepare "Processed" folder in an appropreate drive and "Slices_Maxima", "Slices_Centroids" folders in "Processed" folder
 */

 /*
 Procedure:
 1) run the test stack (having signals) for taking lower threhshold
 2) run the test stack for taking torelance of Find Maxima
 3) run the data for calculation
  */

//parameters
//1) make Gaussian blurred image
Gaussian_sigma_1 = 1;
//2) Divide
//*If SN is very low, this procedure may not be efficient. In this case, skip the step.
//3) Subtract background
Rolling_size = 1; //whole cellのシグナルは1??
//4) 3x expand
//5) Gaussian blur before Laplacian filter
Gaussian_sigma_2 = 2;
//6) FeatureJ Laplacian Filter
Laplacian_sigma = 2;
//7) Minimum filter 
//*This procedure can be used for crawded cells with good SN images. 
//if the images have a poor SN, this step may results in ovedetection of noises and nonspecific signals
//8)-1 Convert to Mask (RenyiEntropy) for taking threshold
//8)-2 set Threshold -> Find Maxima -> Maximum filter (radius = 0.5) -> get 5 pixel-Maxima points
//9) 3D centroid calculation

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Started ===");
print("");

setBatchMode(true); 

//get image info
Original = getTitle();
 
n = nSlices();
if (n % 2 == 0) {
	halfn = n/2;
} else {
	halfn = n/2+0.5;
}

X = getWidth();
Y = getHeight();

X_3time = X*3;
Y_3time = Y*3;

//set procedures
Dialog.create("Use processes below?");
Dialog.addCheckbox("Division by blurred image", true);
Dialog.addCheckbox("Minimum before binalization", true);
Dialog.show();
Division_use = Dialog.getCheckbox();
Minimum_use = Dialog.getCheckbox();

Dialog.create("");
Dialog.addCheckbox("Test for taking lower threshold?", false);
Dialog.show();
Test_for_threshold = Dialog.getCheckbox();

Dialog.create("");
Dialog.addNumber("Start Z of stack", 0);
Dialog.show();
Z_start = Dialog.getNumber();
Z_end = Z_start+n-1;
Slice_start = Z_start+1;

print("*** Image info ***");
print("File name: "+Original);
print("X = "+X+" pixels");
print("Y = "+Y+" pixels");
print("Start Z of stack: "+IJ.pad(Z_start,5));
print("No. of slices: "+n);
print("");

print ("*** Pre-processing ***");
if (Test_for_threshold == true) {
	print("(This macro runs as Test-for-taking-lower-threshold-value mode)");
	print("");
}

if (Division_use == true) {
//make Gaussian blurred image with masking
Dialog.create("Choise of mask making");
Dialog.addCheckbox("Make internal mask", false);
Dialog.addCheckbox("Use other stack", false);
Dialog.addCheckbox("Process without mask", false);
Dialog.show();
Make_internal_mask = Dialog.getCheckbox();
Use_other_stack = Dialog.getCheckbox();
Without_mask = Dialog.getCheckbox();

//create ROI series
if(Make_internal_mask == true) {
	selectImage(Original);
	print("Make internal mask...");
}else if(Use_other_stack == true){;
	run("Open...");
	Image_for_Mask = getTitle();
	selectImage(Image_for_Mask);
	print("Make mask using other image (file name: "+Image_for_Mask+")");
}
for(i=1;i<n+1;i++){
	setSlice(i);
	run("Duplicate...", "use");
	setAutoThreshold("Huang dark");
	run("Convert to Mask");
	run("Erode");
	run("Erode");
	run("Create Selection");
	roiManager("Add");
	close();
}

if(Use_other_stack == true){
	close(Image_for_Mask);
}

//Gaussian blur
print("Preparing blurred stack...");
selectWindow(Original);
run("Duplicate...", "duplicate title=[for_Blur]");
selectWindow("for_Blur");
if(Make_internal_mask == true || Use_other_stack == true){
	for(i=1;i<n+1;i++){
		setSlice(i);
		roiManager("Select", i-1);
		run("Gaussian Blur...", "sigma=Gaussian_sigma_1");
		run("Select None");
	}
	roiManager("Delete");
} else if (Without_mask == true){
	print("Apply Gaussian blur without mask");
	run("Gaussian Blur...", "sigma=Gaussian_sigma_1 stack");
}
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish making blurred image (sigma = "+Gaussian_sigma_1+") at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Divide
print("Dividing...");
imageCalculator("Divide create 32-bit stack", Original,"for_Blur");
selectWindow("Result of "+Original);
run("8-bit");
close("for_Blur");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish dividing at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//No use of blurring & division
}else{
	print("Division by blurred image was not used.");
	print("");
}

//subtract background (rolling ball)
print("Running Subtract background (rolling ball)...");
run("Subtract Background...", "rolling=Rolling_size stack");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Subtract Background (rolling ball) at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("Rolling = "+Rolling_size);
print("");

//x3 expand
print("Resizing (3x expansion)...");
run("Size...", "width=X_3time height=Y_3time depth=n constrain average interpolation=Bilinear"); 
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Resize (3x) at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Gaussian blur before Laplacian filter
//selectWindow(After_expand);
print("Running Gaussian Blur filter...");
run("Gaussian Blur...", "sigma=Gaussian_sigma_2 stack");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Gaussian Blur (Sigma = "+Gaussian_sigma_2+") at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//FeatureJ Laplacian filter
print("Running FeatureJ Laplacian filter...");
makeOval(5, 5, 20, 20);
run("Clear", "stack");
makeOval(5, 25, 20, 20);
run("Fill", "stack");
run("Select None");
run("FeatureJ Laplacian", "compute smoothing="+Laplacian_sigma);
After_Laplacian = getTitle();
setBatchMode(false);
run("Histogram", "bins=256 use x_min=-22.60 x_max=17.49 y_max=Auto stack");
waitForUser("check and close Histogram window...");
setBatchMode(true);
run("Invert", "stack");
run("16-bit");
close("Result of "+Original);
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish FeatureJ Laplacian filter (Sigma = "+Laplacian_sigma+") at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Minimum filter (optional)
selectWindow(After_Laplacian);
if (Minimum_use == true) {
	print("Mimium filter...");
	run("Minimum...", "radius=1.5 stack");
	//run("Invert", "stack");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
	print("Finish Minimum filter (radius = 1.5) at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
	print("");
}else{
	print("Minimum filter was not used.");
	print("");
}

//Detect cell position
//test for taking shreshold
if (Test_for_threshold == true) {
	setBatchMode(false);
	print("Save image for threshold analysis...");
	selectWindow(After_Laplacian);
	waitForUser("Save image");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
	print("End of test run for taking lower threshold at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
	print("");
	print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Finished ==="); //End Telop
	print("");
	print("");
	close(Original);

//Process for Find Maxima
}else{
	print("Set lower thresold (Apply LUT)...");
	Dialog.create("");
	Dialog.addNumber("Lower threshold", 15000);
	Dialog.show();
	Lower_threshold = Dialog.getNumber();
	selectWindow(After_Laplacian);
	setMinAndMax(Lower_threshold, 65535);
	call("ij.ImagePlus.setDefault16bitRange", 16);	
	run("Apply LUT", "stack");
	print("Lower threshold: "+Lower_threshold);
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
	print("Finish thresholding at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
	print("");
	close(Original);

//Find stack maxima
  print("Find Maxima & Maximum filter...");
  setBatchMode(false);
  waitForUser("Evaluate noise tolerance");
  Dialog.create("");
  Dialog.addNumber("Noise tolerance", 100);
  Dialog.show();
  Noise = Dialog.getNumber();
  setBatchMode(true);
  for (j=1; j<=n; j++) {
     showProgress(j, n);
     selectImage(After_Laplacian);
     setSlice(j);
     run("Find Maxima...", "noise=Noise output=[Single Points]");
     if (j==1){
        Maxima_output = getImageID();
     }else{
       run("Select All");
       run("Copy");
       close();
       selectImage(Maxima_output);
       run("Add Slice");
       run("Paste");
    }
  }
run("Select None");
close(After_Laplacian);

Radius = 0.5; 
selectImage(Maxima_output);
run("Maximum...", "radius=Radius stack"); 
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Find Maxima and Maximum filter at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("Noise parameter of Find Maxima = "+Noise);
print("Radius of Maximum filter = "+Radius);

print("saving Maxima stack...");
selectImage(Maxima_output);
saveAs("Tiff", "/Users/suishess/Desktop/Temporary saved files/Maxima_stack.tif"); // Write a proper directry pass
Maxima_stack = getTitle();
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish saving Maxima stack at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Save binary images from stack
print("Each Maxima image is saving...");
selectImage(Maxima_stack);
run("Stack to Images");
for(j=0;j<n;j++){
Slice_no = j+1;
selectWindow("Maxima_stack-"+IJ.pad(Slice_no,4));
//add white box to avoid "no object" error of 3D centroid calculation
makeRectangle(0, 0, 14, 14);
run("Fill");
saveAs("Tiff", "/Users/suishess/Desktop/Temporary saved files/Slices_Maxima/Maxima_Z_["+IJ.pad(Z_start+j,5)+"].tif"); //  Write a proper directry pass
run("Close"); 
}
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish saving Maxima slices at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");
print("...Finish all pre-processing!!");
print("");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Finished ==="); //End Telop
print("");
