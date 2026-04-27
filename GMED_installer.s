// Script to install GMED to DigitalMicrograph, as scripts or as a package.
// Note: must install Python module to DigitalMicrograph venv seperately.

string script_path = "\\path\\to\\files"
string script_name = "\\GiveMeED.s"
string package = "gmed"
/*
AddScriptFileToMenu( (script_path + script_name), "GiveMeED", "3DED","", 0 )

script_name = "\\export_insitu.s"
AddScriptFileToMenu( (script_path + script_name), "Export InSitu", "3DED","", 0 )

script_name = "\\Go2Alpha.s"
AddScriptFileToMenu( (script_path + script_name), "Go2Alpha", "3DED","", 0 )

script_name = "\\AutoResolutionRings.s"
AddScriptFileToMenu( (script_path + script_name), "AutoResolutionRings", "3DED","", 0 )
*/

// Install as a package.
AddScriptFileToPackage( (script_path + script_name),package, 0, "user_plugin", "GiveMeED", "3DED","", 0 )

script_name = "\\ExportInSitu.s"
AddScriptFileToPackage( (script_path + script_name),package, 0, "user_plugin", "Export Insitu", "3DED","", 0 )

script_name = "\\Go2Alpha.s"
AddScriptFileToPackage( (script_path + script_name),package, 0, "user_plugin", "Go2Alpha", "3DED","", 0 )

script_name = "\\AutoResolutionRings.s"
AddScriptFileToPackage( (script_path + script_name),package, 0, "user_plugin", "AutoResolutionRings", "3DED","", 0 )
