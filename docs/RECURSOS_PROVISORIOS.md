# Recursos provisórios e como substituí-los

Todos os recursos visuais e sonoros atuais são **provisórios por decisão de
projeto**: não havia arquivos de arte/áudio externos licenciados para uso, então
o jogo foi construído com alternativas funcionais geradas por código, sem
depender de nada que não esteja no repositório.

Nada aqui está "faltando" para o jogo rodar — são pontos de melhoria artística.

## Inventário

| Recurso | Situação | Onde |
| --- | --- | --- |
| Personagens (jogador e NPCs) | malhas primitivas detalhadas (rosto, mãos, cabelo, véu, turbante, barba, joias, sandálias), roupas masculinas/femininas e animação procedural; quatro exploradores jogáveis com nomes bíblicos (Josué, Daniel, Ester e Sara) e prévia 3D | `scripts/player/stylized_rig.gd`, `scripts/player/player_looks.gd`, `scripts/characters/npc.gd` |
| Animais | malhas primitivas + animação procedural (patas articuladas, orelhas, asas, cauda, olhos com brilho e piscadas) | `scripts/characters/animal_rig.gd` |
| Cenário (árvores, rochas, tendas, mercado, arca, montanha) | geometria procedural | `scripts/worlds/props.gd`, `scripts/worlds/*.gd` |
| Céu, luz, névoa, colinas | `WorldEnvironment` procedural | `scripts/worlds/env_builder.gd` |
| Texturas | nenhuma textura externa; materiais com cor sólida e ruído procedural em tecido/lã | `assets/textures/` (vazia de propósito) |
| Modelos 3D importados | nenhum; `assets/models/` e `assets/materials/` ficam para arte futura | — |
| Animações importadas | nenhuma; `assets/animations/` reservado | — |
| Música e efeitos | WAV sintetizados: 6 trilhas originais de 48 compassos em cinco seções (72–137 s), com melodia, contracanto, harmonia, baixo, percussão e reverb; 8 efeitos | `assets/audio/`, gerados por `tools/generate_audio.py` |
| Fonte | Baloo 2 (SIL OFL 1.1) | `assets/fonts/` |
| Ícone | emblema original rasterizado com fundo transparente (PNG 1024 px e ICO 16–256 px), aplicado ao jogo, ao instalador e aos atalhos | `assets/icon/`, `installer/app.ico` |

## Áudio

`scripts/systems/audio_manager.gd` espera exatamente estes nomes:

- Música (loop): `assets/audio/music/trilha_menu.wav`, `trilha_eden.wav`,
  `trilha_arca.wav`, `trilha_davi.wav`, `trilha_moises.wav`,
  `trilha_jesus.wav`.
- Efeitos: `assets/audio/sfx/click.wav`, `collect.wav`, `success.wav`,
  `interact.wav`, `jump.wav`, `wrong.wav`, `throw.wav`, `deliver.wav`.

Regenerar os provisórios:

```bash
python tools/generate_audio.py
```

Para substituir por áudio definitivo:

1. Mantenha os nomes e a pasta (ou atualize `MUSIC_BY_WORLD` e `SFX_NAMES`).
2. Prefira **WAV** para a música em loop: o gerenciador configura
   `loop_mode = LOOP_FORWARD` automaticamente. Com **OGG**, ative o loop nas
   configurações de importação do arquivo no Godot.
3. Duração sugerida da trilha: pelo menos 60 s; os arquivos atuais têm 72–137 s
   e emendam em loop (a cauda de reverb é dobrada para o início).
4. Níveis: pico em torno de −6 dBFS para música e −3 dBFS para efeitos; o
   volume final é controlado por `Settings` (geral × música/efeitos). As seis
   faixas estão niveladas entre si (RMS 0,132–0,148).
5. Depois de trocar arquivos, rode `Godot --headless --path . --import` e os
   testes em `docs/TESTES.md` (eles verificam existência e carregamento dos 14
   arquivos).

## Modelos e animações

O jogo não carrega arquivos de modelo — tudo é criado em tempo de execução. Para
introduzir arte definitiva:

1. Coloque os arquivos em `assets/models/` (`.glb`/`.gltf` com esqueleto e
   animações nomeadas: `idle`, `walk`, `run`, `jump`, `interact`).
2. Substitua a criação procedural em `stylized_rig.gd`/`animal_rig.gd` por uma
   cena instanciada, mantendo a interface usada pelos chamadores:
   `set_locomotion(velocidade, no_chão, velocidade_vertical)`,
   `play_interact()`, `play_cheer(tempo)`, `set_motion(velocidade)`.
3. O jogador usa `PlayerCharacter.rig` e a câmera é independente — nenhuma outra
   parte depende da geometria interna do rig.
4. Para cenário, troque chamadas de `Props.*` por cenas próprias mantendo
   colisões (`StaticBody3D` na camada 1) e escala compatível (personagem ≈ 1,7 m).

## Limitações visuais conhecidas

- Formas simples e cores chapadas (sem texturas pintadas, normal maps ou
  sombras suaves de alta qualidade) — estilo “brinquedo de madeira”, coerente e
  mais detalhado que um protótipo, mas não fotorreal.
- Sombras direcionais usam o renderizador **Compatibility**; em placas antigas o
  Godot troca para ANGLE automaticamente.
- Alguns elementos (montanha do sermão, paredes do mar) são blocos funcionais e
  podem ganhar modelagem dedicada.
- NPCs têm etiquetas de nome 3D e o botão de interação em Sprite3D; em
  distâncias grandes ambos ficam pequenos, mas voltam ao tamanho normal ao se
  aproximar.
- O menu usa um diorama 3D recortado; a composição pode ser ajustada em
  `scripts/main.gd` (`_build_menu_stage`).
- O ícone deriva do emblema fornecido; para arte vetorial definitiva, substitua
  `assets/icon/icon.png` e `assets/icon/app.ico` (mesmo tamanho/transparência) e
  `installer/app.ico`.

## Checklist antes de publicar

- [ ] Aprovar as seis trilhas sintetizadas (ou substituí-las por gravações).
- [ ] Revisar textos e referências com o responsável de conteúdo
      (`docs/CONTEUDO_BIBLICO.md`).
- [ ] Testar em um PC de configuração intermediária (movimento, câmera,
      colisões, pausa, configurações, save).
- [ ] Reexportar com os templates 4.7.2 e testar o `.exe` + `.pck`.
- [ ] Rodar os dois conjuntos de testes headless e anexar o resultado.
