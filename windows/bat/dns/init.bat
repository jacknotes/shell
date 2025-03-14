@echo off
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

powershell.exe .\RunSetDNS.ps1