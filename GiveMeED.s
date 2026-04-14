/*
GiveMeElectronDiffraction
B L Weare, @NMRC

Associated preprint for greater context: http://arxiv.org/abs/2507.10247
Please consider citing if you found this script useful.

*/

// Calculate the wavelength given the accelerating voltage, in metres.
number CalculateWavelength( number HT )
{
	//EMGetHighTension( ) / 1000
	number c = 299792458
	number h = 6.62607015e-34
	number e = 1.602176634e-19
	number m_e = 9.1093837139e-31
	
	number E_k = HT*e
	number lamb = h/(2*m_e*E_k*(1+(E_k/(2*m_e*(c**2)))))**0.5

	return lamb
}
//Grab scale from image
number ScaleInfo( )
{
	image img := GetFrontImage()
	number img_scale = ImageGetDimensionScale(img, 0)
	string scale_units = ImageGetDimensionUnitString(img, 0)
	//result("Scale: " + img_scale + " " + scale_units + "\n")
	return img_scale
}
// Grab image center.
void get_image_center( number &x, number &y )
{
	image img = GetFrontImage()
	x = ImageGetDimensionSize(img, 0)/2
	y = ImageGetDimensionSize(img, 1)/2
	return
}

//Initialise variables
number alpha_start = -60 //start stage tilt
number alpha_end = 60 //end stage tilt
string save_dir = "X:\\" //directory to save log file, no trailing slash
string ISName = "sample_name"
string sample_name = ISName
string log_ext = ".cif" //file extension for log file
string ISDataPath = save_dir + ISName
string notes = "[e.g. cryo 120 K]" //enter notes here and they are included in the log file
string filename, saveName
number frame_rate = 175
number exp_num = 0 // initial log file suffix
number fiddle = 1.0 // tolerance in angle
number cam_sleep = 0.001 // sync while loop
number fileCheck = 1 
number start_angle, end_angle 
number camid = CameraGetActiveCameraID()
number camera_length
number HT = EMGetHighTension()
number lambda = CalculateWavelength( HT ) *1e10 // in Angstroms

number img_center_x, img_center_y
get_image_center( img_center_x, img_center_y )

number axis_value = 0

string program_name = "GiveMeED"
string microscope_name = "JEOL 2100Plus transmission electron microscope"
string camera_name = "Gatan OneView"

// Event timing variables
number time_1, time_2
number false = 0; number true =1
// Declare functions
string UniqueSaveName( string save_dir, string &saveName, string fileName, string sample_name,\
						string log_ext, number &exp_num, number fileCheck )
{
	try
	{
		while ( fileCheck == 1 )
		{
			filename = sample_name + "_" + exp_num + log_ext
			saveName = PathConcatenate( save_dir, filename )
			fileCheck = DoesFileExist( saveName )

			if ( fileCheck == 1 )
				exp_num = exp_num + 1
			else 
				break
		}
	}
	catch
	{
		result( "Something went wrong." )
	}
	return saveName
}
// actual camera length based on image pixel size
//number calcualte_camera_length(, number distance, number lamb, number size )
//{ 
//	number cam_length_1x_bin, cam_length_2x_bin, cam_length_4x_bin
//	distance = (1/distance)*1e-9
//	size = size*1e-9
//	// camera length in metres 
//	cam_length_1x_bin = (distance * size) / lamb
//	
//	cam_length_2x_bin = cam_length_1x_bin / 2
//	cam_length_4x_bin = cam_length_1x_bin / 4
//	
//	return
//}
//calculate_camera_length( 0.074319, 0.00251, 15 )
// Counts files in folder
TagGroup CreateFileList( string folder, number inclSubFolder )
{
	TagGroup filesTG = GetFilesInDirectory( folder , 1 )
	TagGroup fileList = NewTagList()
	for (number i = 0; i < filesTG.TagGroupCountTags() ; i++ )
	{
		TagGroup entryTG
		if ( filesTG.TagGroupGetIndexedTagAsTagGroup( i , entryTG ) )
		{
			string fileName
			if ( entryTG.TagGroupGetTagAsString( "Name" , fileName ) )
			{
				filelist.TagGroupInsertTagAsString( fileList.TagGroupCountTags() , PathConcatenate( folder , fileName ) )
			}
		}
	}

	TagGroup allFolders = GetFilesInDirectory( folder, 2 )
	number nFolders = allFolders.TagGroupCountTags()
	for ( number i = 0; i < nFolders; i++ )
	{
		string sfolder
		TagGroup entry
		allFolders.TagGroupgetIndexedTagAsTagGroup( i , entry )
		entry.TagGroupGetTagAsString( "Name" , sfolder )
		sfolder = StringToLower( sfolder )
		TagGroup SubList = CreateFileList( PathConcatenate( folder , sfolder ) , inclSubFolder )
		for ( number j = 0; j < SubList.TagGroupCountTags(); j++ )
		{
			string file
			if ( SubList.tagGroupGetIndexedTagAsString( j , file ) )
			fileList.TagGroupInsertTagAsString( Infinity() , file )
		}
	}   
	return fileList
}
// Convert a string to lower-case characters
string ToLowerCase( string in )
{
	string out = ""
	for( number c = 0 ; c < len( in ) ; c++ )
	{
		string letter = mid( in , c , 1 )
        number n = asc( letter )
        if ( ( n > 64 ) && ( n < 91 ) )        letter = chr( n + 32 )
        out += letter
	}        
	return out
}
// Removes entries not matching in suffix
TagGroup FilterFilesList( TagGroup list, string suffix )
{
	TagGroup outList = NewTagList()
	suffix = ToLowerCase( suffix )
	for ( number i = 0 ; i < list.TagGroupCountTags() ; i++ )
	{
		string origstr
        if ( list.TagGroupGetIndexedTagAsString( i , origstr ) ) 
        {
			string str = ToLowerCase( origstr )
			number matches = 1
			if ( len( str ) >= len( suffix ) )
			{
				if ( suffix == right( str , len( suffix ) ) )
				{
					outList.TagGroupInsertTagAsString( outList.TagGroupCountTags() , origstr )
				}
			}
		}
	}
	return outList
}
// File counting block - works well for low frame rates
number HowManyFrames( string folder )
{
	number input = 1
	string extension = ".dm4"
	TagGroup filesList = CreateFileList( folder, input )
	TagGroup filteredList = FilterFilesList( fileslist, extension )
	number nfiles = filteredList.TagGroupCountTags( )
	nfiles = nfiles - 1//IS data is systematically high due to control file
	return nfiles
}
// Writes tag to images
void Tag3DEDData( string progname, number start_angle, number end_angle,\
				number total_time, number fps, string rotation_axis, string notes,\
				string DataPath, string ISName )
{
	number rotation_range = end_angle - start_angle
	number exposure = 1 / fps
	string ImageName = DataPath + "\\"+ ISName + ".dm4"
	result( ImageName )
	try{
		image target:=OpenImage(ImageName)
		TagGroup imgTags = target.ImageGetTagGroup()
		string bosstag
		bosstag = "3DED data:"
		imgTags.TagGroupSetTagAsString( bosstag + "Program", progname )
		imgTags.TagGroupSetTagAsNumber( bosstag + "Start angle (deg)", start_angle )
		imgTags.TagGroupSetTagAsNumber( bosstag + "End angle (deg)", end_angle )
		imgTags.TagGroupSetTagAsNumber( bosstag + "Rotation range (deg)", rotation_range )
		imgTags.TagGroupSetTagAsNumber( bosstag + "Total time (s)", total_time )
		imgTags.TagGroupSetTagAsNumber( bosstag + "Frame rate (fps)", fps )
		imgTags.TagGroupSetTagAsNumber( bosstag + "Exposure (s)", exposure )
		imgTags.TagGroupSetTagAsString( bosstag + "Rotation axis (deg)", rotation_axis )
		imgTags.TagGroupSetTagAsString( bosstag + "Notes", notes )
		Save( target )
		CloseImage( target )
	}
	catch{
		result( "Something went wrong. Tags not written to image." + "\n" )
		result(ImageName + "\n" )
	}
	
}
// Puts date into yyyy-mm-dd
string format_date()
{
	number year, month, day, hour, minute, second, nanosecond
	DeconstructUTCDate( GetCurrentTime(), year, month, day, hour, minute, second, nanosecond )
	string formatted = format(year, "%04d") + "-" + format(month, "%02d") + "-" + format(day, "%02d" + "\n")
	return formatted	
}
// Writes metadata string as CIF
string format_metadata( string ISDataPath, string saveName, string notes,image img,number scale_x,\
						number scale_y,number phys_pixelsize_x,number phys_pixelsize_y,string timestamp,\
						string program_name,number lambda,string tem_name,string camera_name,number high_tension,\
						number spot_size,number camera_length,number start_angle, number end_angle,number total_time,\
						number frame_rate,number no_frames,string rotation_axis )
{
	string date
	date = format_date()
	string CIF_3DED = "data_GMED"+"\n"+\
	"_audit_creation_date " + "?" + "\n"+\
	"_audit_creation_method " + "'Created by GMED'" + "\n"+\
	"_computing_data_collection " + program_name + "\n"+\
	"_diffrn_source 'LaB6'\n"+\
	"_diffrn_radiation_probe " + "electron" + "\n"+\
	"_diffrn_radiation_type electrons \n"+\
	"_diffrn_radiation_wavelength " + lambda + "\n"+\
	"_diffrn_radiation_monochromator " + "'transmission electron microscope'" + "\n"+\
	"_diffrn_radiation_device " + "'transmission electron microscope'" + "\n"+\
	"_diffrn_radiation_device_type " + tem_name + "\n"+\
	"_diffrn_detector " + "'CMOS camera'" + "\n"+\
	"_diffrn_detector_type " + camera_name + "\n"+\
	"_diffrn_measurement_method '3DED'"+ "\n"+\
	"_diffrn_source_voltage " + high_tension + "\n" +\
	"_diffrn_detector_details 'electron camera'" +"\n"+\
	"_cell_measurement_temperature ?" +"\n"+\
	"_diffrn_measurement_details" +"\n"+\
	";" +"\n"+\
	"Save Location: " + ISDataPath + "\n"+\
	"IS Data: " + saveName + "\n"+\
	"Spot Size: " + spot_size + "\n"+\
	"Camera: " + camera_name + "\n"+\
	"Camera length (mm): " + camera_length + "\n"+\
	"Camera pixel size x/y (um): (" + phys_pixelsize_x + ", " + phys_pixelsize_y + ")\n"+\
	"Scale (nm-1 px-1): " + scale_x + ", " + scale_y + "\n"+\
	"Image size x/y (px): (" + ImageGetDimensionSize(img, 0) + ", " + ImageGetDimensionSize(img, 1) + ")\n"+\
	"Date and time: " + timestamp + "\n"+\
	"Start angle (deg): " + start_angle + "\n"+\
	"End angle (deg): " + end_angle +  "\n"+\
	"Rotation range (deg): " + (end_angle - start_angle) + "\n"+\
	"Data collection time (s): " + total_time + "\n"+\
	"Frame Rate (fps): " + frame_rate + "\n"+\
	"Exposure (s): " + 1/frame_rate + "\n"+\
	"Number of frames : " + no_frames + "\n"+\
	"Angle per frame (deg): " + abs( end_angle - start_angle ) / no_frames + "\n"+\
	"Rotation axis (deg): " + rotation_axis + "\n"+\
	"Notes:" + notes + "\n"+\
	";\n"
	return( CIF_3DED )
}
// Metadata block
void CreateLogFile( string program_name, string fileName, string saveName, number camid,\
 number time_1, number time_2, number end_angle, number start_angle, string notes,\
  number fiddle, number cam_sleep, string ISDataPath, number frame_rate, number lambda, number camera_length )
{
	// event timings
	number total_time = CalcHighResSecondsBetween( time_1, time_2 )
	number no_frames = -1
	try
	{
		no_frames = HowManyFrames( ISDataPath )
	}
	catch
	{
		no_frames = -1 //total number of frames
	}
	// get experiment parameters 
	//number end_angle = EMGetStageAlpha( )
	number spot_size = EMGetSpotSize( )
	number acquisition_time = total_time / no_frames
	number total_angle = abs( end_angle - start_angle )
	string timestamp = FormatTimeString( GetCurrentTime(), 33 )
	// get camera and tem name
	string camera_name = CameraGetName( camid )
	string tem_name = "'JEOL 2100Plus Transmission Electron Microscope'"
	string rotation_axis = "-25.1"
	number high_tension = EMGetHighTension( ) / 1000 //accelerating voltage in kV
	image img := GetFrontImage()
	number phys_pixelsize_x, phys_pixelsize_y, scale_x, scale_y
	CameraGetPixelSize(camid, phys_pixelsize_x, phys_pixelsize_y)
	GetScale( img, scale_x, scale_y )
	
	// create log
	string log_message = format_metadata(ISDataPath, saveName, notes, img, scale_x, scale_y, phys_pixelsize_x,\
	 phys_pixelsize_y, timestamp, program_name, lambda, tem_name, camera_name, high_tension, spot_size,\
	 camera_length, start_angle, end_angle, total_time, frame_rate, no_frames, rotation_axis)
	
	// print log to console
	result( "\n ===== \n" )
	result( log_message )
	// write log to file
	number fileNum = CreateFileForWriting( saveName )
	WriteFile( fileNum, log_message )
	CloseFile( fileNum )
	result( "Wrote file: " + fileName )
	result( "Saved data to: " + saveName + "\n" )
	
	Tag3DEDData( program_name, start_angle, end_angle, total_time, frame_rate, rotation_axis, notes, ISDataPath, ISName )
}
// data collection block
void ContinousTilt( number fiddle, number alpha_start, number alpha_end, number &end_angle,\
 number &start_angle, number &time_1, number &time_2, number cam_sleep, number &camera_length )
{
	camera_length = EMGetCameraLength()
	EMSetStageAlpha( alpha_start )
	while ( abs( EMGetStageAlpha( )- alpha_start ) >= fiddle )
	{
		if ( ShiftDown( ) ) exit( 0 )
	}
	sleep(0.25)//sleeps to settle stage
	EMSetBeamBlanked(0)//unblank beam
	EMSetStageAlpha( alpha_end )
	number current_alpha, angle_delta
	while ( angle_delta < fiddle )//waits until tilt starts
	{
		sleep( cam_sleep )
		current_alpha = EMGetStageAlpha( )
		angle_delta = abs( current_alpha - start_angle )
	}
	CM_InSitu_StartRecord( ) // start IS capture
	start_angle = EMGetStageAlpha()
	result( "IS Acquire" + "\n" )
	
	time_1 = GetHighResTickCount( )

	if ( alpha_start > 0 )
		while ( abs( EMGetStageAlpha( )- alpha_start ) <= abs( ( alpha_start - alpha_end  ) - fiddle ) )
		{
			if ( ShiftDown( ) ) exit( 0 ) //exit loop if shift is held
		}
	else
		while ( abs( EMGetStageAlpha( ) - alpha_start ) <= abs( ( alpha_start - alpha_end  ) + fiddle ) )
		{
			if ( ShiftDown( ) ) exit( 0 )
		}

	//End IS capture
	end_angle = EMGetStageAlpha( )
	time_2 = GetHighResTickCount( )
	CM_InSitu_StopRecord( )
	result( "IS Cease" + "\n" )

	EMSetBeamBlanked( 1 )//blank beam

	return
}


//// Resolution rings and Tilt Axis ////
number ConvertToRecNM( number num2convert )
{ 
	number convertednum = 1/(num2convert*0.1)
	//result(num2convert + " A = " + convertednum + " nm-1" + "\n")
	return convertednum
}
//Create ROI
ROI CreateResRing( number radlabel, number radius, number x, number y, number r, number g, number b )
{
	ROI resRing = NewROI( )
	ROISetCircle(resRing, x, y, radius)
	image img := GetFrontImage()
	ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
	//imgDisplay.ImageDisplayAddROI( resRing )
	
	string label = radlabel + " A"
	ROISetColor( resRing, r, g, b) //RBG in 0-1
	if (radlabel != 100)
		ROISetLabel( resRing, label )
	ROISetMoveable( resRing, 0 )
	ROISetVolatile( resRing, 0 )
	ROISetRestrictToDisplay( resRing, 0 )
	//ROISetName(resRing, radius )
	
	return resRing
}
image resolution_rings := [1,6] : {
	{100},
	{4},
	{2},
	{1.4},
	{1},
	{0.8}//,
	//{0.6}
}
// Draw ROIs on front image.
void draw_tilt_axis( number angle, number cent_x, number cent_y, image img )
{
	ROI tilt_axis = NewROI()
	angle = angle * (3.141/180)
	number length = cent_x
	number x, y
	x = ( length ) * sin( angle )
	y = ( length ) * cos( angle )
	
	// Get cartesian coords from axis
	ROISetLine( tilt_axis, cent_x+x, cent_y+y, cent_x-x, cent_y-y )
	
	ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
	imgDisplay.ImageDisplayAddROI( tilt_axis )
	
	string label = "Tilt axis"
	//ROISetLabel( tilt_axis, label )
	ROISetMoveable( tilt_axis, 0 )
	ROISetVolatile( tilt_axis, 0 )
	number r, g, b
	r = 0
	b = 0
	g = 1
	ROISetColor( tilt_axis, r, g, b )
}
void draw_resolution_rings( image img, number rval, number gval, number bval, number cent_x, number cent_y )
{
	ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
	number array_length = ImageGetDimensionSize(Resolution_Rings, 1)//y dimentsion of array

	ROI ring
	for (number i = 0; i < array_length ; i++ )//less than length of array
	{
		try
		{
			number ringRadius = GetPixel(resolution_rings, 0, i )//element i of array (counts from 0)
			number scale = ScaleInfo( )
			number rawRadius = ConvertToRecNM( ringRadius )
			number pixRadius = rawRadius / scale
			ring = CreateResRing( ringRadius, pixRadius, cent_x, cent_y, rval, gval, bval )
			imgDisplay.ImageDisplayAddROI( ring )
		}
		catch
		{
			result("something went wrong" + "\n")
		}
	}
	CloseImage(Resolution_Rings)
}

// Remove ROIs.
void remove_ROIs( imageDisplay disp, number flag )
{
	number nR = disp.ImageDisplayCountROIs() 
	for ( number i = ( nR - 1 ) ; i >= 0 ; i-- )
		{
		ROI r = disp.ImageDisplayGetROI( i )
		if (flag == 1 ){
			if ( r.ROIIsCircle() )
					disp.ImageDisplayDeleteROI( r )
			}
		if (flag == 0){
		if ( r.ROIIsLine() )
					disp.ImageDisplayDeleteROI( r )
			}
		}
}

//// UI block ////
// declare threads
Class data_collection_thread : thread //controls data collection
{
	number linkedDLG_ID
	data_collection_thread( object self )//constructor
	{
		result( self.ScriptObjectGetID() + " collector created.\n" )
	}
	~data_collection_thread( object self )//destructor
	{
		result( self.ScriptObjectGetID() + " collector destroyed.\n" )
	}
	void SetLinkedDialogID( object self, number ID ) { linkedDLG_ID = ID; }
	void RunThread( object self )
	{
		UniqueSaveName( save_dir, saveName, fileName, sample_name, log_ext, exp_num, fileCheck )
		ContinousTilt( fiddle, alpha_start, alpha_end, end_angle, start_angle, time_1, time_2, cam_sleep, camera_length ) 
		// Pause to write IS data.
		sleep(5.0)
		CreateLogFile( program_name, fileName, saveName, camid, time_1, time_2, end_angle, start_angle,\
		 notes, fiddle, cam_sleep, ISDataPath, frame_rate, lambda, camera_length ) 
	}
}
// declare UI elements
class myDialog : UIframe
{
	object callThread
	myDialog( object self )
	{
		// result( self.ScriptObjectGetID() + " created.\n" )
	}
	~myDialog( object self )
	{
		// result( self.ScriptObjectGetID() + " destroyed.\n")
	}
// UI functions; name is same as corresponding button
	// updates variables by pulling from UI input
	void UpdateValues( object self, number &alpha_start, number &alpha_end, string &notes,\
	 string &save_dir, string &sample_name, string &ISName, string &ISDataPath, number &frame_rate, number &lambda )
	{ 
		return
	}
	void browse_files( object self )//may need to rename function
	{
		string directory
		if ( !GetDirectoryDialog("Select directory", save_dir, directory) ) 
		{
			return
		}
		self.DLGValue("path_field", directory)
	}
	// Buttons for 3DED control.
	void start_pressed( object self )//start 3DED 
	{
		self.Setelementisenabled( "start_pressed", false )
		self.Setelementisenabled( "reset_pressed", false )
		self.Setelementisenabled( "stop_pressed", true )
		//Pull values from UI
		self.DLGGetValue( "alpha_1_field", alpha_start ) 
		self.DLGGetValue( "alpha_2_field", alpha_end ) 
		self.DLGGetValue( "notes_field", notes ) 
		self.DLGGetValue( "path_field", save_dir ) 
		self.DLGGetValue( "sample_name_field", sample_name ) 
		self.DLGGetValue( "IS_name_field", ISName ) 
		self.DLGGetValue( "fps_field", frame_rate ) 
		self.DLGGetValue( "wavelength_field", lambda ) 
		self.DLGGetValue( "notes_field", notes ) 
		self.DLGGetValue( "sample_name_field", ISName ) 
		//run functions
		result(save_dir + "\n")
		string saveName = UniqueSaveName( save_dir, saveName, fileName, sample_name, log_ext, exp_num, fileCheck )
		ISDataPath = save_dir + "\\" + ISName
		//ISDataPath = save_dir + newName
		result(saveName + "\n")
		ContinousTilt( fiddle, alpha_start, alpha_end, end_angle, start_angle, time_1, time_2, cam_sleep, camera_length ) 
		sleep(4.0)//pause to write IS data
		CreateLogFile( program_name, fileName, saveName, camid, time_1, time_2, end_angle, start_angle, notes,\
		 fiddle, cam_sleep, ISDataPath, frame_rate, lambda, camera_length ) 
		//reset GUI
		self.Setelementisenabled( "start_pressed", true )
		self.Setelementisenabled( "reset_pressed", true )
		self.Setelementisenabled( "stop_pressed", false )
	}
	void stop_pressed( object self )//end 3DED
	{
		EMSetBeamBlanked( true )//blank beam
		CM_InSitu_StopRecord( )
		val = EMGetStageAlpha( )
		self.Setelementisenabled( "start_pressed", true )
		self.Setelementisenabled( "stop_pressed", false )
		result( "Capture stopped by user" + "\n" )
	}
	void reset_pressed( object self )//reset stage
	{
		//EMSetBeamBlanked( true )
		EMSetStageAlpha( 0 )
		self.Setelementisenabled( "start_pressed", false )
		self.Setelementisenabled( "stop_pressed", true )
	}
	// Buttons for tilt control.
	void GoToAlpha1( object self )
	{
		number alpha_start
		self.DLGGetValue( "alpha_1_field", alpha_start )
		EMSetStageAlpha( alpha_start )
	}
	void GoToAlpha2( object self )
	{
		number alpha_end
		self.DLGGetValue( "alpha_2_field", alpha_end )
		EMSetStageAlpha( alpha_end )
	}
	// Buttons for resolution rings and tilt axis.
	void DrawRings( object self )
{
	{ 
		self.DLGGetValue( "x_cent", img_center_x )
		self.DLGGetValue( "y_cent", img_center_y )
	}
		image img := GetFrontImage()
		result(img_center_x)
		draw_resolution_rings( img, 1, 0, 0, img_center_x, img_center_y )
	}
	void delete_rings( object self )
	{
		image img := GetFrontImage()
		ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
		remove_ROIs( imgDisplay, 1 )
	}
	void delete_axis( object self )
	{
		image img := GetFrontImage()
		ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
		remove_ROIs( imgDisplay, 0 )
	}
	void DrawAxis( object self )
	{
		{ 
			self.DLGGetValue( "ta_field", axis_value )
		}
			image img := GetFrontImage()
			draw_tilt_axis( axis_value, img_center_x, img_center_y, img )
	}
  TagGroup CreateDLG( object self )
  {
		number label_width = 15
        number entry_width = 10
        number button_width = 50
        TagGroup label
        TagGroup Dialog_UI = DLGCreateDialog("GiveMeED")
        // Create a box for the setup parameters             
        TagGroup setup_box_items
        TagGroup setup_box = DLGCreateBox("Save Data Path", setup_box_items).DLGFill("XY")
        // Work directory field
        TagGroup path_field
        label = DLGCreateLabel("Path:").DLGWidth(label_width)
        path_field = DLGCreateStringField(save_dir).DLGIdentifier("path_field").DLGWidth(entry_width*4)
        TagGroup path_group = DLGGroupItems(label, path_field).DLGTableLayout(2, 1, 0)
        // Sample name field
        TagGroup sample_name_field
        label = DLGCreateLabel("Sample name:").DLGWidth(label_width)
        sample_name_field = DLGCreateStringField(sample_name).DLGIdentifier("sample_name_field").DLGWidth(entry_width*4)
        TagGroup sample_name_group = DLGGroupItems(label, sample_name_field).DLGTableLayout(2, 1, 0)
		//notes field - not in UI yet
		TagGroup notes_field
        label = DLGCreateLabel("Notes:").DLGWidth(label_width)
        notes_field = DLGCreateStringField(notes).DLGIdentifier("notes_field").DLGWidth(entry_width*4)
        TagGroup notes_group = DLGGroupItems(label, notes_field).DLGTableLayout(2, 1, 0)
        
        // Buttons
        TagGroup browse_button = DLGCreatePushButton("Browse files", "browse_files").DLGWidth(button_width)
        TagGroup setup_group = DLGGroupItems(path_group, sample_name_group, browse_button).DLGTableLayout(1, 6, 0)
        setup_box_items.DLGAddElement( setup_group )
        Dialog_UI.DLGAddElement( setup_box )
        
        // Variables group
        TagGroup variables_box_items
        TagGroup variables_box = DLGCreateBox("Variables", variables_box_items).DLGFill("XY")
        TagGroup wavelength_field
        label = DLGCreateLabel("Lambda / nm:").DLGWidth(label_width)
        wavelength_field = DLGCreateStringField("0.00251").DLGIdentifier("wavelength_field").DLGWidth(entry_width*4)
        TagGroup wavelength_group = DLGGroupItems(label, wavelength_field).DLGTableLayout(2, 1, 0)
        TagGroup fps_field
        label = DLGCreateLabel("Frame rate:").DLGWidth(label_width)
        fps_field = DLGCreateStringField("175").DLGIdentifier("fps_field").DLGWidth(entry_width*4)
        TagGroup fps_group = DLGGroupItems(label, fps_field).DLGTableLayout(2, 1, 0)
        TagGroup variables_group = DLGGroupItems( wavelength_group, fps_group, notes_group ).DLGTableLayout(1, 3, 0)//IS_name_group,
        variables_box_items.DLGAddElement( variables_group )
        Dialog_UI.DLGAddElement( variables_box )
        
        // Angles: alpha is tilt-x on a JEOL microscope
        TagGroup alpha_box_items
        TagGroup alpha_box = DLGCreateBox("Tilt Range", alpha_box_items).DLGFill("XY")
        TagGroup alpha_1_field//start angle for tilt
        label = DLGCreateLabel("Start Angle (deg):").DLGWidth(label_width*1.2)
        alpha_1_field = DLGCreateStringField("-60").DLGIdentifier("alpha_1_field").DLGWidth(entry_width)
        TagGroup alpha_1_group = DLGGroupItems(label, alpha_1_field).DLGTableLayout(2, 1, 0)
        TagGroup alpha_2_field//end angle for tilt
        label = DLGCreateLabel("End Angle (deg):").DLGWidth(label_width*1.2)
        alpha_2_field = DLGCreateStringField("60").DLGIdentifier("alpha_2_field").DLGWidth(entry_width)
        TagGroup alpha_2_group = DLGGroupItems(label, alpha_2_field).DLGTableLayout(2, 1, 0)
        
        //Alpha buttons
        TagGroup GoToAlpha1 = DLGCreatePushButton( "Go to Start", "GoToAlpha1" ).DLGWidth(button_width)
        TagGroup GoToAlpha2 = DLGCreatePushButton( "Go to End", "GoToAlpha2" ).DLGWidth(button_width)
        TagGroup reset_button = DLGCreatePushButton("Tilt Neutral", "reset_pressed").DLGIdentifier("reset_button").DLGWidth(button_width)
        TagGroup alpha_buttons = DLGGroupItems( GoToAlpha1,  reset_button, GoToAlpha2 ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "East" )
        TagGroup alpha_group = DLGGroupItems( alpha_1_group, alpha_2_group, alpha_buttons ).DLGTableLayout( 1, 4, 0 )
        alpha_box_items.DLGAddElement( alpha_group )
        Dialog_UI.DLGAddElement( alpha_box )
        
        // Resolution rings and tilt axis box.
        TagGroup rr_box_items
        TagGroup rr_box = DLGCreateBox( "Overlay", rr_box_items ).DLGFill( "XY" )
        
        TagGroup ta_field
        label = DLGCreateLabel( "Tilt axis (deg):" ).DLGWidth( label_width*1.0 )
        ta_field = DLGCreateStringField( "25.1" ).DLGIdentifier( "ta_field" ).DLGWidth( entry_width )
        TagGroup ta_group = DLGGroupItems( label, ta_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup x_cent, y_cent
        string center
        label = DLGCreateLabel( "Image Center X/Y (px):" ).DLGWidth( label_width*1.6 )
        center = BaseN(img_center_x, 10, 4)
        x_cent = DLGCreateStringField( center ).DLGIdentifier( "x_cent" ).DLGWidth( entry_width )
        center = BaseN(img_center_y, 10, 4)
        y_cent = DLGCreateStringField( center ).DLGIdentifier( "y_cent" ).DLGWidth( entry_width )
        TagGroup pattern_box = DLGGroupItems( label, x_cent, y_cent ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        

        TagGroup rrbutton = DLGCreatePushButton( "Draw Rings", "DrawRings" ).DLGWidth(button_width)
        TagGroup rr_del = DLGCreatePushButton( "Remove Rings", "delete_rings" ).DLGWidth(button_width)
        TagGroup tabutton = DLGCreatePushButton( "Draw Axis", "DrawAxis" ).DLGWidth(button_width)
        TagGroup ta_del = DLGCreatePushButton( "Remove Axis", "delete_axis" ).DLGWidth(button_width)
        TagGroup rr_buttons = DLGGroupItems( rrbutton, tabutton, rr_del, ta_del ).DLGTableLayout( 2, 2, 0 ).DLGAnchor( "Middle" )
        
        TagGroup rr_group = DLGGroupItems( ta_group, pattern_box, rr_buttons ).DLGTableLayout( 1, 4, 0 )
        rr_box_items.DLGAddElement( rr_group )
        Dialog_UI.DLGAddElement( rr_box )
        
        // Experiment control box
        TagGroup control_box_items
        TagGroup control_box = DLGCreateBox("Data Collection", control_box_items).DLGFill("XY")
        TagGroup start_button = DLGCreatePushButton("Start 3DED", "start_pressed").DLGIdentifier("start_button").DLGWidth(button_width)
        TagGroup stop_button = DLGCreatePushButton("Abort 3DED", "stop_pressed").DLGIdentifier("stop_button").DLGWidth(button_width)
        
        // Create the button box and contents
        taggroup control_group = DLGGroupItems(start_button, stop_button).DLGTableLayout(3, 1, 0).DLGAnchor("Center").DLGExpand("X")
        control_box_items.DLGAddElement(control_group)
        Dialog_UI.DLGAddElement(control_box)
        TagGroup footer = DLGCreateLabel(" ")
        Dialog_UI.DLGAddElement(footer)
        
        return Dialog_UI
        
  }
  object Init(object self, number callThreadID )
  {
    // Assign thread-object via weak-reference
    callThread = GetScriptObjectFromID( callThreadID )      
    if ( !callThread.ScriptObjectIsvalid() )
      Throw( "Invalid thread object passed in! Object of given ID not found." )
    // Pass weak-reference to thread object
    callThread.SetLinkedDialogID( self.ScriptObjectGetID() )  
    return self.super.init( self.CreateDLG() )
  }

}
// Launch threads.
void Invoke( string program_name )
{
	result("starting")
	object threadObject = alloc( data_collection_thread )
	object dlgObject = alloc( myDialog ).Init( threadObject.ScriptObjectGetID() )
	// UI title.
	dlgObject.display( program_name )
}
// Script starts here.
Invoke( program_name )
// End.