// writePETS2import
// BLW @ nmRC, 27-09-24
//
// This script creates a UI in DigitalMicrograph that is used to create a PETS2 project file. It is designed to work with
// In-Situ datasets exported from Digital Micrograph in .tif format.
//
//Variables
number alpha = -60, alphastep = 0.05, nframes = 100, scaleinfo = 0.00584221
number wavelength = 0.0251, tiltaxis = 245

string location = "X:\\BLW"
string name = "ISData_01"
string extension = ".tif"
string save_dir

void write_to_file( number alphastep, number wavelength, number nframes, number scaleinfo, number tiltaxis, string location, string name, string extension )
{
	number beta = 0, refdia = 5, imgnumber = 0, alpharound, binning = 1
	number centX = 500, centY = 500, dstarmin = 0.2, dstarmax = 1.2, dstarmaxps = 1.2
	string output, leadingzeros, imagename
	output = "lambda " + wavelength + "\n"
	output += "Aperpixel " + scaleinfo + "\n"
	output += "phi " + alphastep/2 + "\n"
	output += "omega " + tiltaxis + "\n"
	output += "geometry continuous" + "\n"
	output += "noiseparameters 1 40 \n"
	output += "reflectionsize " + refdia + "\n"
	output += "bin " + binning + "\n"
	output += "dstarmin " + dstarmin + "\n"
	output += "dstarmax " + dstarmax + "\n"
	output += "dstarmaxps " + dstarmaxps + "\n"
	output += "center " + centX + " " + centY + "\n"
	output += "imagelist" + "\n"
	
	while ( imgnumber < nframes )
	{
		if ( imgnumber < 10 )
		{
			leadingzeros = "00000"
		}
		if ( imgnumber > 9 && imgnumber < 100 )
		{
			leadingzeros = "0000"
		}
		if ( imgnumber > 99 && imgnumber < 1000 )
		{
			leadingzeros = "000"
		}
		if ( imgnumber > 999 && imgnumber < 10000 )
		{
			leadingzeros = "00"
		}
		if ( imgnumber > 9999 )
		{
			result("leading zeros incorrect")
			break
		}
		
		imagename = location + "\\" + name + "_" + leadingzeros + imgnumber + extension
		if ( imgnumber == 0 )
		{
			alpha = alpha
		}
		else 
		{
			alpha = alpha + alphastep
		}
		output += "\"" + imagename + "\" " + alpha + " " + beta + "\n"
		imgnumber = imgnumber + 1
	}
	
	output += "endimagelist" + "\n"
	result(output)	
	
	try
	{
		string saveName = location + "\\" + name + ".pts2"
		number fileNum = CreateFileForWriting( saveName )
		WriteFile( fileNum, output )
		CloseFile( fileNum )
		result( "Saved data to: " + saveName + "\n" )
	}
	catch
	{
		result("something went wrong saving file")
	}
}

class Go2AlphaThread:Thread
{
  number linkedDLG_ID

  Go2AlphaThread( object self )  
  {
   // result( self.ScriptObjectGetID() + " created.\n" )
  }

  ~Go2AlphaThread( object self )
  {
   // result( self.ScriptObjectGetID() + " destroyed.\n" )
  }

  void SetLinkedDialogID( object self, number ID ) { linkedDLG_ID = ID; }

}

//Declare UI elements
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

//Button functions
void GoToAlpha1( object self )//save data button
{
	try
	{
		//update variables from GUI
		self.DLGGetValue( "samplename_field", name )
		self.DLGGetValue( "start_alpha_field", alpha )
		self.DLGGetValue( "alpha_step_field", alphastep )
		self.DLGGetValue( "nframes_field", nframes )
		self.DLGGetValue( "wavelength_field", wavelength )
		self.DLGGetValue( "scale_field", scaleinfo )
		self.DLGGetValue( "tiltaxis_field", tiltaxis )
		self.DLGGetValue( "path_field", location )
	}
	catch
	{
		result("something went wrong updating values")
	}
	write_to_file( alphastep, wavelength, nframes, scaleinfo, tiltaxis, location, name, extension )
}

void GoToAlpha2( object self )//browse folders button
{
		string directory
		if ( !GetDirectoryDialog("Select directory", save_dir, directory) ) 
		{
			return
		}
		self.DLGValue("path_field", directory)
}

  TagGroup CreateDLG( object self )//copied from GiveMeED
  {
		number label_width = 20
        number entry_width = 20
        number button_width = 50

        TagGroup label
        TagGroup Dialog_UI = DLGCreateDialog( "Write PETS2 File" )
        
        //Input data fields
        TagGroup input_box_items
        TagGroup input_box = DLGCreateBox( "Experiment Variables", input_box_items ).DLGFill( "XY" )
        
        TagGroup samplename_field
        label = DLGCreateLabel( "Name:" ).DLGWidth( label_width )
        samplename_field = DLGCreateStringField( "ISData_01" ).DLGIdentifier( "samplename_field" ).DLGWidth( entry_width )
        TagGroup samplename_group = DLGGroupItems( label, samplename_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )

        TagGroup start_alpha_field
        label = DLGCreateLabel( "Start / o:" ).DLGWidth( label_width )
        start_alpha_field = DLGCreateStringField( "-60" ).DLGIdentifier( "start_alpha_field" ).DLGWidth( entry_width )
        TagGroup start_alpha_group = DLGGroupItems( label, start_alpha_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )

        TagGroup alpha_step_field
        label = DLGCreateLabel( "Step / o:" ).DLGWidth( label_width )
        alpha_step_field = DLGCreateStringField( "0.05" ).DLGIdentifier( "alpha_step_field" ).DLGWidth( entry_width )
        TagGroup alpha_step_group = DLGGroupItems( label, alpha_step_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )

        TagGroup nframes_field
        label = DLGCreateLabel( "Number of frames:" ).DLGWidth( label_width )
        nframes_field = DLGCreateStringField( "100" ).DLGIdentifier( "nframes_field" ).DLGWidth( entry_width )
        TagGroup nframes_group = DLGGroupItems( label, nframes_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        

        TagGroup input_group = DLGGroupItems( samplename_group, start_alpha_group, alpha_step_group, nframes_group ).DLGTableLayout( 1, 4, 0 )
        input_box_items.DLGAddElement( input_group )
        Dialog_UI.DLGAddElement( input_box )
        
        //Standard data fields
        TagGroup standard_box_items
        TagGroup standard_box = DLGCreateBox( "Standard Variables", standard_box_items ).DLGFill( "XY" )
        
        TagGroup wavelength_field
        label = DLGCreateLabel( "Wavelength / A:" ).DLGWidth( label_width )
        wavelength_field = DLGCreateStringField( "0.0251" ).DLGIdentifier( "wavelength_field" ).DLGWidth( entry_width )
        TagGroup wavelength_group = DLGGroupItems( label, wavelength_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup scale_field
        label = DLGCreateLabel( "Scale / A px-1:" ).DLGWidth( label_width )
        scale_field = DLGCreateStringField( "0.00292" ).DLGIdentifier( "scale_field" ).DLGWidth( entry_width )
        TagGroup scale_group = DLGGroupItems( label, scale_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup tiltaxis_field
        label = DLGCreateLabel( "Tilt axis / o:" ).DLGWidth( label_width )
        tiltaxis_field = DLGCreateStringField( "245" ).DLGIdentifier( "tiltaxis_field" ).DLGWidth( entry_width )
        TagGroup tiltaxis_group = DLGGroupItems( label, tiltaxis_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup standard_group = DLGGroupItems( wavelength_group, scale_group, tiltaxis_group ).DLGTableLayout( 1, 4, 0 )
        standard_box_items.DLGAddElement( standard_group )
        Dialog_UI.DLGAddElement( standard_box )
        
        //Path fields
        TagGroup alpha_box_items
        TagGroup alpha_box = DLGCreateBox( "Save Data", alpha_box_items ).DLGFill( "XY" )
        
        TagGroup alpha_2_field//directory
        label = DLGCreateLabel( "Path:" ).DLGWidth( label_width )
        alpha_2_field = DLGCreateStringField( "X:\BLW" ).DLGIdentifier( "path_field" ).DLGWidth( entry_width )
        TagGroup alpha_2_group = DLGGroupItems( label, alpha_2_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        //Buttons 
        TagGroup GoToAlpha1 = DLGCreatePushButton( "Write to file", "GoToAlpha1" ).DLGWidth(button_width)
        TagGroup GoToAlpha2 = DLGCreatePushButton( "Browse", "GoToAlpha2" ).DLGWidth(button_width)
        TagGroup alpha_buttons = DLGGroupItems( GoToAlpha2, GoToAlpha1 ).DLGTableLayout( 2, 2, 0 ).DLGAnchor( "East" )

        TagGroup alpha_group = DLGGroupItems( alpha_2_group, alpha_buttons ).DLGTableLayout( 1, 4, 0 )
        alpha_box_items.DLGAddElement( alpha_group )
        Dialog_UI.DLGAddElement( alpha_box )
        
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
	object threadObject = alloc( Go2AlphaThread )
	object dlgObject = alloc( myDialog ).Init( threadObject.ScriptObjectGetID() )
	dlgObject.display( "Write PETS2 File" ) //title of UI
}

// Script starts here
Invoke()
