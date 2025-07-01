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
void CreateResRing( number radlabel, number radius, number x, number y, number r, number g, number b )
{
	ROI resRing = NewROI( )
	ROISetCircle(resRing, x, y, radius)
	image img := GetFrontImage()
	ImageDisplay imgDisplay = img.ImageGetImageDisplay(0)
	imgDisplay.ImageDisplayAddROI( resRing )
	
	string label = radlabel + " A"
	ROISetColor( resRing, r, g, b) //RBG in 0-1
	if (radlabel != 100)
		ROISetLabel( resRing, label )
	ROISetMoveable( resRing, 0 )
	ROISetVolatile( resRing, 0 )
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
image resolution_rings := [1,7] : {
	{100},
	{4},
	{2},
	{1.4},
	{1},
	{0.8},
	{0.6}
}
number array_length = ImageGetDimensionSize(Resolution_Rings, 1)//y dimentsion of array
// Script starts here
// User defined centre of pattern
//number img_center_x = 514
//number img_center_y = 523
// This block gives geometric centre of image; for Fourier transforms.
//image img := GetFrontImage()
number img_center_x = ImageGetDimensionSize(img, 0)/2
number img_center_y = ImageGetDimensionSize(img, 1)/2
//Colour of rings in RGB
number rval = 1; number gval = 0; number bval = 0
 for (number i = 0; i < array_length ; i++ )//less than length of array
{
	try
	{
		number ringRadius = GetPixel(resolution_rings, 0, i )//element i of array (counts from 0)
		number scale = ScaleInfo( )
		number rawRadius = ConvertToRecNM( ringRadius )
		number pixRadius = rawRadius / scale
		CreateResRing( ringRadius, pixRadius, img_center_x, img_center_y, rval, gval, bval )
	}
	catch
	{
		result("something went wrong" + "\n")
	}
}
CloseImage(Resolution_Rings)
// End
