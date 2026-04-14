# Python version of GMED
# Under dev
import DigitalMicrograph as DM
import numpy as np

# Global functions.
def _caculate_wavelength( HT ):
    E_k = HT*Constants.e
    lamb = Constants.h/(2*Constants.m_e*Constants.E_k*\
    (1+(Constants.E_k/(2*Constants.m_e*(Constants.c**2)))))**0.5
    return lamb

def _calculate_camera_length():
    # use camera_length eqn to calc real camera length from pixel size
    return

def _count_frames():
    # Count how many frames in IS dataset.
    return


class Constants():
    '''
    Class to contain some constants for calculations.
    '''
    c = 299792458
    h = 6.62607015e-34
    e = 1.602176634e-19
    m_e = 9.1093837139e-31

class Variables():
    '''
    Class to contain some variables.
    '''
    def __init__( self ):
        #self.display = DM.PyMicroscope.GetFrontImage()
        
        self.alpha_start = -60
        self.alpha_end = 60
        self.frame_rate = 175
        self.tilt_axis = -25.1
        
        self.exp_num = 0
        self.fiddle = 2.0
        self.came_sleep = 0.001
        self.file_check = 1
        
        self.name = 'GiveMeED'
        self.microscope = 'JEOL 2100Plus Transmission Electron Microscope'
        self.camera = 'Gatan OneView'
        self.source = 'LaB6'
        
        
        self.save_dir = 'X:\\'
        self.is_name = 'sample_name'
        self.log_ext = '.cif'
        self.notes = '[e.g. cryo 120 K]'
        self.sample_name = self.is_name
        self.isdatapath = self.is_name + self.sample_name
        
        self.start_angle
        self.end_angle
        self.time_1, self.time_2
        
        self.camid
        self.camera_length
        self.high_tension #=EMGetHT
        self.lamb = _caculate_wavelength( self.high_tension )
        self.date#=get date

class logFile():
    '''
    Class to write log files after 3DED.
    '''
    def get_file_list( self ):
        # Get list of files in folder, of a specific suffix.
        return
        
    def to_lower_case():
        # Put string in all lower case.
        return
    
    def get_unique_name( self ):
    # Use os or similar to check if file name exists.
        return
    
    def tag_is_data( self ):
        # Write metadata tags to IS dataset.
        return
    
    def format_date( self ):
        # Put date into correct format for log.
        return
    
    def create_output_cif( self ):
        output = "data_GMED"#+"\n"\
        
        "_audit_creation_date " + "?" + "\n"+\
        "_audit_creation_method " + "'Created by GMED'" + "\n"+\
        "_computing_data_collection " + Variables.name + "\n"+\
        "_diffrn_source " + Variables.source + "\n"+\
        "_diffrn_radiation_probe " + "electron" + "\n"+\
        "_diffrn_radiation_type electrons \n"+\
        "_diffrn_radiation_wavelength " + str(Variables.lamb) + "\n"+\
        "_diffrn_radiation_monochromator " + "'transmission electron microscope'" + "\n"+\
        "_diffrn_radiation_device " + "'transmission electron microscope'" + "\n"+\
        "_diffrn_radiation_device_type " + Variables.microscope + "\n"+\
        "_diffrn_detector " + "'CMOS camera'" + "\n"+\
        "_diffrn_detector_type " + Variables.camera + "\n"+\
        "_diffrn_measurement_method '3DED'"+ "\n"+\
        "_diffrn_source_voltage " + Variables.high_tension + "\n" +\
        "_diffrn_detector_details 'electron camera'" +"\n"+\
        "_cell_measurement_temperature ?" +"\n"+\
        "_diffrn_measurement_details" +"\n"#+\
        #";" +"\n"+\ #This line causing an indetation error for some reason?
        #"Save Location: " + Variables.isdatapath + "\n"+\
        #"IS Data: " + Variables.save_name + "\n"+\
        #"Spot Size: " + Variables.spot_size + "\n"+\
        #"Camera: " + camera_name + "\n"+\
        #"Camera length (mm): " + camera_length + "\n"+\
        #"Camera pixel size x/y (um): (" + phys_pixelsize_x + ", " + phys_pixelsize_y + ")\n"+\
        #"Scale (nm-1 px-1): " + scale_x + ", " + scale_y + "\n"+\
        #"Image size x/y (px): (" + ImageGetDimensionSize(img, 0) + ", " + ImageGetDimensionSize(img, 1) + ")\n"+\
        #"Date and time: " + timestamp + "\n"+\
        #"Start angle (deg): " + start_angle + "\n"+\
        #"End angle (deg): " + end_angle +  "\n"+\
        #"Rotation range (deg): " + (end_angle - start_angle) + "\n"+\
        #"Data collection time (s): " + total_time + "\n"+\
        #"Frame Rate (fps): " + frame_rate + "\n"+\
        #"Exposure (s): " + 1/frame_rate + "\n"+\
        #"Number of frames : " + no_frames + "\n"+\
        #"Angle per frame (deg): " + abs( end_angle - start_angle ) / no_frames + "\n"+\
        #"Rotation axis (deg): " + rotation_axis + "\n"+\
        #"Notes:" + Variables.notes + "\n"+\
        ";\n" 
        return output
    
    def write_output( self )
        '''
        Write metadata as a CIF.
        '''
        return

class DataCollection():
    '''
    Class for data collection functions.
    '''
    def continuous_tilt():
        # Python version, or execute as a DM script.
        return

class DMScripts():
    '''
    Class to contain DM scripts as Python strings.
    
    For functions that DM.PyMicroscope can't handle.
    '''
    pass
    
# UI elements.
# May have to execute as a DM script.