## Aliases.ps1 -- to be dot-sourced from your profile
if($Host.Version.Major -ge 2) {
  function script:Resolve-Aliases {
      param($line)

      [System.Management.Automation.PSParser]::Tokenize($line,[ref]$null) | % {
         if($_.Type -eq "Command") {
            $cmd = @(Get-Command $_.Content)[0]
            if($cmd.CommandType -eq "Alias") {
               $line = $line.Remove( $_.StartColumn -1, $_.Length ).Insert( $_.StartColumn -1, $cmd.Definition )
            }
         }
      }
      $line
   }
}

function alias {
   # pull together all the args and then split on =
   $alias,$cmd = [string]::join(" ",$args).split("=",2) | % { $_.trim()}

   if($Host.Version.Major -ge 2) {
      $cmd = Resolve-Aliases $cmd
   }
   New-Item -Path function: -Name "Global:Alias$Alias" -Options "AllScope" -Value @"
Invoke-Expression '$cmd `$args'
###ALIAS###
"@ | out-null

   Set-Alias -Name $Alias -Value "Alias$Alias" -Description "A UNIX-style alias using functions" -Option "AllScope" -scope Global -passThru | out-null
}

function unalias([string]$Alias,[switch]$Force){ 
   if( (Get-Alias $Alias).Description -eq "A UNIX-style alias using functions" ) {
      Remove-Item "function:Alias$Alias" -Force:$Force
      Remove-Item "alias:$alias" -Force:$Force
      if($?) {
         "Removed alias '$Alias' and accompanying function"
      }
   } else {
      Remove-Item "alias:$alias" -Force:$Force
      if($?) {
         "Removed alias '$Alias'"
      }
   }
}