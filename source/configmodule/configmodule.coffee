############################################################
import fs from "fs"
import path from "path"

############################################################
import * as sS from "./serverstatemodule.js"

try
    configPath = path.resolve(process.cwd(), "./.config.json")
    localCfgString = fs.readFileSync(configPath, 'utf8')
    localCfg = JSON.parse(localCfgString)
catch err
    console.error "Local Config File could not be read or parsed!"
    console.error err
    sS.setError(err)
    localCfg = {}

############################################################
export blsAPIKey = localCfg.blsAPIKey || ""
export beaAPIKey = localCfg.beaAPIKey || ""
export fredAPIKey = localCfg.fredAPIKey || ""
export estatAPIKey = localCfg.estatAPIKey || ""
export passphrase = localCfg.blsAPIKey || "I shall pass!"

############################################################
export statisticsDataRequestHeartbeatMS = 3600000 #1h

