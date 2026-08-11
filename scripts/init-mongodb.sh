#!/usr/bin/env bash
set -Eeuo pipefail

until mongosh --quiet --host 127.0.0.1 --port 27017 --eval 'db.adminCommand({ ping: 1 }).ok' >/dev/null 2>&1; do
    sleep 1
done

mongosh --quiet --host 127.0.0.1 --port 27017 <<'EOF'
try {
  const status = rs.status();
  print(`Replica Set ativo: ${status.set}`);
} catch (error) {
  rs.initiate({
    _id: "rs0",
    members: [{ _id: 0, host: "127.0.0.1:27017" }]
  });
  print("Replica Set rs0 iniciado");
}
EOF

