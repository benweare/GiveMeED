## GiveMeED

GiveMeED is an automatic data collection solution for 3DED on transmission electron microscopes.

GiveMeED has been used successfully with a JEOL 2100Plus TEM with Gatan OneView Camera and JEOL 2100F TEM with Gatan K3 camera. It should work with any TEM using a Gatan camera that has “In-Situ” (video) mode and an installation of DigitalMicrograph. 

## Reference 
These scripts are associated with the following publicatons, please include a citation in your own works if you found these scripts useful: 
http://arxiv.org/abs/2507.10247

## Installation

GiveMeED can be used in three ways:

1) As a standalone script. Open the script in DigitalMicrograph and press execute to get started.

2) Installed as scripts, e.g. by using the supplied installation script within DigitalMicrograph.

3) Installed as a plugin, either adding the supplied plugin to DigitalMicrograph or using the supplied script to create a plugin.


Installing GiveMeED to DigitalMicrograph may be preferred.

## Usage Instructions for GiveMeED

<img src="https://github.com/benweare/GiveMeED/blob/main/assets/GUI.png" width="400" alt="GMED Graphical User Interface" />

Please see the associated preprint for greater context: http://arxiv.org/abs/2507.10247

When “Start 3DED” is pressed, GiveMeED rotates the TEM stage to the value entered in the “Start Angle” field. The beam blank is turned off and the camera begins recording data while the stage is rotated to the value entered in the “End Angle” field. Once rotation ends the beam is blanked and all data is saved. Pressing “Abort 3DED” will blank the beam and stop the camera recording. 3DED metadata is saved with the name entered in the “Sample name” field at the path entered in the “Path” field. The values in the “Variables” container are for later reference and do not affect data collection. The recorded metadata is a mixture of information pulled from the microscope during data collection and standard values that can be defined in the script. Modifying the metadata file to include/exclude information can be done by adding/removing lines in the “log_message” string.

The “Abort 3DED” button will blank the beam and stop the camera recording, and the script can also be stopped using the DigitalMicrograph kill script shortcut (default “ctrl + numlock”). GiveMeED can also be operated without a user interface in which case the variables discussed above are set in the script before executing it. The maximum tilt range of the microscope stage should be checked before attempting 3DED.

Step-by-step instructions for GiveMeED:

1.	Insert the camera in “In-Situ” mode and start the live view with the frame rate set to a suitable value. 
2.	In the camera control pane, check the following variables are set correctly: “save data path”, and “experiment name”. Ensure that the experiment has a unique name. In the GiveMeED UI the “Path” field should match “save data path”, and the “Sample Name” field should match the “experiment name”. 
3.	Confirm that the specimen is at eucentric height and remains visible over the tilt range entered into the “Tilt Range” container. Pressing the “Go to Start” and “Go to End” buttons will rotate the stage to the value in the corresponding box. “Tilt Neutral” sets the stage angle to 0 degrees. 
4.	Put the microscope into diffraction mode and press “Start 3DED” to perform data collection. Data and metadata is automatically saved to the file path in Step 2. 

## ExportInsitu

<img src="https://github.com/benweare/GiveMeED/blob/main/assets/GUI2.png" width="400" alt="ExportInSitu Graphical User Interface" />

ExportInSitu provides a convienient way to convert DigitialMicrograph's InSitu file format to a format compatible with data reduction software. Currently PETS2 and DIALS formats are supported, but this could be easily extended in the future.

It works by opening the InSitu dataset in DigitalMicrograph as a stack. At this point the user may perform post-capture processing, such as binning or cropping. The dataset is then exported as a .dm4 stack, a directory of .tif files, or both. The experimental metadata is read from the CIF written by GiveMeED, which is used to write "import.phil" or .pets2 project. 

ExportInSitu uses the included Python module export_insitu. This can be installed into DigitalMicrograph's Python virtual environment, or the module can be imported at runtime by setting the path to the module location witin ExportInSitu.

## List of Scripts 
- GiveMeED
- AutoResRings
- GMED_installer
- ExportInSitu

Some scripts are optionally available without a user interface. 
