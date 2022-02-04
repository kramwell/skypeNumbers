#Written by KramWell.com - 26/NOV/2018
#Show all numbers used and spare that are available in a Skype4Business on-prem environment

Param(
	[string]$TypeLimit,
	[string]$LocationLimit
)

function Get-UniqueExt {
    Param(
        [string]$Uri1,
        [string]$Uri2
    )

    $Reg = "^([0-9+])+$"

    if ([string]::IsNullOrEmpty($uri1) -and [string]::IsNullOrEmpty($Uri2)) { return "Two blank strings provided" }
    if ($Uri1 -eq $Uri2) { return $Uri1 }
    if ([string]::IsNullOrEmpty($uri1)) { return $Uri2 }
    if ([string]::IsNullOrEmpty($uri2)) { return $Uri1 }
    if ($Uri1.Length -ne $Uri2.Length) { return "Strings cannot be different lengths" }
    if (($Uri1 -notmatch $Reg) -or ($Uri2 -notmatch $Reg)) { return "Strings must be in the format '0123..' or '+123..'" }

    ($Uri1.Length-1)..0 | % {
        if ($Uri1[$_] -ne $Uri2[$_]) { $Diff = $_ }
    }

    $Start = $Uri1.Substring(0,$Diff)
    $Sub1 = $Uri2.Substring($Diff)
    $Sub2 = $Uri1.Substring($Diff)

    if ($Sub1 -lt $Sub2) {
        $Min = $Sub1 ; $Max = $Sub2
    } else {
        $Min = $Sub2 ; $Max = $Sub1
    }

    $FormatStr = "" ; 1..$Min.Length | % { $FormatStr += "0"}
    $Min..$Max | % { "$($Start)$($_.ToString($FormatStr))" }
}

#region Helper Functions
Function Get-CsAssignedURIs {
	$AllNumbers = @()
	$Users = Get-CsUser
	$Users | ? {$_.LineURI -ne ""} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.SipAddress ; Number = $_.LineURI ; Type = "User" }}
	$Users | ? {$_.PrivateLine -ne ""} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.SipAddress ; Number = $_.PrivateLine ; Type = "PrivateLine" }}
	Get-CsRgsWorkflow | Where-Object {$_.LineURI -ne ""} | Select Name,LineURI | %{$AllNumbers += New-Object PSObject -Property @{Name = $_.Name ; SipAddress = $_.PrimaryUri ; Number = $_.LineURI ; Type = "Workflow" }}
	Get-CsCommonAreaPhone -Filter {LineURI -ne $null} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.SipAddress ; Number = $_.LineURI ; Type = "CommonArea" }}
	#Get-CsAnalogDevice -Filter {LineURI -ne $null} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.SipAddress ; Number = $_.LineURI ; Type = "AnalogDevice" }}
	Get-CsExUmContact -Filter {LineURI -ne $null} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.SipAddress ; Number = $_.LineURI ; Type = "ExUmContact" }}
	Get-CsDialInConferencingAccessNumber -Filter {LineURI -ne $null} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.PrimaryUri ; Number = $_.LineURI ; Type = "DialInAccess" }}
	Get-CsTrustedApplicationEndpoint -Filter {LineURI -ne $null} | %{ $AllNumbers += New-Object PSObject -Property @{Name = $_.DisplayName ; SipAddress = $_.SipAddress ; Number = $_.LineURI ; Type = "ApplicationEndpoint" }}
	Return $AllNumbers
}

Function Get-SkypeNumbers {
    Param(
        [string]$TypeLimit,
        [string]$LocationLimit
    )

    #Set the number ranges here to scan, it will loop and check against records of already assigned numbers, this is mainly to show free numbers
    $NumRanges = @{

        "+35316000000" = "+35316000099" #DUBLIN
        "+353740000000" = "+353740000049" #LETTERKENNY
		"+35351300001" = "+35351300001" #WATERFORD MAINLINE
    }

    #region Process Data
    $AllNums = $NumRanges.Keys | % {
        Get-UniqueExt -Uri1 $_ -Uri2 $NumRanges[$_]
    }
    $S4BNums = Get-CsAssignedURIs
    $S4BNums | % { $_.Number = ($_.Number.Split(';')[0] -ireplace "tel:","") }

    $KT = @{}

    $S4BNums | % {
        $KT[$_.Number] = $_
    }

    $FullRecord = $AllNums | Sort | % {

        $Number = $_
        $Ext = $Number.Substring($Number.Length - 4)


        if ($KT[$_] -ne $null){
            $UseDetails = $KT[$_]
            $Name = $UseDetails.Name
            $Type = $UseDetails.Type
        }else{
            $Type = "SPARE"
            $Name = ""
        }

		#Set the numbers here to be picked up by the program so you can define locations

        if ($UseDetails.Number -Like "+3531600*"){
            $Location = "DUBLIN"
        }	
        if ($UseDetails.Number -Like "+35374000*"){
            $Location = "LETTERKENNY"
        }
        if ($UseDetails.Number -Like "+35351300001"){
            $Location = "WATERFORD"
        }
        [PSCustomObject]@{
            Number = $Number
            Ext = $Ext
            Name = $Name
            Type = $Type
            Location = $Location
        }
    }

    Return $FullRecord | Where-Object {$_.Type -Like "$TypeLimit*" -And $_.Location -Like "$LocationLimit*"} | Format-Table -AutoSize 
}

Get-SkypeNumbers -LocationLimit "$LocationLimit" -TypeLimit "$TypeLimit"

Read-Host -Prompt "`nPress Enter to exit"
	
Remove-PSSession $session -ErrorAction stop