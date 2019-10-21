cmake_minimum_required(VERSION 3.10)
# This file contains a bunch of commin things to do in cmake
# example useage
# include("cmake/common.cmake")
# INIT_BUILD() # set build type, opt flags and download submodules


if(NOT DEFINED MLIB_COMMON_CMAKE_INCLUDE_GUARD)
    set(MLIB_COMMON_CMAKE_INCLUDE_GUARD TRUE)
    macro(print_list name list)
        message("${name}")
        foreach(item IN LISTS ${list})
            message("  -- ${item}")
        endforeach()
    endmacro()

    macro(print_filenames name list)
        message("${name}")
        foreach(item IN LISTS ${list})
            get_filename_component(filename ${item} NAME)
            message("     ${filename}")
        endforeach()
    endmacro()

    macro(display_library name includes libs) # maybe add defines
        message("${name}")
        set(tab "    ")
        message("${tab}includes:")
        foreach(item IN LISTS ${includes})
            message("${tab}${tab}${item}")
        endforeach()
        message("${tab}libs:")
        foreach(item IN LISTS ${libs})
            message("${tab}${tab}${item}")
        endforeach()
        message("")
    endmacro()

    if(CMAKE_COMPILER_IS_GNUCXX)  # GCC
        message("Compiling Using GCC: ${CMAKE_CXX_COMPILER}")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        message("Compiling Using CLANG: ${CMAKE_CXX_COMPILER}")
    else()
        message("Unknown compiler: ${CMAKE_CXX_COMPILER}")
    endif()


    # add the cmake folder to module path for custom find scripts to likely positions
    LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/extern/mlib/extern/cmake" )
    LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/mlib/extern/cmake" )
    LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/extern/cmake" )
    LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" )
    LIST(APPEND CMAKE_MODULE_PATH "/usr/local/lib/cmake/" )        
    #print_list(CMAKE_MODULE_PATH CMAKE_MODULE_PATH) # uncomment to list where you are looking




    # setup basics, note, warnings are a per target property
    macro(INIT_BUILD)
        # common options
        option(verbose "build system is verbose"  ON)
        set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON) # default in windows already, should be default everywhere
        BuildConfig()
        OptimizationConfig()
        option(WError "Warnings are errors" OFF)
        if(WError)
            add_compile_options(-Werror)
        endif()
        option(enable_global_warnings, "applies warnings to everything" OFF)
        if(enable_global_warnings)
            WarningsConfig()
            add_compile_options(${WARNINGS})
        endif()
        #get_submodules()
        # ccache
        find_program(CCACHE_PROGRAM ccache)
        if(CCACHE_PROGRAM)
            set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
            set(CMAKE_CUDA_COMPILER_LAUNCHER "${CCACHE_PROGRAM}") # CMake 3.9+
        endif()
    endmacro()

    macro(get_submodules)# go download all the submodules

    find_package(Git REQUIRED)
    # Update submodules as needed
    option(GIT_SUBMODULE "Check submodules during build" OFF)
    if(GIT_SUBMODULE)
        message("Warning: \ngit submodules should only be used for projects which you do not also develop, otherwise use git subtree, or better yet, a symlink to the clone of the lib. ")
        message("Warning: \ngit submodules are inherently broken, and you will inevetably need to manually edit .git/ files ")
        message(STATUS "Submodule update")
        execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE GIT_SUBMOD_RESULT)
        if(NOT GIT_SUBMOD_RESULT EQUAL "0")
            message(FATAL_ERROR "git submodule update --init failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
        endif()
    endif()
    endmacro()

    # Build configuration
    macro(BuildConfig)

        set(default_build_type "Release")
        if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
            message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
            set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
                STRING "Choose the type of build." FORCE)
            # Set the possible values of build type for cmake-gui
            set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                "Debug" "Release" "RelWithDebInfo")
        endif()

    endmacro()




    macro(OptimizationConfig)

        set(common_flags "") # change to function to get the scope!
        option(WITH_RTTI "c++ rtti breaks dont pay for what you dont use, turn this off if possible" ON)
        if(NOT WITH_RTTI)
            list(APPEND common_flags -fno-rtti)
        endif()

        option(WITH_EXCEPTIONS "c++ exceptions breaks static determination of upper time for functions, which is critical in rt systems, turn this off if possible" ON)
        if(NOT WITH_EXCEPTIONS)
            list(APPEND common_flags -fno-exceptions)
        endif()

        option(WITH_FASTMATH "speeds up floating point math, at the cost of that nans must no longer occur and less repeatable results" OFF)
        if(NOT WITH_EXCEPTIONS)
            list(APPEND common_flags -fffast-math)
        endif()

        # basically three types
        # full debug
        set(debug_flags ${common_flags})
        list(APPEND debug_flags -g ) # debug symbols
        list(APPEND debug_flags -pg ) # profiling
        # for names in informative asserts (backtrace)
        # this one may be different between gcc and clang...
        list(APPEND debug_flags -rdynamic )
        list(APPEND debug_flags -fno-omit-frame-pointer ) # for names in informative asserts (backtrace)


        # full release
        set(release_flags ${common_flags})
        list(APPEND release_flags -O3) # optimization level
        list(APPEND release_flags -march=native) # allowed to use all instructions of this cpu
        list(APPEND release_flags -mtune=native) # acctually use all instructions of this cpu
        list(APPEND release_flags -DNDEBUG) # disable asserts

        if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            # be careful if you override these...
            # add_compile_options( isnt an option, it forces the flags with no way to avoid them, crashing with cuda
            # target_add_compile_otions would work though, but lets not...
            set(CMAKE_CXX_FLAGS_DEBUG "")
            foreach(item IN LISTS debug_flags)
                set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${item}")
            endforeach()

            set(CMAKE_CXX_FLAGS_RELEASE "")
            foreach(item IN LISTS release_flags)
                set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${item}")
            endforeach()


        else()
            message("TODO: fix opt options on this compiler, though the defaults are almost always good")
        endif()

    endmacro()

    macro(target_configure_optimization target)
        # its generally better to let compile options be common,
        # but I think thats what messes with cuda.
        # im not sure how the optimizer behaves with both nvcc and cxx compilers
    endmacro()

    macro(target_configure_warnings target)
        WarningConfig()
        target_compile_options(${target} PRIVATE ${WARNINGS})
    endmacro()


    macro(WarningConfig)
        set(warn "")


        if(CMAKE_COMPILER_IS_GNUCXX)  # GCC

            list(APPEND warn -Wall)
            list(APPEND warn -Wextra)
            #list(APPEND warn -Wstrict-aliasing)
            #list(APPEND warn -Wdouble-promotion)
            #list(APPEND warn -Weffc++)
            #list(APPEND warn -Wnull-dereference)
            #list(APPEND warn -Wsequence-point)
            #list(APPEND warn -Wshadow)
            #list(APPEND warn -Wunsafe-loop-optimizations)


            #list(APPEND warn -Wcast-qual)

            #list(APPEND warn -Wuseless-cast)
            #list(APPEND warn -Waddress)
            #list(APPEND warn -Waggressive-loop-optimizations)
            #list(APPEND warn -Winline)
            #set(warn "${warn} -Wno-unknown-pragmas")
            #set(warn "${warn} -Wno-sign-compare")
            #set(warn "${warn} -Wno-unused-parameter")
            #set(warn "${warn} -Wunused-parameter")
            #set(warn "${warn} -Wno-missing-field-initializers")
            #set(warn "${warn} -Wno-unused")
            #set(warn "${warn} -Wno-unused-function")
            #set(warn "${warn} -Wno-unused-label")
            #set(warn "${warn} -Wno-unused-parameter")
            #set(warn "${warn} -Wno-unused-value")
            #set(warn "${warn} -Wno-unused-variable")
            #set(warn "${warn} -Wno-unused-but-set-parameter")
            #set(warn "${warn} -Wno-unused-but-set-variable")

            #set(warn "${warn} -Wno-variadic-macros" )
            #set(warn "${warn} -Wno-deprecated-declarations" )

            #set(warn "${warn} -Wformat=2 ")
            #set(warn "${warn} -Wnounreachable-code")
            #set(warn "${warn} -Wswitch-default ")
            #set(warn "${warn}     -Winline ")
            #not relevant...
            #set(warn "${warn} -Wshadow")
            #set(warn "${warn} ")


        endif()
        if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")

            list(APPEND warn -W)
            if(TRUE)
                list(APPEND warn -Wall)
                list(APPEND warn -Wextra)
                list(APPEND warn -WCL4)

                list(APPEND warn -Wabstract-vbase-init)
                list(APPEND warn -Warc-maybe-repeated-use-of-weak)
                list(APPEND warn -Warc-repeated-use-of-weak)
                list(APPEND warn -Warray-bounds-pointer-arithmetic)
                list(APPEND warn -Wassign-enum)

                list(APPEND warn -Watomic-properties)
                list(APPEND warn -Wauto-import)
                list(APPEND warn -Wbad-function-cast)
                list(APPEND warn -Wbitfield-enum-conversion)
                list(APPEND warn -Wbitwise-op-parentheses)


                # specical ones!
                list(APPEND warn -Wcast-align)
                list(APPEND warn -Wcast-qual)



                list(APPEND warn -Wchar-subscripts)
                list(APPEND warn -Wcomma)
                list(APPEND warn -Wconditional-type-mismatch)
                list(APPEND warn -Wconditional-uninitialized)
                list(APPEND warn -Wconfig-macros)
                list(APPEND warn -Wconstant-conversion)
                list(APPEND warn -Wconsumed)
                list(APPEND warn -Wconversion)

                list(APPEND warn -Wcustom-atomic-properties)
                list(APPEND warn -Wdate-time)

                list(APPEND warn -Wdelete-non-virtual-dtor)
                #list(APPEND warn -Wdeprecated)
                list(APPEND warn -Wno-deprecated-declarations)
                list(APPEND warn -Wdeprecated-dynamic-exception-spec)
                list(APPEND warn -Wdeprecated-implementations)

                list(APPEND warn -Wdirect-ivar-access)
                list(APPEND warn -Wdisabled-macro-expansion)
                #list(APPEND warn -Wdocumentation)
                list(APPEND warn -Wduplicate-enum)
                list(APPEND warn -Wduplicate-method-arg)
                list(APPEND warn -Wduplicate-method-match)
                #list(APPEND warn -Weffc++)
                list(APPEND warn -Wembedded-directive)

                list(APPEND warn -Wempty-translation-unit)
                list(APPEND warn -Wexpansion-to-defined)

                list(APPEND warn -Wexperimental-isel)
                list(APPEND warn -Wexplicit-ownership-type)
                list(APPEND warn -Wextra-semi)


                list(APPEND warn -Wflexible-array-extensions)
                list(APPEND warn -Wfloat-conversion)
                #list(APPEND warn -Wfloat-equal)
                list(APPEND warn -Wfloat-overflow-conversion)
                list(APPEND warn -Wfloat-zero-conversion)

                list(APPEND warn -Wfor-loop-analysis)
                list(APPEND warn -Wformat-nonliteral)
                list(APPEND warn -Wformat-non-iso)
                list(APPEND warn -Wformat-pedantic)
                list(APPEND warn -Wfour-char-constants)
                option(Warn_on_globals "Warn on globals" OFF)
                if(Warn_on_globals)
                    list(APPEND warn -Wglobal-constructors)
                endif()


                list(APPEND warn -Wgnu)

                list(APPEND warn -Wheader-guard)
                list(APPEND warn -Wheader-hygiene)
                list(APPEND warn -Widiomatic-parentheses)
                list(APPEND warn -Wignored-qualifiers)
                list(APPEND warn -Wimplicit-atomic-properties)
                list(APPEND warn -Wimplicit)
                list(APPEND warn -Wimplicit-fallthrough)

                list(APPEND warn -Wimplicit-function-declaration)


                list(APPEND warn -Wimplicit-retain-self)
                list(APPEND warn -Wimport-preprocessor-directive-pedantic)


                list(APPEND warn -Winconsistent-dllimport)
                list(APPEND warn -Winconsistent-missing-destructor-override)
                list(APPEND warn -Winfinite-recursion)
                list(APPEND warn -Winvalid-or-nonexistent-directory)
                list(APPEND warn -Wkeyword-macro)
                list(APPEND warn -Wlanguage-extension-token)

                list(APPEND warn -Wlogical-op-parentheses)
                list(APPEND warn -Wmain)
                list(APPEND warn -Wmethod-signatures)
                list(APPEND warn -Wmismatched-tags)
                list(APPEND warn -Wmissing-braces)
                list(APPEND warn -Wmissing-field-initializers)
                list(APPEND warn -Wmissing-method-return-type)
                list(APPEND warn -Wmissing-noreturn)

                list(APPEND warn -Wmissing-variable-declarations)

                list(APPEND warn -Wmost)
                list(APPEND warn -Wmove)
                list(APPEND warn -Wnewline-eof)
                list(APPEND warn -Wnon-gcc)
                list(APPEND warn -Wnon-virtual-dtor)
                list(APPEND warn -Wnonportable-system-include-path)
                list(APPEND warn -Wnull-pointer-arithmetic)
                list(APPEND warn -Wnullable-to-nonnull-conversion)
                list(APPEND warn -Wobjc-interface-ivars)
                list(APPEND warn -Wobjc-messaging-id)
                list(APPEND warn -Wobjc-missing-property-synthesis)

                #list(APPEND warn -Wold-style-cast)
                list(APPEND warn -Wover-aligned)
                list(APPEND warn -Woverlength-strings)
                list(APPEND warn -Woverloaded-virtual)
                list(APPEND warn -Woverriding-method-mismatch)
                list(APPEND warn -Wpacked)
                #list(APPEND warn -Wpadded)
                list(APPEND warn -Wparentheses)


                list(APPEND warn -Wpessimizing-move)
                list(APPEND warn -Wpointer-arith)

                list(APPEND warn -Wpragma-pack)
                list(APPEND warn -Wpragma-pack-suspicious-include)
                list(APPEND warn -Wprofile-instr-missing)

                list(APPEND warn -Wrange-loop-analysis)
                list(APPEND warn -Wredundant-move)
                list(APPEND warn -Wredundant-parens)
                list(APPEND warn -Wreorder)
                list(APPEND warn -Wreserved-id-macro)
                list(APPEND warn -Wretained-language-linkage)
                list(APPEND warn -Wreserved-user-defined-literal)

                list(APPEND warn -Wselector)
                list(APPEND warn -Wself-assign)
                list(APPEND warn -Wself-move)
                list(APPEND warn -Wsemicolon-before-method-body)


                #list(APPEND warn -Wshadow-all)
                list(APPEND warn -Wshadow)
                list(APPEND warn -Wshadow-field)
                #list(APPEND warn -Wshadow-field-in-constructor)
                list(APPEND warn -Wshadow-uncaptured-local)
                list(APPEND warn -Wshadow-field-in-constructor-modified)



                list(APPEND warn -Wshift-sign-overflow)

                list(APPEND warn -Wshorten-64-to-32)
                list(APPEND warn -Wsign-compare)

                list(APPEND warn -Wno-sign-conversion)

                list(APPEND warn -Wsigned-enum-bitfield)
                list(APPEND warn -Wsometimes-uninitialized)
                list(APPEND warn -Wspir-compat)
                list(APPEND warn -Wstatic-in-inline)
                list(APPEND warn -Wstrict-prototypes)
                list(APPEND warn -Wstrict-selector-match)
                list(APPEND warn -Wstring-conversion)
                list(APPEND warn -Wsuper-class-method-mismatch)
                list(APPEND warn -Wswitch-enum)
                list(APPEND warn -Wtautological-compare)
                list(APPEND warn -Wtautological-constant-in-range-compare)
                list(APPEND warn -Wtautological-overlap-compare)

                list(APPEND warn -Wthread-safety)

                list(APPEND warn -Wthread-safety-negative)
                list(APPEND warn -Wthread-safety-verbose)
                list(APPEND warn -Wthread-safety-beta)

                list(APPEND warn -Wtrigraphs)
                list(APPEND warn -Wundeclared-selector)
                list(APPEND warn -Wundef)
                list(APPEND warn -Wundefined-func-template)
                list(APPEND warn -Wundefined-inline)
                list(APPEND warn -Wundefined-internal-type)
                list(APPEND warn -Wundefined-reinterpret-cast)
                list(APPEND warn -Wuninitialized)
                list(APPEND warn -Wunknown-escape-sequence)
                list(APPEND warn -Wunknown-pragmas)
                list(APPEND warn -Wunknown-sanitizers)
                list(APPEND warn -Wunknown-warning-option)
                list(APPEND warn -Wunneeded-internal-declaration)
                list(APPEND warn -Wunneeded-member-function)
                list(APPEND warn -Wunreachable-code)
                list(APPEND warn -Wunreachable-code-aggressive)
                list(APPEND warn -Wunused)
                list(APPEND warn -Wunused-const-variable)
                list(APPEND warn -Wunused-exception-parameter)
                list(APPEND warn -Wunused-function)
                list(APPEND warn -Wunused-label)
                list(APPEND warn -Wunused-lambda-capture)
                list(APPEND warn -Wunused-local-typedef)
                list(APPEND warn -Wunused-macros)
                list(APPEND warn -Wunused-member-function)
                list(APPEND warn -Wunused-parameter)
                list(APPEND warn -Wunused-private-field)
                list(APPEND warn -Wunused-property-ivar)
                list(APPEND warn -Wunused-template)
                list(APPEND warn -Wunused-value)
                list(APPEND warn -Wused-but-marked-unused)
                list(APPEND warn -Wunused-variable)
                list(APPEND warn -Wvariadic-macros)
                list(APPEND warn -Wvector-conversion)
                list(APPEND warn -Wweak-template-vtables)
                list(APPEND warn -Wweak-vtables)
                list(APPEND warn -Wzero-as-null-pointer-constant)
                list(APPEND warn -Wzero-length-array)


                list(APPEND warn-Rremark-backend-plugin)
                list(APPEND warn-Rsanitize-address)

                list(APPEND warn -Rmodule-build)
                list(APPEND warn -Rpass)
                list(APPEND warn -Rpass-analysis)

                # cuda stuff!
                list(APPEND warn -Wcuda-compat)

                # check specific to program version
                list(APPEND warn -Wc++11-extensions)
                list(APPEND warn -Wc++17-compat-pedantic)
            endif()
        endif()
        set(WARNINGS ${warn})
    endmacro()

    macro(relative_install files dest)
        foreach(file ${files})
            get_filename_component(dir ${file} DIRECTORY)
            install(FILES ${file} DESTINATION "${dest}/${dir}")
            message("DIR: ${dir}")
        endforeach()
    endmacro()




    MACRO(SUBDIRLIST result curdir)
    FILE(GLOB children RELATIVE ${curdir} ${curdir}/*)
    SET(dirlist "")
    FOREACH(child ${children})
    IF(IS_DIRECTORY ${curdir}/${child})
    LIST(APPEND dirlist ${child})
    ENDIF()
    ENDFOREACH()
    SET(${result} ${dirlist})
    ENDMACRO()





    macro(RANDOM_NUMBER_CONFIG)
        option(RANDOM_SEED_FROM_TIME "generate a seed from time, default" ON)
        list(APPEND RANDOM_DISPLAY "RANDOM_SEED_FROM_TIME: ${RANDOM_SEED_FROM_TIME}")
        if(NOT RANDOM_SEED_FROM_TIME)
            set(RANDOM_SEED "123" CACHE STRING "enter the string generated by a previous run"  FORCE)
            list(APPEND RANDOM_DISPLAY "RANDOM_SEED: ${RANDOM_SEED}")
        endif()


        if(RANDOM_SEED_FROM_TIME)
            add_definitions(-DRANDOM_SEED_FROM_TIME)
        else()
            add_definitions(-DRANDOM_SEED_VALUE=${RANDOM_SEED})
        endif()

        if(verbose)
            message("${line}")
            message("Random number options:")
            printlist("${RANDOM_DISPLAY}" "    ")
        endif()
    endmacro()

    macro(add_subdirectory_if_exists dir)
        if(EXISTS "${dir}/CMakeLists.txt")
            add_subdirectory(${dir})
        else()
            message("subdirectory not found? ${dir}")
        endif()
    endmacro()


    macro(testit name libs)
        if(BUILD_TESTING)
        string(TOUPPER ${name} uname)
        add_executable(test_${name} test_${name}.cpp)
        foreach(item ${libs})
            target_link_libraries(test_${name}  ${item})
        endforeach()
        add_test(TEST_${uname} test_${name} COMMAND TargetName)
    endif()
    endmacro()




    macro(getheadersandsourcesrec)

        FILE(GLOB module_HDRS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)
        set(HDRS ${HDRS} ${module_HDRS} PARENT_SCOPE)

        FILE(GLOB module_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
        set(SRCS ${SRCS} ${module_SRCS} PARENT_SCOPE)
        # recurcisve install
        #install(DIRECTORY ../sfm DESTINATION ${INCLUDE_INSTALL_DIR} FILES_MATCHING PATTERN "*.h" )
        #install(DIRECTORY ../sfm DESTINATION ${INCLUDE_INSTALL_DIR} FILES_MATCHING PATTERN "*.hpp" )
    endmacro()



endif(NOT DEFINED MLIB_COMMON_CMAKE_INCLUDE_GUARD)

