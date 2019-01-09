@echo off
SET VERSION=1.7
lrun config/encrypt.lua %1 > UserInfo.lua
call luadep imperiaonline ImperiaOnline
mkdir "users\%1-%VERSION%"
copy install\*.* "users\%1-%VERSION%\"
copy imperiaonline_files\ImperiaOnline.lux* users\%1-%VERSION%\
REM cd users
REM \cygwin\bin\zip -r "%1-%VERSION%.zip" "%1-%VERSION%"
REM cd ..
REM move users\%1-%VERSION%.zip z:\
