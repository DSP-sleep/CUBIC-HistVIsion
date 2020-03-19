//This macro can make 10x10 divided stacks of a whole-brain image

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Started ===");
print("");

setBatchMode(true);
 Original = getTitle();
 print("*** Cropping area ***");
 //border definition
 for (x=0;x<10;x++){
 Border_X = x*216;
	 for (y=0;y<10;y++){
 	Border_Y = y*256;
	
	 //Define merge
	if (x == 0){
		Merge_X_minus = 0;
		Merge_X_plus = 10;
	}else if (x == 9){
		Merge_X_minus = 10;
		Merge_X_plus = 0;
	}else{
		Merge_X_minus = 10;
		Merge_X_plus = 10;
	}
	
	if (y == 0){
		Merge_Y_minus = 0;
		Merge_Y_plus = 10;
	}else if (x == 9){
		Merge_Y_minus = 10;
		Merge_Y_plus = 0;
	}else{
		Merge_Y_minus = 10;
		Merge_Y_plus = 10;
	}
	
	//Define rectangle parameter
	Rectangle_X0 = Border_X - Merge_X_minus;
	Rectangle_Y0 = Border_Y - Merge_Y_minus;
	Width_X = 216 + Merge_X_minus + Merge_X_plus;
	Width_Y = 256 + Merge_Y_minus + Merge_Y_plus;

	//make crop stacks
	selectWindow(Original);
	makeRectangle(Rectangle_X0, Rectangle_Y0, Width_X, Width_Y);
	run("Duplicate...", "duplicate");
	ID = getImageID;
	File.makeDirectory("D:/ImageJ/Processed/Crop_X"+x+"_Y"+y);
	saveAs("TIFF", "D:/ImageJ/Processed/Crop_X"+x+"_Y"+y+"/Crop.tiff");
	close("Crop.tiff");
	selectWindow(Original);
	run("Select None");
	print("Crop rectangle ("+Rectangle_X0+", "+Rectangle_Y0+", "+Width_X+", "+Width_Y+")");
 }//j loop
 }//i loop

print("");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, seconds, msec);
rmonth = month+1;
print("=== "+year+"-"+rmonth+"-"+dayOfMonth+" "+IJ.pad(hour,2)+":"+IJ.pad(minute,2)+":"+IJ.pad(seconds,2)+" Macro Finished ==="); //End Telop
print("");
