# AzerothCore-Windows-AutoBuilder
Windows PowerShell script to automate the entire build process

Script performs ALL actions needed to compile your own server core
1. Downloads and installs CMAKE, VS studio, MySQL, etc
2. Clones AzerothCore repository
3. Searches the catalogue and allows you to select the additional modules you want included
4. Compiles and builds the server
5. Runs all sql scripts to include sql files included with modules
6. Downloads and copies HeidiSQL to your server folder
