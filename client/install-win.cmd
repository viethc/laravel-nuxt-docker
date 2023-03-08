@echo off

SET NUXT_VERSION=3
SET ENV_DIST_FILE=.env.dev
SET ENV_FILE=.env
SET GATEWAY_NETWORK=gateway
SET COMPOSE_FILE=docker-compose.dev.yml
SET APP_CONTAINER=app
SET TEMP_INSTALL_DIRECTORY=src
SET SELF_DESTRUCTION=false
IF "%~1" == "--nuxt2" "]" || [ "%~1" == "--nuxt-2" (
  shift "1"
  SET NUXT_VERSION=2
)
IF "%~1" == "--destruct" (
  shift "1"
  SET SELF_DESTRUCTION=true
)
echo "Using Nuxt %NUXT_VERSION% version"
IF "%NUXT_VERSION%" == "2" (
  COPY  "stubs\nuxt2\." "."
)
IF "!" "-f" "%ENV_FILE%" (
  COPY  "%ENV_DIST_FILE%" "%ENV_FILE%"
)
docker "network" "create" "%GATEWAY_NETWORK%"
docker "compose" "-f" "%COMPOSE_FILE%" "build"
IF "%NUXT_VERSION%" == "2" (
  docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "--user" "%undefined%":"%undefined%" "%APP_CONTAINER%" "yarn" "create" "nuxt-app" "%TEMP_INSTALL_DIRECTORY%"
) ELSE (
  docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "--user" "%undefined%":"%undefined%" "%APP_CONTAINER%" "npx" "nuxi" "init" "%TEMP_INSTALL_DIRECTORY%"
)
sudo "chown" "-R" "%undefined%":"%undefined%" "%TEMP_INSTALL_DIRECTORY%"
mv "%TEMP_INSTALL_DIRECTORY%/*" "%TEMP_INSTALL_DIRECTORY%/.*" "."
DEL /S "%TEMP_INSTALL_DIRECTORY%"
IF "%NUXT_VERSION%" == "3" (
  docker "compose" "-f" "%COMPOSE_FILE%" "run" "--rm" "--no-deps" "--user" "%undefined%":"%undefined%" "%APP_CONTAINER%" "yarn" "install"
)
docker "compose" "-f" "%COMPOSE_FILE%" "up" "-d"
IF "%SELF_DESTRUCTION%" == "true" (
  echo "Removing stubs directory"
  DEL /S "stubs"
  echo "Removing installation script"
  DEL  "%CD%\install"
)
echo "The client app has been installed and run on http://localhost:3000."