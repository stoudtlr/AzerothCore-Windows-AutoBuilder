#DefaultLocations

#Location that install executables for Cmake, Git, etc will be installed
$DownloadFolder = "C:\ACdownloads"

# BaseLocation is where all of the .git repositories will be downloaded
$BaseLocation = "C:\AzerothCore-WotLK"

# BuildFolder is where all those repositories will be compiled
$BuildFolder = "C:\Build"

# Choose what you want the root SQL password to be.This should be a strong password.
$SQLRootPassword = "123456"

# Download maps data from Github? REMEMBER, This is a large file!
# "Yes" to download maps data, "No" to skip maps data. If skipped remember to manually extract files
$Downloaddata = "Yes"
$AZCoreDataURL = "https://github.com/wowgaming/client-data/releases/download/v11/data.zip"

# PersonalServerFolder is where your finished product will be if you choose Option 6 to create your own custom server or repack.
# This folder contains all required files to run your server.
# Entire contents can be moved to another PC if desired or zipped and shared as a repack.
# This is only used if the "Create Repack" option is used
# You MUST do this if you plan to play on your built server.
# Otherwise all characters and progress are wiped next time you build a server
$PersonalServerFolder = "D:\AzerothCore-by-Luke-TEST"

###############################################
##      DO NOT EDIT ANYTHING BELOW THIS      ##
##  UNLESS YOU 100% KNOW WHAT YOU ARE DOING  ##
###############################################


Function Show-Menu {
    Write-Host "`n`n`n=============Windows-Auto-AC-Tool============="
    Write-Host "1: Install dependencies (Cmake, Git, MySql, etc)"
    Write-Host "2: Clone/Clean/Update AzerothCore Git Repo"
    Write-Host "3: Download PR to Test"
    Write-Host "4: Add custom modules"
    Write-Host "5: Build Server and database"
    Write-Host "6: Start Test Server"
    Write-Host "7: Create Repack/Personal Server (#5 must have already been done)"
    Write-Host "Q: Quit"
}

do {
    Show-Menu
    $Selection = Read-Host "`nEnter choice #"
    switch ($Selection) {
        #Install dependencies (Cmake, Git, MySql, etc)
        '1' {
            if (!(Test-Path -path $DownloadFolder)) {
                New-Item -path $DownloadFolder -ItemType Directory -Force
            }
            $GitURL = "https://api.github.com/repos/git-for-windows/git/releases/latest"
            $GitInstallFile = "$DownloadFolder\$($GitVersion.name)"
            $CmakeVersion = "https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-win64-x64.msi"
            $CmakeFileName = $CmakeVersion.Split("/")[-1]
            $CmakeInstallFile = "$DownloadFolder\$CmakeFileName"
            $VisualStudioURL = "https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16#"
            $VSFileName = "vs_community.exe"
            $VSInstallFile = "$DownloadFolder\$VSFileName"
            $OpenSSLURL = "http://slproweb.com/download/Win64OpenSSL-1_1_1L.exe"
            $OpenSSLFileName = $OpenSSLURL.Split("/")[-1]
            $OpenSSLInstallFile = "$DownloadFolder\$OpenSSLFileName"
            $MySQLURL = "https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.29-winx64.zip"
            $MySQLFileName = $MySQLURL.Split("/")[-1]
            $MySQLZipFile = "$DownloadFolder\$MySQLFileName"
            $HeidiURL = "https://www.heidisql.com/downloads/releases/HeidiSQL_10.3_64_Portable.zip"
            $HeidiFileName = $HeidiURL.Split("/")[-1]
            $HeidiZipFile = "$DownloadFolder\$HeidiFileName"
            #$BoostURL = "https://boostorg.jfrog.io/native/main/release/1.74.0/binaries/boost_1_74_0-msvc-14.2-64.exe"
            $BoostURL = "https://sourceforge.net/projects/boost/files/boost-binaries/1.74.0/boost_1_74_0-msvc-14.2-64.exe/download"
            $BoostFileName = $BoostURL.Split("/")[-2]
            $BoostInstallFile = "$DownloadFolder\$BoostFileName"

            $AZCoreDataURL = "https://github.com/wowgaming/client-data/releases/download/v11/data.zip"
            $AZCoreDataZipName = $AZCoreDataURL.Split("/")[-1]
            $AZCoreDataZip = "$DownloadFolder\$AZCoreDataZipName"

            # Pre-requisite checks section
            Write-Information -MessageData "Beginning pre-requisite checks and`ninstalling any missing but required software`n`n" -InformationAction Continue
            # Download HeidiSQL
            if (!(Test-Path -path $HeidiZipFile)) {
                Write-Information -MessageData "HeidiSQL not found. Downloading now" -InformationAction Continue
                Try {
                    Invoke-WebRequest -Uri $HeidiURL -OutFile $HeidiZipFile
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $HeidiFileName with error message: $fail" -InformationAction Continue
                    Break
                }
                Expand-Archive -Path $HeidiZipFile -DestinationPath "$DownloadFolder\HeidiSQL"
                Start-Sleep -Seconds 2
            }
            # check for Git 64bit install
            if (!(Test-Path -Path "C:\Program Files\Git\git-cmd.exe")) {
                Write-Information -MessageData "Git 64bit not found.  Downloading now" -InformationAction Continue
                $GitVersion = Invoke-RestMethod -Method Get -Uri $GitURL | ForEach-Object assets | Where-Object name -like "*64-bit.exe"
                Try {
                    $response = Invoke-WebRequest -Uri $GitVersion.browser_download_url -OutFile $GitInstallFile
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $GitInstallFile with error message:`n$fail" -InformationAction Continue
                    Break
                }
                Write-Information -MessageData "Download finished. Now installing" -InformationAction Continue
                # create .inf file for git silent install
                $GitINF = "$DownloadFolder\gitinstall.inf"
                New-Item -Path $GitINF -ItemType File -Force
                Add-Content -Path $GitINF -Value "[Setup]
                    Lang=default
                    Dir=C:\Program Files\Git
                    Group=Git
                    NoIcons=0
                    SetupType=default
                    Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh
                    Tasks=
                    EditorOption=Notepad++
                    CustomEditorPath=
                    PathOption=Cmd
                    SSHOption=OpenSSH
                    TortoiseOption=false
                    CURLOption=OpenSSL
                    CRLFOption=CRLFAlways
                    BashTerminalOption=ConHost
                    PerformanceTweaksFSCache=Enabled
                    UseCredentialManager=Enabled
                    EnableSymlinks=Disabled
                    EnableBuiltinInteractiveAdd=Disabled"
                $GitArguments = "/VERYSILENT /NORESTART /LOADINF=""$GitINF"""
                Try {
                    Start-Process -FilePath $GitInstallFile -ArgumentList $GitArguments -Wait
                } Catch {
                    Write-Error -Message "Git Install failed" -ErrorAction Stop
                }
                Write-Information -MessageData "Git Install finished" -InformationAction Continue
                $RestartRequired = $true
            } else {
                Write-Information -MessageData "Git already installed. Continuing to next step." -InformationAction Continue
            }

            # check for CMake 64bit install
            if (!(Test-Path -Path "C:\Program Files\CMake\bin\cmake.exe")) {
                Write-Information -MessageData "CMake 64bit not found. Downloading now" -InformationAction Continue
                Try {
                    $Response = Invoke-WebRequest -Uri $CmakeVersion -OutFile $CmakeInstallFile
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $CmakeFileName with error message:`n$fail" -InformationAction Continue
                    Break
                }
                Write-Information -MessageData "Download finished. Now installing" -InformationAction Continue
                $CmakeArguments = "/i `"$CmakeInstallFile`" /norestart /quiet"
                Try {
                    Start-Process msiexec.exe -ArgumentList $CmakeArguments -Wait
                } Catch {
                    Write-Error -Message "CMake Install failed" -ErrorAction Stop
                }
                Write-Information -MessageData "CMake install finished" -InformationAction Continue
                $RestartRequired = $true
            } else {
                Write-Information -MessageData "CMake already installed. Continuing to next step." -InformationAction Continue
            }

            # check for Visual Studio
            if (!(Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe")) {
                Write-Information -MessageData "Visual Studio not found. Downloading and installing now" -InformationAction Continue
                Try {
                    $Response = Invoke-WebRequest -Uri $VisualStudioURL -OutFile "$VSInstallFile.txt"
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download VS file list with error message:`n$fail" -InformationAction Continue
                    Break
                }
                $installerURL = Select-String -Path "$VSInstallFile.txt" -Pattern "$VSFileName"
                $installerURL = "https:" + ($installerURL -replace ".*:" -replace ".{1}$")
                Try {
                    $Response = Invoke-WebRequest -Uri $installerURL -OutFile $VSInstallFile
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $VSFileName with error message:`n$fail" -InformationAction Continue
                    Break
                }
                $VSArguments = "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended --quiet --norestart"
                Try {
                    Start-Process -FilePath $VSInstallFile -ArgumentList $VSArguments -Wait
                } Catch {
                    Write-Error -Message "Visual Studio install failed" -ErrorAction Stop
                }
                Write-Information -MessageData "Visual Studio install finished" -InformationAction Continue
                $RestartRequired = $true
            } else {
                Write-Information -MessageData "Visual Studio already installed. Continuing to next step." -InformationAction Continue
            }

            # check for OpenSSL 64bit
            if (!(Test-Path -Path "C:\Program Files\OpenSSL-Win64\bin\openssl.exe")) {
                Write-Information -MessageData "OpenSSL not found. Downloading and installing now" -InformationAction Continue
                Try {
                    $Response = Invoke-WebRequest -Uri $OpenSSLURL -OutFile $OpenSSLInstallFile
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $OpenSSLFileName with error message: $fail" -InformationAction Continue
                    Break
                }
                Write-Information -MessageData "Download finished. Now installing" -InformationAction Continue
                $OpenSSLArguments = "/VERYSILENT"
                Try {
                    Start-Process -FilePath $OpenSSLInstallFile -ArgumentList $OpenSSLArguments -Wait
                } Catch {
                    Write-Error -Message "OpenSSL 64bit install failed" -ErrorAction Stop
                }
                Write-Information -MessageData "OpenSSL 64bit install finished" -InformationAction Continue
                $RestartRequired = $true
            } else {
                Write-Information -MessageData "OpenSSL already installed. Continuing to next step." -InformationAction Continue
            }

            # check for MySQL
            if (!(Test-Path -Path C:\MySQL\bin\mysqld.exe)) {
                Write-Information -MessageData "Downloading MySQL Portable and expanding archive`nIf you're sitting here staring at the screen...`nit's time to get a beer!" -InformationAction Continue
                Try {
                    $Response = Invoke-WebRequest -Uri $MySQLURL -OutFile $MySQLZipFile
                } catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $MySQLFileName with error message: $fail" -InformationAction Continue
                    Break
                }
                Try {
                    Expand-Archive -Path $MySQLZipFile -DestinationPath "C:\MySQL"
                } catch {
                    Write-Information -MessageData "Failed to extract $MySQLFileName. Download may be corrupt. Delete and try again." -InformationAction Continue
                    break
                }
                Get-ChildItem -Path "C:\MySQL\mysql-5.7.29-winx64" | Move-Item -Destination "C:\MySQL"
                New-Item -Path "C:\MySQL\lib\debug" -ItemType Directory -Force
                Copy-Item -Path "C:\MySQL\lib\libmysql.lib" -Destination "C:\MySQL\lib\debug\libmysql.lib"
                Copy-Item -Path "C:\MySQL\lib\libmysql.dll" -Destination "C:\MySQL\lib\debug\libmysql.dll"
                Remove-Item -Path "C:\MySQL\mysql-5.7.29-winx64" -Force
            } else {
                Write-Information -MessageData "MySQL already exists at C:\MySQL" -InformationAction Continue
            }

            # check for Boost install
            if (!(Test-Path -Path "C:\local\boost_1_74_0\tools\build\src\engine\build.bat")) {
                Write-Information -MessageData "Boost not found. Downloading now" -InformationAction Continue
                Try {
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile($BoostURL,$BoostInstallFile)
                } Catch {
                    $fail = $_.Exception.Response.StatusCode.Value__
                    Write-Information -Message "Failed to download $BoostFileName with error message:`n$fail" -InformationAction Continue
                    Break
                }
                Write-Information -MessageData "Download finished. Now installing" -InformationAction Continue
                $BoostArguments = "/VERYSILENT"
                Try {
                    Start-Process -FilePath $BoostInstallFile -ArgumentList $BoostArguments -Wait
                } Catch {
                    Write-Error -Message "Boost install failed" -ErrorAction Stop
                }
                # set Boost environment variable
                $EnvName = "BOOST_ROOT"
                $EnvValue = "C:/local/boost_1_74_0"
                [System.Environment]::SetEnvironmentVariable($EnvName, $EnvValue, [System.EnvironmentVariableTarget]::Machine)
                Write-Information -MessageData "Boost install finished" -InformationAction Continue
                $RestartRequired = $true
            } else {
                Write-Information -MessageData "Boost already installed. Continuing to next step." -InformationAction Continue
            }

            # check Boost b2.exe Configuration
            if (!(Test-Path -Path "C:\local\boost_1_74_0\b2.exe")) {
                Set-Location -path "C:\local\boost_1_74_0"
                Start-Process -FilePath ".\bootstrap.bat" -Wait -NoNewWindow
                Start-Process -FilePath ".\b2.exe" -Wait
                #Start-Process -FilePath "C:\local\boost_1_74_0\bootstrap.bat" -Wait
                #Start-Process -FilePath "C:\local\boost_1_74_0\tools\build\src\engine\b2.exe" -Wait
            } else {
                Write-Information -MessageData "Bootstrap already ran" -InformationAction Continue
            }
            

            # set Boost environment variable
            $EnvName = "BOOST_ROOT"
            $EnvValue = "C:/local/boost_1_74_0"
            [System.Environment]::SetEnvironmentVariable($EnvName, $EnvValue, [System.EnvironmentVariableTarget]::Machine)


            # Program installation finished.  Restart now if required.
            if ($RestartRequired) {
                Write-Information -MessageData "`n`n`nOne or more applications have been installed`nand PATH variables modified`nyou MUST close and reopen Powershell to continue`nrerun script to continue`n`n`n" -InformationAction Continue
                Break
            } else {
                Clear-Host
                Write-Information -MessageData "All prerequisite software already installed and configured." -InformationAction Continue
            }
        }
        #Clone/Clean/Update AzerothCore Git Repo
        '2' {
            $AzerothCoreRepo = "https://github.com/azerothcore/azerothcore-wotlk.git"
            if (!(Test-Path -Path $BaseLocation)) {
                Write-Information -MessageData "Creating Folder:`n$BaseLocation" -InformationAction Continue
                Try {
                New-Item -Path $BaseLocation -ItemType Directory
                } Catch {
                    Write-Error -Message "Unable to create folder. Ensure valid path was used and retry" -ErrorAction Stop
                }
            }
            if (!(Test-Path -Path "$BaseLocation\.git\HEAD")) {
                Write-Information -MessageData "Cloning AzerothCore Git Repo" -InformationAction Continue
                Try {
                    git clone $AzerothCoreRepo $BaseLocation --branch master
                    if (-not $?) {
                        throw "git error! failed to clone AzerothCore!"
                    }
                } Catch {
                    throw
                }
                Write-Information -MessageData "Clone successfull!" -InformationAction Continue
            } else {
                Write-Information -MessageData "AzerothCore already exists`nWill clean and update repo now" -InformationAction Continue
                if (Test-Path -path "$BaseLocation\modules") {
                    Remove-Item -path "$BaseLocation\modules" -Recurse -Force
                }
                if (Test-Path -path "$BaseLocation\data\sql\updates") {
                    Remove-Item -path "$BaseLocation\data\sql\updates" -Recurse -Force
                }
                #Remove-Item -path "$BaseLocation\.git\refs" -Recurse -Force
                Set-Location $BaseLocation
                
                Try {
                    git reset --hard
                    if (-not $?) {
                        throw "git error! failed to reset AzerothCore!"
                    }
                } Catch {
                    throw
                }
                Try {
                    git checkout master
                    if (-not $?) {
                        throw "git error! failed to checkout master!"
                    }
                } Catch {
                    throw
                }
                $PRLocalBranches = (Get-ChildItem -path "$BaseLocation\.git\refs\heads" -exclude "master").name
                foreach ($PRLocalBranch in $PRLocalBranches) {
                    Write-Information -MessageData "Deleting local branch $PRLocalBranch"
                    Try {
                        git branch -D $PRLocalBranch
                        if (-not $?) {
                            throw "git error! failed to delete local branch $PRLocalBranch"
                        }
                    } Catch {
                        throw
                    }
                }

                Try {
                    git clean -fd
                    if (-not $?) {
                        throw "git error! failed to clean AzerothCore!"
                    }
                } Catch {
                    throw
                }

                Try {
                    git pull
                    if (-not $?) {
                        throw "git error! failed to update AzerothCore!"
                    }
                } Catch {
                    throw
                }

            }
            #Clear-Host
            Write-Information -MessageData "AzerothCore cloned and/or cleaned.  You may now build server or download PR to test" -InformationAction Continue
        }
        #Download PR to Test
        '3' {
            $PRRepo = "https://github.com/azerothcore/azerothcore-wotlk/pull/"
            Do {
                $PR = Read-Host "`nEnter 4 digit PR number that you want to test`n`nPR #"
                $PRURL = $PRRepo + $PR
                $PRURLIsValid = $false
                Try {
                    $PRResult = Invoke-WebRequest -Uri $PRURL -Method Get
                    $PRURLIsValid = $true 
                } Catch {
                    Write-Information -MessageData "URL was not valid. Check PR # and retry" -InformationAction Continue
                }
                if ($PRURLIsValid -eq $True) {
                    $PRTitle = $PRResult.ParsedHtml.title
                    $CorrectPR = Read-Host "`n$PRTitle`n`nIs this the correct PR?`n`nEnter 'y' or 'n'"
                    if ($CorrectPR -eq "y") {
                        $PRURLIsValid = $true
                    } else {
                        $PRURLIsValid = $false
                        Write-Information -MessageData "Enter PR # again"
                    }
                }
            } until ($PRURLIsValid -eq $True)
            if ($PRURLIsValid -eq $True) {
                Set-Location $BaseLocation
                Try {
                    git checkout -b pr-$PR
                    if (-not $?) {
                        throw "git error! failed to clone AzerothCore!"
                    }
                } Catch {
                    throw
                }
                Try {
                    git pull origin pull/$PR/head
                    if (-not $?) {
                        throw "git error! failed to clone AzerothCore!"
                    }
                } Catch {
                    throw
                }
                Clear-Host
                Write-Information -MessageData "PR# $PR has been pulled.  You may now build server" -InformationAction Continue

            }
        }
        #Add custom modules
        '4' {
            Function Get-AZModule {
                param (
                    [Parameter(Mandatory = $true,Position = 0)]
                    [string]$AZmodPath,
                    [Parameter(Mandatory = $true,Position = 1)]
                    [string]$AZmodURL
                )

                $AZmodname = ($AZmodURL -replace ".{4}$").Remove(0,31)
                if (Test-Path "$AZmodPath\.git\HEAD") {
                    Write-Information -MessageData "$AZmodname already exists`nUpdating repo now" -InformationAction Continue
                    try {
                        Set-Location $AZmodPath
                        git pull
                        if (-not $?) {
                            throw "git error! failed to update $AZmodname"
                        }
                    } Catch {
                        throw
                    }
                } else {
                    Write-Information -MessageData "Module doesn't exist yet`nCloning $AZmodname repo" -InformationAction Continue
                    Try {
                        git clone $AZmodURL $AZmodPath
                        if (-not $?) {
                            throw "git error! failed to clone $AZmodname"
                        }
                    } Catch {
                        throw
                    }
                }
            }

            # Winform to select modules

            [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
            [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

            $Form = New-Object System.Windows.Forms.Form
            $Form.Size = New-Object System.Drawing.Size(700,380)
            $Form.text ="Choose desired AzerothCore modules"
            $Form.StartPosition = 'CenterScreen'

            $OKButton = New-Object System.Windows.Forms.Button
            $OKButton.Location = New-Object System.Drawing.Point(520,310)
            $OKButton.Size = New-Object System.Drawing.Size(75,23)
            $OKButton.Text = 'OK'
            $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $Form.AcceptButton = $OKButton
            $Form.Controls.Add($OKButton)

            $cancelButton = New-Object System.Windows.Forms.Button
            $cancelButton.Location = New-Object System.Drawing.Point(600,310)
            $cancelButton.Size = New-Object System.Drawing.Size(75,23)
            $cancelButton.Text = 'Cancel'
            $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $Form.CancelButton = $cancelButton
            $Form.Controls.Add($cancelButton)

            # Start group boxes
            $groupBox = New-Object System.Windows.Forms.GroupBox
            $groupBox.Location = New-Object System.Drawing.Size(20,20)
            $groupBox.text = "Availabe Modules:"
            $groupBox.size = New-Object System.Drawing.Size(660,275)
            $Form.Controls.Add($groupBox)

            # Create check boxes
            $checklist = New-Object System.Windows.Forms.CheckedListBox
            $checklist.Location = New-Object System.Drawing.Size(20,20)
            $checklist.Size = New-Object System.Drawing.Size(620,250)
            $checklist.CheckOnClick = $true
            $checklist.MultiColumn = $true

            # Get Available Modules
            $uri = New-Object System.UriBuilder -ArgumentList 'https://api.github.com/search/repositories?q=topic%3Acore-module+fork%3Atrue+org%3Aazerothcore&type=Repositories&per_page=100'
            $baseuri = $uri.uri
            $acmods = Invoke-RestMethod -Method Get -Uri $baseuri
            $acmodslist = $acmods.items | Select-Object -Property name, clone_url | Sort-Object Name

            # Add modules to checkboxlist with any already present defaulted to checked
            $CurrentModules = Get-ChildItem -Path "$BaseLocation\Modules" -Filter "mod*" | Select-Object -Property Name
            $modnumber = 0
            foreach ($acmod in $acmodslist) {
                if ($acmod.name -like "mod*") {
                    $modsName = ($acmod.name).remove(0,4)
                    $checklist.Items.Add($modsName) | Out-Null
                    foreach ($CurrentModule in $CurrentModules) {
                        if (($CurrentModule.Name).remove(0,4) -eq $modsName) {
                            $checklist.SetItemChecked($modnumber,$true)
                        }
                    }
                    $modnumber ++
                }
            }

            $groupBox.Controls.Add($checklist)

            # OK is clicked
            $OKButton.Add_Click({
                $Script:Cancel=$false
                $Form.Hide()
                foreach ($mod in $checklist.CheckedItems) {
                    foreach ($acmod in $acmodslist) {
                        if ($acmod.name -like "*$mod") {
                            $modpath = "$BaseLocation\modules\" + $acmod.name
                            Write-Progress -Activity "Downloading Modules" -Status $acmod.name
                            Get-AZModule -AZmodPath $modpath -AZmodURL $acmod.clone_url
                        }
                    }
                    if ($mod -eq "eluna-lua-engine") {
                        Write-Progress -Activity "Downloading Modules" -Status "Installing LUA Engine"
                        Get-AZModule -AZmodPath "$BaseLocation\modules\mod-eluna-lua-engine\LuaEngine" -AZmodURL "https://github.com/ElunaLuaEngine/Eluna.git"
                    }
                }
                Write-Progress -Activity "Downloading Modules" -Status "Ready" -Completed
                $Form.Close()
            })

            $cancelButton.Add_Click({
                $Script:Cancel=$true
                $Form.Close()
            })

            # Show Form
            $Form.ShowDialog() | Out-Null

            if ($Cancel -eq $true) {
                break
            }
        }
        #Build Server and database
        '5' {
            #Deletes old files, to include databases, to ensure clean build
            if (Test-Path -path "$BuildFolder\bin\Release") {
                Remove-Item -path "$BuildFolder\bin\Release" -Recurse -Force
            }
            #Build Server
            Set-Location 'C:\Program Files\CMake\bin'
            Write-Progress -Activity "Building Server" -Status "Compiling Source"
            Write-Information -MessageData "Compiling and building will take some time. Go have a beer!" -InformationAction Continue
            $BuildArgs = "-G `"Visual Studio 16 2019`" -A x64 -DTOOLS=1 -S $BaseLocation -B $BuildFolder"
            Start-Process -FilePath 'C:\Program Files\CMake\bin\cmake.exe' -ArgumentList $BuildArgs -Wait
            Write-Progress -Activity "Building Server" -Status "Final Build"
            $FinalArgs = "--build $BuildFolder --config Release"
            Start-Process -FilePath "C:\Program Files\CMake\bin\cmake.exe" -ArgumentList $FinalArgs -Wait
            Write-Progress -Activity "Building Server" -Status "Ready" -Completed
            # Check to ensure build finished
            if ((Test-Path -Path "$BuildFolder\bin\Release\authserver.exe") -and (Test-Path -Path "$BuildFolder\bin\Release\worldserver.exe")) {
                Write-Information -MessageData "Compile and build Successful! Continuing..." -InformationAction Continue
            } else {
                Write-Information -MessageData "Compile and build failed.  Check cmake logs and try again." -InformationAction Continue
                break
            }

            # Copy all conf.dist files to .conf
            $DistFiles = Get-ChildItem -Path "$BuildFolder\bin\Release\configs" -Filter "*.dist"
            foreach ($Dist in $DistFiles) {
                $Conf = $Dist -replace ".{5}$"
                Copy-Item -Path "$BuildFolder\bin\Release\configs\$Dist" -Destination "$BuildFolder\bin\Release\configs\$Conf"
            }

            # Copy all conf.dist files from mods to .conf
            $ModDistFiles = Get-ChildItem -Path "$BuildFolder\bin\Release\configs\modules" -Filter "*.dist"
            foreach ($moddist in $ModDistFiles) {
                $Conf = $moddist -replace ".{5}$"
                Copy-Item -Path "$BuildFolder\bin\Release\configs\modules\$moddist" -Destination "$BuildFolder\bin\Release\configs\modules\$Conf"
            }

            # Change .conf file settings
            New-Item -Path "$BuildFolder\bin\Release\Data" -ItemType Directory
            New-Item -Path "$BuildFolder\bin\Release\Logs" -ItemType Directory
            #World Config
            $WorldServerConf = Get-Content -Path "$BuildFolder\bin\Release\configs\worldserver.conf"
            $NewWorldDataDir = $WorldServerConf -replace "DataDir = `".`"", "DataDir = `"Data`""
            $NewWorldDataDir | Set-Content -Path "$BuildFolder\bin\Release\configs\worldserver.conf"

            $WorldServerConf = Get-Content -Path "$BuildFolder\bin\Release\configs\worldserver.conf"
            $NewWorldLogDir = $WorldServerConf -replace "LogsDir = `".`"", "LogsDir = `"Logs`""
            $NewWorldLogDir | Set-Content -Path "$BuildFolder\bin\Release\configs\worldserver.conf"

            $WorldServerConf = Get-Content -Path "$BuildFolder\bin\Release\configs\worldserver.conf"
            $NewWorldSQLExe = $WorldServerConf -replace "MySQLExecutable = `"`"", "MySQLExecutable = `".\database\bin\mysql.exe`""
            $NewWorldSQLExe | Set-Content -Path "$BuildFolder\bin\Release\configs\worldserver.conf"

            #Auth Config
            $AuthServerConf = Get-Content -Path "$BuildFolder\bin\Release\configs\authserver.conf"
            $NewAuthLogDir = $AuthServerConf -replace "LogsDir = `"`"", "LogsDir = `"Logs`""
            $NewAuthLogDir | Set-Content -Path "$BuildFolder\bin\Release\configs\authserver.conf"

            $AuthServerConf = Get-Content -Path "$BuildFolder\bin\Release\configs\authserver.conf"
            $NewAuthSQLExe = $AuthServerConf -replace "MySQLExecutable = `"`"", "MySQLExecutable = `".\database\bin\mysql.exe`""
            #$NewAuthSQLExe = $AuthServerConf -replace "MySQLExecutable = `"`"", "MySQLExecutable = `"$BuildFolder\bin\Release\database\bin\mysql.exe`""
            $NewAuthSQLExe | Set-Content -Path "$BuildFolder\bin\Release\configs\authserver.conf"

            #Maps Data
            $AZCoreDataZipName = $AZCoreDataURL.Split("/")[-1]
            $AZCoreDataZip = "$DownloadFolder\$AZCoreDataZipName"
            if ($Downloaddata -eq "Yes") {
                Write-Information -MessageData "Download is >1Gb so it will take some time.  Go have another beer!" -InformationAction Continue
                if (!(Test-Path -path $AZCoreDataZip)) {
                    Try {
                        Invoke-WebRequest -Uri $AZCoreDataURL -OutFile $AZCoreDataZip
                    } Catch {
                        $fail = $_.Exception.Response.StatusCode.Value__
                        Write-Information -Message "Failed to download $AZCoreDataZipName with error message: $fail" -InformationAction Continue
                        Break
                    }
                } else {
                    Write-Information -MessageData "$AZCoreDataZipName was previously downloaded. Delete file and rerun if you need a new version downloaded" -InformationAction Continue
                }
                Write-Information -MessageData "Extracting files should take long enough for you to have another beer. Enjoy!" -InformationAction Continue
                $datapaths = "$BuildFolder\bin\Release\Data"
                if ((!(Test-Path -path "$datapaths\Cameras")) -or (!(Test-Path -path "$datapaths\dbc")) -or (!(Test-Path -path "$datapaths\maps")) -or (!(Test-Path -path "$datapaths\mmaps")) -or (!(Test-Path -path "$datapaths\vmaps"))) {
                    Expand-Archive -Path $AZCoreDataZip -DestinationPath "$BuildFolder\bin\Release\Data"
                } else {
                    Write-Information -MessageData "Skipping. Maps data previously extracted."
                }
            } else {
                Write-Information -MessageData "`n`n!!Don't forget to manually copy data files!!`n`n" -InformationAction Continue
                Start-Sleep -Seconds 3
            }

            #Copy SQL and Build Database. SQL is copied to ensure nothing is deleted or altered from main MySQL install in case program is also used for something else
            New-Item -Path "$BuildFolder\bin\Release\database\bin" -ItemType Directory
            $SQLBinFilesToCopy = @(
                "C:\MySQL\lib\libmysql.dll"
                "C:\MySQL\lib\libmysqld.dll"
                "C:\MySQL\bin\mysql.exe"
                "C:\MySQL\bin\mysql_upgrade.exe"
                "C:\MySQL\bin\mysqladmin.exe"
                "C:\MySQL\bin\mysqlcheck.exe"
                "C:\MySQL\bin\mysqld.exe"
                "C:\MySQL\bin\mysqldump.exe"
            )
            foreach ($SQLBinFile in $SQLBinFilesToCopy) {
                Copy-Item -Path "$SQLBinFile" -Destination "$BuildFolder\bin\Release\database\bin"
            }
            Copy-Item -Path "C:\MySQL\share" -Destination "$BuildFolder\bin\Release\database" -Recurse
            Copy-Item -Path 'C:\MySQL\lib\libmysql.dll' -Destination "$BuildFolder\bin\Release\"
            Copy-Item -Path "C:\Program Files\OpenSSL-Win64\libcrypto-1_1-x64.dll" -Destination "$BuildFolder\bin\Release\"
            Copy-Item -Path "C:\Program Files\OpenSSL-Win64\libssl-1_1-x64.dll" -Destination "$BuildFolder\bin\Release\"
            Copy-Item -Path 'C:\MySQL\lib\libmysql.dll' -Destination "$BuildFolder\bin\Release\configs\"
            Copy-Item -Path "C:\Program Files\OpenSSL-Win64\libcrypto-1_1-x64.dll" -Destination "$BuildFolder\bin\Release\configs\"
            Copy-Item -Path "C:\Program Files\OpenSSL-Win64\libssl-1_1-x64.dll" -Destination "$BuildFolder\bin\Release\configs\"

            # Initialize MySQL
            New-Item -Path "$BuildFolder\bin\Release\database\tmp" -ItemType Directory
            New-Item -Path "$BuildFolder\bin\Release\database\data" -ItemType Directory
            Set-Location "$BuildFolder\bin\Release\database\bin"
            Start-Process -FilePath "mysqld.exe" -ArgumentList "--initialize-insecure" -Wait

            # Create MySQLini
            $MySQLINI = "$BuildFolder\bin\Release\database\my.ini"
                New-Item -Path $MySQLINI -ItemType File -Force
                Add-Content -Path $MySQLINI -Value "#Client Settings
                [client]
                    default-character-set = utf8mb4
                    port = 3306
                    socket = /tmp/mysql.sock
            # MySQL 5.7.29 Settings
                [mysqld]
                    port = 3306
                    basedir=`"..`"
                    datadir=`"../data`"
                    socket = /tmp/mysql.sock
                    skip-external-locking
                    skip_ssl
                    skip-slave-start
                    key_buffer_size = 256M
                    max_allowed_packet = 64M
                    table_open_cache = 256
                    sort_buffer_size = 1M
                    read_buffer_size = 1M
                    read_rnd_buffer_size = 4M
                    myisam_sort_buffer_size = 64M
                    thread_cache_size = 8
                    query_cache_size= 16M
                    character-set-server=utf8mb4
                    collation-server=utf8mb4_unicode_ci
                    skip-character-set-client-handshake
                    server-id = 1
                    innodb_write_io_threads = 64
                    innodb_read_io_threads = 64
                    explicit_defaults_for_timestamp = 1
                    sql-mode=`"NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION`"
                [mysqldump]
                    quick
                    max_allowed_packet = 16M
                [myisamchk]
                    key_buffer_size = 128M
                    sort_buffer_size = 128M
                    read_buffer = 16M
                    write_buffer = 16M
                [mysqlhotcopy]
                    interactive-timeout"

            # Create MySQLConfigcnf
            $MySQLConfigCNF = "$BuildFolder\bin\Release\database\config.cnf"
            New-Item -Path $MySQLConfigCNF -ItemType File -Force
            Add-Content -Path $MySQLConfigCNF -Value "[client]
            user = root
            password = $SQLRootPassword
            host = 127.0.0.1
            port = 3306"

            # Create MySQLUpdatecnf
            $MySQLUpdateCNF = "$BuildFolder\bin\Release\database\mysqlupdate.cnf"
            New-Item -Path $MySQLUpdateCNF -ItemType File -Force
            Add-Content -Path $MySQLUpdateCNF -Value "[client]
            user = root
            password = $SQLRootPassword
            host = 127.0.0.1
            port = 3306"

            # Create MySQL.bat
            $MySQLbat = "$BuildFolder\bin\Release\1_start_mysql.bat"
            New-Item -Path $MySQLbat -ItemType File -Force
            Add-Content -Path $MySQLbat -Value "@echo off
            SET NAME=MyCustomServer - mysql-5.6.46-winx64
            TITLE %NAME%

            echo.
            echo.
            echo Starting MySQL. Press CTRL C for server shutdown
            echo.
            echo.
            cd .\database\bin
            mysqld --defaults-file=..\my.ini --console --standalone"

            # Start MySQL Server
            Set-Location "$BuildFolder\bin\Release"
            Start-Process -FilePath "1_start_mysql.bat"

            # Set MySQL Root PW
            $sqlCMD = "ALTER USER 'root'@'localhost' IDENTIFIED BY '$SQLRootPassword';"
            $SQLChangePWArgs = "-uroot --execute=`"$sqlCMD`""
            Start-Process -FilePath "$BuildFolder\bin\Release\database\bin\mysql.exe" -ArgumentList $SQLChangePWArgs -Wait -ErrorAction Stop
            Write-Information -MessageData "Root password set to: $SQLRootPassword" -InformationAction Continue

            # Create databases
            $CreateDBCMD = Get-Content -Path "$BaseLocation\data\sql\create\create_mysql.sql"
            $CreateDBArgs = "--defaults-file=$BuildFolder\bin\Release\database\config.cnf --execute=`"$CreateDBCMD`""
            Start-Process -FilePath "$BuildFolder\bin\Release\database\bin\mysql.exe" -ArgumentList $CreateDBArgs -Wait

            # Configure the databases
            Function Import-SQLscripts {
                param (
                    [Parameter(Mandatory = $true,Position = 0)]
                    [string]$SQLDatabase,
                    [Parameter(Mandatory = $true,Position = 1)]
                    [string]$SQLScriptsPath
                )

                $SQLscripts = Get-ChildItem -Path $SQLScriptsPath -Filter "*.sql"
                foreach ($SQLscript in $SQLscripts) {
                    $SQLscriptpath = $SQLScriptsPath + "\" + $SQLscript
                    Write-Progress -Activity "Importing SQL Files for $SQLDatabase" -Status "$SQLscript"
                    Try {
                        Get-Content $SQLscriptpath | &".\mysql.exe" --defaults-file=..\config.cnf $SQLDatabase 
                    } catch {
                        Write-Information -MessageData "$SQLscriptpath failed to import" -InformationAction Continue
                    }
                }
                Write-Progress -Activity "Importing SQL Files" -Status "Ready" -Completed
            }
            Set-Location -Path "$BuildFolder\bin\Release\database\bin"
            $authDBScriptsPath = "$BaseLocation\data\sql\base\db_auth"
            $authDBupdateScriptsPath = "$BaseLocation\data\sql\updates\db_auth"
            $authDBpendingupdateScriptsPath = "$BaseLocation\data\sql\updates\pending_db_auth"
            
            $characterDBScriptsPath = "$BaseLocation\data\sql\base\db_characters"
            $characterDBupdateScriptsPath = "$BaseLocation\data\sql\updates\db_characters"
            $characterDBpendingupdateScriptsPath = "$BaseLocation\data\sql\updates\pending_db_characters"

            $worldDBScriptsPath = "$BaseLocation\data\sql\base\db_world"
            $worldDBupdateScriptsPath = "$BaseLocation\data\sql\updates\db_world"
            $worldDBpendingupdateScriptsPath = "$BaseLocation\data\sql\updates\pending_db_world"

            Import-SQLscripts -SQLDatabase "acore_auth" -SQLScriptsPath $authDBScriptsPath
            Import-SQLscripts -SQLDatabase "acore_auth" -SQLScriptsPath $authDBupdateScriptsPath
            Import-SQLscripts -SQLDatabase "acore_auth" -SQLScriptsPath $authDBpendingupdateScriptsPath
            Import-SQLscripts -SQLDatabase "acore_characters" -SQLScriptsPath $characterDBScriptsPath
            Import-SQLscripts -SQLDatabase "acore_characters" -SQLScriptsPath $characterDBupdateScriptsPath
            Import-SQLscripts -SQLDatabase "acore_characters" -SQLScriptsPath $characterDBpendingupdateScriptsPath
            Import-SQLscripts -SQLDatabase "acore_world" -SQLScriptsPath $worldDBScriptsPath
            Import-SQLscripts -SQLDatabase "acore_world" -SQLScriptsPath $worldDBupdateScriptsPath
            Import-SQLscripts -SQLDatabase "acore_world" -SQLScriptsPath $worldDBpendingupdateScriptsPath

            # Import SQL scripts from modules
            $InstalledModules = Get-ChildItem -Path "$BaseLocation\modules" -Filter "mod*"
            foreach ($InstalledModule in $InstalledModules) {
                Write-Progress -Activity "Importing SQL files from installed modules" -Status "$InstalledModule"
                $Modfiles = Get-ChildItem -Path "$BaseLocation\modules\$InstalledModule" -Recurse -Filter "*.sql"
                foreach ($Modfile in $Modfiles) {
                    $Modpath = $Modfile.FullName
                    $SQLDatabase = $false
                    if (($Modpath -like "*character*") -and ($Modpath -notlike "*world*") -and ($Modpath -notlike "*auth*")) {
                        $SQLDatabase = "acore_characters"
                    } elseif (($Modpath -like "*world*") -and ($Modpath -notlike "*auth*") -and ($Modpath -notlike "*characters*")) {
                        $SQLDatabase = "acore_world"
                    } elseif (($Modpath -like "*auth*") -and ($Modpath -notlike "*world*") -and ($Modpath -notlike "*characters*")) {
                        $SQLDatabase = "acore_auth"
                    } else {
                        $SQLDatabase = $false
                    }
                    if ($SQLDatabase -eq $false) {
                        Write-Information -MessageData "`n`nCan not determine database for $Modpath" -InformationAction Continue
                        Write-Information -MessageData "Provide database sql script should be applied to`nuse format `"auth`", `"characters`", or `"world`"`n" -InformationAction Continue
                        do {
                            $SQLDatabase = Read-Host -Prompt "database for this SQL script?"
                        } until (($SQLDatabase -eq "auth") -or ($SQLDatabase -eq "characters") -or ($SQLDatabase -eq "world"))
                        if ($SQLDatabase -eq "auth") {
                            $SQLDatabase = "acore_auth"
                        }
                        if ($SQLDatabase -eq "character") {
                            $SQLDatabase = "acore_characters"
                        }
                        if ($SQLDatabase -eq "world") {
                            $SQLDatabase = "acore_world"
                        }
                    }
                    Try {
                        #Write-Host "$Modpath installing to $SQLDatabase"
                        Get-Content $Modpath | &".\mysql.exe" --defaults-file=..\config.cnf $SQLDatabase 
                    } catch {
                        Write-Information -MessageData "$Modpath failed to import" -InformationAction Continue
                    }
                }
                Write-Progress -Activity "Importing SQL files form installed modules" -Status "Ready" -Completed
            }

            # Stop SQL server after database configuration
            Start-Process -FilePath "$BuildFolder\bin\Release\database\bin\mysqladmin.exe" -ArgumentList "--user=root --password=$SQLRootPassword shutdown"

            # Create authserver.bat
            $AuthServerbat = "$BuildFolder\bin\Release\2_start_authserver.bat"
            New-Item -Path $AuthServerbat -ItemType File -Force
            Add-Content -Path $AuthServerbat -Value "@echo off
            echo.
            echo This server was autocompiled using Windows PowerShell
            echo https://github.com/stoudtlr/AzerothCore-Windows-AutoBuilder.git
            echo.
            echo Starting authserver. Press CTRL C for server shutdown
            echo.
            start authserver.exe"

            # Create worldserver.bat
            $WorldServerbat = "$BuildFolder\bin\Release\3_start_worldserver.bat"
            New-Item -Path $WorldServerbat -ItemType File -Force
            Add-Content -Path $WorldServerbat -Value "@echo off
            echo.
            echo This server was autocompiled using Windows PowerShell
            echo https://github.com/stoudtlr/AzerothCore-Windows-AutoBuilder.git
            echo.
            echo Starting authserver. Press CTRL C for server shutdown
            echo.
            start worldserver.exe"

            Write-Information -MessageData "Server and database build has finished!`nYou may now choose '6' to start the server for testing`nor choose '7' to move the files to another location`nif this will be a personal server or a repack" -InformationAction Continue
        }
        #Start Server
        '6' {
            Write-Information -MessageData "Remember that this should only be used for testing PR's!`nDo not play a solo server or host from here`nThese files are automatically deleted on rebuild`nto ensure clean testing environment`nChoose '7' if you want a permanent personal server to play on" -InformationAction Continue
            Start-Sleep -Seconds 3
            Set-Location -Path "$BuildFolder\bin\Release"
            Start-Process -FilePath "1_start_mysql.bat"
            Start-Sleep -Seconds 3
            Start-Process -FilePath "2_start_authserver.bat"
            Start-Sleep -Seconds 3
            Start-Process -FilePath "3_start_worldserver.bat"
            Write-Information -MessageData "Use CTRL-C in each server to stop them" -InformationAction Continue
            Break

        }
        #Create Repack
        '7' {
            if (Test-Path -path "$PersonalServerFolder\Server\worldserver.exe") {
                Write-Host "Existing Server Repack found at:`n$PersonalServerFolder`n`n"
                Write-Host "What would you like to do?"
                Write-Host "1. Delete existing files and continue building repack"
                Write-Host "2. Exit"

                do {
                    $RepackChoice = read-host "`nEnter Choice #"
                } until (($RepackChoice -eq "1") -or ($RepackChoice -eq "2"))

                if ($RepackChoice -eq "2") {
                    Break
                } else {
                    Write-Information -MessageData "Deleting existing files" -InformationAction Continue
                    Remove-Item -path $PersonalServerFolder -Recurse -Force
                }
            }
            Write-Information -MessageData "Creating personal server at:`n$PersonalServerFolder" -InformationAction Continue
            Try {
                New-Item -Path $PersonalServerFolder -ItemType Directory
            } Catch {
                Write-Error -Message "Unable to create folder. Ensure valid path was used and retry" -ErrorAction Stop
            }
            Copy-Item -path "$BuildFolder\bin\Release" -Destination $PersonalServerFolder -Recurse
            Rename-Item -Path "$PersonalServerFolder\Release" -NewName "Server"
            New-Item -Path "$PersonalServerFolder\Tools" -ItemType Directory
            Start-Sleep -Seconds 3
            Write-Information -InformationAction "Copying HeidiSQL to repack folder" -InformationAction Continue
            Try {
                Copy-Item -Path "$DownloadFolder\HeidiSQL_10.3_64_Portable" -Destination "$PersonalServerFolder\Tools" -Recurse
            } Catch {
                Write-Information -MessageData "Failed to copy HeidiSQL.  Try to manually copy from:`n$DownloadFolder\HeidiSQL`n To folder:`n$PersonalServerFolder\Tools"
            }
            $StartServerbat = "$PersonalServerFolder\Start_WoW_Server.bat"
            New-Item -Path $StartServerbat -ItemType File -Force
            Add-Content -Path $StartServerbat -Value "@echo off
            cd .\Server
            start 1_start_mysql.bat
            timeout /T 3
            start 2_start_authserver.bat
            timeout /T 3
            3_start_worldserver.bat"

            Write-Information -MessageData "Finished creating repack/personal server`nFiles can be found here:`n$PersonalServerFolder" -InformationAction Continue
            Write-Information -MessageData "You can start your server by double-clicking the filed named:`nStart_WoW_Server.bat" -InformationAction Continue
            Write-Information -MessageData "Entire folder can be zipped and shared as well" -InformationAction Continue

            
        }
    
    }
} until ($Selection -eq "q")

