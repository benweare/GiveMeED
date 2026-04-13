// Automatic Resolution Rings 
// 27-09-24
// B L Weare, @NMRC
// Draws a standard set of resolution rings on the front image
// Can tweak how many rings & diameter by editing the matrix
//Angstroms to nm-1
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
//Grab scale from image
number ScaleInfo( )
{
	image img := GetFrontImage()
	number img_scale = ImageGetDimensionScale(img, 0)
	string scale_units = ImageGetDimensionUnitString(img, 0)
	//result("Scale: " + img_scale + " " + scale_units + "\n")
	return img_scale
}
// Using image object as a matrix
image resolution_rings := [1,6] : {
	{100},
	{4},
	{2},
	{1.4},
	{1},
	{0.8}//,
	//{0.6}
}
// Draw the tilt axis onto the image.
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
// Draw ROIs on image
void draw( image img, number rval, number gval, number bval, number img_center_x, number img_center_y )
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
			ring = CreateResRing( ringRadius, pixRadius, img_center_x, img_center_y, rval, gval, bval )
			imgDisplay.ImageDisplayAddROI( ring )
		}
		catch
		{
			result("something went wrong" + "\n")
		}
	}
	CloseImage(Resolution_Rings)
}

// Remove ROIs
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

image img := GetFrontImage()
number axis_value

// This block gives geometric centre of image, i.e. for Fourier transforms.
number img_center_x = ImageGetDimensionSize(img, 0)/2
number img_center_y = ImageGetDimensionSize(img, 1)/2

class ResRingsThread:Thread
{
  number linkedDLG_ID
  ResRingsThread( object self )  
  {
   // result( self.ScriptObjectGetID() + " created.\n" )
  }
  ~ResRingsThread( object self )
  {
   // result( self.ScriptObjectGetID() + " destroyed.\n" )
  }
  void SetLinkedDialogID( object self, number ID ) { linkedDLG_ID = ID; }
}

//Declare UI elements
class myDialog : UIframe
{
  object callThread

  myDialog( object self ){}
  ~myDialog( object self ){}

//Button functions
void DrawRings( object self )
{
	{ 
	self.DLGGetValue( "x_cent", img_center_x )
	self.DLGGetValue( "y_cent", img_center_y )
	}
	img := GetFrontImage()
	draw( img, 1, 0, 0, img_center_x, img_center_y )
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
	img := GetFrontImage()
	draw_tilt_axis( axis_value, img_center_x, img_center_y, img )
}

  TagGroup CreateDLG( object self )//copied from GiveMeED
  {
		number label_width = 10
        number entry_width = 10
        number button_width = 50
        string center

        TagGroup label
        TagGroup Dialog_UI = DLGCreateDialog( "ResRings" )
        
        // Angles: alpha is tilt-x on a JEOL microscope
        TagGroup rr_box_items
        TagGroup rr_box = DLGCreateBox( "Settings", rr_box_items ).DLGFill( "XY" )
        
        TagGroup ta_field//start angle for tilt
        label = DLGCreateLabel( "Tilt axis (deg):" ).DLGWidth( label_width )
        ta_field = DLGCreateStringField( "25.1" ).DLGIdentifier( "ta_field" ).DLGWidth( entry_width )
        TagGroup ta_group = DLGGroupItems( label, ta_field ).DLGTableLayout( 2, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup x_cent, y_cent
        label = DLGCreateLabel( "X/Y:" ).DLGWidth( label_width )
        center = BaseN(img_center_x, 10, 4)
        x_cent = DLGCreateStringField( center ).DLGIdentifier( "x_cent" ).DLGWidth( entry_width )
        center = BaseN(img_center_y, 10, 4)
        y_cent = DLGCreateStringField( center ).DLGIdentifier( "x_cent" ).DLGWidth( entry_width )
        TagGroup pattern_box = DLGGroupItems( label, x_cent, y_cent ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        
        //Alpha buttons - add a function for go to start angle of alpha 
        TagGroup rrbutton = DLGCreatePushButton( "Draw Rings", "DrawRings" ).DLGWidth(button_width)
        TagGroup rr_del = DLGCreatePushButton( "Remove Rings", "delete_rings" ).DLGWidth(button_width)
        TagGroup tabutton = DLGCreatePushButton( "Draw Axis", "DrawAxis" ).DLGWidth(button_width)
        TagGroup ta_del = DLGCreatePushButton( "Remove Axis", "delete_axis" ).DLGWidth(button_width)
        TagGroup rr_buttons = DLGGroupItems( rrbutton, tabutton, rr_del, ta_del ).DLGTableLayout( 2, 2, 0 ).DLGAnchor( "East" )
        
        TagGroup rr_group = DLGGroupItems( ta_group, pattern_box, rr_buttons ).DLGTableLayout( 1, 4, 0 )
        rr_box_items.DLGAddElement( rr_group )
        
        
        Dialog_UI.DLGAddElement( rr_box )
        
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
	object threadObject = alloc( ResRingsThread )
	object dlgObject = alloc( myDialog ).Init( threadObject.ScriptObjectGetID() )
	dlgObject.display( "Resolution Rings" ) //title of UI
}

// Script starts here
Invoke()
