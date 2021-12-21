######################window第三方库######################
# 在window平台下，根据自身的环境，提前预设置好需要的第三方库的
# <libname>-config.cmake目录，以及部分库的头文件目录，库文件目录。
##########################################################

## 项目名称
SET(PROJECT_NAME tusdkcore)

## 项目构建类型
if(WIN32)
	set(BUILD_TYPE STATIC)
elseif(UNIX)
	set(BUILD_TYPE SHARED)
endif()

get_filename_component(PROJECT_PATH "${CMAKE_CURRENT_LIST_FILE}" PATH)

if(WIN32)
	if (MSVC_VERSION GREATER_EQUAL "1900")
		add_compile_options("/std:c++17")
	endif()

	message(STATUS "##########################################################")
	message(STATUS "##current third_party_root is ${THIRD_PARTY_ROOT},\n##please set owns if needed!!!")
	message(STATUS "##########################################################")

	set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} 
		"${THIRD_PARTY_ROOT}/gflags/install/lib/cmake/gflags"
		"${THIRD_PARTY_ROOT}/glog/build64_2015/install/lib/cmake/glog"
		)
	
	######################rapidjson库######################
	set(RAPIDJSON_INCLUDB_DIR ${THIRD_PARTY_ROOT}/rapidjson/build/native/include)
	add_definitions("-D_CRT_SECURE_NO_WARNINGS")
elseif(UNIX)
	##suppprt c++17
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
endif(WIN32)

######################glog库######################

if(TUTU_GLOG_SUPPORT)
	add_definitions("-DTUTU_GLOG_SUPPORT")
	if(WIN32)
		find_package(glog REQUIRED)
		
		if(glog_FOUND)
			message(STATUS "-----------glog fonud-----------")
			set(GLOG_LIB glog::glog)
		else(glog_FOUND)
			message(FATAL_ERROR glog not found!!!)
		endif(glog_FOUND)
	elseif(UNIX)
		set(GLOG_LIB glog gflags)		
	endif(WIN32)

	set(EXTEND_OBJS ${GLOG_LIB})
endif(TUTU_GLOG_SUPPORT)

######################项目源码######################

file(GLOB_RECURSE PROJECT_HEADERS *.hh *.h *.hpp)
file(GLOB_RECURSE PROJECT_CPPS *.cc *.c *.cpp)
set(ALL_FILES ${PROJECT_HEADERS} ${PROJECT_CPPS})

source_group_by_dir(ALL_FILES)

## 构建库
add_library(${PROJECT_NAME} ${BUILD_TYPE} ${ALL_FILES})
## 链接头文件
target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_PATH} ${RAPIDJSON_INCLUDB_DIR})
## 链接其他库
target_link_libraries( ${PROJECT_NAME} PUBLIC ${EXTEND_OBJS})

if(UNIX)
	## 安装库	
install(TARGETS ${PROJECT_NAME} 
		LIBRARY DESTINATION /usr/local/lib
		)
endif()


message(STATUS "--tusdkcore compile done")
