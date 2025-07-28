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
export absAPIKey = localCfg.absAPIKey || ""
export passphrase = localCfg.passphrase || "I shall pass!"

############################################################
export statisticsDataRequestHeartbeatMS = 3600000 #1h

############################################################
# export testRun = "euroMRR"
# export testRun = "euroHICP"
# export testRun = "euroGDPG"

# export testRun = "usMRR"
# export testRun = "usHICP"
# export testRun = "usGDPG"

# export testRun = "japanMRR"
# export testRun = "japanHICP"
# export testRun = "japanGDPG"

# export testRun = "swissMRR"
# export testRun = "swissHICP"
# export testRun = "swissGDPG"

# export testRun = "canadaMRR"
# export testRun = "canadaHICP"
# export testRun = "canadaGDPG"

# export testRun = "aussieMRR"
# export testRun = "aussieHICP"
# export testRun = "aussieGDPG"
