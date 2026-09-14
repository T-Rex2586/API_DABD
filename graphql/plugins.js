import { depthLimit } from "@graphile/depth-limit";
import { NoSchemaIntrospectionCustomRule } from "graphql";

export const SecurityPlugin = {
    name: "SecurityPlugin",
    grafserv: {
        middleware: {
            setPreset(next, event) {
                event.validationRules.push(
                    depthLimit({
                        maxDepth: 12,
                        maxListDepth: 4,
                        maxSelfReferentialDepth: 2,
                    }),
                );
                if (process.env.NODE_ENV === "production") {
                    event.validationRules.push(NoSchemaIntrospectionCustomRule);
                }
                return next();
            },
        },
    },
};

export const NoSingularizePlugin = {
    name: "NoSingularizePlugin",
    inflection: {
        replace: {
            singularize(_previous, _options, text) {
                return text;
            },
        },
    },
};
