#!/usr/bin/env node
const crypto = require('crypto');
const fs = require('fs');

const { Client } = require('pg');

const projectId = process.env.N8N_SEED_PROJECT_ID || '';
const foldersPath = process.env.N8N_SEED_FOLDERS_FILE || '/opt/n8n-seed/folders.json';

if (!projectId) {
  console.log('[n8n-seed] N8N_SEED_PROJECT_ID is empty; skipping folder assignment');
  process.exit(0);
}

if (!fs.existsSync(foldersPath)) {
  console.log(`[n8n-seed] folders file not found: ${foldersPath}`);
  process.exit(0);
}

const alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

function stableId(input) {
  const digest = crypto.createHash('sha256').update(input).digest();
  let value = BigInt(`0x${digest.subarray(0, 12).toString('hex')}`);
  let out = '';
  while (out.length < 16) {
    out += alphabet[Number(value % BigInt(alphabet.length))];
    value /= BigInt(alphabet.length);
  }
  return out;
}

async function main() {
  const folders = JSON.parse(fs.readFileSync(foldersPath, 'utf8'));
  const client = new Client({
    host: process.env.DB_POSTGRESDB_HOST || 'n8n_postgres',
    port: Number(process.env.DB_POSTGRESDB_PORT || 5432),
    database: process.env.DB_POSTGRESDB_DATABASE || 'n8n_production',
    user: process.env.DB_POSTGRESDB_USER || 'n8n',
    password: process.env.DB_POSTGRESDB_PASSWORD,
  });

  await client.connect();
  try {
    for (const folder of folders) {
      const id = stableId(`${projectId}:${folder.name}`);
      await client.query(
        `insert into folder (id, name, "projectId", "createdAt", "updatedAt")
         values ($1, $2, $3, now(), now())
         on conflict (id) do update set name = excluded.name, "updatedAt" = now()`,
        [id, folder.name, projectId],
      );
      const result = await client.query(
        `update workflow_entity
            set "parentFolderId" = $1, "updatedAt" = now()
          where name like $2 escape '\\'
          returning id`,
        [id, `%\\_${folder.suffix}`],
      );
      console.log(`[n8n-seed] folder ${folder.name}: ${result.rowCount} workflows`);
    }
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('[n8n-seed] folder assignment failed');
  console.error(error);
  process.exit(1);
});
