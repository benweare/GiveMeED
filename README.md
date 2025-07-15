## GiveMeED

GiveMeED is an automatic data collection solution for 3DED on transmission electron microscopes.

GiveMeED has been used successfully with a JEOL 2100Plus TEM with Gatan OneView Camera and JEOL 2100F TEM with Gatan K3 camera. It should work with any TEM using a Gatan camera that has “In-Situ” (video) mode and an installation of DigitalMicrograph. 

## Reference 
These scripts are associated with the following publicatons, please include a citation in your own works if you found these scripts useful: 
http://arxiv.org/abs/2507.10247

## Usage Instructions for GiveMeED

Please see the associated preprint for greater context: http://arxiv.org/abs/2507.10247

When “Start 3DED” is pressed, GiveMeED rotates the TEM stage to the value entered in the “Start Angle” field. The beam blank is turned off and the camera begins recording data while the stage is rotated to the value entered in the “End Angle” field. Once rotation ends the beam is blanked and all data is saved. Pressing “Abort 3DED” will blank the beam and stop the camera recording. 3DED metadata is saved with the name entered in the “Sample name” field at the path entered in the “Path” field. The values in the “Variables” container are for later reference and do not affect data collection. The recorded metadata is a mixture of information pulled from the microscope during data collection and standard values that can be defined in the script. Modifying the metadata file to include/exclude information can be done by adding/removing lines in the “log_message” string.

The “Abort 3DED” button will blank the beam and stop the camera recording, and the script can also be stopped using the DigitalMicrograph kill script shortcut (default “ctrl + numlock”). GiveMeED can also be operated without a user interface in which case the variables discussed above are set in the script before executing it. The maximum tilt range of the microscope stage should be checked before attempting 3DED.

Step-by-step instructions for GiveMeED:

1.	Insert the camera in “In-Situ” mode and start the live view with the frame rate set to a suitable value. 
2.	In the camera control pane, check the following variables are set correctly: “save data path”, and “experiment name”. Ensure that the experiment has a unique name. In the GiveMeED UI the “Path” field should match “save data path”, and the “Sample Name” field should match the “experiment name”. 
3.	Confirm that the specimen is at eucentric height and remains visible over the tilt range entered into the “Tilt Range” container. Pressing the “Go to Start” and “Go to End” buttons will rotate the stage to the value in the corresponding box. “Tilt Neutral” sets the stage angle to 0 degrees. 
4.	Put the microscope into diffraction mode and press “Start 3DED” to perform data collection. Data and metadata is automatically saved to the file path in Step 2. 

## List of Scripts 
- GiveMeED
- AutoResRings
- writePETS2import

Some scripts are optionally available without a user interface. 
