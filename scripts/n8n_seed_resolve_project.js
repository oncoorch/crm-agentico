#!/usr/bin/env node
const { Client } = require('pg');

async function main() {
  const client = new Client({
    host: process.env.DB_POSTGRESDB_HOST || 'n8n_postgres',
    port: Number(process.env.DB_POSTGRESDB_PORT || 5432),
    database: process.env.DB_POSTGRESDB_DATABASE || 'n8n_production',
    user: process.env.DB_POSTGRESDB_USER || 'n8n',
    password: process.env.DB_POSTGRESDB_PASSWORD,
  });

  await client.connect();
  try {
    const result = await client.query(
      `select id
         from project
        where type = 'personal'
        order by "createdAt"
        limit 1`,
    );
    if (result.rows[0]?.id) {
      process.stdout.write(result.rows[0].id);
    }
  } finally {
    await client.end();
  }
}

main().catch(() => process.exit(0));
