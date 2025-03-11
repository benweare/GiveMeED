/*
GiveMeED v1.0

B L Weare, @NMRC
Updated: 27-09-24

See attached publication: Weare et al, DOI:

This script is used to collect 3DED data with transmission electron microscopes equipped
with Gatan cameras that have In-Situ mode. It has been tested with a JEOL2100Plus with OneView
and JEOL2100F with K3. 

Notes:
- Run script from the View window in DigitalMicrograph.
- Tilt is the alpha axis, which corresponds to tilt-x for a JEOL microscope. Tilt-y is 
  not affected by this script.
- The Live View may lag during data collection, but this does not affect the data collection.
- Microscope must be in Diffraction mode prior to starting data collection or 
  script will break when trying to write metadata file. 
- Kill script in DigitalMicrograph: "ctrl + numlock". Back: hold "shift" during tilt.
- Set up capture parameters from IS side panel. 
*/

//Initialise variables
number alpha_start = -20 //start stage tilt
number alpha_end = 20 //end stage tilt
string save_dir = "X:\\BLW\\GMED Testing\\" //directory to save log file
string ISName = "IS02"
string sample_name = ISName
string log_ext = ".txt" //file extension for log file
string ISDataPath = save_dir + ISName

string notes = "No notes" //enter notes here and they are included in the log file

string filename, saveName
number frame_rate = 175 // can't grab from In Situ capture for some reason
number exp_num = 0 // initial log file suffix
number fiddle = 1.0 // amount angles can be off by
number cam_sleep = 0.001 // camera sleep in syncing while loop 
number fileCheck = 1 
number start_angle, end_angle 
number camid = CameraGetActiveCameraID()
number camera_length = EMGetCameraLength( )

// Event timing variables
number time_1, time_2

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

// writes tags to data file
void Tag3DEDData( string progname, number start_angle, number end_angle, number total_time, number fps, string rotation_axis, string notes, string DataPath, string ISName )
{
	number rotation_range = end_angle - start_angle
	number exposure = 1 / fps
	string ImageName = DataPath + "\\"+ ISName + ".dm4"
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
		
		CloseImage( target )
	}
	catch{
		result( "Something went wrong. Tags not written to image." + "\n" )
		result(ImageName + "\n" )
	}
}

// metadata block
void CreateLogFile( string fileName, string saveName, number camid, number time_1, number time_2, number end_angle, number start_angle, string notes, number fiddle, number cam_sleep, string ISDataPath, number frame_rate, number camera_length )
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
	number rot_per_frame = abs( end_angle - start_angle ) / no_frames
	number acquisition_time = total_time / no_frames
	number total_angle = abs( end_angle - start_angle )
	string timestamp = FormatTimeString( GetCurrentTime(), 33 )
	// get camera and tem name
	string camera_name = CameraGetName( camid )
	string tem_name = "2100Plus"
	number high_tension = EMGetHighTension( ) / 1000 //accelerating voltage in kV
	
	number lambda // in nm
	lambda = 0.00251 // 200 kV
	//lambda = 0.00267 // 180 kV
	//lambda = 0.00285 // 160 kV
	//lambda = 0.00307 // 140 kV
	//lambda = 0.00307 // 120 kV
	//lambda = 0.00370 // 100 kV
	//lambda = 0.00418 // 80 kV
	//lambda = 0.00487 // 60 kV
	//lambda = 0.00602 // 40 kV
	//lambda = 0.00859 // 20 kV 
	
	number calib_rot_ax = 334.9
	
	image img := GetFrontImage() //no need to close as it is saying it is live view, not making a copy
	
	number phys_pixelsize_x, phys_pixelsize_y, scale_x, scale_y
	CameraGetPixelSize(camid, phys_pixelsize_x, phys_pixelsize_y)
	GetScale( img, scale_x, scale_y )
	
	// create log message
	string log_message = "Program: " + programe_name + "\n"
	log_message += "Save Location: " + ISDataPath + "\n"
	log_message += "IS Data: " + saveName + "\n"
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

	Tag3DEDData( programe_name, start_angle, end_angle, total_time, frame_rate, rotation_axis, notes, ISDataPath, ISName )
}

// data collection block
void ContinousTilt( number fiddle, number alpha_start, number alpha_end, number &end_angle, number &start_angle, number &time_1, number &time_2, number cam_sleep )
{
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

// launches threads
void Invoke( )
{
	alloc( data_collection_thread ).StartThread( )
}

// declare threads
Class data_collection_thread : thread //controls data collection
{
	data_collection_thread( object self )//constructor
	{
		result( self.ScriptObjectGetID() + " collector created.\n" )
	}
	~data_collection_thread( object self )//destructor
	{
		result( self.ScriptObjectGetID() + " collector destroyed.\n" )
	}
	void RunThread( object self )
	{
		UniqueSaveName( save_dir, saveName, fileName, sample_name, log_ext, exp_num, fileCheck )
		ContinousTilt( fiddle, alpha_start, alpha_end, end_angle, start_angle, time_1, time_2, cam_sleep ) 
		sleep(2.0)//pause to write IS data
		CreateLogFile( fileName, saveName, camid, time_1, time_2, end_angle, start_angle, notes, fiddle, cam_sleep, ISDataPath, frame_rate, camera_length ) 
	}
}

// Script starts here
Invoke( )
//end
