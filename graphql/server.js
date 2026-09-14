import { createServer } from "node:http";
import express from "express";
import cors from "cors";
import { grafserv } from "postgraphile/grafserv/express/v4";
import { postgraphile } from "postgraphile";
import preset from "./graphile.config.js";

// Inisialisasi instance PostGraphile dengan preset
export const pgl = postgraphile(preset);

// Buat instance grafserv dengan adaptor Express
const serv = pgl.createServ(grafserv);

// Buat aplikasi Express dan pasang CORS
const app = express();
app.use(cors());

// Mount Express ke HTTP server Node.js (dibutuhkan agar websocket siap)
const server = createServer(app);

server.once("error", (e) => {
    console.error(e);
    process.exit(1);
});

// Daftarkan handler Grafserv ke Express
serv.addTo(app, server).catch((e) => {
    console.error(e);
    process.exit(1);
});

const { host, port } = preset.grafserv;

server.listen(port, host, () => {
    console.log(
        `🚀 Server PostGraphile V5 berjalan di http://localhost:${port}/ (GraphiQL)`,
    );
});
