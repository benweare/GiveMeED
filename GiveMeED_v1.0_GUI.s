/*
GiveMeED v1.0 GUI

B L Weare, @NMRC
Updated: 27-09-24
 
/* Notes
- Kill script: ctrl + numlock
- Set up capture parameters from IS side panel. 
- Live view will lag, but does not affect data collected. 
- Only works for alpha tilt axis.
- Have to run from VIEW window.
- Compare tilt start angle to IS tags
Changes:
- Does not count frames in folder
- Has 3 tilt angle measuring variables to track down source of error
- Moved frame rate variale to top
- Log file has same name as IS file name. Should append a suffix to stop overwriting. 
- Recording correct start angle
Bugs: 
- If TEM not in Diffraction mode then script will break during log file writing. 
- Reads incorrect exposure for In Situ mode (capture not record). 
- Weird bug where sometimes the IS capture won't end and the script hangs. 
- Not recording at correct frame rate sometimes; DM may freeze during collection
FIX WAVELENGTH
*/

//Initialise variables
number alpha_start = -60 //start stage tilt
number alpha_end = 60 //end stage tilt
string save_dir = "X:\\BLW\\GMED Testing" //directory to save log file, no trailing slash
string ISName = "PCC_120824_01"
string sample_name = ISName
string log_ext = ".txt" //file extension for log file
string ISDataPath = save_dir + ISName

string notes = "e.g. cryo 120.0(5) K" //enter notes here and they are included in the log file

string filename, saveName
number frame_rate = 175 // can't grab from In Situ capture for some reason
number exp_num = 0 // initial log file suffix
number fiddle = 1.0 // amount angles can be off by
number cam_sleep = 0.001 // camera sleep in syncing while loop 
number fileCheck = 1 
number start_angle, end_angle 
number camid = CameraGetActiveCameraID()
number camera_length
number lambda // in nm
	//lambda = 0.00251 // 200 kV
	//lambda = 0.00267 // 180 kV
	//lambda = 0.00285 // 160 kV
	//lambda = 0.00307 // 140 kV
	//lambda = 0.00307 // 120 kV
	//lambda = 0.00370 // 100 kV
	//lambda = 0.00418 // 80 kV
	//lambda = 0.00487 // 60 kV
	//lambda = 0.00602 // 40 kV
	//lambda = 0.00859 // 20 kV 

// Event timing variables
number time_1, time_2

number false = 0; number true =1

// Declare functions
string UniqueSaveName( string save_dir, string &saveName, string fileName, string sample_name, string log_ext, number &exp_num, number fileCheck )
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

//This block taken from DMscript examples; counts files in folder
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

// Function converts a string to lower-case characters
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

// Function removes entries not matching in suffix
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
			if ( len( str ) >= len( suffix ) )                 // Ensure that the suffix isn't longer than the whole string
			{
				if ( suffix == right( str , len( suffix ) ) ) // Compare suffix to end of original string
				{
					outList.TagGroupInsertTagAsString( outList.TagGroupCountTags() , origstr )        // Copy if matching
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

// metadata block
void CreateLogFile( string fileName, string saveName, number camid, number time_1, number time_2, number end_angle, number start_angle, string notes, number fiddle, number cam_sleep, string ISDataPath, number frame_rate, number lambda, number camera_length )
{
	string programe_name = "GiveMeED_v1.0"
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
	number end_angle = EMGetStageAlpha( )
	number spot_size = EMGetSpotSize( )
	number rot_per_frame = abs( end_angle - start_angle ) / no_frames//insteaDMatic expilcity counts frames with a while loop
	number acquisition_time = total_time / no_frames
	number total_angle = abs( end_angle - start_angle )
	string timestamp = FormatTimeString( GetCurrentTime(), 33 )
	// get camera and tem name
	string camera_name = CameraGetName( camid )
	string tem_name = "2100Plus"
	number high_tension = EMGetHighTension( ) / 1000 //accelerating voltage in kV
	
	number calib_rot_ax = 334.9
	
	image img := GetFrontImage() //no need to close as it is saying it is live view, not making a copy
	
	number phys_pixelsize_x, phys_pixelsize_y, scale_x, scale_y
	CameraGetPixelSize(camid, phys_pixelsize_x, phys_pixelsize_y)
	GetScale( img, scale_x, scale_y )
	
	// create log message
	string log_message = "Program: " + programe_name + "\n"
	//log_message += "Save Location: " + ISDataPath + "\n"
	log_message += "Save Location: " + saveName + "\n"
	log_message += "---Microscope Info---" + "\n"
	log_message += "Microscope: " + tem_name + "\n" 
	log_message += "Accelerating Voltage (kV): " + high_tension + "\n"
	log_message += "Wavelength (nm): " + lambda + "\n"
	log_message += "Spot Size: " + spot_size + "\n" //DM spot size is 1 smaller than JEOL spot size
	log_message += "Camera: " + camera_name + "\n" 
	log_message += "Camera length (mm): " + camera_length + "\n"
	log_message += "Camera pixel size x/y (um): (" + phys_pixelsize_x + ", " + phys_pixelsize_y + ")\n" 
	log_message += "---Image Data---" + "\n"
	log_message += "Scale (nm-1 px-1): " + scale_x + ", " + scale_y + "\n" 
	log_message += "Image size x/y (px): (" + ImageGetDimensionSize(img, 0) + ", " + ImageGetDimensionSize(img, 1) + ")\n" 
	log_message += "---Aquisition Info---" + "\n"
	log_message += "Data Collection Time: " + timestamp + "\n"
	log_message += "Start angle (deg): " + start_angle + "\n"
	log_message += "End angle (deg): " + end_angle +  "\n"
	log_message += "Rotation range (deg): " + (end_angle - start_angle) + "\n"
	log_message += "Angle tolerance: +/-" + fiddle + "\n"
	log_message += "Total time (s): " + total_time + "\n"
	log_message += "Frame Rate (fps): " + frame_rate + "\n"
	log_message += "Exposure (s): " + 1/frame_rate + "\n"
	log_message += "Number of frames : " + no_frames + "\n"
	log_message += "Angle per frame (deg): " + no_frames / (end_angle - start_angle) + "\n"
	log_message += "Rotation axis (deg): " + "-25.1" + "\n"
	log_message += "---Notes---" + "\n"
	log_message += "Notes: " + notes + "\n"
	log_message += "---CIF---" + "\n"
	log_message += "data_3DED" + "\n"
	timestamp = FormatTimeString( GetCurrentTime(), 1 )
	log_message += "_audit_creation_date " + timestamp + "\n"
	log_message += "_audit_creation_method " + "'Digital Micrograph'" + "\n"
	log_message += "_computing_data_collection " + "'Digital Micrograph'" + "\n"
	log_message += "_diffrn_source " + "'transmission electron microscope'" + "\n"
	log_message += "_diffrn_radiation_probe " + "electron" + "\n"
	log_message += "_diffrn_radiation_type " + "'transmission electron microscope'" + "\n"
	log_message += "_diffrn_radiation_wavelength " + lambda + "\n"
	log_message += "_diffrn_radiation_monochromator " + "'transmission electron microscope'" + "\n"
	log_message += "_diffrn_radiation_device " + "'transmission electron microscope'" + "\n"
	log_message += "_diffrn_radiation_device_type " + "'JEOL 2100Plus'" + "\n"
	log_message += "_diffrn_detector " + "'CCD'" + "\n"
	log_message += "_diffrn_detector_type '" + camera_name + "'" + "\n"
	
	// print log message to console
	result( "\n ===== \n" )
	result( log_message )
	// write log message to file
	number fileNum = CreateFileForWriting( saveName )
	WriteFile( fileNum, log_message )
	CloseFile( fileNum )
	result( "Wrote file: " + fileName )
	result( "Saved data to: " + saveName + "\n" )
}

// data collection block
void ContinousTilt( number fiddle, number alpha_start, number alpha_end, number &end_angle, number &start_angle, number &time_1, number &time_2, number cam_sleep, number &camera_length )
{
	camera_length = EMGetCameraLength()
	EMSetStageAlpha( alpha_start )//tilt to angle alpha_start

	while ( abs( EMGetStageAlpha( )- alpha_start ) >= fiddle )
	{
		if ( ShiftDown( ) ) exit( 0 )
	}

	sleep(0.25)//sleeps to settle stage tilt
	
	EMSetBeamBlanked(0)//unblank beam

	EMSetStageAlpha( alpha_end )//tilt to alpha_end; issue with syncing tilt start and IS start
	
	number current_alpha, angle_delta
	while ( angle_delta < fiddle )//waits until tilt starts, can use a lookback buffer
	{
		sleep( cam_sleep ) //sleep to prevent DM crash
		current_alpha = EMGetStageAlpha( )
		angle_delta = abs( current_alpha - start_angle )
	}
	CM_InSitu_StartRecord( ) //Start IS capture
	start_angle = EMGetStageAlpha() // tilt start angle
	result( "IS Acquire" + "\n" )
	
	time_1 = GetHighResTickCount( )//measures delay in start of tilt

	if ( alpha_start > 0 )
		while ( abs( EMGetStageAlpha( )- alpha_start ) <= abs( ( alpha_start - alpha_end  ) - fiddle ) )//these loops will prevent other commands firing until they done
		{
			if ( ShiftDown( ) ) exit( 0 ) //exit loop if shift is held, as backup to kill script
		}
	else
		while ( abs( EMGetStageAlpha( ) - alpha_start ) <= abs( ( alpha_start - alpha_end  ) + fiddle ) )
		{
			if ( ShiftDown( ) ) exit( 0 )
		}

	//End IS capture - maybe add a loop that checks if stage movement has stopped 
	time_2 = GetHighResTickCount( )//IS takes a couple seconds to stop
	CM_InSitu_StopRecord( )
	result( "IS Cease" + "\n" )

	EMSetBeamBlanked( 1 )//blank beam

	return
}

// UI block
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
	
	void SetLinkedDialogID( object self, number ID ) { linkedDLG_ID = ID; }//sets ID of linked UI
	
	void RunThread( object self )
	{
		UniqueSaveName( save_dir, saveName, fileName, sample_name, log_ext, exp_num, fileCheck )
//		ContinousTilt( fiddle, alpha_start, alpha_end, end_angle, start_angle, time_1, time_2, cam_sleep, camera_length ) 
		sleep(2.0)//pause to write IS data
		CreateLogFile( fileName, saveName, camid, time_1, time_2, end_angle, start_angle, notes, fiddle, cam_sleep, ISDataPath, frame_rate, lambda, camera_length ) 
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
	//updates variables by pulling from UI input
	void UpdateValues( object self, number &alpha_start, number &alpha_end, string &notes, string &save_dir, string &sample_name, string &ISName, string &ISDataPath, number &frame_rate, number &lambda )
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
		//ISDataPath = save_dir + "\\" + ISName
		//ISDataPath = save_dir + newName
		result(saveName + "\n")
		ContinousTilt( fiddle, alpha_start, alpha_end, end_angle, start_angle, time_1, time_2, cam_sleep, camera_length ) 
		sleep(4.0)//pause to write IS data
		CreateLogFile( fileName, saveName, camid, time_1, time_2, end_angle, start_angle, notes, fiddle, cam_sleep, ISDataPath, frame_rate, lambda, camera_length ) 
		//reset GUI
		self.Setelementisenabled( "start_pressed", true )
		self.Setelementisenabled( "reset_pressed", true )
		self.Setelementisenabled( "stop_pressed", false )
	}

	void stop_pressed( object self )//end 3DED
	{
		EMSetBeamBlanked( true )//blank beam
		CM_InSitu_StopRecord( )
		val = EMGetStageAlpha( ) //should cause tilt to stop
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

	void GoToAlpha1( object self )//go to start tilt. JEOL TEM Controller can accept decimal places and gets as near as possible to the supplied value (approx 0.1 degs)
	{
		number alpha_start
		self.DLGGetValue( "alpha_1_field", alpha_start )
		EMSetStageAlpha( alpha_start )
	}

	void GoToAlpha2( object self )//go to end tilt
	{
		number alpha_end
		self.DLGGetValue( "alpha_2_field", alpha_end )
		EMSetStageAlpha( alpha_end )
	}

  TagGroup CreateDLG( object self )//copied from Insteadmatic
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
        //TagGroup open_button = DLGCreatePushButton("Open work directory", "open_directory_pressed").DLGWidth(button_width)
        TagGroup browse_button = DLGCreatePushButton("Browse files", "browse_files").DLGWidth(button_width)
        //TagGroup setup_buttons = DLGGroupItems( browse_button ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "East" )
        //TagGroup setup_buttons = DLGGroupItems( browse_button ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "East" )

        TagGroup setup_group = DLGGroupItems(path_group, sample_name_group, browse_button).DLGTableLayout(1, 6, 0)//IS_name_group,
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
        label = DLGCreateLabel("Start Angle (deg):").DLGWidth(label_width)
        alpha_1_field = DLGCreateStringField("-60").DLGIdentifier("alpha_1_field").DLGWidth(entry_width*4)
        TagGroup alpha_1_group = DLGGroupItems(label, alpha_1_field).DLGTableLayout(2, 1, 0)
        
        TagGroup alpha_2_field//end angle for tilt
        label = DLGCreateLabel("End Angle (deg):").DLGWidth(label_width)
        alpha_2_field = DLGCreateStringField("60").DLGIdentifier("alpha_2_field").DLGWidth(entry_width*4)
        TagGroup alpha_2_group = DLGGroupItems(label, alpha_2_field).DLGTableLayout(2, 1, 0)
        
        //Alpha buttons - add a function for go to start angle of alpha 
        TagGroup GoToAlpha1 = DLGCreatePushButton( "Go to Start", "GoToAlpha1" ).DLGWidth(button_width)
        TagGroup GoToAlpha2 = DLGCreatePushButton( "Go to End", "GoToAlpha2" ).DLGWidth(button_width)
        TagGroup reset_button = DLGCreatePushButton("Tilt Neutral", "reset_pressed").DLGIdentifier("reset_button").DLGWidth(button_width)
        TagGroup alpha_buttons = DLGGroupItems( GoToAlpha1,  reset_button, GoToAlpha2 ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "East" )
        
        TagGroup alpha_group = DLGGroupItems( alpha_1_group, alpha_2_group, alpha_buttons ).DLGTableLayout( 1, 4, 0 )
        alpha_box_items.DLGAddElement( alpha_group )
        Dialog_UI.DLGAddElement( alpha_box )

        // Experiment control box
        TagGroup control_box_items
        TagGroup control_box = DLGCreateBox("Data Collection", control_box_items).DLGFill("XY")
        TagGroup start_button = DLGCreatePushButton("Start 3DED", "start_pressed").DLGIdentifier("start_button").DLGWidth(button_width)
        TagGroup stop_button = DLGCreatePushButton("Abort 3DED", "stop_pressed").DLGIdentifier("stop_button").DLGWidth(button_width)
        
        
        // Create the button box and contents
        taggroup control_group = DLGGroupItems(start_button, stop_button).DLGTableLayout(3, 1, 0).DLGAnchor("Center").DLGExpand("X")
        control_box_items.DLGAddElement(control_group)
        Dialog_UI.DLGAddElement(control_box)
        
        
        TagGroup footer = DLGCreateLabel("DM may freeze during collection")
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

// launches threads
void Invoke( )
{
	result("starting")
	object threadObject = alloc( data_collection_thread )
	object dlgObject = alloc( myDialog ).Init( threadObject.ScriptObjectGetID() )
	dlgObject.display( "GiveMeED" ) //title of UI
}

// Script starts here
Invoke()
//end