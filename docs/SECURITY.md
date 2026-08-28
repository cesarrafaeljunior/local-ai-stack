# Segurança

## Nunca versionar

- `.env`;
- `WEBUI_SECRET_KEY`;
- tokens;
- API keys reais;
- modelos;
- banco do Open WebUI;
- chats;
- backups;
- uploads pessoais.

Revise sempre:

```bash
git status
git diff --cached
```

antes de publicar.

## Portas

Open WebUI:

```text
127.0.0.1:3000
```

Não fica exposto à rede local por padrão.

LM Studio:

O container precisa alcançar a API executada no host. O CLI tenta detectar a interface `docker0` e usa esse IP como `--bind`. Se não conseguir, usa `0.0.0.0` e emite aviso.

Se ocorrer fallback para `0.0.0.0`:

- não encaminhe a porta 1234 no roteador;
- não exponha essa porta à internet;
- revise UFW/firewall;
- prefira configurar `LMS_BIND` explicitamente para uma interface local adequada.

## Repositório público

É aceitável tornar o repositório público quando:

```bash
git grep -nE '(sk-|token|password|secret|api[_-]?key)' -- ':!*.md'
```

não retornar credenciais reais e `git status` confirmar que `data/`, `.env` e backups não estão sendo rastreados.
