# Hardware

A seleção de modelo depende principalmente de:

1. VRAM;
2. RAM;
3. contexto configurado;
4. CPU, quando há offload parcial;
5. espaço em disco.

## Máquina de referência inicial

```text
CPU: Intel Core i5-12600KF
RAM: 16 GiB
GPU: NVIDIA GeForce RTX 5060
VRAM: 8 GiB
```

Perfil padrão recomendado: `work`.

Antes de adicionar um modelo pesado:

```bash
lms load --estimate-only <model-key> \
  --gpu max \
  --context-length 8192
```

## Detectar hardware

```bash
./scripts/detect-hardware.sh
```

O repositório pode conter vários arquivos em `config/hardware/` para registrar configurações já testadas em máquinas diferentes.
