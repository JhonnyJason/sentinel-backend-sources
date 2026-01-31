############################################################
import fs from "fs"
import path from "path"

############################################################
import { report } from "./bugsnitchmodule.js"

############################################################
localCfg = Object.create(null)

try
    configPath = path.resolve(process.cwd(), "./.config.json")
    localCfgString = fs.readFileSync(configPath, 'utf8')
    localCfg = JSON.parse(localCfgString)
catch err
    msg = "[configmodule]: Local Config File could not be read or parsed!"
    msg += "\n> "+err.message
    report(msg)

############################################################
export apiKeyBls = localCfg.apiKeyBls || ""
export apiKeyBea = localCfg.apiKeyBea || ""
export apiKeyFred = localCfg.apiKeyFred || ""
export apiKeyEstat = localCfg.apiKeyEstat || ""
export apiKeyAbs = localCfg.apiKeyAbs || ""
# export apiKeyNz = localCfg.apiKeyNz || "" # New Zealand new Data sharing Portal - does not have the right data available...
export rbnzUserAgent = localCfg.rbnzUserAgent || ""

############################################################
export accessManagerId = localCfg.accessManagerId || ""
export snitchSocket = localCfg.snitchSocket || "/run/bugsnitch.sk"

############################################################
localCfg = null

############################################################
export name = "sentinel-backend"
export legalOrigins = [
    "localhost", 
    "localhost:3333", 
    "sentinel-backend.dotv.ee",
    "sentinel-dashboard-dev.dotv.ee",
    "sentinel.ewag-handelssysteme.de"
]

############################################################
export fallbackAuthCode = "aaaaaaaabbbbbbbbccccccccdddddddd"

############################################################
export statisticsDataRequestHeartbeatMS = 3_600_000 #1h

############################################################
export cotDataRequestHeartbeatMS = 86_400_000 #24h

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

# export testRun = "zealandMRR"
# export testRun = "zealandHICP"
# export testRun = "zealandGDPG"

# export testRun = "ukMRR"
# export testRun = "ukHICP"
# export testRun = "ukGDPG"

# export testRun = "cotData"

# export testRun = "accounts"