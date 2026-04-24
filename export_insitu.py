'''
Module to handle In-Situ datasets automatically.

Allows importing as a stack, and exporting.
'''
# BLW @ nmRC, 24-04-2026.


import DigitalMicrograph as DM
import numpy as np
import os
from os import path


def _open_image( file_path ):
    # Util for opening images im DM.
    img = DM.OpenImage( file_path )
    img.ShowImage()
    return img


def _does_directory_exist( target_path ):
    exists = os.path.exists( target_path )
    if exists == False:
        os.mkdir( target_path )
    return


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


def _create_container_from_template( file_path, **kwargs ):
    # Use an existing image to create an empty container.
    sizeZ = kwargs.get('length', 1) - 1
    
    img = DM.OpenImage( file_path )
    sizeX = img.GetDimensionSize(0)
    sizeY = img.GetDimensionSize(1)
    
    imgArray = np.zeros( (sizeZ, sizeX, sizeY) )
    
    DM.CloseImage( img )
    
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
    _does_directory_exist( file_path )
    save_path = file_path + '\\' + name + ext
    input.SaveAsGatan( save_path )
    return


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
    # [X, Y, Z]
    size = [stack.GetDimensionSize(0), stack.GetDimensionSize(1), stack.GetDimensionSize(2)]
    
    img_data = np.zeros( (size[2], size[1], size[0]) )
    img_data = stack.GetNumArray()
    
    _does_directory_exist( target_path )
    
    files = []
    
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
        save_path = target_path + '\\' + base_name + zeros + str(n)
        files.append( base_name + zeros + str(n) + ext )
        # Copy array then create image and save.
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
    
    return files


class DataReductionVariables():
    '''
    Class to contain variables for data reduction.
    
    Used to write projects for PETS2 and DIALS.
    '''
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
        self.material = '"Si"'
        self.trusted_range = [-1000000, 4294967295]
        self.gain = 1
        self.cam_length = 100
        self.image_size = [512, 512]
        self.beam_center = [0, 0]
        self.probe = "'x-ray *electron neutron'"
        self.camera_name = 'Gatan OneView'
        self.pixel_size = [0.0, 0.0]
        return
    
    
    def _read_CIF( self, path ): #, name ):
        # Read the metadata from the 3DED experiment.
        #print( path + '\\' + name )
        #file = open( (path + '\\' + name) )
        try:
            file = open( path )
            exp_data = file.read()
            file.close()
        except:
            print("Error: could not read CIF.")
        return exp_data
    
    
    def _get_spacing( self, data, val ):
        line_break = data[val:].find( '\n' )
        space = data[val:].find( ' ' )
        colon = data[val:].find( ':' )
        return line_break, space, colon
    
    
    def _get_exp_floats( self, data ):
        # find var in string, then read it
        # find next line break to know how much to read
        search = [ '_gmed_start_deg_angle',\
        '_gmed_angle_per_frame',\
        '_gmed_total_frames',\
        '_gmed_rotation_axis',\
        '_gmed_camera_length',\
        '_gmed_camera_pix_size_x',\
        '_gmed_camera_pix_size_y',\
        '_diffrn_radiation_wavelength']
        vals = []
        for n, m in enumerate(search):
            location = data.find( m )
            lb, s, c = self._get_spacing( data, location )
            vals.append( data[ (location + s + 1) : (location + lb) ] )
        floats = [ float(i) for i in vals ]
        return floats


    def _store_exp_data( self, floats ):
        self.alpha = floats[0]
        self.alphastep = floats[1]
        self.nframes = floats[2]
        self.tilt_axis = floats[3]
        self.cam_length = floats[4]
        self.pixel_size[0] = floats[5]
        self.pixel_size[1] = floats[6]
        self.lamb = floats[7]
        return


def _save_project( output, location, name, format ):
    # Formats: '.phil', '.txt', '.CIF', '.pets2', etc.
    #try:
    #block for saving file
    savepath = location + '\\' + name + format
    print(savepath)
    file = open( savepath, 'x' )
    file.write( output )
    file.close( )
    #except:
    #    print( "Error: something went wrong saving the project." )
    return


def _calc_axis_angle( angle, x, y, z ):
    # Convert tilt axis from angle to axis-angle vector.
    # [x, y, z] is direction of rotation: -1, 0, or 1.
    vector = np.array([ x, y, z ])
    vector = vector * angle
    return vector


def _write_DIALS_project( vars ):
    # DIALS import.phil format.
    try:
        axis_angle = _calc_axis_angle( vars.tilt_axis, 1, 0, 0 )
    except:
        axis_angle = [0, 0, 0]
        print( 'Error: could not calculate tilt axis.' )
    output = ''\
    'geometry {'+ '\n'\
    '  beam {'+ '\n'\
    '    probe = ' + vars.probe + '\n'\
    '    wavelength = ' + str(vars.lamb) + '\n'\
    '  }'+ '\n'\
    '  detector {'+ '\n'\
    '    panel {'+ '\n'\
    '      name = ' + vars.camera_name + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      material = ' + vars.material + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      pixel_size = ' + str(vars.pixel_size[0]) + ' ' + str(vars.pixel_size[1]) + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      image_size = ' + str(vars.image_size[0]) + ' ' + str(vars.image_size[1]) + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      trusted_range = ' + str(vars.trusted_range[0]) + ' '  + str(vars.trusted_range[1]) + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      gain = '+ str(vars.gain) + '\n'\
    '    }'+ '\n'\
    '    distance = ' + str(vars.cam_length) + '\n'\
    '    fast_slow_beam_centre = ' + str(vars.beam_center[0]) + ' ' + str(vars.beam_center[1]) + '\n'\
    '  }'+ '\n'\
    '  goniometer {'+ '\n'\
    '    axes = ' + str(axis_angle[0]) + ' ' + str(axis_angle[1]) +\
    ' ' + str(axis_angle[2]) + ' ' + '\n'\
    '  }'+ '\n'\
    '  scan {'+ '\n'\
    '    oscillation = '+ str(vars.alpha) + ' ' + str(vars.alphastep) + '\n'\
    '  }'+ '\n'\
    '}'
    return output


def _write_PETS2_project( vars, files_list ):
    # PETS2 project format.
    output = ''\
    'lambda ' + str(vars.lamb) + '\n'\
    'geometry ' + vars.geometry + '\n'\
    'Aperpixel ' + str(vars.scale) + '\n'\
    'phi ' + str(vars.semiangle) + '\n'\
    'omega ' + str(vars.tilt_axis) + '\n'\
    'noiseparameters 1 40 \n'\
    'reflectionsize ' + str(vars.refdia) + '\n'\
    'bin ' + str(vars.binning) + '\n'\
    'dstarmin ' + vars.dstarmin + '\n'\
    'dstarmax ' + vars.dstarmax + '\n'\
    'dstarmaxps ' + vars.dstarmaxps + '\n'\
    'center ' + str(vars.image_center[0]) + ' ' + str(vars.image_center[0]) + '\n'\
    'imagelist' + '\n'
    
    # Write list of files.
    for n in files_list:
        output += str(n) + '\n'
    
    output += 'endimagelist'
    
    return output

# Functions to write projects.
def create_DIALS_project( IS_stack, IS_length, save_path, cif_path, **kwargs ):
    '''
    Save IS data as a DIALS project.
    '''
    
    name = kwargs.get('name', 'exp')
    
    print( 'Starting.\n' )
    
    # Save files to folder.
    print( 'Saving files to: ' + str(save_path) + '\\DIALS' )
    _save_IS_as_stack( IS_stack, name, '.dm4', (save_path + '\\DIALS') )
    
    # Read in variables from experiment.
    exp_variables = DataReductionVariables()
    try:
        cif_data = exp_variables._read_CIF( cif_path )
        floats = exp_variables._get_exp_floats( cif_data )
        exp_variables._store_exp_data( floats )
    except:
        print("Error: something went wrong reading CIF.")
    
    exp_variables.image_center = [IS_stack.GetDimensionSize(0)/2, IS_stack.GetDimensionSize(1)/2]
    
    # Create DIALS import.phil.
    project_string = _write_DIALS_project( exp_variables )
    _save_project( project_string, (save_path + '\\DIALS' ), 'import', '.phil' )
    
    print( 'Finished.\n' )
    
    return


def create_PETS2_project( IS_stack, IS_length, save_path, cif_path, **kwargs ):
    '''
    Save IS data as a PETS2 project.
    '''
    
    name = kwargs.get('name', 'experiment')
    
    # Save files to folder.
    print( 'Starting.\n' )
    
    path = save_path + '\\PETS2'
    _does_directory_exist( path )
    
    path = path + '\\files'
    
    # Save files and return list of names.
    files = _save_files_to_folder( IS_stack, path, name,IS_length,'.tiff' )
    
    # Read in variables from experiment.
    exp_variables = DataReductionVariables()
    try:
        cif_data = exp_variables._read_CIF( cif_path )
        floats = exp_variables._get_exp_floats( floats )
        exp_variables._store_exp_data( cif_data )
    except:
        print( "Error: could not read CIF." )
    
    exp_variables.image_center = [IS_stack.GetDimensionSize(0)/2, IS_stack.GetDimensionSize(1)/2]
    
    # Create .pets2 file.
    project_string = _write_PETS2_project( exp_variables, files )
    _save_project( project_string, (save_path + '\\PETS2'), name, '.pts2' )
    
    print( 'Finished.\n' )
    
    return