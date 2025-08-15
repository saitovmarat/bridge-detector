@echo off
:: clone-modules.bat
:: Скрипт для клонирования подмодулей в папку modules

setlocal

set MODULES_DIR=%~dp0modules

echo [1/3] Проверка и создание папки modules...
if not exist "%MODULES_DIR%" (
    mkdir "%MODULES_DIR%"
    if %errorlevel% neq 0 (
        echo ОШИБКА: Не удалось создать папку modules
        exit /b 1
    )
    echo Папка modules создана.
) else (
    echo Папка modules уже существует.
)

cd /d "%MODULES_DIR%"

echo.
echo [2/3] Клонирование репозитория bridge-detector-api...
if not exist "bridge-detector-api" (
    git clone https://github.com/saitovmarat/bridge-detector-api.git bridge-detector-api
    if %errorlevel% neq 0 (
        echo ОШИБКА: Не удалось клонировать bridge-detector-api
        exit /b 1
    )
    echo OK: bridge-detector-api успешно клонирован.
) else (
    echo ПРЕДУПРЕЖДЕНИЕ: Папка bridge-detector-api уже существует. Пропускаем клонирование.
)

echo.
echo [3/3] Клонирование репозитория bridge-detector-client...
if not exist "bridge-detector-client" (
    git clone https://github.com/saitovmarat/bridge-detector-client.git bridge-detector-client
    if %errorlevel% neq 0 (
        echo ОШИБКА: Не удалось клонировать bridge-detector-client
        exit /b 1
    )
    echo OK: bridge-detector-client успешно клонирован.
) else (
    echo ПРЕДУПРЕЖДЕНИЕ: Папка bridge-detector-client уже существует. Пропускаем клонирование.
)

echo.
echo ✅ Все репозитории успешно клонированы (или уже существуют).
echo.
echo Следующий шаг: запустите CMake из корня проекта.
pause