12:52 19/03/2012
These files should be placed in the following location on build server:-
 C:\Program Files (x86)\MSBuild\TfL
(or location referenced by 

use the following in sqlproj file to include appropriate targets

<Import Project="$(MSBuildExtensionsPath)\Tfl\SqlProjAfterBuild.targets" Condition="Exists('$(MSBuildExtensionsPath)\Tfl\SqlProjAfterBuild.targets')"  /> 


