import { addModulesToDebug } from "thingy-debug"

############################################################
modulesToDebug = {
    accessmodule: true
    authmodule: true
    # cotdatamodule: true
    # eurodata: true
    # usdata: true
    # japandata: true
    # swissdata: true
    # canadadata: true
    # aussiedata: true
    # ukdata: true
    # zealanddata: true
    # scicoremodule: true
    scimodule: true
    # startupmodule: true
    wsimodule: true
}

addModulesToDebug(modulesToDebug)
