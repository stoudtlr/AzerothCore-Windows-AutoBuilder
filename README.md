# AzerothCore-Windows-AutoBuilder
Windows PowerShell script to automate the entire build process

Script performs ALL actions needed to compile your own server core
1. Downloads and installs CMAKE, VS studio, MySQL, etc
2. Clones AzerothCore repository
3. Searches the catalogue and allows you to select the additional modules you want included
4. Allows easy testing of pull requests
5. Compiles and builds the server
6. Runs all sql scripts to include sql files included with modules
7. Can create personal server / repack

## Instructions
1. Launch Powershell as admin and run the following command:
  Set-ExecutionPolicy Unrestricted
2. copy script to your PC
3. Open folder you saved the script to with File Explorer
4. Right click on script and choose "edit"
5. edit these lines to match the folders you want used and the password for SQL root account
![image](https://user-images.githubusercontent.com/36058236/132113742-08479d56-d1a4-4eb9-b7b6-d4c7e09da23a.png)
6. Click File > Open Windows Powershell (must choose to run as admin if you are installing dependencies,
   otherwise PowerShell can be launched without admin rights)
7. Start script by typing the following command into powershell:
.\Start-AzerothCoreAutoBuilder.ps1

A window will show up displaying your options.  Simply choose the one you want to use.
![image](https://user-images.githubusercontent.com/36058236/132113658-6070c6cc-ce26-4ba3-a93e-67abf7a996ff.png)

### To build a server
1. option 1 if you have never used the script before to ensure all dependencies get installed
2. option 2 to clone the AzerothCore repositories
3. option 4 to choose and download any custom modules you want included
4. option 5 to build the server
5. option 6 to start the server if just testing OR
6. option 7 to move all files to folder you chose on line 26 of the script.  This ensures your own personal
   server is never overwritten while testing PR's

### To test PR's
1. option 2 to clean and update the base AzerothCore files from GitHub
2. option 3 and then enter the PR number you wish to test
![image](https://user-images.githubusercontent.com/36058236/132113848-170f6165-32b8-4fcf-8c25-e85b2469bc21.png)
3. option 5 to build the server and database.  All pending SQL files from the PR are added to the database. No manual steps required
4. option 6 to start the server and begin your testing
5. once finished you can choose option 2 again to clean your base files and return to the default state so you can begin testing the next PR.
