cmake_minimum_required(VERSION 3.14)

project(bridge-detector LANGUAGES CXX)

find_package(Python3 REQUIRED COMPONENTS Interpreter)

include(ProcessorCount)
if(COMMAND ProcessorCount)
    ProcessorCount(N)
    if(NOT N EQUAL 0)
        set(CMAKE_BUILD_PARALLEL_STD ${N} CACHE INTERNAL "parallel jobs")
    endif()
else()
    message(STATUS "ProcessorCount не доступен — параллельная сборка не настроена")
endif()

set(API_DIR ${CMAKE_CURRENT_SOURCE_DIR}/modules/bridge-detector-api)
set(REQUIREMENTS_FILE ${API_DIR}/requirements.txt)
set(VENV_DIR ${CMAKE_CURRENT_SOURCE_DIR}/.venv)

if(NOT EXISTS ${REQUIREMENTS_FILE})
    message(FATAL_ERROR "Файл requirements.txt не найден: ${REQUIREMENTS_FILE}
    Убедитесь, что репозиторий bridge-detector-api клонирован в папку modules/")
endif()

if(WIN32)
    set(PYTHON_VENV_BIN_DIR Scripts)
    set(PYTHON_EXECUTABLE_IN_VENV ${VENV_DIR}/Scripts/python.exe)
else()
    set(PYTHON_VENV_BIN_DIR bin)
    set(PYTHON_EXECUTABLE_IN_VENV ${VENV_DIR}/bin/python)
endif()

set(SETUP_DONE_FLAG ${VENV_DIR}/.setup_done)

add_custom_command(
    OUTPUT ${SETUP_DONE_FLAG}
    COMMAND ${CMAKE_COMMAND} -E echo "🔧 Создаём виртуальное окружение и устанавливаем зависимости..."
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${VENV_DIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${VENV_DIR}
    COMMAND ${Python3_EXECUTABLE} -m venv ${VENV_DIR}
    COMMAND ${PYTHON_EXECUTABLE_IN_VENV} -m pip install --upgrade pip
    COMMAND ${CMAKE_COMMAND} -E chdir ${API_DIR} 
            ${PYTHON_EXECUTABLE_IN_VENV} -m pip install -r ${REQUIREMENTS_FILE}
    COMMAND ${CMAKE_COMMAND} -E touch ${SETUP_DONE_FLAG}
    COMMENT "📦 Установка Python-зависимостей в виртуальное окружение..."
    VERBATIM
)

add_custom_target(setup_python DEPENDS ${SETUP_DONE_FLAG})
set_property(TARGET setup_python PROPERTY USES_TERMINAL TRUE)

add_custom_command(TARGET setup_python POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "✅ Python-зависимости установлены в ${VENV_DIR}"
)

set(MODULES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/modules)

if(EXISTS ${MODULES_DIR})
    message(STATUS "🔍 Поиск модулей в папке: ${MODULES_DIR}")

    file(GLOB MODULE_FOLDERS LIST_DIRECTORIES true ${MODULES_DIR}/*)

    list(FILTER MODULE_FOLDERS EXCLUDE REGEX "/\\.")
    list(FILTER MODULE_FOLDERS EXCLUDE REGEX "/__pycache__")

    foreach(MODULE_PATH IN LISTS MODULE_FOLDERS)
        get_filename_component(MODULE_NAME ${MODULE_PATH} NAME)

        set(CMAKELISTS_FILE ${MODULE_PATH}/CMakeLists.txt)

        if(EXISTS ${CMAKELISTS_FILE})
            message(STATUS "📦 Подключаю модуль: ${MODULE_NAME}")
            add_subdirectory(${MODULE_PATH} ${CMAKE_CURRENT_BINARY_DIR}/modules/${MODULE_NAME})
        else()
            message(STATUS "⚠️  Пропущено: ${MODULE_NAME} — нет CMakeLists.txt")
        endif()
    endforeach()
else()
    message(WARNING "Папка modules/ не найдена: ${MODULES_DIR}")
endif()

if(TARGET BridgeVision)
    add_custom_target(run_client
        COMMAND $<TARGET_FILE:BridgeVision>
        DEPENDS BridgeVision
        USES_TERMINAL
        COMMENT "🎮 Запуск клиента BridgeVision..."
    )
    message(STATUS "🎯 Добавлен таргет: run_client")
endif()

message(STATUS "")
message(STATUS "💡 Доступные команды сборки:")
message(STATUS "   setup_python — установить Python-зависимости")
message(STATUS "   BridgeVision — собрать C++ клиент")
message(STATUS "   run_client   — запустить C++ клиент")
message(STATUS "")