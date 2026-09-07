############################################################
import fs from "fs"
import path from "path"

############################################################
import { report } from "./bugsnitchmodule.js"

############################################################
localCfg = Object.create(null)

try
    configPath = path.resolve(process.cwd(), ".config.json")
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
# local testing: "21e35d83b9960ce67da1b2a132edc99d633cf41336ac591960aa30ad1d958a25"
# remote testing: "d9475cc24ed55635304a4b1e310dc4200a581c8f7099ab0dfae7cec2dad94fe1"
export accessManagerId = localCfg.accessManagerId || ""

export snitchSocket = localCfg.snitchSocket || "/run/bugsnitch.sk"


############################################################
export statisticsDataRequestHeartbeatMS = localCfg.makroHeartbeatMS || 3_600_000 #1h

############################################################
export cotDataRequestHeartbeatMS = localCfg.cotHeartbeatMS || 43_200_000 #12h

export legalOrigins = localCfg.legalOrigins || [
    "localhost", 
    "localhost:3333", 
    "sentinel-backend.dotv.ee",
    "sentinel-dashboard-dev.dotv.ee",
    "sentinel.ewag-handelssysteme.de"
]

############################################################
localCfg = null

############################################################
export name = "sentinel-backend"
export version = "0.0.2"

############################################################
export fallbackAuthCode = "aaaaaaaabbbbbbbbccccccccdddddddd"


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
# export testRun = "zealandHICP" # maybe check
# export testRun = "zealandGDPG" # maybe check

# export testRun = "ukMRR"
# export testRun = "ukHICP"
# export testRun = "ukGDPG"

# export testRun = "cotData"

# export testRun = "accounts"

# export testRun = "eventdata"