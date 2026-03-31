@echo off
setlocal
node "%~dp0studio-bridge.js" %*
exit /b %errorlevel%
