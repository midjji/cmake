
cmake_minimum_required(VERSION 3.16)
if(NOT DEFINED MLIB_DEPENDENCIES_CMAKE_INCLUDE_GUARD)
    set(DEFINED MLIB_DEPENDENCIES_CMAKE_INCLUDE_GUARD TRUE)

    # Cmake include file
    # the standard mlib dependencies

    macro(FIND_FILESYSTEM)
        if(NOT DEFINED FIND_FILESYSTEM_GUARD)
            set(FIND_FILESYSTEM_GUARD TRUE)
            # filesystem will be a pain in the ass for a while
            # TODO fix the namespace so its always just std::fs not std::experimental::fs...
            # TODO fix the FINDMODULE thingy...

            #if(TARGET std::filesystem)        return()    endif()

            add_library(stdfs INTERFACE )
            target_compile_features(stdfs INTERFACE cxx_std_14)

            if(CMAKE_COMPILER_IS_GNUCXX)
                set(Filesystem_FOUND TRUE)
                target_link_libraries(stdfs INTERFACE -lstdc++fs)
            endif()
            if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
                set(Filesystem_FOUND TRUE)
                target_link_libraries(stdfs INTERFACE -lstdc++fs)
                #target_link_libraries(stdfs INTERFACE -lc++fs)
            endif()
            if(NOT Filesystem_FOUND)
                message(FATAL_ERROR "std::experimental::filesystem missing")
            endif()
        endif()
    endmacro()




    macro(Find_OpenCV)
        message("\n${line}\n")
        message("OpenCV 4\n")
        find_package( OpenCV 4 REQUIRED)

        message("-- Found OpenCV version ${OpenCV_VERSION}")
        set(OpenCV_LIBRARIES ${OpenCV_LIBS} )# fixes the name
        # pulls in cuda options, mark them as advanced...
        mark_as_advanced(FORCE CUDA_BUILD_CUBIN)
        mark_as_advanced(FORCE CUDA_BUILD_EMULATION)
        mark_as_advanced(FORCE CUDA_HOST_COMPILER)
        mark_as_advanced(FORCE CUDA_SDK_ROOT_DIR)
        mark_as_advanced(FORCE CUDA_SEPARABLE_COMPILATION)
        mark_as_advanced(FORCE CUDA_TOOLKIT_ROOT_DIR)
        mark_as_advanced(FORCE CUDA_verbose_BUILD)

        if(verbose)
            message("-- Include directories:")
            print_list(${OpenCV_INCLUDE_DIRS} "    ")
            message("-- OpenCV_Libraries:  ")
            print_list("${OpenCV_LIBRARIES}" "    ")
        endif()
        add_definitions(-DWITH_OPENCV)
    endmacro()



    macro(FIND_OSG)
        message("\n${line}\n")
        message("OSG\n")
        find_package(OpenSceneGraph 3 REQUIRED osgDB osgUtil osgViewer osgGA osgWidget REQUIRED)

        message("\nFound OSG Version: ${OPENSCENEGRAPH_VERSION}")
        add_definitions(-DWITH_OSG)

        mark_as_advanced(FORCE OPENTHREADS_INCLUDE_DIR)
        mark_as_advanced(FORCE OPENTHREADS_LIBRARY)
        mark_as_advanced(FORCE OPENTHREADS_LIBRARY_DEBUG)
        mark_as_advanced(FORCE OSGDB_INCLUDE_DIR)
        mark_as_advanced(FORCE OSGDB_LIBRARY     )
        mark_as_advanced(FORCE OSGDB_LIBRARY_DEBUG)
        mark_as_advanced(FORCE OSGGA_INCLUDE_DIR   )
        mark_as_advanced(FORCE OSGGA_LIBRARY        )
        mark_as_advanced(FORCE OSGGA_LIBRARY_DEBUG   )
        mark_as_advanced(FORCE OSGUTIL_INCLUDE_DIR )
        mark_as_advanced(FORCE OSGUTIL_LIBRARY      )
        mark_as_advanced(FORCE OSGUTIL_LIBRARY_DEBUG )
        mark_as_advanced(FORCE OSGVIEWER_INCLUDE_DIR  )
        mark_as_advanced(FORCE OSGVIEWER_LIBRARY       )
        mark_as_advanced(FORCE OSGVIEWER_LIBRARY_DEBUG  )
        mark_as_advanced(FORCE OSGWIDGET_INCLUDE_DIR  )
        mark_as_advanced(FORCE OSGWIDGET_LIBRARY )
        mark_as_advanced(FORCE OSGWIDGET_LIBRARY_DEBUG   )
        mark_as_advanced(FORCE OSG_INCLUDE_DIR  )
        mark_as_advanced(FORCE OSG_LIBRARY         )
        mark_as_advanced(FORCE OSG_LIBRARY_DEBUG)


        if(verbose)
            message("OpenSceneGraph include directories: ${OPENSCENEGRAPH_INCLUDE_DIR}")
            message("OpenSceneGraph libraries: ")
            print_list("${OPENSCENEGRAPH_LIBRARIES}" "    ")
        endif()
    endmacro()


    macro(Find_Ceres)
        message("\n${line}\n")
        message("Ceres: \n")
        find_package(Ceres 1.1 REQUIRED)
        message("Warning changed from 1.14 to 1.1, may mess up daimler")
        message("\n -- Found Ceres Version: ${CERES_VERSION}")
        message("Ceres include directories: ")
        print_list("${CERES_INCLUDE_DIRS}" "    ")
        message("Ceres libraries: ${CERES_LIBRARIES}")
    endmacro()


    macro(Find_Curses)
        message("\n${line}\n")
        message("Curses: \n")
        FIND_PACKAGE(Curses REQUIRED)
        message("\n -- Found Curses Version: ${CURSES_VERSION}")
        INCLUDE_DIRECTORIES(${CURSES_INCLUDE_DIRS})
        link_directories(${CURSES_LIBRARIES})

        list(APPEND EXTLIBS ${CURSES_LIBRARIES})
        add_definitions("-DWITH_CURSES")



        message("Curses include directories: ${CURSES_INCLUDE_DIRS}")
        message("Curses libraries: ")
        print_list("${CURSES_LIBRARIES}" "    ")
    endmacro()

endif()




