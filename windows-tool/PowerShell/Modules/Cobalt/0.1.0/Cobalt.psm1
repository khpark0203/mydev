# Module created by Microsoft.PowerShell.Crescendo
Function Get-WinGetSource
{
[CmdletBinding()]

param(
[Parameter()]
[string]$Name
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = '--name='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ($output)
                        if ($output) {
                            $output | ConvertFrom-Json
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "source"
        "export"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Return WinGet package sources

.PARAMETER Name
Source Name



#>
}

Function Register-WinGetSource
{
[CmdletBinding()]

param(
[Parameter(Mandatory=$true)]
[string]$Name,
[Parameter(Mandatory=$true)]
[string]$Argument
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = '--name='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Argument = @{ OriginalName = '--arg='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ($output)
                        if ($output) {
                            if ($output[-1] -ne 'Done') {
                                Write-Error ($output -join "`r`n")
                            }
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "source"
        "add"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Register a new WinGet package source

.PARAMETER Name
Source Name


.PARAMETER Argument
Source Argument



#>
}

Function Unregister-WinGetSource
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
[string]$Name
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = '--name='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ($output)
                        if ($output) {
                            if ($output[-1] -match 'Did not find a source') {
                                Write-Error ($output -join "`r`n")
                            }
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "source"
        "remove"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Unegister an existing WinGet package source

.PARAMETER Name
Source Name



#>
}

Function Install-WinGetPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$ID,
[Parameter()]
[switch]$Exact,
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Source,
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Version
    )

BEGIN {
    $__PARAMETERMAP = @{
        ID = @{ OriginalName = '--id='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Version = @{ OriginalName = '--version='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
    param ($output)
    if ($output) {
        if ($output -match 'failed') {
            # Only show output that matches or comes after the 'failed' keyword
            Write-Error ($output[$output.IndexOf($($output -match 'failed' | Select-Object -First 1))..($output.Length-1)] -join "`r`n")
        } else {
            $output | ForEach-Object {
                if ($_ -match 'Found .+ \[(?<id>[\S]+)\] Version (?<version>[\S]+)' -and $Matches.id -and $Matches.version) {
                        [pscustomobject]@{
                            ID = $Matches.id
                            Version = $Matches.version
                        }
                }
            }
        }
    }
 } }
    }
}
PROCESS {
    $__commandArgs = @(
        "install"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--silent"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Install a new package with WinGet

.PARAMETER ID
Package ID


.PARAMETER Exact
Search by exact package name


.PARAMETER Source
Package Source


.PARAMETER Version
Package Version



#>
}

Function Get-WinGetPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$ID,
[Parameter()]
[switch]$Exact,
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Source
    )

BEGIN {
    $__PARAMETERMAP = @{
        ID = @{ OriginalName = '--id='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                param ( $output )

                $language = (Get-UICulture).Name

                $languageData = try {
                    # We have to trim the leading BOM for .NET's XML parser to correctly read Microsoft's own files - go figure
                    ([xml](((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/winget-cli/master/Localization/Resources/$language/winget.resw" -ErrorAction Stop ).Content -replace "\uFEFF", ""))).root.data
                } catch {
                    # Fall back to English if a locale file doesn't exist
                    (
                        ('SearchName','Name'),
                        ('SearchID','Id'),
                        ('SearchVersion','Version'),
                        ('AvailableHeader','Available'),
                        ('SearchSource','Source')
                    ) | ForEach-Object {[pscustomobject]@{name = $_[0]; value = $_[1]}}
                }

                $nameHeader = $output -Match "^$($languageData | Where-Object name -eq SearchName | Select-Object -ExpandProperty value)"

                if ($nameHeader) {

                    $headerLine = $output.IndexOf(($nameHeader | Select-Object -First 1))

                    if ($headerLine -ne -1) {
                        $idIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq SearchID | Select-Object -ExpandProperty value))
                        $versionIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq SearchVersion | Select-Object -ExpandProperty value))
                        $availableIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq AvailableHeader | Select-Object -ExpandProperty value))
                        $sourceIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq SearchSource | Select-Object -ExpandProperty value))

                        # Stop gathering version data at the 'Available' column if it exists, if not continue on to the 'Source' column (if it exists)
                        $versionEndIndex = $(
                            if ($availableIndex -ne -1) {
                                $availableIndex
                            } else {
                                $sourceIndex
                            }
                        )

                        # The -replace cleans up errant characters that come from WinGet's poor treatment of truncated columnar output
                        $output -replace '[^i\p{IsBasicLatin}]',' ' | Select-Object -Skip ($headerLine+2) | ForEach-Object {
                            $package = [ordered]@{
                                ID = $_.SubString($idIndex,$versionIndex-$idIndex).Trim()
                            }

                            # I'm so sorry, blame WinGet
                            # If neither the 'Available' or 'Source' column exist, gather version data to the end of the string
                            $package.Version = $(
                                if ($versionEndIndex -ne -1) {
                                    $_.SubString($versionIndex,$versionEndIndex-$versionIndex)
                                } else {
                                    $_.SubString($versionIndex)
                                }
                            ).Trim() -replace '[^\.\d]'

                            # If the 'Source' column was included in the output, include it in our output, too
                            if (($sourceIndex -ne -1) -And ($_.Length -ge $sourceIndex)) {
                                $package.Source = $_.SubString($sourceIndex).Trim() -split ' ' | Select-Object -Last 1
                            }

                            [pscustomobject]$package
                        }
                    }
                }
             } }
    }
}
PROCESS {
    $__commandArgs = @(
        "list"
        "--accept-source-agreements"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Get a list of installed WinGet packages

.PARAMETER ID
Package ID


.PARAMETER Exact
Search by exact package name


.PARAMETER Source
Package Source



#>
}

Function Find-WinGetPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$ID,
[Parameter()]
[switch]$Exact,
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Source
    )

BEGIN {
    $__PARAMETERMAP = @{
        ID = @{ OriginalName = '--id='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                param ( $output )

                $language = (Get-UICulture).Name

                $languageData = try {
                    # We have to trim the leading BOM for .NET's XML parser to correctly read Microsoft's own files - go figure
                    ([xml](((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/winget-cli/master/Localization/Resources/$language/winget.resw" -ErrorAction Stop ).Content -replace "\uFEFF", ""))).root.data
                } catch {
                    # Fall back to English if a locale file doesn't exist
                    (
                        ('SearchName','Name'),
                        ('SearchID','Id'),
                        ('SearchVersion','Version'),
                        ('AvailableHeader','Available'),
                        ('SearchSource','Source')
                    ) | ForEach-Object {[pscustomobject]@{name = $_[0]; value = $_[1]}}
                }

                $nameHeader = $output -Match "^$($languageData | Where-Object name -eq SearchName | Select-Object -ExpandProperty value)"

                if ($nameHeader) {

                    $headerLine = $output.IndexOf(($nameHeader | Select-Object -First 1))

                    if ($headerLine -ne -1) {
                        $idIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq SearchID | Select-Object -ExpandProperty value))
                        $versionIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq SearchVersion | Select-Object -ExpandProperty value))
                        $availableIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq AvailableHeader | Select-Object -ExpandProperty value))
                        $sourceIndex = $output[$headerLine].IndexOf(($languageData | Where-Object name -eq SearchSource | Select-Object -ExpandProperty value))

                        # Stop gathering version data at the 'Available' column if it exists, if not continue on to the 'Source' column (if it exists)
                        $versionEndIndex = $(
                            if ($availableIndex -ne -1) {
                                $availableIndex
                            } else {
                                $sourceIndex
                            }
                        )

                        # The -replace cleans up errant characters that come from WinGet's poor treatment of truncated columnar output
                        $output -replace '[^i\p{IsBasicLatin}]',' ' | Select-Object -Skip ($headerLine+2) | ForEach-Object {
                            $package = [ordered]@{
                                ID = $_.SubString($idIndex,$versionIndex-$idIndex).Trim()
                            }

                            # I'm so sorry, blame WinGet
                            # If neither the 'Available' or 'Source' column exist, gather version data to the end of the string
                            $package.Version = $(
                                if ($versionEndIndex -ne -1) {
                                    $_.SubString($versionIndex,$versionEndIndex-$versionIndex)
                                } else {
                                    $_.SubString($versionIndex)
                                }
                            ).Trim() -replace '[^\.\d]'

                            # If the 'Source' column was included in the output, include it in our output, too
                            if (($sourceIndex -ne -1) -And ($_.Length -ge $sourceIndex)) {
                                $package.Source = $_.SubString($sourceIndex).Trim() -split ' ' | Select-Object -Last 1
                            }

                            [pscustomobject]$package
                        }
                    }
                }
             } }
    }
}
PROCESS {
    $__commandArgs = @(
        "search"
        "--accept-source-agreements"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Find a list of available WinGet packages

.PARAMETER ID
Package ID


.PARAMETER Exact
Search by exact package name


.PARAMETER Source
Package Source



#>
}

Function Update-WinGetPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$ID,
[Parameter()]
[switch]$Exact,
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Source,
[Parameter()]
[switch]$All
    )

BEGIN {
    $__PARAMETERMAP = @{
        ID = @{ OriginalName = '--id='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        All = @{ OriginalName = '--all'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
    param ($output)
    if ($output) {
        if ($output -match 'failed') {
            # Only show output that matches or comes after the 'failed' keyword
            Write-Error ($output[$output.IndexOf($($output -match 'failed' | Select-Object -First 1))..($output.Length-1)] -join "`r`n")
        } else {
            $output | ForEach-Object {
                if ($_ -match 'Found .+ \[(?<id>[\S]+)\] Version (?<version>[\S]+)' -and $Matches.id -and $Matches.version) {
                        [pscustomobject]@{
                            ID = $Matches.id
                            Version = $Matches.version
                        }
                }
            }
        }
    }
 } }
    }
}
PROCESS {
    $__commandArgs = @(
        "upgrade"
        "--accept-source-agreements"
        "--silent"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Updates an installed package to the latest version

.PARAMETER ID
Package ID


.PARAMETER Exact
Search by exact package name


.PARAMETER Source
Package Source


.PARAMETER All
Upgrade all packages



#>
}

Function Uninstall-WinGetPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$ID,
[Parameter()]
[switch]$Exact,
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Source
    )

BEGIN {
    $__PARAMETERMAP = @{
        ID = @{ OriginalName = '--id='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ($output)
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "uninstall"
        "--accept-source-agreements"
        "--silent"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Uninstall an existing package with WinGet

.PARAMETER ID
Package ID


.PARAMETER Exact
Search by exact package name


.PARAMETER Source
Package Source



#>
}

Export-ModuleMember -Function Get-WinGetSource, Register-WinGetSource, Unregister-WinGetSource, Install-WinGetPackage, Get-WinGetPackage, Find-WinGetPackage, Update-WinGetPackage, Uninstall-WinGetPackage
