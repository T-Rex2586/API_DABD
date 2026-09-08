import { createServer } from "node:http";
import { grafserv } from "postgraphile/grafserv/node";
import { postgraphile } from "postgraphile";
import preset from "./graphile.config.js";

// Inisialisasi instance PostGraphile dengan preset
export const pgl = postgraphile(preset);

// Buat instance grafserv
const serv = pgl.createServ(grafserv);

// Jalankan HTTP Server Node.js
const server = createServer();

server.once("error", (e) => {
    console.error(e);
    process.exit(1);
});

serv.addTo(server).catch((e) => {
    console.error(e);
    process.exit(1);
});

const { host, port } = preset.grafserv;

server.listen(port, host, () => {
    console.log(`🚀 Server PostGraphile V5 berjalan di http://${host}:${port}/graphiql`);
});
