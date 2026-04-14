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
void draw( image img, number axis, number rval, number gval, number bval, number img_center_x, number img_center_y )
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
	draw_tilt_axis( axis, img_center_x, img_center_y, img )
}



// Script starts here
image img := GetFrontImage()

// User defined centre of pattern
//number img_center_x = 514
//number img_center_y = 523
number axis = 25.6

// This block gives geometric centre of image, i.e. for Fourier transforms.
number img_center_x = ImageGetDimensionSize(img, 0)/2
number img_center_y = ImageGetDimensionSize(img, 1)/2

draw( img, axis, 1, 0, 0, img_center_x, img_center_y )
// End