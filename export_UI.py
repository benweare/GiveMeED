// Number ChooseMenuItem( String menu_name, String sub_menu_name, String menu_item_name )
// Throw(  )

// Global variables.
string IS_data_dir = "X:\\"
string cif_data_dir = "X:\\"

// Python script strings (as raw string).
string python_dir = "r'C:\\Users\\VALUEDGATANCUSTOMER\\Desktop\\temp'"

string python_import_module
python_import_module += "import sys\n"
python_import_module += "cwd = " + python_dir + "\n"
python_import_module += "sys.path.append( cwd )\n"
python_import_module += "import export_IS_data as IS"

string create_raw_string( string input )
{
	// Creates a Python raw string for hybrid scripts.
	number length
	string rightmost = right( input, 1 )
	if ( rightmost == " " )
	{
		length = len( input )
		input = left( input, (length-1) )
	}
	
	rightmost = right( input, 1 )
	
	string raw = "r'" + input// + "'+" + "'\\\\'"
	
	rightmost = right( raw, 1 )
	if ( rightmost == "\\" )
	{
		length = len( raw )
		raw = left( raw, (length-1) )
		raw = raw + "''\\\\'"
		
	}
	else
	{
		raw = raw + "'"
	}
	return raw
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
	void UpdateValues( object self, number &export_dials, number &export_pets, string &IS_data_dir, string &cif_data_dir )
	{ 
		return
	}
	void browse_IS_data( object self )
	{
		string directory
		if ( !GetDirectoryDialog("Select directory", IS_data_dir, directory) ) 
		{
			return
		}
		self.DLGValue("path_field", directory)
	}
	void browse_CIF( object self )
	{
		string directory
		if ( !GetDirectoryDialog("Select directory", cif_data_dir, directory) ) 
		{
			return
		}
		self.DLGValue( "cif_field", directory )
	}
	void open_IS_dataset( object self )
	{
		// Hybrid script to open IS datasets as a stack.
		self.DLGGetValue( "path_field", IS_data_dir )
		
		string raw_string = create_raw_string( IS_data_dir )
		
		string python_open_IS
		python_open_IS += "file_path = " + raw_string + "\n"
		python_open_IS += "IS_stack, IS_length = IS.IS_to_stack( file_path )\n"
		python_open_IS += "IS_stack.ShowImage()"
		
		string pyscript = python_import_module + "\n" + python_open_IS
		
		// Asynchronous on background thread.
		ExecutePythonScriptString( pyscript, 1 )

	}
	void export_IS_dataset( object self )
	{
		number export_dials, export_pets
		
		self.DLGGetValue( "checkbox_dials", export_dials )
		self.DLGGetValue( "checkbox_pets", export_pets )
		self.DLGGetValue( "path_field", IS_data_dir )
		self.DLGGetValue( "path_field", cif_data_dir )
		
		// Import python module.
		//ExecutePythonScriptString( python_import_module )

		if ( export_dials == 1 )
		{
			// Export to DIALS format.
			result( "Exporting to DIALS format.\n" )
			
			// TO DO: get length of IS dataset, pass IS image stack and length to python, variable for experiment name,
			// update UI with name field and some other stuff
			string py_export_dials = ""
			py_export_dials += "create_DIALS_project( IS_stack, IS_length,"+ IS_data_dir+","+ cif_data_dir +", name = 'exp_name' )"
			
			string pyscript = python_export_dials + "\n" + python_open_IS
			//ExecutePythonScriptString( pyscript, 1 )
			
			result(pyscript)
			
		}
		if ( export_pets == 1 )
		{
			// Export to PETS2 format.
			result( "Exporting to PETS2 format.\n" )
		}
		if ( export_dials == 0 && export_pets == 0 )
		{
			result( "Error: select export format.\n" )
			//ExecutePythonScriptString( python_path_pets2 )
		}
		return
	}
	void ActOnCheck( object self, TagGroup checkbox )
	{
		checkbox.DLGGetValue()
	}
  TagGroup CreateDLG( object self )
  {
		number export_dials, export_pets = 0
		
		
		number label_width = 15
        number entry_width = 8
        number button_width = 50
        TagGroup label
        TagGroup Dialog_UI = DLGCreateDialog("GiveMeED")
        
        // Create a box for the setup parameters             
        TagGroup setup_box_items
        TagGroup setup_box = DLGCreateBox("Select Experiment", setup_box_items).DLGFill("XY")
        
        // Directory fields.
        TagGroup IS_path_field
        label = DLGCreateLabel("Images:").DLGWidth(label_width)
        IS_path_field = DLGCreateStringField( IS_data_dir ).DLGIdentifier("path_field").DLGWidth(entry_width*4)
        TagGroup IS_path_group = DLGGroupItems(label, IS_path_field).DLGTableLayout(2, 1, 0)
        
        TagGroup cif_path_field
        label = DLGCreateLabel("CIF:").DLGWidth(label_width)
        cif_path_field = DLGCreateStringField( cif_data_dir ).DLGIdentifier("cif_field").DLGWidth(entry_width*4)
        TagGroup cif_path_group = DLGGroupItems(label, cif_path_field).DLGTableLayout(2, 1, 0)
        
        TagGroup path_group = DLGGroupItems( IS_path_group, cif_path_group ).DLGTableLayout(1, 2, 0)
        
        // Buttons.
        TagGroup browse_button = DLGCreatePushButton("Select IS data", "browse_IS_data").DLGWidth(button_width)
        TagGroup open_button = DLGCreatePushButton("Select CIF", "browse_CIF").DLGWidth(button_width)
        TagGroup button_group = DLGGroupItems( browse_button, open_button).DLGTableLayout(2, 1, 0)
        TagGroup setup_group = DLGGroupItems(path_group, button_group).DLGTableLayout(1, 6, 0)
        
        setup_box_items.DLGAddElement( setup_group )
        Dialog_UI.DLGAddElement( setup_box )
        
        // Open data group.
        TagGroup open_data_button = DLGCreatePushButton("Open IS data", "open_IS_dataset").DLGWidth(button_width)
        Dialog_UI.DLGAddElement( open_data_button )
        
        // Variables group
        TagGroup variables_box_items
        TagGroup variables_box = DLGCreateBox("Export data", variables_box_items).DLGFill("XY")
        
		TagGroup notes_field
        label = DLGCreateLabel("Name:").DLGWidth(label_width)
        notes_field = DLGCreateStringField( "experiment_name" ).DLGIdentifier("notes_field").DLGWidth(entry_width*4)
        TagGroup notes_group = DLGGroupItems(label, notes_field).DLGTableLayout(2, 1, 0)
        
        // Checkboxes
        label = DLGCreateLabel("Export format:").DLGWidth(label_width)
        TagGroup checkbox_dials = DLGCreateCheckBox( "DIALS", export_dials, "ActOnCheck" ).DLGIdentifier("checkbox_dials")
        TagGroup checkbox_pets = DLGCreateCheckBox( "PETS2", export_pets, "ActOnCheck" ).DLGIdentifier("checkbox_pets")
        TagGroup checkbox_group = DLGGroupItems( label, checkbox_dials, checkbox_pets  ).DLGTableLayout(3, 1, 0)
        
        // Buttons
        TagGroup export_button = DLGCreatePushButton("Export IS Data", "export_IS_dataset").DLGWidth(button_width)
        
        TagGroup variables_group = DLGGroupItems( notes_group, checkbox_group, export_button ).DLGTableLayout(1, 3, 0)
        
        
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
string dialogue_name = "Export 3DED Data"
// Python scripts

Invoke( dialogue_name )
// End.