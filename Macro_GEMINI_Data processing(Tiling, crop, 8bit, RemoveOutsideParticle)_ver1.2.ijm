
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Started ===");
print("Data processing: Tiling 0~3x of sheet focused regions -> Tiling L+R (with intensity adjustment)");
print("                        -> Save 16-bit -> Crop -> Remove outside particle -> save 8-bit");
print("");

//***get lightsheet border from refenece image (L+R x 3xBW)***
Dialog.create("");
Dialog.addCheckbox("Auto border setting from reference images:", true); 	
Dialog.show;
AutoBorderSetting = Dialog.getCheckbox();

setBatchMode(true);

if (AutoBorderSetting == true) {

print("<< get tiling panel borders >>");
//Open reference images and get peak (left)
for (i=0; i<3; i++){
	open("D:\\ImageJ\\Processed_RefImage\\Image_Z_00001_Left_"+IJ.pad(i,3)+".tiff"); //directory for reference images: path up to user
	run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 2 -1 -1\n-1 2 5 2 -1\n-1 -1 2 -1 -1\n-1 -1 -1 -1 -1\n]");
	run("Select All");
	getStatistics(area, mean);
	setResult("Ref_meanL", i, mean);
	run("Scale...", "x=0.1 y=0.1 width=216 height=256 interpolation=Bilinear average create");
	selectWindow("Image_Z_00001_Left_"+IJ.pad(i,3)+"-1.tiff");
	run("Select All");
	profile_L = getProfile();
	max_x_L = 0;
	for (j=0; j<216; j++){
		if (profile_L[j] > profile_L[max_x_L]) {
			max_x_L = j;
		}
	}
	setResult("max_x_L",i,max_x_L);
	close("Image_Z_00001_Left_"+IJ.pad(i,3)+"-1.tiff");
}
updateResults();

//Open reference images and get peak (right)
for (i=0; i<3; i++){
	open("D:\\ImageJ\\Processed_RefImage\\Image_Z_00001_Right_"+IJ.pad(i,3)+".tiff"); //directory for reference images: path up to user
	run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 2 -1 -1\n-1 2 5 2 -1\n-1 -1 2 -1 -1\n-1 -1 -1 -1 -1\n]");
	run("Select All");
	getStatistics(area, mean);
	setResult("Ref_meanR", i, mean);
	run("Scale...", "x=0.1 y=0.1 width=216 height=256 interpolation=Bilinear average create");
	selectWindow("Image_Z_00001_Right_"+IJ.pad(i,3)+"-1.tiff");
	run("Select All");
	profile_R = getProfile();
	max_x_R = 0;
	for (j=0; j<216; j++){
		if (profile_R[j] > profile_R[max_x_R]) {
			max_x_R = j;
		}
	}
	setResult("max_x_R",i,max_x_R);
	close("Image_Z_00001_Right_"+IJ.pad(i,3)+"-1.tiff");
}
updateResults();

//intensity adjustment (Left)
Ref_meanL1 = getResult("Ref_meanL",1);
Ref_meanR1 = getResult("Ref_meanR",1);
Ref_ratioLR = Ref_meanL1/Ref_meanR1;
print("Ratio L/R of refenece images (step1) = "+Ref_ratioLR);

for (i=0; i<3; i++){
	Ref_meanL = getResult("Ref_meanL",i);
	Ref_ratioL = Ref_meanL1/Ref_meanL;
	selectWindow("Image_Z_00001_Left_"+IJ.pad(i,3)+".tiff"); 
	run("Multiply...", "value=Ref_ratioL");
	setResult("Ref_ratioL", i, Ref_ratioL);
	
	Ref_meanR = getResult("Ref_meanR",i);
	Ref_ratioR = Ref_meanR1/Ref_meanR;
	selectWindow("Image_Z_00001_Right_"+IJ.pad(i,3)+".tiff"); 
	run("Multiply...", "value=Ref_ratioR");
	run("Multiply...", "value=Ref_ratioLR");
	setResult("Ref_ratioR", i, Ref_ratioR);
}
updateResults();

//get borders of step0-1 & 1-2  (left)
for (i=0; i<2; i++){
max_x_L = getResult("max_x_L", i);
max_x_L_plus1 = getResult("max_x_L", i+1);
width_L = max_x_L - max_x_L_plus1;
imageCalculator("Difference create", "Image_Z_00001_Left_"+IJ.pad(i,3)+".tiff","Image_Z_00001_Left_"+IJ.pad(i+1,3)+".tiff");
selectWindow("Result of Image_Z_00001_Left_"+IJ.pad(i,3)+".tiff");
run("Scale...", "x=0.1 y=0.1 width=216 height=256 interpolation=Bilinear average create");
selectWindow("Result of Image_Z_00001_Left_"+IJ.pad(i,3)+"-1.tiff");
makeRectangle(max_x_L_plus1, 0, width_L, 256);
run("Crop");
run("Select All");
profile = getProfile();
min_x_L = 0;
	for (j=0; j<width_L; j++) {
		if (profile[j] < profile[min_x_L])  {
			min_x_L = j;
		}
	Border_L = (min_x_L + max_x_L_plus1)*10+5;
	setResult("Border_L", i, Border_L);
	close("Result of Image_Z_00001_Left_"+IJ.pad(i,3)+".tiff");
	close("Result of Image_Z_00001_Left_"+IJ.pad(i,3)+"-1.tiff");
	}
}
updateResults();

//get borders of step0-1 & 1-2  (right)
for (i=0; i<2; i++){
max_x_R = getResult("max_x_R", i);
max_x_R_plus1 = getResult("max_x_R", i+1);
width_R = max_x_R_plus1 - max_x_R;
imageCalculator("Difference create", "Image_Z_00001_Right_"+IJ.pad(i,3)+".tiff","Image_Z_00001_Right_"+IJ.pad(i+1,3)+".tiff");
selectWindow("Result of Image_Z_00001_Right_"+IJ.pad(i,3)+".tiff");
run("Scale...", "x=0.1 y=0.1 width=216 height=256 interpolation=Bilinear average create");
selectWindow("Result of Image_Z_00001_Right_"+IJ.pad(i,3)+"-1.tiff");
makeRectangle(max_x_R, 0, width_R, 256);
run("Crop");
run("Select All");
profile = getProfile();
min_x_R = 0;
	for (j=0; j<width_R; j++) {
		if (profile[j] < profile[min_x_R])  {
			min_x_R = j;
		}
	Border_R = (min_x_R + max_x_R)*10+5;
	setResult("Border_R", i, Border_R);
	close("Result of Image_Z_00001_Right_"+IJ.pad(i,3)+".tiff");
	close("Result of Image_Z_00001_Right_"+IJ.pad(i,3)+"-1.tiff");
	}
}
updateResults();

//get borders of Left step 0-Right step 0
max_x_L0 = getResult("max_x_L", 0);
max_x_R0 = getResult("max_x_R", 0);
width_L0R0 = max_x_R0 - max_x_L0;
if (width_L0R0 ==0){
Midline = max_x_L0*10+5;
}else{
imageCalculator("Difference create", "Image_Z_00001_Left_000.tiff","Image_Z_00001_Right_000.tiff");
selectWindow("Result of Image_Z_00001_Left_000.tiff");
run("Scale...", "x=0.1 y=0.1 width=216 height=256 interpolation=Bilinear average create");
selectWindow("Result of Image_Z_00001_Left_000-1.tiff");
makeRectangle(max_x_L0, 0, width_L0R0, 256);
run("Crop");
run("Select All");
profile = getProfile();
min_x_L0R0 = 0;
	for (j=0; j<width_L0R0; j++) {
		if (profile[j] < profile[min_x_L0R0])  {
			min_x_L0R0 = j;
		}
	}
Midline = (min_x_L0R0 + max_x_L0)*10+5;
}
print("Midline = "+Midline);
close("Result of Image_Z_00001_Left_000.tiff");
close("Result of Image_Z_00001_Left_000-1.tiff");
updateResults();

//close all images
for (i=0; i<3; i++){
	close("Image_Z_00001_Left_"+IJ.pad(i,3)+".tiff");
	close("Image_Z_00001_Right_"+IJ.pad(i,3)+".tiff");
}
print("Other parameters are in Result table.");
print("");
updateResults();

}else if (AutoBorderSetting == false) {
	print("Auto lightsheet border calculation - off");
	Dialog.create("");
	Dialog.addNumber("Border_L1:", 675,0,4,""); 
	Dialog.addNumber("Border_L0:", 970,0,4,""); 
	Dialog.addNumber("Midline:", 1100,0,4,""); 
	Dialog.addNumber("Border_R0:", 1275,0,4,""); 
	Dialog.addNumber("Border_R1:", 1535,0,4,""); 
	Dialog.show;
	
	Border_L1 = Dialog.getNumber();
	Border_L0 = Dialog.getNumber();
	Midline = Dialog.getNumber();
	Border_R0 = Dialog.getNumber();
	Border_R1 = Dialog.getNumber();
	
	print("Manual border setting: Start of step L1 ="+Border_L1);
	print("Manual border setting: Start of step L0 ="+Border_L0);
	print("Manual border setting: Midline ="+Midline);
	print("Manual border setting: End of step R0 ="+Border_R0);
	print("Manual border setting: End of step R1 ="+Border_R1);
	print("");
}

//if manual border setting needed, make the lines active
//Border_L1 = 636; //start of step L1
//Border_L0 = 889; //start of step L0
//Midline = 1084;
//Border_R0 = 1336; //end of step R0
//Border_R1 = 1560; //end of step R1
//print("Manual border setting: Start of step L1 ="+Border_L1);
//print("Manual border setting: Start of step L0 ="+Border_L0);
//print("Manual border setting: Midline ="+Midline);
//print("Manual border setting: End of step R0 ="+Border_R0);
//print("Manual border setting: End of step R1 ="+Border_R1);
//print("");

//***Make combined images***

//assign directory of sample images
dir = getDirectory("Choose a Raw Data Directory");	

//Set manual parameters
Dialog.create("Set parameters");			
Dialog.addNumber("Z Start #", 0,0,4,"");			
Dialog.addNumber("Z End #", 1000,0,4,"");
Dialog.addNumber("Z step size", 1,0,4,"");
Dialog.addNumber("Sheet focus position # of Left", 3,0,4,"");
Dialog.addNumber("Sheet focus position # of Right", 3,0,4,"");
Dialog.addCheckbox("Merge L+R with Max intensity:", false); 	
Dialog.addCheckbox("Crop:", true); 	
Dialog.addNumber("Crop width",1950,0,4,"");

Dialog.addCheckbox("Remove outside particles:", true); 	
Dialog.addNumber("Lower threshold (covering ROI)",6,0,4,"");
Dialog.addNumber("Upper threshold",254,0,4,"");
Dialog.show;

//assign z range and stepsize
zStart = Dialog.getNumber();
zEnd = Dialog.getNumber();
Stepsize = Dialog.getNumber();

//get BW number
BWno_L = Dialog.getNumber();
BWno_R = Dialog.getNumber();

//Max or tiling
Max_select = Dialog.getCheckbox();

//calculate crop width
Crop = Dialog.getCheckbox(); 
if (Crop == true) {
	CropWidth = Dialog.getNumber();
	CropX0 = Midline-CropWidth/2;
}else{
	CropWidth = Dialog.getNumber();
	Cropwidth = 2159;
	CropX0 = 0;
}

//Select On or Off of Remove Outside Particle
RemoveParticle = Dialog.getCheckbox(); 
Lower_Threshold = Dialog.getNumber();
Upper_Threshold = Dialog.getNumber();

//assign borders of beam waist stitching
//Left step 002: lx21-lx22
//Left step 001: lx11(Border_L1)-lx12
//Left step 000: lx01(Border_L0)-lx02(Midline)
//Right step 000: rx01-rx02(Border_R0)
//Right step 001: rx11-rx12(Border_R1)
//Right step 002: rx21-rx22


if (BWno_L == 1) {
	lx01 = 0;
}else{
	if (AutoBorderSetting == true) {
	Border_L0 = getResult("Border_L", 0);
	}
	lx01 = Border_L0;
}

if (BWno_R == 0 || Max_select == true){
	lx02 = 2159;
}else{
	lx02 = Midline;
}

if (BWno_L == 3) {
	if (AutoBorderSetting == true) {
	Border_L1 = getResult("Border_L", 1);
	}
	lx11 = Border_L1;
}else{
	lx11 = 0;
}

lx12 = lx01-1;
lx21 = 0;

if (BWno_L == 3) {
	lx22 = lx11-1;
}else{
	lx22 = 0;
}

if (BWno_L == 0 || Max_select == true){
	rx01 = 0;
}else{
	rx01 = Midline+1; 
}

if (BWno_R == 1) {
	rx02 = 2159; 
}else{
	if (AutoBorderSetting == true) {
	Border_R0 = getResult("Border_R", 0);
	}
	rx02 = Border_R0;
}

rx11 = rx02+1;

if(BWno_R == 3) {
	if (AutoBorderSetting == true) {
	Border_R1 = getResult("Border_R", 1);
	}
	rx12 = Border_R1;
}else{
	rx12=2159;
}

if(BWno_R == 3) {
	rx21 = rx12+1;
}else{
	rx21 = 0;
}
	
rx22 = 2159;

setResult("L_BW start_x", 0, lx01);
setResult("L_BW start_x", 1, lx11);
setResult("L_BW start_x", 2, lx21);
setResult("R_BW start_x", 0, rx01);
setResult("R_BW start_x", 1, rx11);
setResult("R_BW start_x", 2, rx21);

//calculate beam waist width: x1-start, x2-end, w = x2-(x1-1) = x2-x1+1
lw0 = lx02-lx01+1;
lw1 = lx12-lx11+1;
lw2 = lx22-lx21+1;
rw0 = rx02-rx01+1;
rw1 = rx12-rx11+1;
rw2 = rx22-rx21+1;

setResult("L_BW width", 0, lw0);
setResult("L_BW width", 1, lw1);
setResult("L_BW width", 2, lw2);
setResult("R_BW width", 0, rw0);
setResult("R_BW width", 1, rw1);
setResult("R_BW width", 2, rw2);

//Print parameters
print("<< Make tiled images: parameters >>");
print("***Z stack info***");
print("zStart: "+zStart);
print("zEnd: "+zEnd);
print("Step size: "+Stepsize);
print("");
print("***Tiling border_x***");
if (BWno_L == 3){
	print("Step 2 (Left): "+lx21+" ~ "+lx22+", width = "+lw2);
}else{
	print("No step2 (Left)");
}

if (BWno_L == 3 || BWno_L == 2 ){
print("Step 1 (Left): "+lx11+" ~ "+lx12+", width = "+lw1);
}else{
	print("No step1 (Left)");
}

if (BWno_L > 0){
print("Step 0 (Left): "+lx01+" ~ "+lx02+", width = "+lw0);
}else{
	print("No step0 (Left)");
}

if (BWno_R > 0){
	print("Step 0 (Right): "+rx01+" ~ "+rx02+", width = "+rw0);
}else{
	print("No step0 (Right)");
}

if (BWno_R == 3 || BWno_R == 2 ){
	print("Step 1 (Right): "+rx11+" ~ "+rx12+", width = "+rw1);
}else{
	print("No step1 (Right)");
}

if (BWno_R == 3){
print("Step 2 (Right): "+rx21+" ~ "+rx22+", width = "+rw2);
}else{
	print ("No step2 (Right)");
}
print("");
print("***Sheet focus position numbers tiled in the processed images***"); 
print("Left : "+BWno_L+" positions");
print("Right: "+BWno_R+" positions");
print("");
print("***L+R Merge***"); 
if (Max_select == true) {
	print("L+R merge with Max intensity");
	print("");
}else{
	print("Simple tiling at the midline");
	print("");
}
print("***Image cropping***"); 
if (Crop == true) {
	print("Crop range (X): "+CropWidth+" pixls from x = "+CropX0);
	print("");
}else{
	print("Skip Cropping");
	print("");
}

print("***Remove outside particles***"); 
if (RemoveParticle == true) {
	print("Status-On / Threshold: "+Lower_Threshold+" - "+Upper_Threshold);
	print("");
}else{
	print("Status-Off");
	print("");
}

print("");
print("<< make tiled images: process acquired images >>");

for (i=zStart; i<zEnd+1; i=i+Stepsize){
	print("***Processing file#: "+IJ.pad(i,5)+"***");
	
	//get intensity mean of step 1(Left) and adjust intensities of other images
	if (BWno_L == 3 || BWno_L == 2 ){
		for (j=0; j<BWno_L; j++){
		open("Image_Z_"+IJ.pad(i,5)+"_Left_"+IJ.pad(j,3)+".tiff"); 
		run("Select All");
		getStatistics(area, mean);
		setResult("meanL", j, mean);
		}
		meanL0 = getResult("meanL", 0);
		meanL1 = getResult("meanL", 1);
		meanL2 = getResult("meanL", 2);
		ratioL0 = meanL1/meanL0;
		selectWindow("Image_Z_"+IJ.pad(i,5)+"_Left_000.tiff"); 
		run("Multiply...", "value=ratioL0");
			if (BWno_L == 3){
				ratioL2 = meanL1/meanL2;
				selectWindow("Image_Z_"+IJ.pad(i,5)+"_Left_002.tiff"); 
				run("Multiply...", "value=ratioL2");
				print("Mean L0-L2 = "+meanL0+", "+meanL1+", "+meanL2);
				print("Ratio L1/L0, L1/L2 = "+ratioL0+", "+ratioL2);
			}else{
				print("Mean L0-L1 = "+meanL0+", "+meanL1);
				print("Ratio L1/L0 = "+ratioL0);
			}
	}else if (BWno_L == 1){
		open("Image_Z_"+IJ.pad(i,5)+"_Left_000.tiff"); 
		run("Select All");
		getStatistics(areaL1, meanL1);
		print("Use a fixed BW image (LEFT): Mean L0 = "+meanL1);
	}else{
		print("Use no image (LEFT)");
	}

	//get intensity mean of step 1(Right) and adjust intensities of other images
	if (BWno_R == 3 || BWno_R == 2 ){
		for (j=0; j<BWno_R; j++){
		open("Image_Z_"+IJ.pad(i,5)+"_Right_"+IJ.pad(j,3)+".tiff"); 
		run("Select All");
		getStatistics(area, mean);
		setResult("meanR", j, mean);
		}
		meanR0 = getResult("meanR", 0);
		meanR1 = getResult("meanR", 1);
		meanR2 = getResult("meanR", 2);
		ratioR0 = meanR1/meanR0;
		selectWindow("Image_Z_"+IJ.pad(i,5)+"_Right_000.tiff"); 
		run("Multiply...", "value=ratioR0");
			if (BWno_R == 3){
				ratioR2 = meanR1/meanR2;
				selectWindow("Image_Z_"+IJ.pad(i,5)+"_Right_002.tiff"); 
				run("Multiply...", "value=ratioR2");
				print("Mean R0-R2 = "+meanR0+", "+meanR1+", "+meanR2);
				print("Ratio R1/R0, R1/R2 = "+ratioR0+", "+ratioR2);
			}else{
				print("Mean R0-R1 = "+meanR0+", "+meanR1);
				print("Ratio R1/R0 = "+ratioR0);
			}
	}else if (BWno_R == 1){
		open("Image_Z_"+IJ.pad(i,5)+"_Right_000.tiff"); 
		run("Select All");
		getStatistics(areaR1, meanR1);
		print("Use a fixed BW image (RIGHT): Mean R0 = "+meanR1);
	}else{
		print("Use no image (RIGHT)");
	}

	//get Intensity parameter between L/R
	if (BWno_L > 0 && BWno_R >0){
	ratioLR = meanL1/meanR1;
	print("Ratio L1/R1 = "+ratioLR);
	}

	//Make cropped image of BW range (LEFT)
	if (BWno_L > 0){
		for (j=0; j<BWno_L; j++){
		selectWindow("Image_Z_"+IJ.pad(i,5)+"_Left_"+IJ.pad(j,3)+".tiff"); 
		Step_j_start = getResult("L_BW start_x", j);
		Step_j_width = getResult("L_BW width", j);
		makeRectangle(Step_j_start, 0, Step_j_width, 2560);
		setBackgroundColor(0, 0, 0);
		run("Clear Outside"); 
		}
	}

	//Make cropped image of BW range, intensity adjustment (RIGHT)
	if (BWno_R > 0){
		for (j=0; j<BWno_R; j++){
		selectWindow("Image_Z_"+IJ.pad(i,5)+"_Right_"+IJ.pad(j,3)+".tiff"); 
		if (BWno_L > 0 && BWno_R >0){
			run("Multiply...", "value=ratioLR");
		}
		Step_j_start = getResult("R_BW start_x", j);
		Step_j_width = getResult("R_BW width", j);
		makeRectangle(Step_j_start, 0, Step_j_width, 2560);
		setBackgroundColor(0, 0, 0);
		run("Clear Outside");
		}
	}

	//Make Merge -> save 16-bit -> make 8-bit 
	if (BWno_L + BWno_R > 1){
	run("Images to Stack", "name=Stack title=[] use");
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow("MAX_Stack");
	}
	run("Select None");
	saveAs("Tiff", "D:\\ImageJ\\Processed\\Tiled Image_Z_["+IJ.pad(i,5)+"].tiff"); //directory for saving 16-bit images: path up to user
	setMinAndMax(0, 65535);
	run("8-bit");

	//crop
	if (Crop == true){
	makeRectangle(CropX0, 0, CropWidth, 2560);
	run("Crop");
	}

	//close original and intermediate files
	close("Stack"); 
	if (BWno_L > 0){
		for (j=0; j<BWno_L; j++){
		close("Image_Z_"+IJ.pad(i,5)+"_Left_"+IJ.pad(j,3)+".tiff"); 
		}
	}
	if (BWno_R > 0){
		for (j=0; j<BWno_R; j++){
		close("Image_Z_"+IJ.pad(i,5)+"_Right_"+IJ.pad(j,3)+".tiff"); 
		}
	}
	
	print("Finish tiling");

//***Remove Outside Particle***
	if (RemoveParticle == true) {
		selectWindow("Tiled Image_Z_["+IJ.pad(i,5)+"].tiff");
		run("Duplicate...", " ");
		selectWindow("Tiled Image_Z_["+IJ.pad(i,5)+"]-1.tiff");
		//run("Threshold...");
		setThreshold(Lower_Threshold, Upper_Threshold);
		setOption("BlackBackground", false);
		run("Convert to Mask");
		for  (j=0; j<5; j++) {
			run("Erode");
		}
		run("Remove Outliers...", "radius=20 threshold=2 which=Dark");
		run("Invert");
		run("Create Selection");
		roiManager("Add");
		selectWindow("Tiled Image_Z_["+IJ.pad(i,5)+"].tiff");
		roiManager("Select", 0);
		run("Remove Outliers...", "radius=20 threshold=2 which=Bright");
		run("Select None");
		saveAs("Tiff", "D:\\ImageJ\\Processed_2\\Tiled Image_Z_8-bit_NoiseRemoved_["+IJ.pad(i,5)+"].tiff"); //directory for saving 8-bit images: path up to user
		close("Tiled Image_Z_8-bit_NoiseRemoved_["+IJ.pad(i,5)+"].tiff");
		close("Tiled Image_Z_["+IJ.pad(i,5)+"].tiff"); 
		close("Tiled Image_Z_["+IJ.pad(i,5)+"]-1.tiff");
		roiManager("Delete");
		print("Finish removing outside particles");

	}else{
		selectWindow("Tiled Image_Z_["+IJ.pad(i,5)+"].tiff");
		saveAs("Tiff", "D:\\ImageJ\\Processed_2\\Tiled Image_Z_8-bit_["+IJ.pad(i,5)+"].tiff"); //directory for saving 16-bit images: path up to user
		run("Close");
		print("Skip removing outside particles");
	}
	print("");	
	updateResults();
}	


getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("");
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Finished ==="); //End Telop
print("");
print("");