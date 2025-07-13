import Modules from "./allmodules"

############################################################
global.allModules = Modules
import *  as cfg from "./configmodule.js"

############################################################
run = ->
    promises = (m.initialize(cfg) for n,m of Modules when m.initialize?) 
    await Promise.all(promises)
    Modules.startupmodule.serviceStartup()

############################################################
run()
