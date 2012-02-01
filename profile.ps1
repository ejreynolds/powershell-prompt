# Just for fun...
Write-Host "I'm sorry, Erik.  I'm afraid I can't do that."

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

####
# Import Modules
Import-Module PsGet
Import-Module posh-git

####
# Fix where '~/' is...
# This does a few things... (some may not be necessary)
# 1) Sets the $env:Homepath to where I want my 'home' to be
# 2) Sets $env:Home to the same thing
# 3) Force sets '$HOME' to whatever $env:Home is (useful for programs and scripts)
# 4) Changes the Home property of the ProviderInfo object for the FileSystem provider
$env:Homepath = "C:\Users\ereynolds"				# Notice the lack of a trailing '\'.  This is important or else the '~' replacement won't work!
$env:Home = $env:Homepath
set-variable -name HOME -value (resolve-path $env:Home) -force
(get-psprovider FileSystem).Home = $HOME

set-content Function:\mklink "cmd /c mklink `$args"

####
# Setup BASH style alias
. ./aliases.ps1

alias gca="git commit -a"
alias gd="git diff"
alias gco="git checkout"
alias gs="git status -sb"
alias gpush="git push origin HEAD"
alias gpull="git pull --prune"

function glog {
  git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative
}
 
####
# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
   # our theme 
   $darkcyan = [ConsoleColor]::DarkCyan 
   #$magenta = [ConsoleColor]::Magenta
   $cyan = [ConsoleColor]::Cyan 
   $green = [ConsoleColor]::Green
   #$darkgreen = [ConsoleColor]::DarkGreen
    $realLASTEXITCODE = $LASTEXITCODE

    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

   write-host ([Environment]::UserName.ToLower()) -n -f $green
   write-host "@" -n -f @green
   write-host ([net.dns]::GetHostName()) -n -f $green
   write-host ' [' -n -f $darkcyan
   write-host (shorten-path (pwd).Path) -n -f $cyan
   write-host ']' -n -f $darkcyan
    #Write-Host($pwd) -nonewline
        
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus

    $LASTEXITCODE = $realLASTEXITCODE
    return ' '
}

# Shortens the path to something like C:/P/M/Foo (similar to what GVim does)
function shorten-path([string] $path) { 
   $loc = $path.Replace($HOME, '~') 
   # remove prefix for UNC paths 
   $loc = $loc -replace '^[^:]+::', '' 
   # make path shorter like tabs in Vim, 
   # handle paths starting with \\ and . correctly 
   return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2') 
}

if(Test-Path Function:\TabExpansion) {
    $teBackup = 'posh-git_DefaultTabExpansion'
    if(!(Test-Path Function:\$teBackup)) {
        Rename-Item Function:\TabExpansion $teBackup
    }

    # Set up tab expansion and include git expansion
    function TabExpansion($line, $lastWord) {
        $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
        switch -regex ($lastBlock) {
            # Execute git tab completion for all git-related commands
            "^$(Get-AliasPattern git) (.*)" { GitTabExpansion $lastBlock }
            "^$(Get-AliasPattern tgit) (.*)" { GitTabExpansion $lastBlock }
            # Fall back on existing tab expansion
            default { & $teBackup $line $lastWord }
        }
    }
}

Enable-GitColors

Pop-Location

Start-SshAgent -Quiet

# Sets the prompt location to the $HOME variable we tweaked above
Set-Location $HOME