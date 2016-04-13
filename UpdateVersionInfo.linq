<Query Kind="Statements">
  <Reference>C:\Wintools\Console\NetFrameworkExtensions.dll</Reference>
</Query>

var currentQueryDirectoryName = Path.GetDirectoryName(Util.CurrentQueryPath);

var oldVersion     = "0.9.30";
var oldReleaseDate = "February 15, 2016";

var newVersion     = "0.9.31";
var newReleaseDate = "April 13, 2016";

// Readme.txt
FileUtility.TransformAllText(Path.Combine(currentQueryDirectoryName, "Readme.txt"), text => text.Replace(oldVersion + " released on " + oldReleaseDate, newVersion + " released on " + newReleaseDate));

// AcrylicSetup.nsi
FileUtility.TransformAllText(Path.Combine(currentQueryDirectoryName, "AcrylicSetup.nsi"), text => text.Replace("Name \"Acrylic DNS Proxy (" + oldVersion + ")\"", "Name \"Acrylic DNS Proxy (" + newVersion + ")\""));

// AcrylicVersionInfo.pas
FileUtility.TransformAllText(Path.Combine(currentQueryDirectoryName, "AcrylicVersionInfo.pas"), text => text.Replace("Number = '" + oldVersion + "'", "Number = '" + newVersion + "'").Replace("ReleaseDate = '" + oldReleaseDate + "'", "ReleaseDate = '" + newReleaseDate + "'"));