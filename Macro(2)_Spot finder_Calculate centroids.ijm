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
//2) Divide
//*If SN is very low, this procedure may not be efficient. In this case, skip the step.
//3) Subtract background
//4) 3x expand
//5) Gaussian blur before Laplacian filter
//6) FeatureJ Laplacian Filter
//7) Minimum filter 
//*This procedure can be used for crawded cells with good SN images. 
//if the images have a poor SN, this step may results in ovedetection of noises and nonspecific signals
//8)-1 Convert to Mask (RenyiEntropy) for taking threshold
//8)-2 set Threshold -> Find Maxima -> Maximum filter (radius = 0.5) -> get 5 pixel-Maxima points
//9) [Process with this Macro] 3D centroid calculation
Min_size = 6;
Max_size = 76;

//image information
X = 250;
Y = 250;
Z_start = 191;
n = 180;
//Z_end = Z_start+n-1;
Slice_start = Z_start+1;

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Started ===");
print("");

print("*** Image info ***");
print("X = "+X+" pixels");
print("Y = "+Y+" pixels");
print("Start Z of stack: "+Z_start);
print("No. of slices: "+n);
print("");

//calculation of loop no.
if (n<39) {
	Loop_no = 1;
}else{
	for (j=0;j<43;j++){ 
		Start_z = j*35;
		End_z = Start_z +39;
		if (End_z < n) {
			Loop_no = j;
		}
	}	
	Loop_no = Loop_no +2; 
}

print("*** 3D centroid calculation ***");
print("No. of loop for 3D object counter plugin = "+Loop_no);
print("Object size :"+Min_size+" - "+Max_size);
print("");

for (j=0; j<Loop_no; j++){
	Start_z = j*35;
	Stack_start_z = Start_z+1;
	if (j == Loop_no-1){
		Slice_no = n-Start_z;
		End_z = n-1;
	}else{
		Slice_no = 40;
		End_z = Start_z +39;
	}
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
	print("Start centroid calculation: Stack #"+Start_z+" ~ "+End_z+" at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));	
	run("Image Sequence...", "open=[/Users/suishess/Desktop/Temporary saved files/Slices_Maxima] number=Slice_no starting=Stack_start_z sort");  // Write a proper directry pass
	//process of 3D object counter
	setBatchMode(false);
	run("3D OC Options", "volume centroid close_original_images_while_processing_(saves_memory) show_masked_image_(redirection_requiered) dots_size=6 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
	run("3D Objects Counter", "threshold=128 slice=105 min.=Min_size max.=Max_size centroids statistics");
	setMinAndMax(0, 1);
	run("Apply LUT", "stack");
	run("8-bit");
	run("Gaussian Blur...", "sigma=2 stack");
	run("Size...", "width=X height=Y depth=Slice_no constrain average interpolation=Bilinear");
	Centroid_image = getTitle();
	selectWindow("Statistics for Slices_Maxima");
	saveAs("Results", "/Users/suishess/Desktop/Temporary saved files/Results_of_Statistics_"+IJ.pad(Start_z,4)+"to"+IJ.pad(End_z,4)+".csv"); // Write a proper directry pass
	run("Close");
	selectWindow(Centroid_image);
	//Save stack image of centroids
	setBatchMode(true);
	run("Stack to Images");
		if (j == 0){
		close("Centroids-0038"); 
		close("Centroids-0039"); 
		close("Centroids-0040"); 
		run("Images to Stack");
		saveAs("Tiff", "/Users/suishess/Desktop/Temporary saved files/Centroids_stack.tif"); //  Write a proper directry pass 
		print("Finish making the stack of slice #0 - 36");
		print("(Delete slices #37 - 39)");
		print("");
		
		}else if (j == Loop_no-1) {
		close("Centroids-0001");
		close("Centroids-0002"); 
		k_end = Slice_no+1;

		}else{
		close("Centroids-0001"); 
		close("Centroids-0002");  
		close("Centroids-0038"); 
		close("Centroids-0039"); 
		close("Centroids-0040"); 
		k_end = Slice_no-2;
		}

	if (j != 0) {
		print("(Delete slices #"+Start_z+" - "+Start_z+1+")");
		open("/Users/suishess/Desktop/Temporary saved files/Centroids_stack.tif"); //  Write a proper directry pass 
		for (k=3; k<k_end; k++) {
			selectWindow("Centroids-"+IJ.pad(k,4)); 
			run("Copy");
			close();
			selectWindow("Centroids_stack.tif");
			m = nSlices();
			setSlice(m);
			run("Add Slice");
			run("Paste");
			print("Paste slice #" +m);
    		}
  			run("Select None");
			run("Save");
			close("Centroids_stack.tif");

		if (j != Loop_no-1) {
			print("(Delete slices #"+End_z-2+" - "+End_z+")");
			print("");
		}
	}
}

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
//print("");
print("Finish calculation of centroids at "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2));
print("");

//Save centroid slices
print("Each centroid image is saving...");
open("/Users/suishess/Desktop/Temporary saved files/Centroids_stack.tif");  //  Write a proper directry pass
run("Stack to Images");
for (i=1;i<n+1;i++){
	if(i<38){
		Filetitle = "Centroids-";
	}else{
		Filetitle = "Centroids_stack-"; 
	}
selectWindow(Filetitle+IJ.pad(i,4)); 
Slice_no = i-1+Z_start;
saveAs("Tiff", "/Users/suishess/Desktop/Temporary saved files/Slices_Centroids/Centroids_["+IJ.pad(Slice_no,5)+"].tiff"); //  Write a proper directry pass
close("Centroids_["+IJ.pad(Slice_no,5)+"].tiff");
}


print("");
print("...Finish all procedures!!");
print("");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Finished ==="); //End Telop
print("");
