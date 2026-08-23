# crm-agentico
Plataforma de gestión conversacional y CRM multicanal integrada con agentes autónomos de IA. Permite la centralización de mensajes, automatización de flujos de trabajo e interacción inteligente con clientes vía API y webhooks.


# CRM Agéntico Conversacional 🤖💬

Una plataforma de mensajería omnicanal y gestión de clientes impulsada por inteligencia artificial agéntica. Este proyecto permite centralizar conversaciones desde múltiples canales (WhatsApp, Telegram, Live Chat, Email) e integrarlas con agentes autónomos capaces de responder, ejecutar acciones y escalar casos complejos a agentes humanos.

---

## 🚀 Características Principales

* **Omnicanalidad:** Centralización de conversaciones de múltiples canales de comunicación en una sola bandeja de entrada.
* **Agentes de IA Autónomos:** Integración nativa con orquestadores de IA (n8n, LangChain, AutoGen, Flowise) mediante Webhooks y API REST.
* **Asignación Inteligente:** Derivación automática de tickets hacia agentes humanos o bot según la intención detectada.
* **Panel de Control Unificado:** Gestión de contactos, etiquetas, conversaciones y métricas de soporte en tiempo real.
* **Extensible:** Arquitectura modular basada en microservicios lista para desplegar en Docker.

---

## 🏗️ Arquitectura del Sistema

El sistema opera mediante una arquitectura orientada a eventos:

1. **Recepción de mensajes:** Los canales de comunicación reciben los mensajes de los usuarios.
2. **Disparo de Webhooks:** El core del CRM notifica en tiempo real a la capa agéntica sobre los eventos entrantes.
3. **Procesamiento del Agente:** El agente de IA procesa la consulta, accede a herramientas/bases de datos externas y genera una respuesta.
4. **Respuesta Automática:** La solución devuelve la respuesta al usuario final a través del CRM.

---

## 🛠️ Requisitos Previos

Antes de comenzar, asegúrate de contar con:

* **Docker** v20.10+ y **Docker Compose** v2.0+
* Servidor Linux (Ubuntu 22.04 recomendado) con al menos **4 GB de RAM** y **2 vCPUs**
* Dominio configurado con registros DNS apuntando a la IP de tu servidor
* Clave de API para el modelo de lenguaje de tu preferencia (OpenAI, Anthropic, Ollama, etc.)

---

## ⚡ Instalación Rápida

### 1. Clonar el repositorio
```bash
git clone [https://github.com/tu-usuario/crm-agentico.git](https://github.com/tu-usuario/crm-agentico.git)
cd crm-agentico
