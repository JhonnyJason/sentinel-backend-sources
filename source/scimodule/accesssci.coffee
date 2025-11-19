############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accesssci")
#endregion

############################################################
#region Modules from the Environment
import {
    STRINGEMAIL, STRINGHEX64, STRINGHEX32, ARRAY, NUMBER,
    STRINGEMAILORNOTHING, NUMBERORNOTHING, BOOLEANORNOTHING,
    BOOLEAN, createValidator
} from "thingy-schema-validate"

############################################################
import { sciAdd, setValidatorCreator } from "./scicoremodule.js"
setValidatorCreator(createValidator)

############################################################
import { signatureAuth } from "./authmodule.js"

############################################################
import { setAccess, unsetAccess } from "./accessmodule.js"

#endregion

############################################################
## Config Object with all options
# { 
#   bodySizeLimit: # limit body size for this route -> whole payload
#   authOption:  # add a function for request authentication (req, ctx)
#   argsSchema: # required for arguments - will be validated
#   resultSchema: # required for results - will be validated
#   responseAuth: # add a function to proof response authenticity (resultString, ctx)
# }

############################################################ 
#region ADMIN Functions

############################################################ 
sciAdd("grantAccess", setAccess, {
    bodySizeLimit: 1024, 
    authOption: signatureAuth,
    argsSchema: {
        authCode: STRINGHEX32,
        ttlMS: NUMBER
    }
    # resultSchema: ""
})
#Response is 204 when signature is valid 403 otherwise 

############################################################
sciAdd("revokeAccess", unsetAccess, {
    bodySizeLimit: 1024, 
    authOption: signatureAuth,
    argsSchema: STRINGHEX32
})
#Response is 204 when signature is valid 403 otherwise

#endregion

