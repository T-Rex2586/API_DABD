import { makePgService } from "postgraphile/adaptors/pg";
import { PostGraphileAmberPreset } from "postgraphile/presets/amber";
import { PersistedPlugin } from "@grafserv/persisted";
import { SecurityPlugin, NoSingularizePlugin } from "./plugins.js";

const preset = {
    extends: [PostGraphileAmberPreset],
    plugins: [SecurityPlugin, NoSingularizePlugin, PersistedPlugin],
    pgServices: [
        makePgService({
            connectionString: "postgres://postgres:postgrespassword@localhost:5432/kampus",
            schemas: ["public"],
        }),
    ],
    grafast: {
        explain: process.env.NODE_ENV !== "production",
        context(requestContext, args) {
            const req =
                requestContext.node?.req ?? requestContext.expressv4?.req;
            const headers = req?.headers ?? {};
            const pgSettings = { ...args.contextValue?.pgSettings };
            if (headers["x-demo-role"]) {
                pgSettings.role = String(headers["x-demo-role"]);
            }
            if (headers["x-demo-mahasiswa-id"]) {
                pgSettings["jwt.claims.mahasiswa_id"] = String(
                    headers["x-demo-mahasiswa-id"],
                );
            }
            return { ...args.contextValue, pgSettings };
        },
    },
    grafserv: {
        port: 4000,
        host: "::",
        graphiql: true,
        persistedOperations: {
            GetAllFakultas:
                "{ allFakultas { nodes { fakultasId kodeFakultas namaFakultas } } }",
            GetMahasiswaByNim:
                "query GetMahasiswaByNim($nim: String!) { mahasiswaByNim(nim: $nim) { nim namaMahasiswa angkatan } }",
        },
        allowUnpersistedOperation: process.env.NODE_ENV !== "production",
    },
};

export default preset;
