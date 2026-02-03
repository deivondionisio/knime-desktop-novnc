# KNIME Desktop (GUI) via VNC/noVNC em Docker

Provisiona um **desktop Ubuntu LXDE** acessível via **noVNC** com **KNIME** instalado.

- Base: `dorowu/ubuntu-desktop-lxde-vnc` (noVNC na **porta interna 80**, `HTTP_PASSWORD`/`VNC_PASSWORD`).
- KNIME: baixado do site oficial (tar.gz Linux) e instalado em `/opt/knime`.

## Uso local
```bash
cp .env.example .env
# edite HTTP_PASSWORD/VNC_PASSWORD
docker compose up -d --build
# acesso: http://localhost:6080/ (se expor 6080:80)
```

### .env
```
RESOLUTION=1920x1080
HTTP_PASSWORD=troque-esta-senha
VNC_PASSWORD=troque-esta-senha
```

## Deploy no Coolify
1. Serviço **Dockerfile** apontando para este repo.
2. **Network**: Ports Exposes `80`; Ports Mappings *(vazio)*.
3. **Domains**: configure um domínio.
4. **Env/Secrets**: `HTTP_PASSWORD`, `VNC_PASSWORD`, `RESOLUTION`.
5. **Healthcheck**: porta 80, path `/`, start period 60–90s, interval 30s, timeout 5s, retries 10.
6. **Volume**: `/home/ubuntu/KNIME-workspace`.

## Basic Auth (Traefik) com usuário corporativo
Use labels no Coolify (ajuste `SEU_DOMINIO`). **Exemplo pronto com hash bcrypt**:

```
traefik.enable=true
traefik.http.routers.knime.entryPoints=http
traefik.http.routers.knime.rule=Host(`SEU_DOMINIO`)
traefik.http.services.knime.loadbalancer.server.port=80
# BasicAuth (usuário + hash bcrypt)
traefik.http.middlewares.knime-auth.basicauth.users=maria.noreply@cmaa.ind.br:$2y$12$Ke93RNcD1qxgg1iU/E6os.M.LrP59Nr7AfFj0rZq5KgWIDlcUJZL.
traefik.http.routers.knime.middlewares=knime-auth
```

> Não comite senhas em texto. Use **Secrets** no Coolify para `HTTP_PASSWORD`/`VNC_PASSWORD`.

## Memória do KNIME
O `Dockerfile` ajusta `-Xmx4g` no `knime.ini`. Ajuste conforme RAM disponível.
