# skypeNumbers
 26/NOV/2018 - Show all numbers used and spare that are available in a Skype4Business on-prem environment


v0.6.5 - 18/JAN/2022 modified for GitHub

USAGE example:

Show Everything!

	Get-SkypeNumbers


Show the numbers in Dublin that are not in use.

	Get-SkypeNumbers -LocationLimit "DUBLIN" -TypeLimit "SPARE"


Example Output

	Number        Ext  Name                         Type         Location   
	------        ---  ----                         ----         --------  
	+35316000000  0000 Recption                     Workflow     DUBLIN     
	+35316000001  0001 Mike                         User         DUBLIN     
	+35316000002  0002 Stephen                      User         DUBLIN     
	+35316000003  0003                              SPARE        DUBLIN     
	+35316000004  0004 Jack                         User         DUBLIN     
	+35316000005  0005 Canteen                      CommonArea   DUBLIN     
	+35316000006  0006                              SPARE        DUBLIN     
	+35316000007  0007                              SPARE        DUBLIN