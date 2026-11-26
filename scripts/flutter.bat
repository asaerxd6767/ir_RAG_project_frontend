@echo off
rem Flutter's Windows tool cannot use a \\wsl.localhost\... UNC path as its
rem working directory. pushd maps it to a temporary drive letter for the call.
setlocal
pushd "%~dp0.." || exit /b 1
flutter %*
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
