# Arquitetura

Visão geral dos sistemas, do fluxo de dados e de como estender o jogo sem
transformar scripts em arquivos gigantes.

## Camadas

```
scenes/main.tscn          orquestrador: menu, mundos, HUD, pausa, overlays
└─ scripts/main.gd        troca de telas, captura de tela, modo de teste
   ├─ scenes/ui/*         interface (CanvasLayers 5/10/20/30/40)
   ├─ scenes/worlds/*     cinco mundos
   └─ autoloads           sistemas globais
```

### Autoloads (em `project.godot`)

| Autoload | Arquivo | Responsabilidade |
| --- | --- | --- |
| `SaveSystem` | `scripts/systems/save_system.gd` | progresso em JSON, validação, backup, saneamento |
| `Settings` | `scripts/systems/settings_manager.gd` | volumes, resolução, tela cheia, qualidade, sensibilidade; sinal `changed` |
| `Audio` | `scripts/systems/audio_manager.gd` | música por mundo com fade/loop e efeitos; respeita `Settings` |
| `Story` | `scripts/systems/story_manager.gd` | livro de histórias, desbloqueio e contagem por mundo |
| `Missions` | `scripts/systems/mission_manager.gd` | definições por mundo, eventos, progresso, conclusão e desbloqueio em cadeia |
| `Dialogue` | `scripts/systems/dialogue_manager.gd` | carrega falas do mundo, estado do diálogo, emite `talk` e `choice` |
| `Game` | `scripts/systems/game.gd` | capítulos, troca de mundo, itens carregados, toasts, sinais de fluxo |

Nenhum autoload depende da cena principal; o `Game` guarda uma referência
opcional (`Game.main`) para pedir trocas de tela.

## Mundos

`scripts/worlds/world_base.gd` prepara tudo em `_ready()`:

1. `seed(hash(world_id))` → cenário determinístico;
2. carrega capítulo, diálogos e missões do mundo;
3. `_build_world()` (implementado por cada mundo) usa os helpers:
   `add_npc`, `add_animal`, `add_scroll`, `add_quiz_station`, `add_simple_prop`,
   `add_prop`;
4. posiciona o jogador e o registra em `Game`;
5. `Game.register_world_entered()` grava o último mundo e toca a trilha;
6. aplica qualidade gráfica e avisa `Game.main.on_world_ready()`.

Cada mundo (`eden.gd`, `ark.gd`, `david.gd`, `moses.gd`, `jesus.gd`) divide a
construção em métodos pequenos: ambiente, cenário, construções, personagens,
atividades. `env_builder.gd` centraliza céu, luz, névoa, chão, colinas, nuvens e
limites; `props.gd` fornece todas as peças procedurais (árvores, rochas, tendas,
mercado, arca, animais, partículas).

### Interações

Tudo que responde a `E` deriva de `Interactable`
(`scripts/interactions/interactable.gd`): raio, prompt, `can_interact`,
`interact`. Implementações:

- `ScrollPickup` — guarda uma história e emite `collect_scroll`; fica oculto até
  a missão `required_mission` começar.
- `QuizStation` — pedra da memória; abre `Game.quiz_requested` e respeita a
  missão final.
- `SimpleProp` — objetos de missão (mudinhas, provisões, pães) que emitem um
  evento e desaparecem/movem.
- `NPCCharacter` — diálogo, entrega de item e acompanhamento com destino.
- `AnimalCharacter` — cuidado, acompanhamento e passeio.
- `BrazierBeacon`, `TargetRing`, `SlingshotStand` — atividades de Moisés e Davi.

## Missões

`data/missions/<mundo>.json` — lista ordenada:

```json
{
  "id": "eden_animais",
  "title": "Amigos do jardim",
  "objective": "Cuide de 5 animais",
  "event": "care_animal",
  "target": 5,
  "requires": [],
  "match": {},
  "secondary": false,
  "is_final": false,
  "reward": "texto exibido ao concluir"
}
```

- Missões começam quando todas as `requires` estão concluídas.
- `notify_event(nome, quantidade, payload)` só avança missões ativas cujo
  `event` coincide e cujo `match` bate com o payload.
- Missões de colecionáveis reconciliam o progresso com os pergaminhos já
  coletados ao recarregar (`_sync_collect_missions`), contando as passagens-âncora
  (`Story.count_unlocked_scrolls`), não as passagens soltas.
- `secondary: true` = objetivo opcional; não bloqueia o capítulo.
- `is_final: true` conclui o capítulo e emite `world_completed`.

## Diálogos

`data/dialogues/<mundo>.json`:

```json
{"npcs": {"davi": {
  "name": "Davi", "role": "Pastor corajoso",
  "lines": [
    {"speaker": "Davi", "text": "...", "kind": "fala"},
    {"speaker": "Davi", "text": "...", "kind": "paráfrase", "reference": "1 Samuel 16:11-13"},
    {"speaker": "Davi", "text": "...", "kind": "explicação"}
  ]
}}}
```

`kind` separa fala narrativa, paráfrase (com referência) e explicação
educativa — a interface mostra o rótulo. Ao fechar, `Dialogue.finish()` emite
`talk`, usado por missões de conversa. Escolhas usam `Dialogue.notify_choice(tag)`
(`choice` + `match.tag`). O formato é pronto para futura narração por voz: basta
adicionar um campo de áudio por linha.

## Pergaminhos e livro

Cada pergaminho é a **passagem-âncora** de uma coleção temática: as passagens do
mesmo pergaminho compartilham o campo `scroll` em
`data/bible_stories/stories.json`. `ScrollPickup.interact()` chama
`Story.unlock_bundle(id)` — que abre e persiste todas as passagens da coleção —,
emite `collect_scroll` uma vez e mostra um toast com quantas histórias foram
abertas. O livro (`scenes/ui/book_panel.tscn`) lista as 56 passagens por mundo,
com referência, paráfrase e explicação; as ainda não encontradas aparecem
bloqueadas.

## Save

Arquivo: `user://jornada_da_fe_save.json` (no Windows,
`%APPDATA%\Godot\app_userdata\Aventuras Biblicas- Jornada da Fe\`).

```json
{
  "version": 1,
  "unlocked_chapters": ["eden", "ark"],
  "completed_chapters": ["eden"],
  "missions_completed": {"eden": ["eden_animais", "..."]},
  "storybook": ["criacao", "..."],
  "settings": {"volume_master": 0.9, "quality": 1, "...": "..."},
  "last_world": "ark",
  "created_at": "..."
}
```

- Escrita atômica: grava `.tmp`, copia o anterior para `.backup.json`, substitui.
- Leitura tenta principal e backup; qualquer campo inválido é saneado para o
  padrão (`_sanitize`), sem travar o jogo.
- Configurações ficam dentro do save; “Novo jogo” preserva as configurações.

## Jogador e câmera

`PlayerCharacter` (`CharacterBody3D`) usa aceleração/desaceleração, gravidade,
salto, `move_and_slide`, detecção de chão, queda segura para o spawn e foco
automático no interativo mais próximo. `PlayerCamera` é um `SpringArm3D` com
colisão (evita atravessar paredes), zoom na roda, mira com aproximação e
sensibilidade configurável. As animações são procedurais (`StylizedRig` e
`AnimalRig`): caminhada, corrida, salto, gesto de interação e comemoração.

## Interface

`scenes/ui/` — menu, seleção de capítulos, introdução, HUD (capítulo, missões,
pergaminhos, itens carregados), diálogo, livro, quiz, pausa, configurações,
toast, capítulo concluído. `ui_kit.gd` concentra tipografia, botões, cartões e
espaçamentos para manter a identidade visual.

## Como estender

- **Novo capítulo:** adicione entrada em `data/chapters.json`, cena em
  `scenes/worlds/` estendendo `WorldBase`, arquivos em `data/missions/` e
  `data/dialogues/`, quiz em `data/quizzes.json` e histórias em
  `data/bible_stories/stories.json`. O menu e a seleção de capítulos leem os
  dados automaticamente.
- **Nova missão:** acrescente ao JSON com `event`, `target` e `requires`. Se o
  evento ainda não existe, emita `Missions.notify_event` no ponto de gameplay.
- **Novo NPC:** `add_npc(id, nome, posição, cores)` no mundo + entrada em
  `data/dialogues/<mundo>.json`.
- **Novo pergaminho:** `add_scroll(story_id, posição, missão)` no mundo, uma
  passagem-âncora com `scroll` igual ao próprio id e as demais passagens da
  coleção com `scroll` apontando para ela.
- **Nova passagem avulsa:** acrescente o objeto em
  `data/bible_stories/stories.json` com `world` e `scroll` de uma coleção
  existente; o livro e os contadores se atualizam sozinhos.
- **Novo som/música:** mantenha os nomes esperados por
  `scripts/systems/audio_manager.gd` (ver `docs/RECURSOS_PROVISORIOS.md`).

## Captura e testes

`main.gd` aceita `--capture=<pasta>` e `--capture-world=<id>` para gerar PNGs
dos menus e de cada mundo (usado na verificação visual). Os testes headless
estão em `tests/` e são independentes do modo de captura.
