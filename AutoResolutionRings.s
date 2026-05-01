// Automatic Resolution Rings 
// 14-04-26
// B L Weare, @NMRC
// Draws a standard set of resolution rings on the front image
// Can tweak how many rings & diameter by editing the matrix
// Angstroms to nm-1
number ConvertToRecNM( number num2convert )
{ 
	number convertednum = 1/(num2convert*0.1)
	//result(num2convert + " A = " + convertednum + " nm-1" + "\n")
	return convertednum
}
void GetImageCenter( image img, number &x, number &y )
{
	x = ImageGetDimensionSize(img, 0)/2
	y = ImageGetDimensionSize(img, 1)/2
	return
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
	{4},
	{2},
	{1.4},
	{1},
	{0.8},
	{0.6}
}
image ice_rings := [1,5] : {
	{3.78},
	{2.228},
	{1.93},
	{1.47},
	{1.31}
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
void GetROIDetails( number &scale, number &pixRadius, number ringRadius )
{
	scale = ScaleInfo( )
	number rawRadius = ConvertToRecNM( ringRadius )
	pixRadius = rawRadius / scale
	return
}
void draw_ROI( ImageDisplay imgDisp, number scale, number ringRadius, number cent_x, number cent_y, number r, number g, number b )
{
	number pixRadius
	ROI ring
	GetROIDetails( scale, pixRadius, ringRadius )
	ring = CreateResRing( ringRadius, pixRadius, cent_x, cent_y, r, g, b )
	imgDisp.ImageDisplayAddROI( ring )
}
// Draw ROIs on image
void draw( object ui, image img, number cent_x, number cent_y )
{
	number rr00, rr01, rr02, rr03, rr04, rr05
	number ir00, ir01, ir02, ir03, ir04
	
	// Resolution rings.
	ui.DLGGetValue( "rr00", rr00 )
	ui.DLGGetValue( "rr01", rr01 )
	ui.DLGGetValue( "rr02", rr02 )
	ui.DLGGetValue( "rr03", rr03 )
	ui.DLGGetValue( "rr04", rr04 )
	ui.DLGGetValue( "rr05", rr05 )
	// Ice rings.
	ui.DLGGetValue( "ir00", ir00 )
	ui.DLGGetValue( "ir01", ir01 )
	ui.DLGGetValue( "ir02", ir02 )
	ui.DLGGetValue( "ir03", ir03 )
	ui.DLGGetValue( "ir04", ir04 )
	
	// Then do something to draw all rings that are set to True
	
	
	ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
	number ringRadius
	ROI ring
	number rval, bval, gval
	number scale
	
	rval = 1; bval = 0; gval = 0
	scale = ScaleInfo()
	
	// Draw resolution rings.
	ringRadius = 100
	draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	if (rr00 == 1)
	{
		ringRadius = GetPixel(resolution_rings, 0, 0 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (rr01 == 1)
	{
		ringRadius = GetPixel(resolution_rings, 0, 1 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (rr02 == 1)
	{
		ringRadius = GetPixel(resolution_rings, 0, 2 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (rr03 == 1)
	{
		ringRadius = GetPixel(resolution_rings, 0, 3 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (rr04 == 1)
	{
		ringRadius = GetPixel(resolution_rings, 0, 4 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (rr05 == 1)
	{
		ringRadius = GetPixel(resolution_rings, 0, 5 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	// Draw ice rings.
	rval = 0; bval = 1; gval = 0
	if (ir00 == 1)
	{
		ringRadius = GetPixel(ice_rings, 0, 0 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (ir01 == 1)
	{
		ringRadius = GetPixel(ice_rings, 0, 1 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (ir02 == 1)
	{
		ringRadius = GetPixel(ice_rings, 0, 2 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (ir03 == 1)
	{
		ringRadius = GetPixel(ice_rings, 0, 3 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )	
	}
	if (ir04 == 1)
	{
		ringRadius = GetPixel(ice_rings, 0, 4 )
		draw_ROI( imgDisplay, scale, ringRadius, cent_x, cent_y, rval, gval, bval )		
	}
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
number img_center_x, img_center_y

GetImageCenter( img, img_center_x, img_center_y )


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
	self.DLGGetValue( "x_cent", img_center_x )
	self.DLGGetValue( "y_cent", img_center_y )
	
	img := GetFrontImage()
	draw( self, img, img_center_x, img_center_y )
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
	self.DLGGetValue( "ta_field", axis_value )
	self.DLGGetValue( "x_cent", img_center_x )
	self.DLGGetValue( "y_cent", img_center_y )
	img := GetFrontImage()
	draw_tilt_axis( axis_value, img_center_x, img_center_y, img )
}
void UpdateCenter( object self )
{
	number x, y
	image img := GetFrontImage()
	GetImageCenter( img, x, y )
	
	self.DLGValue( "x_cent", x )
	self.DLGValue( "y_cent", y )
}
  TagGroup CreateDLG( object self )//copied from GiveMeED
  {
		number label_width = 10
        number entry_width = 10
        number button_width = 50
        string center

        TagGroup label
        TagGroup Dialog_UI = DLGCreateDialog( "ResRings" )
        
        // Settings box.
        TagGroup rr_box_items
        TagGroup rr_box = DLGCreateBox( "Settings", rr_box_items ).DLGFill( "XY" )
        
        TagGroup ta_field
        label = DLGCreateLabel( "Tilt axis (deg):" ).DLGWidth( label_width )
        ta_field = DLGCreateStringField( "25.1" ).DLGIdentifier( "ta_field" ).DLGWidth( entry_width )
        
        TagGroup ta_group = DLGGroupItems( label, ta_field ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup x_cent, y_cent
        label = DLGCreateLabel( "X/Y (px):" ).DLGWidth( label_width )
        center = BaseN(img_center_x, 10, 4)
        x_cent = DLGCreateStringField( center ).DLGIdentifier( "x_cent" ).DLGWidth( entry_width )
        center = BaseN(img_center_y, 10, 4)
        y_cent = DLGCreateStringField( center ).DLGIdentifier( "y_cent" ).DLGWidth( entry_width )
        TagGroup update_button = DLGCreatePushButton( "Update X/Y", "UpdateCenter" ).DLGWidth(button_width)
        TagGroup pattern_box = DLGGroupItems( label, x_cent, y_cent ).DLGTableLayout( 4, 1, 0 ).DLGAnchor( "West" )
        
        TagGroup rr_group = DLGGroupItems( ta_group, pattern_box ).DLGTableLayout( 1, 4, 0 )
        rr_box_items.DLGAddElement( rr_group )
        rr_box_items.DLGAddElement( update_button )
        Dialog_UI.DLGAddElement( rr_box )

        // Ring checkboxes.
        TagGroup rr_100, rr_4, rr_2, rr_1p4, rr_1, rr_0p8, rr_0p6
        rr_4 = DLGCreateCheckBox( "4.0 A", 1 ).DLGIdentifier( "rr00" )
        rr_2 = DLGCreateCheckBox( "2.0 A", 1 ).DLGIdentifier( "rr01" )
        rr_1p4 = DLGCreateCheckBox( "1.4 A", 1 ).DLGIdentifier( "rr02" )
        rr_1 = DLGCreateCheckBox( "1.0 A", 1 ).DLGIdentifier( "rr03" )
        rr_0p8 = DLGCreateCheckBox( "0.8 A", 1 ).DLGIdentifier( "rr04" )
        rr_0p6 = DLGCreateCheckBox( "0.6 A", 0 ).DLGIdentifier( "rr05" )
        
        
        TagGroup rr_cb, cb_box, rr_cb_00, rr_cb_01
        cb_box = DLGCreateBox( "Rings", rr_cb ).DLGFill( "XY" )
        rr_cb_00 = DLGGroupItems( rr_4, rr_2, rr_1p4 ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        rr_cb_01 = DLGGroupItems( rr_1, rr_0p8, rr_0p6 ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        rr_cb = DLGGroupItems( rr_cb_00, rr_cb_01 ).DLGTableLayout( 1, 2, 0 ).DLGAnchor( "West" )
        
        cb_box.DLGAddElement( rr_cb )
        Dialog_UI.DLGAddElement( cb_box )
        
        // Ice rings checkboxes.
        TagGroup ir_0, ir_1, ir_2, ir_3, ir_4
        ir_0 = DLGCreateCheckBox( "3.78 A", 1 ).DLGIdentifier( "ir00" )
        ir_1 = DLGCreateCheckBox( "2.23 A", 1 ).DLGIdentifier( "ir01" )
        ir_2 = DLGCreateCheckBox( "1.93 A", 1 ).DLGIdentifier( "ir02" )
        ir_3 = DLGCreateCheckBox( "1.47 A", 1 ).DLGIdentifier( "ir03" )
        ir_4 = DLGCreateCheckBox( "1.31 A", 1 ).DLGIdentifier( "ir04" )
        
        TagGroup ir_cb, ir_box, ir_cb_00, ir_cb_01
        ir_box = DLGCreateBox( "Ice Rings", ir_cb ).DLGFill( "XY" )
        ir_cb_00 = DLGGroupItems( ir_0, ir_1, ir_2 ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        ir_cb_01 = DLGGroupItems( ir_3, ir_4 ).DLGTableLayout( 3, 1, 0 ).DLGAnchor( "West" )
        ir_cb = DLGGroupItems( ir_cb_00, ir_cb_01 ).DLGTableLayout( 1, 2, 0 ).DLGAnchor( "West" )
        
        ir_box.DLGAddElement( ir_cb )
        Dialog_UI.DLGAddElement( ir_box )
        
        // ROI control buttons.
        TagGroup buttons_box = DLGCreateBox( "Draw", rr_box_items ).DLGFill( "XY" )
        TagGroup rr_button = DLGCreatePushButton( "Draw Rings", "DrawRings" ).DLGWidth(button_width)
        TagGroup rr_del = DLGCreatePushButton( "Remove Rings", "delete_rings" ).DLGWidth(button_width)
        TagGroup ta_button = DLGCreatePushButton( "Draw Axis", "DrawAxis" ).DLGWidth(button_width)
        TagGroup ta_del = DLGCreatePushButton( "Remove Axis", "delete_axis" ).DLGWidth(button_width)
        TagGroup rr_button_00 = DLGGroupItems( rr_button, rr_del ).DLGTableLayout( 2, 1, 0 )//.DLGAnchor( "East" )
        TagGroup rr_button_01 = DLGGroupItems( ta_button, ta_del ).DLGTableLayout( 2, 1, 0 )//.DLGAnchor( "East" )
        TagGroup rr_buttons = DLGGroupItems( rr_button_00, rr_button_01 ).DLGTableLayout( 1, 2, 0 )//.DLGAnchor( "East" )
        
        buttons_box.DLGAddElement( rr_buttons)
        Dialog_UI.DLGAddElement( buttons_box )
        
        TagGroup footer = DLGCreateLabel("GMED: AutoResRings")
        Dialog_UI.DLGAddElement(footer).DLGWidth( label_width*3.5 )
        
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
try
{
	Invoke()
}
catch
{
	Throw("Please open an image first.")
}
