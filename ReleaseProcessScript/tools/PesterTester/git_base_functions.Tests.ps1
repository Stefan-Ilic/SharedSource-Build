﻿. $PSScriptRoot"\..\Core\git_base_functions.ps1"
. $PSScriptRoot"\Test_Functions.ps1"

$TestDirName = "GitUnitTestDir"
$PseudoRemoteTestDir = "RemoteTestDir"

Describe "git_base_functions" {
    
    BeforeEach {
      Get-Config-File

      Test-Create-Repository $TestDirName
      cd "$($PSScriptRoot)\\$($TestDirName)"
    }

    AfterEach {
      cd $PSScriptRoot
      Remove-Item -Recurse -Force $TestDirName
      Remove-Item -Recurse -Force $PseudoRemoteTestDir 2>&1 | Out-Null
    }

    Context "Get-Branch-Exists" {
        It "Get-Branch-Exists_BranchExists_ReturnTrue" {
            git checkout -b "newBranch" --quiet
        
            Get-Branch-Exists "newBranch" | Should Be $TRUE
        }
       
        It "Get-Branch-Exists_BranchDoesNotExists_ReturnFalse" {
            Get-Branch-Exists "notExistingBranch" | Should Be $FALSE
        }
    }

    Context "Get-Branch-Exists-Remote" {
        It "Get-Branch-Exists-Remote_BranchExists_ReturnTrue" {
            git checkout -b "newBranch" --quiet
            Test-Add-Commit
            Test-Create-And-Add-Remote $TestDirName $PseudoRemoteTestDir
            cd "$($PSScriptRoot)\$($PseudoRemoteTestDir)"

            Get-Branch-Exists-Remote "$($PSScriptRoot)\$($TestDirName)" "newBranch" | Should Be $TRUE
        }

        It "Get-Branch-Exists-Remote_BranchDoesNotExists_ReturnFalse" {
            Test-Create-And-Add-Remote $TestDirName $PseudoRemoteTestDir
            cd "$($PSScriptRoot)\$($PseudoRemoteTestDir)"
            git checkout -b "notExistingOnRemote" --quiet


            Get-Branch-Exists-Remote "$($PSScriptRoot)\\$($TestDirName)" "notExistingOnRemote" | Should Be $FALSE
        }
    }

    Context "Get-Tag-Exists" {
        It "Get-Tag-Exists_TagExists_ReturnTrue" {
            git tag -a "newTag" -m "newTag" 2>&1 > $NULL

            Get-Tag-Exists "newTag" | Should Be $TRUE
        }
        
        It "Get-Tag-Exists_TagDoesNotExist_ReturnFalse" {
            Get-Tag-Exists "notExistingTag" | Should Be $FAlSE
        }
    }

    Context "Is-On-Branch" {
        It "Is-On-Branch_OnRightBranch_ReturnTrue" {
            Is-On-Branch "master" | Should Be $TRUE
        }

        It "Is-On-Branch_NotOnRightBranch_ReturnFalse" {
            Is-On-Branch "randomBranch" | Should Be $FALSE
        }

        It "Is-On-Branch-OnSubBranch_ReturnTrue" {
            git checkout -b "support/test" 2>&1 | Out-Null

            Is-On-Branch "support/" | Should Be $TRUE
        }

        It "Is-On-Branch_OnSubBranch_CalledWithoutSlash_ReturnFalse" {
            git checkout -b "support/test" 2>&1 | Out-Null

            Is-On-Branch "support" | Should Be $FALSE
        }
    }

    Context "Check-Branch-Up-To-Date" {
        It "Check-Branch-Up-To-Date_BrancheBehind_ShouldThrowException" {
            git checkout master --quiet
            Test-Add-Commit
            Test-Create-And-Add-Remote $TestDirName $PseudoRemoteTestDir

            git checkout master --quiet
            Test-Add-Commit

            cd "$($PSScriptRoot)\$($PseudoRemoteTestDir)"
            git checkout master --quiet
            
            $RemoteUrl = "$($PSScriptRoot)\$($TestDirName)"
            $RemoteName = "testRemote"
            Test-Replace-Config-With-New-Remote $RemoteUrl $RemoteName

            { Check-Branch-Up-To-Date "master" } | Should Throw "Need to pull, local 'master' branch is behind on repository '$($RemoteName)'."
        }

        It "Check-Branch-Up-To-Date_BranchesDiverged_ShouldThrowException" {
            git checkout master --quiet
            Test-Add-Commit
            Test-Create-And-Add-Remote $TestDirName $PseudoRemoteTestDir

            git checkout master --quiet
            Test-Add-Commit "--amend"


            cd "$($PSScriptRoot)\$($PseudoRemoteTestDir)"
            git checkout master --quiet
            
            $RemoteUrl = "$($PSScriptRoot)\$($TestDirName)"
            $RemoteName = "testRemote"
            Test-Replace-Config-With-New-Remote $RemoteUrl $RemoteName



            { Check-Branch-Up-To-Date "master" } | Should Throw "'master' diverged, need to rebase at repository '$($RemoteName)'."
        }

        It "Check-Branch-Up-To-Date_RemoteBranchBehind_ShouldNotThrow" {
            git checkout master --quiet
            Test-Add-Commit
            Test-Create-And-Add-Remote $TestDirName $PseudoRemoteTestDir

            cd "$($PSScriptRoot)\$($PseudoRemoteTestDir)"
            git checkout master --quiet
            Test-Add-Commit

            $RemoteUrl = "$($PSScriptRoot)\$($TestDirName)"
            Test-Replace-Config-With-New-Remote $RemoteUrl "testRemote"


            { Check-Branch-Up-To-Date "master" } | Should Not Throw 
        }

        It "Check-Branch-Up-To-Date_BranchesEqual_ShouldNotThrow" {
            git checkout master --quiet
            Test-Add-Commit
            Test-Create-And-Add-Remote $TestDirName $PseudoRemoteTestDir

            cd "$($PSScriptRoot)\$($PseudoRemoteTestDir)"
            git checkout master --quiet

            $RemoteUrl = "$($PSScriptRoot)\$($TestDirName)"
            Test-Replace-Config-With-New-Remote $RemoteUrl "testRemote"

            { Check-Branch-Up-To-Date "master" } | Should Not Throw 
        }
    }
}