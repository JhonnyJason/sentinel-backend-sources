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
    throw new Error("Just testing errorReporting :-)")
catch err
    msg = "[configmodule]: Local Config File could not be read or parsed!"
    msg += "\n"+err.message
    report(msg)

############################################################
export blsAPIKey = localCfg.blsAPIKey || ""
export beaAPIKey = localCfg.beaAPIKey || ""
export fredAPIKey = localCfg.fredAPIKey || ""
export estatAPIKey = localCfg.estatAPIKey || ""
export absAPIKey = localCfg.absAPIKey || ""
# export nzAPIKey = localCfg.nzAPIKey || "" # New Zealand new Data sharing Portal - does not have the right data available...
export rbnzUserAgent = localCfg.rbnzUserAgent || ""
export telegramToken = localCfg.telegramToken || ""
export snitchChatId = localCfg.snitchChatId || ""

localCfg = null

############################################################
export name = "sentinel-backend"
export legalOrigins = ["https://localhost", "https://sentinel-dashboard-dev.dotv.ee"]

############################################################
export statisticsDataRequestHeartbeatMS = 3600000 #1h

############################################################
export cotDataRequestHeartbeatMS = 86400000 #24h

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

export testRun = "accounts"