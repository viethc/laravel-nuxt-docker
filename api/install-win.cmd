@echo off

SET INSTALL_BREEZE=false
SET ENV_DIST_FILE=.env.dev
SET ENV_FILE=.env
SET GATEWAY_NETWORK=gateway
SET COMPOSE_FILE=docker-compose.dev.yml
SET APP_CONTAINER=app
SET TEMP_INSTALL_DIRECTORY=src
SET SELF_DESTRUCTION=false
IF "%~1" == "--breeze" (
  shift "1"
  SET INSTALL_BREEZE=true
)
IF "%~1" == "--destruct" (
  shift "1"
  SET SELF_DESTRUCTION=true
)
IF "!" "-f" "%ENV_FILE%" (
  COPY  "%ENV_DIST_FILE%" "%ENV_FILE%"
)
docker "network" "create" "%GATEWAY_NETWORK%"
make "build.all"
CALL :install_laravel
CALL :install_octane
IF "%INSTALL_BREEZE%" == "true" (
  CALL :install_breeze
)
docker "compose" "-f" "%COMPOSE_FILE%" "up" "-d"
IF "%SELF_DESTRUCTION%" == "true" (
  echo "Removing stubs directory"
  DEL /S "stubs"
  echo "Removing installation script"
  DEL  "%CD%\install"
)
echo "The API app has been installed and run on http://localhost:8000."

EXIT /B %ERRORLEVEL%

:install_laravel
docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "%APP_CONTAINER%" "composer" "create-project" "--prefer-dist" "laravel\laravel" "%TEMP_INSTALL_DIRECTORY%"
sudo "chown" "-R" "%undefined%":"%undefined%" "./%TEMP_INSTALL_DIRECTORY%"
DEL  "%TEMP_INSTALL_DIRECTORY%/%ENV_FILE%"
mv "%TEMP_INSTALL_DIRECTORY%/*" "%TEMP_INSTALL_DIRECTORY%/.*" "."
DEL /S "%TEMP_INSTALL_DIRECTORY%"
docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "%APP_CONTAINER%" "php" "artisan" "key:generate" "--ansi"
EXIT /B 0

:install_octane
docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "%APP_CONTAINER%" "composer" "require" "laravel\octane"
docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "--user" "%undefined%":"%undefined%" "%APP_CONTAINER%" "php" "artisan" "octane:install" "--server=swoole"
EXIT /B 0

:install_breeze
docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "%APP_CONTAINER%" "composer" "require" "laravel\breeze" "--dev"
docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "--user" "%undefined%":"%undefined%" "%APP_CONTAINER%" "php" "artisan" "breeze:install" "api"
EXIT /B 0