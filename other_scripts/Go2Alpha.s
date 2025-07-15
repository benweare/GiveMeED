/* 
 Go2Alpha
 BLW @NMRC

 This script creates a UI in DigitalMicrograph that helps tilting the stage for setting eucentric height.
 Two angles can be defined, "Alpha 1" and "Alpha 2" in degrees. Pressing the correspinding button will move the 
 microscope stage to the defined angle. The "Tilt Neutral" button will set the stage angle to 0. 
 Care should be taken by the user that tilting to the defined angle will not cause a stage touch. If in doubt, check the maximum tilt range of your
 stage before using this script.
 Alpha refers to the tilt-x axis in a JEOL microscope. This script does not control the Beta tilt axis in double-tilt holders. 
 If you found this script useful, consider citing: http://arxiv.org/abs/2507.10247
*/
//Variables
number target_alpha

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
void GoToAlpha1( object self )
{
	{ 
	self.DLGGetValue( "alpha_1_field", target_alpha ) 
	}
	EMSetStageAlpha( target_alpha )
}

void GoToAlpha2( object self )
{
	{ 
	self.DLGGetValue( "alpha_2_field", target_alpha ) 
	}
	EMSetStageAlpha( target_alpha )
}

void TiltNeutral( object self )
{
	EMSetStageAlpha( 0 )
}

  TagGroup CreateDLG( object self )//copied from GiveMeED
  {
		number label_width = 10
        number entry_width = 10
        number button_width = 50

        TagGroup label
        TagGroup Dialog_UI = DLGCreateDialog( "Go2Alpha" )
        
        // Angles: alpha is tilt-x on a JEOL microscope
        TagGroup alpha_box_items
        TagGroup alpha_box = DLGCreateBox( "Stage Alpha", alpha_box_items ).DLGFill( "XY" )
        
        TagGroup alpha_1_field//start angle for tilt
        label = DLGCreateLabel( "Alpha1 (deg):" ).DLGWidth( label_width )
        alpha_1_field = DLGCreateStringField( "0" ).DLGIdentifier( "alpha_1_field" ).DLGWidth( entry_width )
        TagGroup alpha_1_group = DLGGroupItems( label, alpha_1_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup alpha_2_field//end angle for tilt
        label = DLGCreateLabel( "Alpha2 (deg):" ).DLGWidth( label_width )
        alpha_2_field = DLGCreateStringField( "0" ).DLGIdentifier( "alpha_2_field" ).DLGWidth( entry_width )
        TagGroup alpha_2_group = DLGGroupItems( label, alpha_2_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        //Alpha buttons - add a function for go to start angle of alpha 
        TagGroup GoToAlpha1 = DLGCreatePushButton( "Go to A1", "GoToAlpha1" ).DLGWidth(button_width)
        TagGroup GoToAlpha2 = DLGCreatePushButton( "Go to A2", "GoToAlpha2" ).DLGWidth(button_width)
        TagGroup TiltNeutral = DLGCreatePushButton( "Tilt Neutral", "TiltNeutral" ).DLGWidth(button_width)
        TagGroup alpha_buttons = DLGGroupItems( GoToAlpha1, GoToAlpha2, TiltNeutral ).DLGTableLayout( 2, 2, 0 ).DLGAnchor( "East" )
        
        TagGroup alpha_group = DLGGroupItems( alpha_1_group, alpha_2_group, alpha_buttons ).DLGTableLayout( 1, 4, 0 )
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
	dlgObject.display( "Go2Alpha" ) //title of UI
}

// Script starts here
Invoke()
