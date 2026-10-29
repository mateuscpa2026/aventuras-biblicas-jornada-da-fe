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
`interact`. O jogador procura o alvo mais próximo a cada 0,12 s e mostra
`show_prompt()` nele: um `PromptBadge` (SubViewport + Sprite3D billboard com a
pílula escura e a tecla E) flutua acima do alvo, sempre de frente para a câmera.
Ao sair de perto, abrir diálogo/quiz ou pausar, o selo é escondido. Implementações:

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
sensibilidade configurável. O olhar é lido em `_input`, então o mouse não é
engolido pela interface, e funciona mesmo se o sistema recusar a captura do
cursor; `enabled` desliga o olhar quando há modal aberto. `main.gd` recaptura o
mouse ao fechar um modal, ao voltar o foco à janela e ao clicar na tela. As
animações são procedurais (`StylizedRig` e `AnimalRig`): caminhada, corrida,
salto, gesto de interação e comemoração.

`StylizedRig` aceita um dicionário de aparência: `gender`, `outfit`
(`tunic`/`robe`/`dress`), `hair_style` (`short`/`long`/`braid`/`bun`/`bald`),
`headwear` (`none`/`headband`/`turban`/`veil`/`hood`), `jewelry` e as cores de
pele, cabelo, tecido, barra, sandália, faixa, manto e véu. O padrão feminino é
vestido comprido com cabelo longo e joias; o masculino é túnica com cabelo
curto. Todas as peças (rosto, olhos, cílios, mãos, sandálias, dobras, turbante,
barba) são nós nomeados, e a animação procedural controla pernas, braços, saia,
tronco, cabeça e piscadas.

### Exploradores e seleção de personagem

`scripts/player/player_looks.gd` define os quatro exploradores com nomes
bíblicos — Josué e Daniel (meninos), Ester e Sara (meninas) — como presets de
`StylizedRig`: pele, cabelo, íris, túnica/vestido, barra, calça, sandália,
faixa, gênero, penteado, adorno de cabeça e joias.
`CharacterSelectScreen` (`scenes/ui/character_select.tscn`) instancia um
`SubViewport` 400×400 transparente por explorador, cada um com seu próprio
`World3D`, chão de estúdio e três luzes; os viewports só renderizam
(`UPDATE_ALWAYS`) enquanto a tela está aberta. Cada cartão é um `Button` com
prévia, nome, jeito e marca de seleção.

A escolha é validada e persistida por `SaveSystem.player_look` (com sinal
`player_look_changed`); `PlayerLooks.is_valid()` protege contra ids inválidos e
o padrão é `josue`. O `PlayerCharacter` aplica o look salvo ao entrar em cada
mundo, e a tela pode ser aberta pelo menu a qualquer momento.

### Personagens principais de cada capítulo

`scripts/characters/story_cast.gd` (`StoryCast`) registra os dez personagens
bíblicos que protagonizam os capítulos — Adão e Eva, Noé e Sem, Davi e Samuel,
Moisés e Miriã, Jesus e Maria — com nome, papel e o mesmo dicionário de
aparência usado pelo `StylizedRig`. `data/chapters.json` liga cada capítulo ao
seu elenco no campo `cast`; os mundos criam os NPCs com `StoryCast.look(id)`,
então o retrato e o boneco no mundo são idênticos. Samuel é o profeta que ungiu
Davi (1 Samuel 16), e não o sacerdote Eli de outra passagem.

O `IntroOverlay` monta dois `SubViewport` 240×240 transparentes com `World3D`
próprio, medalhão colorido e três luzes para os retratos de busto; eles só
renderizam (`UPDATE_ALWAYS`) enquanto a abertura está visível e voltam a
`UPDATE_DISABLED` ao começar. Os cartões do mapa mostram os mesmos nomes em
“Personagens · …”.

### Animais

`AnimalRig` monta sete animais por código: ovelha (três anéis de mechas de lã),
cabra (chifres em três segmentos), burro (crina e orelhas longas), cervo
(galhada ramificada e focinho alongado), coelho (patas traseiras e orelhas
rosadas), pássaro (asas dobradas com penas) e peixe (brânquias, boca e cauda).
Cada rig tem olhos com brilho e piscadas, orelhas que se mexem, patas em pivôs
articulados, respiração, balanço de cauda e comemoração; todos olham para −Z,
igual aos NPCs.

## Interface

`scenes/ui/` — menu, seleção de explorador, seleção de capítulos, introdução,
HUD (capítulo, missões, pergaminhos, itens carregados), diálogo, livro, quiz,
pausa, configurações, toast, capítulo concluído. `ui_kit.gd` concentra
tipografia, botões, cartões e espaçamentos para manter a identidade visual.
`prompt_badge.gd` desenha o botão 3D de interação em um SubViewport
transparente, reutilizando o mesmo UIKit.

## Música

`tools/generate_audio.py` sintetiza as seis trilhas em Python puro (sem
bibliotecas externas): tabelas de onda por timbre (flauta, palheta, trompa,
cordas, dedilhado, harpa, baixo e “vidro”), melodia escrita por compasso,
acompanhamento por estilo (valsa, balanço, heroico, místico, terno), percussão
suave e reverb com cauda dobrada para o início, garantindo loop sem clique.

Cada tema tem **48 compassos em cinco seções** — `intro` (4), `main` (16),
`lift` (8), `full` (16) e `outro` (4) — com energia, progressão, arranjo,
contracanto e padrões de harpa próprios. A melodia recebe humanização de tempo
e dinâmica, vibrato por instrumento, dobra em oitava nos clímax e uma camada de
cordas de apoio no tema de Davi. Durações finais: 72 s (Éden) a 137 s (Jesus).
O `AudioManager` calcula o fim do loop em quadros a partir de `get_length()`,
compatível com a importação QOA do Godot.

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
dos menus e de cada mundo (usado na verificação visual). `tools/animal_preview.tscn`
gera um PNG dos sete animais em um palco neutro (opcionalmente `-- only=ovelha`;
a saída padrão é `tmp/animal_preview.png`). Os testes headless estão em
`tests/` e são independentes do modo de captura.
