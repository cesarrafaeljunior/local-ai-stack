# Aplicação

Extraia o ZIP e execute:

```bash
cd /home/cesar/Documentos/projetos/local-ai-stack

/caminho/extraido/local-ai-stack-v1-architecture-update/apply.sh   /home/cesar/Documentos/projetos/local-ai-stack
```

O script cria backup dos arquivos substituídos, não altera `.env`, não instala/remover modelos e valida Bash/JSON.

Depois:

```bash
ia --help
ia models
ia info work
ia prompt work
git diff
```
