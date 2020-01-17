<#
.Synopsis
Creates a Powershell process with an environment with dot-sourced content from the .environment folder.

.Description
To use it create a folder caled .environment and fulfill by your content t oset up the environment.
Calling Env at the folder with a .environment folder will create a new Powershell process and dot source
everything that exists at the .environment folder

.Example
PS > Env  - Will create a new console at the same window

PS > Env "some PS code to execute"   - Will create a new console, execute the code and exit

#>

# =============================================================================
# Private stuff
# =============================================================================

function Get-PS
{
    if ($PSVersionTable.PSVersion.Major -gt 5)
    {
        return "pwsh"
    }
    else
    {
        return "powershell"
    }
}

function EnvStart($code, $NoExit)
{


    $start_args = @()
    $start_args += "-NoLogo"

    #adding a command key
    if ($NoExit)
    { $start_args += "-NoExit", "-Command", "echo '`nPS Subprocess with the Environment`n=============started==============`n';" }
    else
    { $start_args += "-Command" }

    #adding a command
    if ($code -and ($code) -ne "")
    { $start_args += $code }
    Start-Process -NoNewWindow -Wait -FilePath $(Get-PS) -ArgumentList $start_args
    echo "`n=============closed=======env========`nPS Subprocess with the Environment`n"
}

$env_main_codeblock=@"
Get-ChildItem `".\.environment\*.ps1`" | ForEach-Object { .`$_ };
Set-Variable -Name "EnvRootDir" -Value $(Get-Location)
"@
# =============================================================================
# Public
# =============================================================================
function Env($code)
{
    $env = Test-Path -Path "$(Get-Location)\.environment\*.ps1" # TODO move this check into $env_main_codeblock
    if (!$env) # TODO move this check into $env_main_codeblock
    {
        Write-Verbose "No environment found"
        return
    }

    if ($code)
    { EnvStart "$env_main_codeblock; $code" -NoExit 0 }
    else
    { EnvStart "$env_main_codeblock" -NoExit 1 }

}

function Env-Init
{
    $env = Test-Path -Path "$(Get-Location)\.environment\*.ps1"
    if ($env)
    {
        Write-Output "./.environment folder is already has scripts";
        return
    }
    New-Item -ItemType Directory -Path "$(Get-Location)\.environment" -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path "$(Get-Location)\.environment\init.ps1"
    $init_ps1_content = @'
# It is a basic Env template. For more information see: https://github.com/an-dr/Env

$host.ui.RawUI.WindowTitle = $(Get-Item -Path $(Get-Location)).BaseName # WindowsTitle is CWD name
'@
    $init_ps1_path = "$(Get-Location)\.environment\init.ps1"
    Add-Content $init_ps1_path $init_ps1_content
}

function Env-Open
{
    Start-Process explorer -ArgumentList "$(Get-Location)\.environment"

}

Export-ModuleMember -Function 'Env'
Export-ModuleMember -Function 'Env-Init'
Export-ModuleMember -Function 'Env-Open'
