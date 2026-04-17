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

def _write_DIALS_project( vars ):
    # DIALS import.phil format.
    axis_angle = _calc_axis_angle( vars.tilt_axis, 1, 0, 0 )
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
    '      pixel_size = ' + str(vars.panel_size[0]) + ' ' + str(vars.panel_size[1]) + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      image_size = ' + str(vars.image_size[0]) + ' ' + str(vars.image_size[1]) + '\n'\
    '    }'+ '\n'\
    '    panel {'+ '\n'\
    '      trusted_range = ' + str(vars.trusted_range[0]) + str(vars.trusted_range[1]) + '\n'\
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

def _write_PETS2_project( vars ):
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
    imgnumber = 0
    extension = '.tif'
    for n in range(vars.nframes):
        #leading zeros
        if imgnumber < 10:
            leadingzeros = '00000'
        elif imgnumber > 9 and imgnumber < 100:
            leadingzeros = '0000'
        elif imgnumber > 99 and imgnumber < 1000:
            leadingzeros = '000'
        elif imgnumber > 999 and imgnumber < 10000:
            leadingzeros = '00'
    #    elif imgnumer > 9999:
    #        print("leading zeros incorrect")
    #        break
        imagename = vars.path + vars.name + '_' \
        + leadingzeros + str(imgnumber) + extension
        if n == 0:
            alpha = vars.alpha
        else:
            alpha = alpha + vars.alphastep
        alpharound = round(alpha, 2)
        output += '"' + imagename+ '"' + ' ' + str(alpharound)\
        + ' ' + str( vars.beta) + '\n'
        imgnumber = imgnumber + 1
    
    output += 'endimagelist' + '\n'
    return output

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


variables = DataReductionVariables()

#test = _write_DIALS_project( variables )

test = variables._read_CIF()
floats = variables._get_exp_floats( test )
variables._store_exp_data( floats )