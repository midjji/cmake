
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
        message("${line}")
        find_package( OpenCV 4 REQUIRED)
        # pulls in cuda options, mark them as advanced...
        mark_as_advanced(FORCE CUDA_BUILD_CUBIN)
        mark_as_advanced(FORCE CUDA_BUILD_EMULATION)
        mark_as_advanced(FORCE CUDA_HOST_COMPILER)
        mark_as_advanced(FORCE CUDA_SDK_ROOT_DIR)
        mark_as_advanced(FORCE CUDA_SEPARABLE_COMPILATION)
        mark_as_advanced(FORCE CUDA_TOOLKIT_ROOT_DIR)
        mark_as_advanced(FORCE CUDA_verbose_BUILD)
        mark_as_advanced(FORCE CCACHE_PROGRAM)


        set(OpenCV_LIBRARIES ${OpenCV_LIBS} )# fixes the name
        add_library(opencv INTERFACE )
        # opencv will possibly fix this at some point...
        target_link_libraries(opencv INTERFACE ${OpenCV_LIBS})
        target_include_directories(opencv INTERFACE ${OpenCV_INCLUDE_DIRS})
        message("Found OpenCV Version ${OpenCV_VERSION}, created target opencv")
        if(verbose)            
            print_list("OpenCV include directories:" OpenCV_INCLUDE_DIRS)
            print_list("OpenCV libraries:  " OpenCV_LIBRARIES)
        endif()
        # this also makes the targets
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




