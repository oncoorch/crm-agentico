ARG CHATWOOT_BASE_IMAGE=chatwoot/chatwoot:v4.6.0
FROM ${CHATWOOT_BASE_IMAGE}

COPY branding/chatwoot/public/ /tmp/crm-komodo-public/
COPY docker/chatwoot/apply_branding.sh /usr/local/bin/apply_crm_komodo_branding

RUN chmod +x /usr/local/bin/apply_crm_komodo_branding \
  && /usr/local/bin/apply_crm_komodo_branding
