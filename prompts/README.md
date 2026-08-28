# System prompts

Estes arquivos são a fonte de verdade versionada para o comportamento dos perfis:

- `light.md`
- `work.md`
- `code.md`
- `heavy.md`
- `code-heavy.md`

O arquivo associado a cada perfil fica em `config/models.json`.

Exibir um prompt:

```bash
ia prompt work
```

Ver a configuração inteira:

```bash
ia info work
```

Os prompts não são aplicados por `lms load`. Eles devem ser associados ao modelo por uma camada cliente, como um Model preset do Open WebUI ou um futuro harness.

Depois de configurar os presets no Open WebUI, use `ia webui-export` para versioná-los.
