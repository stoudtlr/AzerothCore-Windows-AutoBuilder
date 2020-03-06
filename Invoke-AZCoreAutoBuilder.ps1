<#
This script is to simplify the build process when using Windows.  During my searches
I have found plenty of tools and scripts to simply the process while using Linux,
but I'm a Windows user.  With the capabilities of PowerShell it surprised me that I
couldn't find an automation script for Windows. So I created one!
#>
# BaseLocation is where all of the .git repositories will be downloaded
$BaseLocation = "D:\WOW_SERVERS-TEST\AzerothCore-WotLK"
# BuildFolder is where all those repositories will be compiled
$BuildFolder = "D:\WOW_SERVERS-TEST\Build-AzerothCore"
# FinalServerFolder is where your finished product will be.  This entire folder is what would be shared as a "repack"
$FinalServerFolder = "D:\AzerothCore-by-Luke"
# Choose what you want the root SQL password to be.
$SQLRootPassword = "123456"
# Download Data files from Github? REMEMBER, This is a large file!
# "Yes" to download maps data, "No" to skip maps data. If skipped remember to copy later
$Downloaddata = "No"

########################################################################
# !!!DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING!!! #
########################################################################
$AzerothCoreRepo = "https://github.com/azerothcore/azerothcore-wotlk.git"
$GitURL = "https://api.github.com/repos/git-for-windows/git/releases/latest"
$GitInstallFile = "$env:USERPROFILE\Downloads\$($GitVersion.name)"
$CmakeVersion = "https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-win64-x64.msi"
$CmakeFileName = $CmakeVersion.Split("/")[-1]
$CmakeInstallFile = "$env:USERPROFILE\Downloads\$CmakeFileName"
$VisualStudioURL = "https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16#"
$VSFileName = "vs_community.exe"
$VSInstallFile = "$env:USERPROFILE\Downloads\$VSFileName"
$OpenSSLURL = "http://slproweb.com/download/Win64OpenSSL-1_1_1d.exe"
$OpenSSLFileName = $OpenSSLURL.Split("/")[-1]
$OpenSSLInstallFile = "$env:USERPROFILE\Downloads\$OpenSSLFileName"
$MySQLURL = "https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.29-winx64.zip"
$MySQLFileName = $MySQLURL.Split("/")[-1]
$MySQLZipFile = "$env:USERPROFILE\Downloads\$MySQLFileName"
$HeidiURL = "https://www.heidisql.com/downloads/releases/HeidiSQL_10.3_64_Portable.zip"
$HeidiFileName = $HeidiURL.Split("/")[-1]
$HeidiZipFile = "$env:USERPROFILE\Downloads\$HeidiFileName"

$AZCoreDataURL = "https://github.com/wowgaming/client-data/releases/download/v7/data.zip"
$AZCoreDataZipName = $AZCoreDataURL.Split("/")[-1]
$AZCoreDataZip = "$env:USERPROFILE\Downloads\$AZCoreDataZipName"

# Pre-requisite checks section
Write-Information -MessageData "Beginning pre-requisite checks and`ninstalling any missing but required software`n`n" -InformationAction Continue
# check for Git 64bit install
if (!(Test-Path -Path "C:\Program Files\Git\git-cmd.exe")) {
    Write-Information -MessageData "Git 64bit not found.  Downloading now" -InformationAction Continue
    $GitVersion = Invoke-RestMethod -Method Get -Uri $GitURL | ForEach-Object assets | Where-Object name -like "*64-bit.exe"
    Try {
        Invoke-WebRequest -Uri $GitVersion.browser_download_url -OutFile $GitInstallFile
    } Catch {
        Write-Error -Message "Failed to download $($GitVersion.name)" -InformationAction Stop
    }
    Write-Information -MessageData "Download finished. Now installing" -InformationAction Continue
    # create .inf file for git silent install
    $GitINF = "$env:USERPROFILE\Downloads\gitinstall.inf"
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
        Invoke-WebRequest -Uri $CmakeVersion -OutFile $CmakeInstallFile
    } Catch {
        Write-Error -Message "Failed to download $CmakeFileName" -InformationAction Stop
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
        Invoke-WebRequest -Uri $VisualStudioURL -OutFile "$VSInstallFile.txt"
    } Catch {
        Write-Error -Message "Failed to retrieve VS webpage" -ErrorAction Stop
    }
    $installerURL = Select-String -Path "$VSInstallFile.txt" -Pattern "vs_Community.exe"
    $installerURL = "https:" + ($installerURL -replace ".*:" -replace ".{1}$")
    Try {
        Invoke-WebRequest -Uri $installerURL -OutFile $VSInstallFile
    } Catch {
        Write-Error -Message "Failed to download Visual Studio" -ErrorAction Stop
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
        Invoke-WebRequest -Uri $OpenSSLURL -OutFile $OpenSSLInstallFile
    } Catch {
        Write-Error -Message "Failed to download $OpenSSLFileName" -InformationAction Stop
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
    Invoke-WebRequest -Uri $MySQLURL -OutFile $MySQLZipFile
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

# Program installation finished.  Restart now if required.
if ($RestartRequired) {
    Write-Information -MessageData "`n`n`nOne or more applications have been installed`nand PATH variables modified`nyou MUST close and reopen Powershell to continue`nrerun script to continue`n`n`n" -InformationAction Continue
    Break
}

# Downloading AzerothCore Repository
if (!(Test-Path -Path "$BaseLocation\.git\HEAD")) {
    Write-Information -MessageData "Creating Folder`nCloning AzerothCore Git Repo" -InformationAction Continue
    Try {
        New-Item -Path $BaseLocation -ItemType Directory
    } Catch {
        Write-Error -Message "Unable to create folder" -ErrorAction Stop
    }
    Write-Information -MessageData "Folder created`nCloning AzerothCore Git Repo" -InformationAction Continue
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
    Write-Information -MessageData "AzerothCore already exists`nUpdating repo now" -InformationAction Continue
    Try {
        Set-Location $BaseLocation
        git pull
        if (-not $?) {
            throw "git error! failed to update AzerothCore!"
        }
    } Catch {
        throw
    }
}

# Function to download modules

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

# Building the Server
Set-Location 'C:\Program Files\CMake\bin'
Write-Progress -Activity "Building Server" -Status "Compiling Source"
Write-Information -MessageData "Compiling and building will take some time. Go have a beer!" -InformationAction Continue
$BuildArgs = "-G `"Visual Studio 16 2019`" -A x64 -S $BaseLocation -B $BuildFolder"
Start-Process -FilePath 'C:\Program Files\CMake\bin\cmake.exe' -ArgumentList $BuildArgs -Wait
Write-Progress -Activity "Building Server" -Status "Final Build"
$FinalArgs = "--build $BuildFolder --config Release"
Start-Process -FilePath "C:\Program Files\CMake\bin\cmake.exe" -ArgumentList $FinalArgs -Wait

# Check to ensure build finished
if ((Test-Path -Path "$BuildFolder\bin\Release\authserver.exe") -and (Test-Path -Path "$BuildFolder\bin\Release\worldserver.exe")) {
    Write-Information -MessageData "Compile and build Successful! Continuing..." -InformationAction Continue
} else {
    Write-Information -MessageData "Compile and build failed.  Check cmake logs and try again." -InformationAction Continue
    break
}

# Create final server structure
Write-Information -MessageData "Creating final server" -InformationAction Continue
if (Test-Path -Path $FinalServerFolder) {
    Write-Information -MessageData "Server already exists! If you continue it will be deleted!" -InformationAction Continue
    do {
        $Response = Read-Host -Prompt "Continue? Y or N"
    } until (($Response -eq "y") -or ($Response -eq "n"))
    if ($Response -eq "y") {
        Remove-Item -Path "$FinalServerFolder" -Recurse -Force
    } else {
        Write-Information -MessageData "Move your previous server from $FinalServerFolder then try again" -InformationAction Continue
        break
    }
}
New-Item -Path $FinalServerFolder -ItemType Directory
Move-Item -Path "$BuildFolder\bin\Release" -Destination "$FinalServerFolder\Server"

# Copy all conf.dist files to .conf
$DistFiles = Get-ChildItem -Path "$FinalServerFolder\Server" -Filter "*.dist"
foreach ($Dist in $DistFiles) {
    $Conf = $Dist -replace ".{5}$"
    Copy-Item -Path "$FinalServerFolder\Server\$Dist" -Destination "$FinalServerFolder\Server\$Conf"
}

# Change .conf file settings
New-Item -Path "$FinalServerFolder\Server\Data" -ItemType Directory
New-Item -Path "$FinalServerFolder\Server\Logs" -ItemType Directory
$WorldServerConf = Get-Content -Path "$FinalServerFolder\Server\worldserver.conf"
$NewDataDir = $WorldServerConf -replace "DataDir = `".`"", "DataDir = `"Data`""
$NewDataDir | Set-Content -Path "$FinalServerFolder\Server\worldserver.conf"
$NewWorldServerConf = Get-Content -Path "$FinalServerFolder\Server\worldserver.conf"
$NewLogDir = $NewWorldServerConf -replace "LogsDir = `".`"", "LogsDir = `"Logs`""
$NewLogDir | Set-Content -Path "$FinalServerFolder\Server\worldserver.conf"
$AuthServerConf = Get-Content -Path "$FinalServerFolder\Server\authserver.conf"
$NewAuthLogDir = $AuthServerConf -replace "LogsDir = `"`"", "LogsDir = `"Logs`""
$NewAuthLogDir | Set-Content -Path "$FinalServerFolder\Server\authserver.conf"

if ($Downloaddata -eq "Yes") {
    Write-Information -MessageData "Download is >1Gb so it will take some time.  Go have another beer!" -InformationAction Continue
        Try {
            Invoke-WebRequest -Uri $AZCoreDataURL -OutFile $AZCoreDataZip
        } Catch {
            Write-Error -Message "Failed to download $AZCoreDataZipName" -InformationAction Stop
        }
        Write-Information -MessageData "Extracting files should take long enough for you to have another beer. Enjoy!" -InformationAction Continue
        Expand-Archive -Path $AZCoreDataZip -DestinationPath "$FinalServerFolder\Server\Data"
}
if ($Downloaddata -eq "No") {
    Write-Information -MessageData "`n`n!!Don't forget to manually copy data files!!`n`n" -InformationAction Continue
    Start-Sleep -Seconds 3
}

# Copy MySQL files to server
New-Item -Path "$FinalServerFolder\Server\database\bin" -ItemType Directory
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
    Copy-Item -Path "$SQLBinFile" -Destination "$FinalServerFolder\Server\database\bin"
}
Copy-Item -Path "C:\MySQL\share" -Destination "$FinalServerFolder\Server\database" -Recurse
Copy-Item -Path 'C:\MySQL\lib\libmysql.dll' -Destination "$FinalServerFolder\Server"
Copy-Item -Path "C:\Program Files\OpenSSL-Win64\libcrypto-1_1-x64.dll" -Destination "$FinalServerFolder\Server"


# Initialize MySQL
New-Item -Path "$FinalServerFolder\Server\database\tmp" -ItemType Directory
New-Item -Path "$FinalServerFolder\Server\database\data" -ItemType Directory
Set-Location "$FinalServerFolder\Server\database\bin"
Start-Process -FilePath "mysqld.exe" -ArgumentList "--initialize-insecure" -Wait

# Create MySQLini
$MySQLINI = "$FinalServerFolder\Server\database\my.ini"
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

# Create MySQLcnf
$MySQLCNF = "$FinalServerFolder\Server\database\config.cnf"
    New-Item -Path $MySQLCNF -ItemType File -Force
    Add-Content -Path $MySQLCNF -Value "[client]
    user = root
    password = $SQLRootPassword
    host = 127.0.0.1
    port = 3306"

# Create MySQLUpdatecnf
$MySQLCNF = "$FinalServerFolder\Server\database\mysqlupdate.cnf"
    New-Item -Path $MySQLCNF -ItemType File -Force
    Add-Content -Path $MySQLCNF -Value "[client]
    user = root
    password = $SQLRootPassword
    host = 127.0.0.1
    port = 3306"

# Create MySQL.bat
$MySQLbat = "$FinalServerFolder\start_mysql.bat"
New-Item -Path $MySQLbat -ItemType File -Force
Add-Content -Path $MySQLbat -Value "@echo off
SET NAME=MyCustomServer - mysql-5.6.46-winx64
TITLE %NAME%

echo.
echo.
echo Starting MySQL. Press CTRL C for server shutdown
echo.
echo.
cd .\Server\database\bin
mysqld --defaults-file=..\my.ini --console --standalone"

# Start the MySQL Server
Set-Location "$FinalServerFolder"
Start-Process -FilePath "start_mysql.bat"

# Set MySQL root pw
$sqlCMD = "ALTER USER 'root'@'localhost' IDENTIFIED BY '$SQLRootPassword';"
$SQLChangePWArgs = "-uroot --execute=`"$sqlCMD`""
Start-Process -FilePath "$FinalServerFolder\Server\database\bin\mysql.exe" -ArgumentList $SQLChangePWArgs -Wait -ErrorAction Stop
Write-Information -MessageData "Root password set to: $SQLRootPassword" -InformationAction Continue

# Create databases
$CreateDBCMD = Get-Content -Path "$BaseLocation\data\sql\create\create_mysql.sql"
$CreateDBArgs = "--defaults-file=$FinalServerFolder\Server\database\config.cnf --execute=`"$CreateDBCMD`""
Start-Process -FilePath "$FinalServerFolder\Server\database\bin\mysql.exe" -ArgumentList $CreateDBArgs -Wait

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
}
Set-Location -Path "$FinalServerFolder\Server\database\bin"
$authDBScriptsPath = "$BaseLocation\data\sql\base\db_auth"
$authDBupdateScriptsPath = "$BaseLocation\data\sql\updates\db_auth"
$characterDBScriptsPath = "$BaseLocation\data\sql\base\db_characters"
$characterDBupdateScriptsPath = "$BaseLocation\data\sql\updates\db_characters"
$worldDBScriptsPath = "$BaseLocation\data\sql\base\db_world"
$worldDBupdateScriptsPath = "$BaseLocation\data\sql\updates\db_world"

Import-SQLscripts -SQLDatabase "acore_auth" -SQLScriptsPath $authDBScriptsPath
Import-SQLscripts -SQLDatabase "acore_auth" -SQLScriptsPath $authDBupdateScriptsPath
Import-SQLscripts -SQLDatabase "acore_characters" -SQLScriptsPath $characterDBScriptsPath
Import-SQLscripts -SQLDatabase "acore_characters" -SQLScriptsPath $characterDBupdateScriptsPath
Import-SQLscripts -SQLDatabase "acore_world" -SQLScriptsPath $worldDBScriptsPath
Import-SQLscripts -SQLDatabase "acore_world" -SQLScriptsPath $worldDBupdateScriptsPath

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
}

# Stop SQL server after database configuration
Start-Process -FilePath "$FinalServerFolder\Server\database\bin\mysqladmin.exe" -ArgumentList "--user=root --password=$SQLRootPassword shutdown"

# Download HeidiSQL
$HeidiURL = "https://www.heidisql.com/downloads/releases/HeidiSQL_10.3_64_Portable.zip"
$HeidiFileName = $HeidiURL.Split("/")[-1]
$HeidiZipFile = "$env:USERPROFILE\Downloads\$HeidiFileName"
Try {
    Invoke-WebRequest -Uri $HeidiURL -OutFile $HeidiZipFile
} Catch {
    Write-Error -Message "Failed to download $HeidiFileName" -InformationAction Stop
}
Expand-Archive -Path $HeidiZipFile -DestinationPath "$FinalServerFolder\Tools\HeidiSQL"

# Create worldserver.bat
$WorldServerbat = "$FinalServerFolder\start_worldserver.bat"
New-Item -Path $WorldServerbat -ItemType File -Force
Add-Content -Path $WorldServerbat -Value "@echo off
echo.
echo This server was autocompiled using Windows PowerShell
echo https://github.com/stoudtlr/AzerothCore-Windows-AutoBuilder.git
echo.
echo Starting authserver. Press CTRL C for server shutdown
echo.
cd .\Server
start worldserver.exe"

# Create authserver.bat
$AuthServerbat = "$FinalServerFolder\start_authserver.bat"
New-Item -Path $AuthServerbat -ItemType File -Force
Add-Content -Path $AuthServerbat -Value "@echo off
echo.
echo This server was autocompiled using Windows PowerShell
echo https://github.com/stoudtlr/AzerothCore-Windows-AutoBuilder.git
echo.
echo Starting authserver. Press CTRL C for server shutdown
echo.
cd .\Server
start authserver.exe"

Write-Information -MessageData "`n`nServer finished! Go to $FinalServerFolder and run SQL,Auth, and World bat files to launch your server" -InformationAction Continue