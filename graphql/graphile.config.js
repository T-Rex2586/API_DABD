import { makePgService } from "postgraphile/adaptors/pg";
import { PostGraphileAmberPreset } from "postgraphile/presets/amber";

const preset = {
    extends: [PostGraphileAmberPreset],
    pgServices: [
        makePgService({
            connectionString: "postgres://postgres:postgrespassword@localhost:5432/kampus",
            schemas: ["public"],
        }),
    ],
    grafserv: {
        port: 4000,
        host: "localhost",
        graphiql: true,
    },
};

export default preset;
