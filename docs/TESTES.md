# Testes e verificações

Este documento descreve os testes automatizados, as verificações manuais que
ainda precisam ser feitas em cada PC e o modo de captura de tela usado para
inspecionar a parte visual.

## Como executar

Pré-requisito: os recursos precisam estar importados. Na primeira vez (ou
depois de trocar arquivos em `assets/`), rode uma importação:

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
```

Depois, os dois testes:

```bash
# Sistemas, dados, missões, save e áudio
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/smoke_test.tscn

# Integração das cinco cenas de mundo
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/world_test.tscn
```

Os dois imprimem `=== N checagens, 0 falhas ===` e terminam com código de saída
`0`. Qualquer falha imprime `[test] FAIL ...`/`[world] FAIL ...` e o processo
sai com código `1` (útil para CI).

> Os testes não rodam a janela do jogo nem simulam entrada de teclado/mouse.
> Eles exercitam os nós reais das cenas chamando os métodos de interação e os
> sistemas de missão, diálogo, save e quiz.

## `smoke_test` — sistemas e dados (491 checagens)

Cobre:

- **Dados**: `chapters.json` (5 capítulos, cenas existentes, ordem,
  desbloqueio), missões de todos os mundos (ids únicos, eventos, alvos,
  recompensas, missão final), diálogos (NPCs referenciados, falas com
  `speaker`/`text`/`kind`, referências), quizzes (5 quizzes finais, perguntas e
  respostas válidas) e as 56 passagens do livro (referência, paráfrase,
  explicação, ícone).
- **Cadeias de missões**: para cada mundo, percorre a ordem real dos eventos e
  confere que a missão seguinte só abre depois da anterior; missões secundárias
  não travam a missão final; conclusão do capítulo só acontece com todos os
  objetivos obrigatórios; cada capítulo concluído desbloqueia o próximo.
- **Persistência**: `SaveSystem.new_game`, conclusão de missões e capítulos,
  pergaminhos guardados, último mundo visitado; recarrega o save do disco e
  confere que o estado sobrevive.
- **Retomada de colecionáveis**: simula 2 de 3 pergaminhos, recarrega, verifica
  que o progresso é reconstruído pelo livro e que a missão fecha ao pegar o
  terceiro.
- **Save corrompido**: grava lixo no arquivo, confere que o save é rejeitado sem
  travar, que o erro é registrado e que o progresso volta ao estado padrão
  seguro; em seguida restaura o save original do jogador.
- **Desafio da memória (interface)**: instancia o `QuizDialog` real, abre o quiz
  de Éden, confere que todas as opções aparecem, que errar mostra a dica sem
  avançar nem encerrar, que cada acerto avança, que acertar todas conclui e
  mostra a tela final, e que fechar emite `closed(true)` e esconde a janela.
- **Áudio**: os 8 efeitos e as 6 trilhas existem, carregam como
  `AudioStreamWAV`, têm duração mínima esperada, a música inicia/para pelo
  `AudioManager` e o loop cobre a faixa inteira (calculado em quadros, o que
  funciona com WAV comprimido em QOA).
- **Personagens**: o rig masculino de túnica tem saia curta, faixa na cabeça e
  sandálias; o feminino de vestido tem trança, véu e bracelete; o ancião com
  turbante tem voltas de tecido e barba. Nenhum homem recebe véu.
- **Exploradores e seleção**: os quatro presets existem com ids únicos, são
  válidos, expõem todas as cores e montam o rig com gênero/roupa/penteado
  corretos; há exatamente dois meninos e duas meninas, todos com nomes bíblicos
  distintos (Josué, Daniel, Ester e Sara); `SaveSystem.player_look` grava, lê e cai no padrão diante de um id
  inválido; a `CharacterSelectScreen` cria quatro cartões e quatro prévias 3D,
  atualiza enquanto aberta, marca a escolha, emite `changed` ao confirmar e
  desliga a renderização ao fechar.
- **Botão flutuante**: uma interação cria o `PromptBadge`, mostra a ação pedida
  e o esconde ao sair de perto.

O teste salva uma cópia do save do jogador no início e restaura no final, então
rodá-lo não apaga progresso real.

## `world_test` — integração das cenas (381 checagens)

Para cada um dos cinco mundos (`eden`, `ark`, `david`, `moses`, `jesus`),
instancia a cena real e verifica:

- cena carrega, `world_id`, capítulo e `spawn_position` corretos;
- `Missions.current_world` e `Dialogue.current_world` apontam para o mundo;
- jogador existe, é o `Game.get_player()`, câmera tem alcance válido;
- **colisão/gravidade**: posiciona o jogador 4 m acima do chão, espera cair e
  confere `is_on_floor()` e que ele não atravessou o cenário;
- pelo menos 6 objetos interativos e pelo menos 2 NPCs com diálogo e nome
  (Moisés usa 4 viajantes em vez de animais);
- cada animal tem rig montado, cabeça e olhos visíveis, quatro patas (exceto
  peixe e pássaro), nome e texto de ação preenchidos; os que podem acompanhar
  têm raio de interação válido;
- conversar com um NPC abre o diálogo, pausa a lógica, `finish()` fecha e marca
  `_talked`;
- exatamente 3 pergaminhos, cada um ligado a uma história válida, mesma missão
  obrigatória, inicialmente inativos/invisíveis;
- existe uma `QuizStation` com `quiz_id == "<mundo>_final"` presente em
  `data/quizzes.json`; antes dos pergaminhos ela mostra o texto de bloqueio;
- ao completar a missão de colecionáveis os pergaminhos ficam ativos/visíveis;
  pegar os 3 desbloqueia +3 histórias e conclui a missão;
- a pedra muda o texto e `interact()` emite `Game.quiz_requested` com o id certo;
- a missão final declarada em `data/missions` fica disponível, é concluída pelo
  evento correspondente, marca o capítulo como concluído, conclui as missões
  secundárias restantes (`is_world_done()`), e libera o próximo capítulo (exceto
  em Jesus, que é o último).

Cada cena é liberada ao final do seu bloco e a música é parada, para um mundo
não vazar estado para o próximo. O save do jogador também é salvo/restaurado.

## Resultado desta entrega

Executado em 2026-10-29 com Godot 4.7.2 stable (renderer GL Compatibility,
Windows 10 x64):

| Suíte | Checagens | Falhas | Saída |
| --- | ---: | ---: | --- |
| `smoke_test.tscn` | 491 | 0 | `0` |
| `world_test.tscn` | 381 | 0 | `0` |

### Aviso esperado ao sair (headless)

Ao final dos testes headless o Godot pode imprimir:

```
WARNING: N ObjectDB instances were leaked at exit
ERROR: 1 resources still in use at exit
```

Isso vem do driver de áudio *dummy* do modo headless: qualquer reprodução de
`AudioStreamWAV` deixa o playback vivo até o encerramento. Um teste mínimo
(carregar `success.wav`, tocar e parar) reproduz o mesmo aviso sem envolver
código do jogo; somente carregar o arquivo, sem tocar, não reproduz. O
`AudioManager` já para e limpa os players no `_exit_tree`, e os testes silenciam
os players antes de sair — o aviso residual é do motor, não indica falha e não
altera o código de saída (`0`). Na janela normal do jogo o encerramento não
depende desse caminho.

## Captura de tela (inspeção visual)

```bash
# Menu, seleção de capítulos, livro, configurações e telas de cada mundo
Godot_v4.7.2-stable_win64_console.exe --path . -- --capture=tmp/captures

# Apenas um mundo (menu + introdução + cena)
Godot_v4.7.2-stable_win64_console.exe --path . -- --capture=tmp/eden --capture-world=eden
```

O modo de captura abre a janela, espera o quadro ser desenhado, salva PNGs na
pasta indicada e fecha sozinho; ele também salva/restaura o save do jogador.
Ao rodar o **executável exportado**, o diretório de trabalho é a pasta do `.exe`,
então a pasta de captura é criada ao lado dele (por exemplo,
`build/windows/tmp/...`), e não dentro do projeto.

## Verificação manual pendente

O que os testes automatizados **não** cobrem e precisa de uma pessoa em cada PC
alvo:

1. Movimento com WASD relativo à câmera, aceleração/desaceleração, corrida
   (`Shift`) e pulo (`Espaço`) com sensação agradável.
2. Mouse look, zoom da roda e prevenção da câmera contra paredes/encostas.
3. Percorrer cada capítulo do início ao fim pela interface: introdução, painel
   de missão, diálogos, pegar pergaminhos, abrir o livro, responder ao quiz,
   tela de capítulo concluído e desbloqueio.
4. Pausa (`Esc`), configurações (volumes, resolução, tela cheia, qualidade,
   sensibilidade) e persistência delas após reabrir o jogo.
5. `Continuar` retomando o último mundo e capítulos concluídos sendo rejogados.
6. Áudio audível e agradável: conferir as seis trilhas em loop (cada uma tem
   introdução, tema, levantada, clímax e encerramento) e o volume relativo entre
   música e efeitos (os arquivos continuam sintetizados — ver
   [RECURSOS_PROVISORIOS.md](RECURSOS_PROVISORIOS.md)).
7. Leitura do botão flutuante sobre NPCs, animais e objetos a diferentes
   distâncias, das roupas masculinas/femininas em cada mundo e da troca de
   explorador no menu.
8. Desempenho em PC intermediário (o jogo usa primitivas procedurais e não
   depende de assets pesados).

Itens 1–3 foram exercitados pelos testes de cena de forma programática
(colisão, interações, missões e quiz), mas a sensação de controle e a leitura da
interface só se confirmam com uso humano.

## Adicionar novos testes

- Novas missões/histórias entram automaticamente na varredura de dados do
  `smoke_test` (ele lê `data/`).
- Para um novo mundo, acrescente o id em `WORLDS` no `world_test.gd` e garanta:
  `world_id`, `spawn_position`, 3 pergaminhos com `required_mission`, uma
  `QuizStation` com quiz final e missões coerentes em `data/missions/`.
- Os testes usam os mesmos autoloads do jogo (`SaveSystem`, `Missions`,
  `Dialogue`, `Game`); não é preciso mockar nada.
