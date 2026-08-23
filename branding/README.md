# Branding Assets

Colocar aqui los assets autorizados para la instancia:

```text
branding/
└── chatwoot/
    └── public/
        ├── favicon.ico
        ├── logo.png
        └── ...
```

Aplicar con:

```bash
./scripts/chatwoot_branding_assets.sh
```

El script copia los archivos al contenedor Chatwoot y sincroniza `/app/storage/public` con `/app/public`.
