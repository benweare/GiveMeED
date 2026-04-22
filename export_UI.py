// Number ChooseMenuItem( String menu_name, String sub_menu_name, String menu_item_name )

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
	
	// UI functions. 
	void UpdateValues( object self )
	{ 
		return
	}
	void browse_files( object self )//may need to rename function
	{
		//string directory
		//if ( !GetDirectoryDialog("Select directory", save_dir, directory) ) 
		//{
		//	return
		//}
		//self.DLGValue("path_field", directory)
	}
	
	// Button Functions.
	void start_pressed( object self )//start 3DED 
	{
	}
	void stop_pressed( object self )//end 3DED
	{
	}
	void reset_pressed( object self )//reset stage
	{
	}
	// Buttons for tilt control.
	void GoToAlpha1( object self )
	{
	}
	void GoToAlpha2( object self )
	{
	}
	// Buttons for resolution rings and tilt axis.
	void DrawRings( object self )
	{
	}
	void delete_rings( object self )
	{
	}
	void delete_axis( object self )
	{
	}
	void DrawAxis( object self )
	{
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
        TagGroup setup_box = DLGCreateBox("Select Experiment", setup_box_items).DLGFill("XY")
        
        // Work directory field
        TagGroup path_field
        label = DLGCreateLabel("Path:").DLGWidth(label_width)
        path_field = DLGCreateStringField( "C://" ).DLGIdentifier("path_field").DLGWidth(entry_width*4)
        TagGroup path_group = DLGGroupItems(label, path_field).DLGTableLayout(2, 1, 0)
        
        // Sample name field
        //TagGroup sample_name_field
        //label = DLGCreateLabel("Sample name:").DLGWidth(label_width)
        //sample_name_field = DLGCreateStringField( "Test" ).DLGIdentifier("sample_name_field").DLGWidth(entry_width*4)
        //TagGroup sample_name_group = DLGGroupItems(label, sample_name_field).DLGTableLayout(2, 1, 0)
		
		
		// Notes field
		TagGroup notes_field
        label = DLGCreateLabel("Notes:").DLGWidth(label_width)
        notes_field = DLGCreateStringField( "Test" ).DLGIdentifier("notes_field").DLGWidth(entry_width*4)
        TagGroup notes_group = DLGGroupItems(label, notes_field).DLGTableLayout(2, 1, 0)
        
        // Buttons
        TagGroup browse_button = DLGCreatePushButton("Browse files", "browse_files").DLGWidth(button_width)
        TagGroup open_button = DLGCreatePushButton("Open IS Data", "browse_files").DLGWidth(button_width)
        TagGroup setup_group = DLGGroupItems(path_group, browse_button, open_button).DLGTableLayout(1, 6, 0)
        setup_box_items.DLGAddElement( setup_group )
        Dialog_UI.DLGAddElement( setup_box )
        
        // Export to...
        //TagGroup radio_list =  DLGCreateRadioList()
        //TagGroup radio_dials =  DLGCreateRadioItem( "DIALS", 0 )
        //TagGroup radio_pets =  DLGCreateRadioItem( "PETS2", 0  )
        //Dialog_UI.DLGAddElement( radio_pets )
        
        // Checkboxes
        TagGroup checkbox_dials = DLGCreateCheckBox( "DIALS", 0 )
        TagGroup checkbox_pets = DLGCreateCheckBox( "PETS2", 0 )
        TagGroup checkboxes = DLGGroupItems( checkbox_dials, checkbox_pets )
        Dialog_UI.DLGAddElement( checkboxes ).DLGTableLayout(2, 1, 0)

        
        // Variables group
        TagGroup variables_box_items
        TagGroup variables_box = DLGCreateBox("Name:", variables_box_items).DLGFill("XY")
        TagGroup wavelength_field
        
        label = DLGCreateLabel("Lambda / nm:").DLGWidth(label_width)
        wavelength_field = DLGCreateStringField("0.00251").DLGIdentifier("wavelength_field").DLGWidth(entry_width*4)
        TagGroup wavelength_group = DLGGroupItems(label, wavelength_field).DLGTableLayout(2, 1, 0)
        
        TagGroup fps_field
        label = DLGCreateLabel("Frame rate:").DLGWidth(label_width)
        
        fps_field = DLGCreateStringField("175").DLGIdentifier("fps_field").DLGWidth(entry_width*4)
        TagGroup fps_group = DLGGroupItems(label, fps_field).DLGTableLayout(2, 1, 0)
        TagGroup variables_group = DLGGroupItems( wavelength_group, fps_group, notes_group ).DLGTableLayout(1, 3, 0)
        
        // Buttons
        TagGroup browse_button = DLGCreatePushButton("Export IS Data", "browse_files").DLGWidth(button_width)
        TagGroup setup_group = DLGGroupItems(path_group, browse_button, open_button).DLGTableLayout(1, 6, 0)
        setup_box_items.DLGAddElement( setup_group )
        Dialog_UI.DLGAddElement( setup_box )
        
        
        variables_box_items.DLGAddElement( variables_group )
        Dialog_UI.DLGAddElement( variables_box )
        
        
        TagGroup footer = DLGCreateLabel(" ")
        Dialog_UI.DLGAddElement(footer)
        
        return Dialog_UI
        
  }
  
  // Init the UI.
  object Init(object self, number callThreadID )
  {
    // Assign thread-object via weak-reference.
    callThread = GetScriptObjectFromID( callThreadID )      
    if ( !callThread.ScriptObjectIsvalid() )
      Throw( "Invalid thread object passed in! Object of given ID not found." )
    // Pass weak-reference to thread object.
    callThread.SetLinkedDialogID( self.ScriptObjectGetID() )  
    return self.super.init( self.CreateDLG() )
  }
}

// Launch threads.
void Invoke( string program_name )
{
		object threadObject = alloc( data_collection_thread )
		object dlgObject = alloc( myDialog ).Init( threadObject.ScriptObjectGetID() )
		// UI title.
		dlgObject.display( program_name )
		result("Starting.\n")

}
// Script starts here.
Invoke( "Test" )
// End.