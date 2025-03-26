@echo off
:: Runs the founder_return update task

set RELEASE_NAME=startup_game
set RELEASE_ROOT=%~dp0..

set release_ctl=%RELEASE_ROOT%\bin\%RELEASE_NAME%.bat

:: Run the task
call %release_ctl% eval "StartupGame.Release.update_founder_returns()"
