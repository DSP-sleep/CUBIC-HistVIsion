//for stained cell spot detection (cFos, whole brain, 10x10 devided stacks)
//parameters
//1) make Gaussian blurred image
Gaussian_sigma_1 = 1;
//2) Divide
//*If SN is very low, this procedure may not be efficient. In this case, skip the step.
//3) Subtract background
Rolling_size = 1; 
//4) 3D 3x expand
//5) Minimum 3D
//6) Gaussian Blur 3D
//7) set Threshold -> 3D Find Maxima

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Started ===");
print("");

File.makeDirectory("D:/ImageJ/Processed/Slices_pre-processed");

//parameters
Dialog.create("");
Dialog.addNumber("Lower threshold", 2);
Dialog.addNumber("Radius of 3D Maxima calc.", 2.5);
Dialog.addNumber("Noise tolerance of 3D Maxima calc.", 1);

Dialog.show();
Lower_threshold = Dialog.getNumber();
Radius = Dialog.getNumber();
Noise = Dialog.getNumber();

setBatchMode(true); 

for (x=0;x<10;x++){
for (y=0;y<10;y++){
	
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Start processing Crop_X"+x+"_Y"+y+" at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+"... =====================================");
print("");

open("D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Crop.tiff");

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
Z_3time = n*3;
Z_start = 0;
Z_end = Z_start+n-1;
Slice_start = Z_start+1;

print("*** Image info ***");
print("X = "+X+" pixels");
print("Y = "+Y+" pixels");
print("Start Z of stack: "+IJ.pad(Z_start,5));
print("No. of slices: "+n);
print("");

print ("*** Pre-processing ***");

//subtract background (rolling ball)
print("Run Subtract background (rolling = "+Rolling_size+")...");
run("Subtract Background...", "rolling=Rolling_size stack");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Subtract Background (rolling ball) at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//x3 expand
print("Resizing (3D 3x expansion)...");
run("Size...", "width=X_3time height=Y_3time depth=Z_3time constrain average interpolation=Bilinear"); 
After_3x = getImageID();
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Resize at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Minimum 3D
print("Run Minimum 3D (x=1, y=1, Z=1)...");
selectImage(After_3x);
run("Minimum 3D...", "x=1 y=1 z=1");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Minimum 3D at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Gaussian 3D
print("Run Gaussian Blur 3D (x=1, y=1, Z=1)...");
selectImage(After_3x);
run("Gaussian Blur 3D...", "x=1 y=1 z=1");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish Gaussian Blur 3D at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//set lower threshold
print("Set lower thresold (Apply LUT)...");
selectImage(After_3x);
setMinAndMax(Lower_threshold, 255);
call("ij.ImagePlus.setDefault16bitRange", 8);	
run("Apply LUT", "stack");
print("Lower threshold: "+Lower_threshold);
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Finish setting threshold at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Save image from stack
print("Each pre-processed image is saving...");
selectImage(After_3x);
run("Stack to Images");

for(j=0;j<Z_3time;j++){
Slice_no = j+1;
selectWindow("Crop-"+IJ.pad(Slice_no,4));
saveAs("Tiff", "D:/ImageJ/Processed/Slices_pre-processed/pre-processed_Z_["+IJ.pad(Z_start+j,5)+"].tif"); //  Write a proper directry pass
run("Close"); 
}

print("Finish pre-processing!!");
print("");

//3D Maxima calculation
//calculation of loop no.
if (Z_3time<119) {
	Loop_no = 1;
}else{
	for (j=0;j<40;j++){ 
		Start_z = j*115;
		End_z = Start_z +119;
		if (End_z < Z_3time) {
			Loop_no = j;
		}
	}	
	Loop_no = Loop_no +2; 
}

//3D Find Maxima
print("*** 3D Maxima calculation ***");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Start 3D Maxima calculation at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));	
print("Radius XYZ = "+Radius);
print("Noise tolerance = "+Noise);
print("No. of loop = "+Loop_no);
print("Start loop calculation...");
print("");

for (j=0; j<Loop_no; j++){
	print("[loop "+j+1+" of "+Loop_no+"]");
	Start_z = j*115;
	Stack_start_z = Start_z+1;
	if (j == Loop_no-1){
		Slice_no = Z_3time-Start_z;
		End_z = Z_3time-1;
	}else{
		Slice_no = 120;
		End_z = Start_z +119;
	}
	print("Stack range: slice "+Start_z+" - "+End_z+", slice #: "+Slice_no);
	run("Image Sequence...", "open=[D:/ImageJ/Processed/Slices_pre-processed] number=Slice_no starting=Stack_start_z sort");  // Write a proper directry pass
	stack_original = getImageID();
	run("3D Maxima Finder", "radiusxy=Radius radiusz=Radius noise=Noise");
	selectWindow("Results");
	saveAs("Results", "D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima.csv"); 
	run("Close");
	selectImage(stack_original);
	run("Close");
	selectWindow("peaks");
	//saveAs("Tiff", "D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima.tif"); 
	run("8-bit");
	setMinAndMax(0, 1);
	call("ij.ImagePlus.setDefault16bitRange", 8);	
	run("Apply LUT", "stack");
	peaks = getImageID();

	//Save stack image of centroids
	run("Stack to Images");
	if (j == 0){
		close("peaks-0118");
		close("peaks-0119"); 
		close("peaks-0120"); 
		run("Images to Stack");
		saveAs("Tiff", "D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima_stack(3x)_X"+x+"_Y"+y+".tif"); //  Write a proper directry pass 
		run("Close");
		print("Finish making the stack of slice #0 - 116");
		print("[Delete slices #117 - 119]");
		
	}else if (j == Loop_no-1) {
		close("peaks-0001");
		close("peaks-0002"); 
		k_end = Slice_no+1;

	}else{
		close("peaks-0001"); 
		close("peaks-0002");  
		close("peaks-0118"); 
		close("peaks-0119"); 
		close("peaks-0120"); 
		k_end = Slice_no-2;
		}

	if (j != 0) {
		print("(Delete first two slices)");
		open("D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima_stack(3x)_X"+x+"_Y"+y+".tif"); //  Write a proper directry pass 
		for (k=3; k<k_end; k++) {
			selectWindow("peaks-"+IJ.pad(k,4)); 
			run("Copy");
			close();
			selectWindow("Results_of_Maxima_stack(3x)_X"+x+"_Y"+y+".tif");
			m = nSlices();
			setSlice(m);
			run("Add Slice");
			run("Paste");
			print("Paste slice #" +m);
    		}
  			run("Select None");
			run("Save");
			close("Results_of_Maxima_stack(3x)_X"+x+"_Y"+y+".tif");

			if (j != Loop_no-1) {
				print("(Delete last three slices)");
		}
	}
	print("Finish 3D Maxima calculation of Crop_X"+x+"_Y"+y);
	print("");
} //loop j


//cropping
//Define merge
open("D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima_stack(3x)_X"+x+"_Y"+y+".tif"); //  Write a proper directry pass 
print("resize (1/3x)...");
run("Size...", "width=X height=Y depth=n constrain average interpolation=None"); 
if (x == 0){
	Merge_X = 0;
}else{
	Merge_X = 10;
}
	
if (y == 0){
	Merge_Y = 0;
}else{
	Merge_Y = 10;
}

//make crop stacks
print("Crop rectangle ("+Merge_X+", "+Merge_Y+", "+216+", "+256+")...");
setMinAndMax(0, 1);
call("ij.ImagePlus.setDefault16bitRange", 8);	
run("Apply LUT", "stack");
makeRectangle(Merge_X, Merge_Y, 216, 256);
run("Crop");
saveAs("Tiff", "D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima_stack_X"+x+"_Y"+y+".tif"); //  Write a proper directry pass 
run("Close");

//end telop
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("");
print("...Finish cell detection of Crop_X"+x+"_Y"+y+" at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+"!!");
print("");
print("");

} //y loop
} //x loop

//tiling
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
print("Start tiling at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));	
for (x=0;x<10;x++){
	for (y=0;y<10;y++){
		open("D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Results_of_Maxima_stack_X"+x+"_Y"+y+".tif");
	}
	for (y=1;y<10;y++){
		if(y == 1){
			run("Combine...", "stack1=Results_of_Maxima_stack_X"+x+"_Y0.tif stack2=Results_of_Maxima_stack_X"+x+"_Y1.tif combine");
			saveAs("Tiff", "D:/ImageJ/Processed/Results_of_Maxima_stack_Combined_X"+x+".tif");
		}else{
			run("Combine...", "stack1=Results_of_Maxima_stack_Combined_X"+x+".tif stack2=Results_of_Maxima_stack_X"+x+"_Y"+y+".tif combine");
			saveAs("Tiff", "D:/ImageJ/Processed/Results_of_Maxima_stack_Combined_X"+x+".tif");
		}
	}
	close("Results_of_Maxima_stack_Combined_X"+x+".tif");
}
for (x=0;x<10;x++){
	open("D:/ImageJ/Processed/Results_of_Maxima_stack_Combined_X"+x+".tif");
}
for (x=1;x<10;x++){
		if(x == 1){
			run("Combine...", "stack1=Results_of_Maxima_stack_Combined_X0.tif stack2=Results_of_Maxima_stack_Combined_X1.tif");
			saveAs("Tiff", "D:/ImageJ/Processed/Results_of_Maxima_stack_Combined.tif");
		}else{
			run("Combine...", "stack1=Results_of_Maxima_stack_Combined.tif stack2=Results_of_Maxima_stack_Combined_X"+x+".tif");
			saveAs("Tiff", "D:/ImageJ/Processed/Results_of_Maxima_stack_Combined.tif");
		}
	}

print("run Gaussian Blur 3D... (sigma: x=1 y=1 z=1)");
run("Gaussian Blur 3D...", "x=1 y=1 z=1");

//Save centroid slices
print("Each centroid image is saving...");
run("Stack to Images");

for (i=1;i<n+1;i++){
selectWindow("Results_of_Maxima_stack_Combined-"+IJ.pad(i,4)); 
Slice_no = i-1+Z_start;
File.makeDirectory("D:/ImageJ/Processed/Slices_Results_of_Maxima");
saveAs("Tiff", "D:/ImageJ/Processed/Slices_Results_of_Maxima/Results_of_Maxima_["+IJ.pad(Slice_no,5)+"].tiff"); //  Write a proper directry pass
close("Results_of_Maxima_["+IJ.pad(Slice_no,5)+"].tiff");
}
setBatchMode(false);
//End Telop
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Finished ==="); 
print("");
