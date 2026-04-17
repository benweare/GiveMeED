# A little glue to go from DM to PETS2, DIALS, etc
# Logic:
#1: Open IS dataset
#2: Save it as certain format, with desired processing
#    2a: save as files to folder, then import as stack, then save as stack
#    2b: save directly as stack/files
#3: read the metadata and write an import file (PETS2, DIALS, etc).
#4: save everything in a folder so it's ready to go
#5: open e.g. PETS2, DIALS, and begin preprocessing?

import DigitalMicrograph as DM
import numpy as np
import os
from os import path
import glob

def _open_image( file_path ):
    img = DM.OpenImage( file_path )
    img.ShowImage()
    return img


def _create_container_from_template( file_path, **kwargs ):
    # Use an existing image to create an empty container, and copy tags.
    sizeZ = kwargs.get('length', 1) - 1
    
    img = DM.OpenImage( file_path )
    sizeX = img.GetDimensionSize(0)
    sizeY = img.GetDimensionSize(1)
    
    imgArray = np.zeros( (sizeZ, sizeX, sizeY) )

    #container  = DM.CreateImage(imgArray)
    #container.SetName( 'IS Data' )
    #_copy_image_tags( img, container )
    
    DM.CloseImage( img )
    #del( imgArray )
    
    return imgArray


def _np_array_to_dm_image( input_array, **kwargs ):
    title = kwargs.get('title', None)
    dm_image = DM.CreateImage( input_array )
    if (title != None):
        dm_image.SetName( title )
    return dm_image


def _copy_image_tags( img1, img2 ):
    tag_group1 = img1.GetTagGroup()
    tag_group2 = img2.GetTagGroup()
    tag_group2.CopyTagsFrom( tag_group1 )
    return


def _get_all_files( start_path, ext ):
    output = []
    for root, dirs, files in os.walk(start_path):
        for file in files:
            if ext in file:
                output.append(os.path.join(root, file))
    num_files = len( output )
    return output, num_files


def _write_IS_to_stack( file_path, stack ):
    for x, slice in enumerate( stack ):
        try:
            img = DM.OpenImage( file_path[x] )
            img_data = img.GetNumArray()
            slice = img_data
            stack[x, :, :] = slice
            print(x)
            DM.CloseImage( img )
        except:
            continue
    return


def _save_IS_as_stack( input, name, ext, file_path ):
    # Save as a Gatan .dm4
    save_path = file_path + '\\' + name + ext
    input.SaveAsGatan( save_path )
    return


# WIP
def _bin_array( input, size, bin_x, bin_y ):
    new_shape = size[0]/bin_x, size[1]/bin_y
    
    shape = (new_shape[0], arr.shape[0] // new_shape[0],
             new_shape[1], arr.shape[1] // new_shape[1])
    return input.reshape( shape ).mean(-1).mean(1)


def IS_to_stack( folder_path, **kwargs ):
    '''
    Function to import IS data as a .dm4 stack.
    '''
    verbose = kwargs.get('verbose', True)
    title = kwargs.get('title', 'IS data')
    # Get all files in IS dataset file structure.
    IS_files, IS_length = _get_all_files( folder_path, '.dm4' )

    # Remove the image that is used by DM to load IS datasets.
    IS_files.pop( 0 )
    
    if verbose == True:
        print( 'Files to process:  ' + str( IS_length ) )

    # Numpy array to contain IS dataset.
    container = _create_container_from_template( IS_files[1], length=IS_length )

    # Write IS data to np array then convert to dm image
    _write_IS_to_stack( IS_files, container )
    IS_stack = _np_array_to_dm_image( container, title=title )

    # Copy tags to new IS image stack.
    reference_image = DM.OpenImage( IS_files[0] )
    _copy_image_tags( reference_image, IS_stack )
    DM.CloseImage( reference_image )
    
    return IS_stack, IS_length

def _save_files_to_folder( stack, target_path, base_name, length, ext ):
    # Save input images as files to folder.
    # Use leading zeros thing from PETS2 project file.
    
    sizeX = stack.GetDimensionSize(0)
    sizeY = stack.GetDimensionSize(1)
    sizeZ = stack.GetDimensionSize(2)
    
    img_data = np.zeros( (sizeZ, sizeX, sizeY) )
    img_data = stack.GetNumArray()
    
    _does_directory_exist( target_path )
    
    for n in range(length):
        if n+1 < 10:
            zeros = '00000'
        elif n+1 > 9 and n+1 < 100:
            zeros = '0000'
        elif n+1 > 99 and n+1 < 1000:
            zeros = '000'
        elif n+1 > 999 and n+1 < 10000:
            zeros = '00'
        print( 'Saving ' + base_name + zeros + str(n) + ext  )
        save_path = target_path + '\\' + base_name + zeros + str(n) + ext
        # Copy array then create image to save.
        slice = np.copy(img_data[0, :, :])
        dm_image = DM.CreateImage( slice )
        _copy_image_tags( stack, dm_image )
        if ext == '.dm4':
            dm_image.SaveImage( save_path )
        if ext == '.tiff':
            doc = dm_image.GetOrCreateImageDocument()
            doc.SaveToFile( 'TIFF Format', save_path )
            doc.Close( False )
        DM.CloseImage( dm_image )
    return


def _save_as_tiff( imageref, path ):
    script_string = 'string format = "TIFF Format"\n'\
    'string path = "' + path + '"\n'\
    'imageDocument doc = dm_image.ImageGetOrCreateImageDocument()\n'\
    'doc.ImageDocumentSaveToFile( format , path )'
    print( script_string )
    #DM.ExecuteScriptString( script_string )
    return

def _does_directory_exist( target_path ):
    exists = os.path.exists( target_path )
    if exists == False:
        os.mkdir( target_path )
    return

def create_PETS2_project( IS_stack, IS_length, folder_path ):
    '''
    Save IS data as a PETS2 project.
    '''
    # Save files to folder.
    _save_files_to_folder( IS_stack,\
                            (folder_path + '\\files',)\# Sub-directory to save frames.
                            'test',\
                             IS_length,\
                             '.tiff' )
    # Create .pets2 file.
    
    return

# Metadata files.
def _save_project( output, format ):
    # Formats: '.phil', '.txt', '.CIF', '.pets2', etc.
    try:
        #block for saving file
        savepath = location + name + format
        file = open( savepath, 'x' )
        file.write( output )
        file.close( )
    except:
        print( "Error: something went wrong saving the project." )
    return

def _calc_axis_angle( angle, x, y, z ):
    # Convert tilt axis from angle to axis-angle vector.
    # [x, y, z] is direction of rotation: -1, 0, or 1.
    vector = np.array([ x, y, z ])
    vector = vector * angle
    return vector

class DataReductionVariables():
    def __init__( self ):
        # Float.
        self.alpha = 0
        self.alphastep = 0
        self.beta = 0
        self.betastep = 0
        self.nframes = 0

        self.scale = 0
        self.lamb = 0
        self.image_center = [0, 0]
        self.tilt_axis = 0
        
        # String.
        self.path = 'C:\\'
        self.name = 'experiment'
        self.ext = '.dm4'
        
        # PETS2 specificA
        self.refdia = 10
        self.binning = 1
        self.semiangle = self.alphastep/2
        self.geometry = 'continuous'
        self.dstarmax = '1.2'
        self.dstarmaxps = '1.2'
        self.dstarmin = '0.2'
        self.img_number = 0
        self.extension = '.tif'
        
        #DIALS specific
        self.panel_size = [0.005, 0.005]
        self.material = '"Si"'
        self.trusted_range = [-1000000, 4294967295]
        self.gain = 1
        self.cam_length = 100
        self.image_size = [512, 512]
        self.beam_center = [0, 0]
        self.probe = "'x-ray *electron neutron'"
        self.camera_name = 'Gatan OneView'
        return
    
    
    def _read_CIF( self ):
        # Read the metadata from the 3DED experiment.
        file = open( 'C:\\Users\\pczbw2\\Desktop\\TEMP\\test.cif' )
        exp_data = file.read()
        file.close()
        return exp_data
    
    def _get_spacing( self, data, val ):
        line_break = data[val:].find( '\n' )
        space = data[val:].find( ' ' )
        colon = data[val:].find( ':' )
        return line_break, space, colon
    
    def _get_exp_floats( self, data ):
        # find var in string, then read it
        # find next line break to know how much to read
        search = [ 'Start angle (deg):',\
        'frames',\
        'Angle per frame (deg):',\
        'Rotation axis (deg):',\
        'Camera length (mm):']#,\
        #'Image size x/y (px):']
        vals = []
        # Fields that end with colon.
        for n, m in enumerate(search):
            location = data.find( m )
            lb, s, c = self._get_spacing( data, location )
            vals.append( data[ (location + c + 1) : (location + lb) ] )
        search = [ '_diffrn_radiation_wavelength' ]
        # Fields that end with space.
        for n, m in enumerate(search):
            location = data.find( m )
            lb, s, c = self._get_spacing( data, location )
            vals.append( data[ (location + s + 1) : (location + lb) ] )
        floats = [ float(i) for i in vals ]
        print( floats )
        return floats
    
    def _store_exp_data( self, floats ):
        self.alpha = floats[0]
        self.alphastep = floats[1]
        self.nframes = floats[2]
        self.cam_length = floats[4]
        self.tilt_axis = floats[3]
        self.lamb = floats[5]
        return



## Scripts start here
# File path. Needs \\ to work.
folder_path = 'C:\\Users\\pczbw2\\Desktop\\TEMP\\SH22_02'


IS_stack, IS_length = IS_to_stack( folder_path )

print('Saving images.')
_save_files_to_folder( IS_stack,\
                        'C:\\Users\\pczbw2\\Desktop\\TEMP\\Test',\
                        'test',\
                         IS_length,\
                         '.tiff' )

# Display the IS image stack.
IS_stack.ShowImage()


#_save_IS_as_stack( IS_stack, 'IS_data', '.dm4', 'C:\\Users\\pczbw2\\Desktop\\TEMP\\Test' )