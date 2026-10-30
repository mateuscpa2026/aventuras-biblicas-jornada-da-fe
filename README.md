# Aventuras Bíblicas: Jornada da Fé

Jogo 3D educativo infantil feito em **Godot 4.7 / GDScript**, com cinco capítulos
jogáveis (Éden, Arca de Noé, Davi, Moisés e Ensinamentos de Jesus), missões,
diálogos, 15 pergaminhos colecionáveis e um livro com 56 passagens bíblicas,
quebra-cabeças de memória e salvamento local.

Os personagens têm rosto, cabelo, barba, turbante, véu, joias e sandálias
modelados por código, com roupas masculinas (túnica/manto) e femininas
(vestido comprido, trança e véu) distintas. A criança escolhe quem vai guiar
entre quatro exploradores com nomes bíblicos — **Josué e Daniel** (meninos),
**Ester e Sara** (meninas) — em uma tela com prévia 3D de cada um; a escolha
fica salva e pode ser trocada no menu.

Cada capítulo destaca os **personagens principais da história** — Adão e Eva,
Noé e Sem, Davi e Samuel, Moisés e Miriã, Jesus e Maria — em retratos 3D na
abertura e nos cartões do mapa. Eles são os mesmos NPCs com quem a criança
conversa no mundo.
Os animais (ovelha, cabra, burro, cervo, coelho, pássaro e peixe) também são
modelados por código, com lã em camadas, focinho e narinas próprios de cada
espécie, olhos com esclera, íris, pupila e brilho, pálpebras, patas articuladas,
cauda e animações de respiração, pastar e comemorar. Cada mundo tem um cinturão
de mata no perímetro (árvores, pinheiros, palmeiras e arbustos com tons
variados), manchas de vegetação rasteira e chão com textura e relevo suave, o
que fecha o horizonte e dá profundidade à paisagem. Tudo isso roda a **60 FPS**
numa GPU de entrada (Radeon R5 340), graças a um único mapa de sombra ortogonal
e à vegetação distante fora da projeção de sombra — os números e o que foi
testado estão em [docs/TESTES.md](docs/TESTES.md). Ao
chegar perto de alguém ou de um objeto, a ação aparece em um **botão flutuante
com a tecla E** acima do personagem. A trilha sonora tem seis temas originais e
sintetizados, cada um com 48 compassos em cinco seções (introdução, tema,
levantada, clímax e encerramento), melodia conduzida, contracanto, arpejos,
baixo, percussão suave e reverb com loop sem emenda.

O projeto é **autossuficiente**: todos os modelos, cenários, animações, ícones e
áudios são gerados por código ou sintetizados, sem dependência de arquivos
externos que não estejam no repositório.

Código-fonte: <https://github.com/mateuscpa2026/aventuras-biblicas-jornada-da-fe>

## Instalação (Windows)

Instalador gerado com Inno Setup (instalação por usuário, sem exigir
administrador):

- Nesta máquina: `D:\Meus Programas de PC\Jogos\AventurasBiblicas-Setup-1.0.exe`
- No GitHub: <https://github.com/mateuscpa2026/aventuras-biblicas-jornada-da-fe/releases>

O instalador cria atalhos no menu Iniciar e, opcionalmente, na área de trabalho,
e permite desinstalar por *Configurações → Aplicativos* ou pelo atalho
*Desinstalar*. Para compilar novamente, veja
[installer/AventurasBiblicas.iss](installer/AventurasBiblicas.iss).

## Requisitos

- **Godot 4.7.x Standard** (não é necessário o build .NET).
  Download: <https://godotengine.org/download>
- Windows 10/11 64 bits.
- Placa de vídeo com OpenGL 3.3. Em drivers antigos/limitados o Godot ativa
  automaticamente o **ANGLE** (Direct3D 11) e mostra um aviso — é esperado e o
  jogo funciona normalmente.
- Para exportar: **Export Templates 4.7.2** instalados no editor
  (*Editor → Gerenciar Modelos de Exportação*).

## Abrir e executar

1. Abra o Godot 4.7.
2. **Importar** → selecione `project.godot` nesta pasta.
3. Pressione **F5** (a cena principal é `scenes/main.tscn`).

Execução por linha de comando (opcional):

```bash
Godot_v4.7.2-stable_win64.exe --path .
```

## Controles

| Ação | Tecla |
| --- | --- |
| Mover | `W` `A` `S` `D` (relativo à câmera) |
| Olhar | Mouse (a câmera é capturada ao entrar no mundo) |
| Correr | `Shift` |
| Pular | `Espaço` |
| Interagir / conversar / pegar | `E` (o botão aparece acima do alvo) |
| Mirar com a funda (Davi) | Botão direito do mouse |
| Lançar pedrinha | Botão esquerdo (durante a mira) |
| Afastar/aproximar câmera | Roda do mouse |
| Pausa / configurações | `Esc` |

O jogo abre em **tela cheia** por padrão. As configurações incluem volume (geral,
música, efeitos), resolução, tela cheia, qualidade gráfica e sensibilidade do mouse.

## Fluxo de jogo

Menu → **Novo jogo** → introdução do capítulo → exploração do mundo com
objetivos no painel → conclusão do desafio final (pedra da memória ou treino de
funda) → tela de capítulo concluído → próximo capítulo desbloqueado.
**Continuar** retoma o último mundo visitado. Capítulos concluídos podem ser
rejogados pelo menu **Capítulos**; os pergaminhos já guardados permanecem no
**Livro de histórias**.

## Testes automatizados

```bash
# 1) Sistemas, dados, missões, save, personagens, câmera e áudio (607 checagens)
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/smoke_test.tscn

# 2) Integração das cinco cenas: jogador, colisão, NPCs, animais, diálogo,
#    pergaminhos, pedra da memória e conclusão de capítulo (419 checagens)
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/world_test.tscn
```

Ambos retornam código de saída `0` quando tudo passa. Detalhes em
[docs/TESTES.md](docs/TESTES.md).

Capturas de tela para inspeção visual (abre uma janela, salva PNGs e fecha):

```bash
Godot_v4.7.2-stable_win64_console.exe --path . -- --capture=tmp/captures
Godot_v4.7.2-stable_win64_console.exe --path . -- --capture=tmp/eden --capture-world=eden
```

## Exportar para Windows

O preset **Windows Desktop** já está em `export_presets.cfg`. O build local
desta entrega fica em `build/windows/` (pasta não versionada; o instalador
publicado está nas Releases do GitHub).

Pelo editor: *Projeto → Exportar… → Windows Desktop → Exportar projeto*.

Por linha de comando:

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . \
  --export-release "Windows Desktop" build/windows/AventurasBiblicas.exe
```

Distribua **junto** o `AventurasBiblicas.exe` e o `AventurasBiblicas.pck`.
Para um executável único, marque *Embed PCK* nas opções do preset.

## Estrutura

```
scenes/      player, worlds, characters, interactions, ui, main
scripts/     player, worlds, characters, interactions, systems, ui
data/        chapters.json, missions/, dialogues/, quizzes.json, bible_stories/
assets/      fonts (Baloo 2, OFL), icon (emblema transparente PNG/ICO),
             audio (6 trilhas originais e efeitos sintetizados)
docs/        conteúdo bíblico, arquitetura, recursos, testes
tests/       smoke_test e world_test (headless)
tools/       generate_audio.py (síntese dos WAVs provisórios),
             animal_preview.tscn (inspeção visual dos animais)
build/       executável Windows exportado
```

Documentação complementar:

- [docs/CONTEUDO_BIBLICO.md](docs/CONTEUDO_BIBLICO.md) — referências,
  paráfrases, política de conteúdo e segurança infantil.
- [docs/ARQUITETURA.md](docs/ARQUITETURA.md) — sistemas, dados, sinais e como
  estender o jogo.
- [docs/RECURSOS_PROVISORIOS.md](docs/RECURSOS_PROVISORIOS.md) — o que é
  provisório e como substituir por arte/áudio definitivos.
- [docs/TESTES.md](docs/TESTES.md) — cobertura e resultados dos testes.

## Situação verificada nesta entrega

- Os cinco capítulos existem, são jogáveis e concluíveis; a progressão
  desbloqueia o capítulo seguinte e o save sobrevive a recarregar/corromper.
- `607` checagens de sistemas + `419` checagens de cenas, **0 falhas**.
- A criança escolhe entre quatro exploradores com nomes bíblicos — dois meninos
  (Josué e Daniel) e duas meninas (Ester e Sara) — com prévia 3D; a escolha é
  persistida e aplicada em todos os mundos.
- Cada capítulo exibe seus personagens bíblicos principais em retratos 3D na
  abertura e nos cartões do mapa; os retratos usam o mesmo visual dos NPCs e
  param de renderizar quando a tela fecha.
- As seis trilhas foram refeitas com forma de 48 compassos e orquestração
  variada; cada faixa emenda em loop (descontinuidade ≤ 0,005) e o volume entre
  elas está nivelado.
- O emblema do jogo foi aplicado como ícone do executável (16–256 px), do
  instalador, dos atalhos e da janela do jogo, com fundo transparente.
- Build Windows exportado e executado em modo de captura, gerando as imagens
  das cinco telas de mundo e dos menus; o instalador foi instalado e o jogo
  aberto a partir da pasta instalada.
- Realismo nesta versão: trilhas de terra com bordas que se dissolvem no capim
  (sem a fita escura que aparecia atrás do jogador), luz com mais contraste
  entre sol e sombra, chão com granulação em escala de 3 m, copas com degradê
  do topo claro à base escura e animais/cenário com silhuetas orgânicas em vez
  de esferas e cones perfeitos.
- Desempenho medido sem vsync: 64–84 FPS de média nos cinco mundos (mínima de
  36 durante a primeira carga do Éden), acima da meta de 60 FPS com vsync.
- O que ainda depende de validação humana: sensação de movimento/câmera em cada
  PC alvo e aprovação artística/áudio final (os recursos continuam provisórios
  por projeto). Ver limitações em `docs/RECURSOS_PROVISORIOS.md`.

## Créditos

- Fonte **Baloo 2** — Google Fonts, licença SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`).
- Todo o restante (modelos, cenários, animações, ícone e áudio sintetizado) foi
  criado para este projeto. Nenhum personagem ou recurso de outro jogo foi
  copiado. Ver [docs/CONTEUDO_BIBLICO.md](docs/CONTEUDO_BIBLICO.md).
