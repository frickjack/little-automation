const util = require("util");
// import authn middleware from lambda layer mounted at /opt/commonjs
const bridge = require("@littleware/little-authn/commonjs/bin/oidcClient/lambdaBridge.js"); 
const confHelper = require("@littleware/little-authn/commonjs/bin/oidcClient/configHelper.js");

/**
 * load authn config via LITTLE_AUTHN_CONFIG load rule - ex:
 * {
 *  "type": "string",
 *  "value": "{ ... }"
 * }
 * 
 * The [little-authn documentation](https://github.com/frickjack/little-authn/tree/master/Notes/howto/devTest.md)
 * has details on the format of the auth configuration value.
 */
const loadRule = JSON.parse(process.env.LITTLE_AUTHN_CONFIG || "null");
if (!loadRule) {
    throw new Error("Unable to load config from LITTLE_AUTHN_CONFIG environment rule");
}
const configProvider = confHelper.loadConfigByRule(loadRule);
const authLambdaPromise = configProvider.then(
    (config) => {
        return bridge.lambdaHandlerFactory(configProvider);
    },
).get();

/**
 * call through to the authn lambdaHandler, and
 * augment with a /hello endpoint
 */
async function lambdaHandler(event, context) {
    if (/\/hello$/.test(event.path)) {
        return {
            body: JSON.stringify({
                message: `hello!`,
                path: event.path,
                // location: ret.data.trim()
            }),
            headers: { "Content-Type": "application/json; charset=utf-8" },
            isBase64Encoded: false,
            statusCode: 200,
            // "multiValueHeaders": { "headerName": ["headerValue", "headerValue2", ...], ... },
        };
    }
    try {
        const authHandler = await authLambdaPromise;
        const authResponse = await authHandler(event, context);
        
        return authResponse;
    } catch (err) {
        return {
            body: {
                message: util.inspect(err),
                path: event.path,
                // location: ret.data.trim()
            },
            headers: { "Content-Type": "application/json; charset=utf-8" },
            isBase64Encoded: false,
            statusCode: 200,
            // "multiValueHeaders": { "headerName": ["headerValue", "headerValue2", ...], ... },
        };
    }
}

exports.lambdaHandler = lambdaHandler
