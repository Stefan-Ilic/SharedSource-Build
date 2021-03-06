function Test-Create-Repository ($DirName)
{
  New-Item $DirName -ItemType directory
  cd $DirName
  git init
  Test-Add-Commit
  cd ".."
}

function Test-Add-Commit ($Amend)
{
  $RandomValue = Get-Random
    
  New-Item $RandomValue -ItemType File -Value $RandomValue
  git add .
  git commit -m $RandomValue $Amend
}

function Test-Create-And-Add-Remote ($TestBaseDir, $TestDirName, $PseudoRemoteTestDir)
{
  cd $TestBaseDir

  New-Item $TestBaseDir\$PseudoRemoteTestDir -ItemType directory
  cd "$TestBaseDir\$PseudoRemoteTestDir"
  $FileName = "file:///$TestBaseDir/$TestDirName"
  git clone $FileName "." 2>&1 > $NULL

  cd "$TestBaseDir\$TestDirName"
}

function Test-Mock-All-Jira-Functions()
{
  Mock Jira-Create-Version { return $TRUE }
  Mock Jira-Get-Current-Version { return "1.2.3" }
  Mock Jira-Release-Version { return $TRUE }
  Mock Jira-Check-Credentials { return $TRUE }
}

function Initialize-GitRepository ($Dir)
{
  Copy-Item releaseProcessScript.config -Destination $Dir

  Set-Location $Dir
  $MarkerName = ".BuildProject"
  $MarkerTemplate = 
"<?xml version=`"1.0`" encoding=`"utf-8`"?>
<!--Marks the path fo the releaseProcessScript config file-->
<configFile>
  <path>releaseProcessScript.config</path>
  <buildToolsVersion>$($BuildToolsVersion)</buildToolsVersion>
</configFile>"

  New-Item -Type file -Name $MarkerName -Value $MarkerTemplate

  git init --quiet
  git add .
  git commit -m "First commit"
  git tag -a "v1.0.0" -m "v1.0.0"
  git checkout master --quiet

  New-Item -Name "TestFile.txt" -ItemType "file" -Value "SomeValue"

  git add .
  git commit -m "Second commit"
  git tag -a "v1.1.0" -m "v1.1.0"
}

function Get-Git-Logs ($Dir)
{
  Set-Location $Dir
  return [string](git log --all --graph --oneline --decorate --pretty=format:'%d %s')
}

function Initialize-Test ($Name)
{
  Set-Location $ReferenceDir
  . "$($ScriptRoot)\GitCommandsForReferenceDir\$Name\Initialize.ps1"
  . "$($ScriptRoot)\GitCommandsForReferenceDir\$Name\Reference.ps1"

  Set-Location $TestDir
  . "$($ScriptRoot)\GitCommandsForReferenceDir\$Name\Initialize.ps1"
}
