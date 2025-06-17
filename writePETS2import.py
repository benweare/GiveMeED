# write_PETS2_import.py
# BLW @ nmRC, 27-09-24
#
# This script writes a PETS2 project file. It can be run from DigitalMicrograph, or with a standard Python installation. It is designed to work
# with In-Situ datasets exported from Digital Micrograph in .tif format.
# The script is designed such that most variables can be set up as standard for a given microscope, then the first block of variables can be
# changed on an experiment-by-experiment basis.
# A GUI version of this script is available for use with Digital Micrograph.
# If you found this script useful please cite: Weare et al, DOI
#
#variables
alpha = -60 #tiltx at start of series
alphastep = 0.05522
beta = 0.00 #tilty at start of series
nframes = 1000
location = 'X:\\'#full path with trailing \
name = 'ISData_01'

#standard variables
scaleinfo =  0.00292111#Angstroms
refdia = 15#reflection diameter

wavelength = '0.0251' #200kV
tiltaxis = 245 
binning = 1 #binning applied by PETS
semiangle = alphastep / 2

geometry = 'continuous'
dstarmax = '1.2'
dstarmaxps = '1.2'
dstarmin = '0.2'
centX = 50
centY = 500

#image info
imgnumber = 0
extension = '.tif'

#beam stop
beamstop_coordinates_1 = '632 443'
beamstop_coordinates_2 = '649 475'
beamstop_coordinates_3 = '11 746'
beamstop_coordinates_4 = '8 703'

#output file
output = 'lambda ' + wavelength + '\n'
output += 'geometry ' + geometry + '\n'
output += 'Aperpixel ' + str(scaleinfo) + '\n'
output += 'phi ' + str(semiangle) + '\n'
output += 'omega ' + str(tiltaxis) + '\n'
output += 'noiseparameters 1 40 \n'
output += 'reflectionsize ' + str(refdia) + '\n'
output += 'bin ' + str(binning) + '\n'
output += 'dstarmin ' + dstarmin + '\n'
output += 'dstarmax ' + dstarmax + '\n'
output += 'dstarmaxps ' + dstarmaxps + '\n'
output += 'center ' + str(centX) + ' ' + str(centY) + '\n'
output += 'beamstop ' + '\n'
output += beamstop_coordinates_1 + '\n'
output += beamstop_coordinates_2 + '\n'
output += beamstop_coordinates_3 + '\n'
output += beamstop_coordinates_4 + '\n'
output += 'endbeamstop ' + '\n'

output += 'imagelist' + '\n'
#for loop for writing images; have to interate frame numbers
for n in range(nframes):
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
    imagename = location + name + '_' + leadingzeros + str(imgnumber) + extension
    if n == 0:
        alpha = alpha
    else:
        alpha = alpha + alphastep
    alpharound = round(alpha, 2)
    output += '"' + imagename+ '"' + ' ' + str(alpharound) + ' ' + str(beta) + '\n'
    imgnumber = imgnumber + 1

output += 'endimagelist' + '\n'
print(output)

try:
    #block for saving file
    savepath = location + name + '.pts2'
    file = open( savepath, 'x' )
    file.write( output )
    file.close( )
except:
    print( "something went wrong saving file" )
