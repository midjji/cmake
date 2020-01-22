
#/usr/include/sqlite3.h#
#/usr/lib/x86_64-linux-gnu/libsqlite3.so
add_library(SQLite::SQLite3 UNKNOWN IMPORTED)
set_target_properties(SQLite::SQLite3 PROPERTIES
            IMPORTED_LOCATION             "/usr/lib/x86_64-linux-gnu/libsqlite3.so"
            INTERFACE_INCLUDE_DIRECTORIES "/usr/include/")

