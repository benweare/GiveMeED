/*
GiveMeED

B L Weare, @NMRC
Updated: 16-06-25

Please see associated publication for instructions, DOI: 

*/
//Initialise variables
number alpha_start = -60 //start stage tilt
number alpha_end = 60 //end stage tilt
string save_dir = "X:\\" //directory to save log file, no trailing slash
string ISName = "sample_name"
string sample_name = ISName
string log_ext = ".txt" //file extension for log file
string ISDataPath = save_dir + ISName
string notes = "[e.g. cryo 120 K]" //enter notes here and they are included in the log file
string filename, saveName
number frame_rate = 175 // can't grab from In Situ capture for some reason
number exp_num = 0 // initial log file suffix
number fiddle = 1.0 // tolerance in angle
number cam_sleep = 0.001 // sync while loop
number fileCheck = 1 
number start_angle, end_angle 
number camid = CameraGetActiveCameraID()
number camera_length
number lambda // in A
	lambda = 0.0251 // 200 kV
	//lambda = 0.0267 // 180 kV
	//lambda = 0.0285 // 160 kV
	//lambda = 0.0307 // 140 kV
	//lambda = 0.0307 // 120 kV
	//lambda = 0.0370 // 100 kV
	//lambda = 0.0418 // 80 kV
	//lambda = 0.0487 // 60 kV
	//lambda = 0.0602 // 40 kV
	//lambda = 0.0859 // 20 kV 
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
void Tag3DEDData( string progname, number start_angle, number end_angle, number total_time, number fps, string rotation_axis, string notes, string DataPath, string ISName )
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
// Formats date for CIF
string CIF_date_format()
{
	string formatted, day, month, year, date
	year = right(date, 4)
	month = mid(date, 3, 2)
	day = left(date, 2)
	formatted = year + "-" + month + "-" + day
	return formatted	
}
// Writes metadata string as CIF
string format_metadata( string ISDataPath, string saveName, string notes,image img,number scale_x,number scale_y,number phys_pixelsize_x,number phys_pixelsize_y,string timestamp,string program_name,number lambda,string tem_name,string camera_name,number high_tension,number spot_size,number camera_length,number start_angle, number end_angle,number total_time,number frame_rate,number no_frames,string rotation_axis )
{
	string date
	date = CIF_date_format()
	string CIF_3DED = "data_GMED"+"\n"+\
	"_audit_creation_date " + "?" + "\n+"+\
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
	"Angle per frame (deg): " + no_frames / (end_angle - start_angle) + "\n"+\
	"Rotation axis (deg): " + rotation_axis + "\n"+\
	"Notes:" + notes + "\n"+\
	";"
	return( CIF_3DED )
}
// Metadata block
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
	number rot_per_frame = abs( end_angle - start_angle ) / no_frames
	number acquisition_time = total_time / no_frames
	number total_angle = abs( end_angle - start_angle )
	string timestamp = FormatTimeString( GetCurrentTime(), 33 )
	// get camera and tem name
	string camera_name = CameraGetName( camid )
	string tem_name = "2100Plus"
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
	
	result( "\n ===== \n" )
	result( log_message )
	// write log to file
	number fileNum = CreateFileForWriting( saveName )
	WriteFile( fileNum, log_message )
	CloseFile( fileNum )
	result( "Wrote file: " + fileName )
	result( "Saved data to: " + saveName + "\n" )
	
	Tag3DEDData( programe_name, start_angle, end_angle, total_time, frame_rate, rotation_axis, notes, ISDataPath, ISName )
}
// data collection block
void ContinousTilt( number fiddle, number alpha_start, number alpha_end, number &end_angle, number &start_angle, number &time_1, number &time_2, number cam_sleep, number &camera_length )
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
	time_2 = GetHighResTickCount( )
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
		sleep(5.0)//pause to write IS data
		CreateLogFile( fileName, saveName, camid, time_1, time_2, end_angle, start_angle, notes, fiddle, cam_sleep, ISDataPath, frame_rate, camera_length ) 
	}
}

// Script starts here
Invoke( )
//end
