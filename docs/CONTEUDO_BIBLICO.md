# Conteúdo bíblico, referências e política editorial

Este documento explica **o que é citação, o que é paráfrase e o que é
explicação educativa** no jogo, lista as referências usadas e registra as
decisões de segurança para o público infantil.

## Regra editorial adotada

1. **O jogo não reproduz o texto de nenhuma tradução da Bíblia.**
   Todos os textos de versículos (`verse_text` em `data/chapters.json`) e das
   histórias (`paraphrase` em `data/bible_stories/stories.json`) são
   **paráfrases originais**, escritas especificamente para este projeto a partir
   do trecho indicado, com referência verificável (livro, capítulo e versículo).
2. Cada texto aparece rotulado com `verse_kind: "paráfrase"` (capítulos) ou no
   campo `paraphrase` (histórias), ao lado da referência. O jogador sempre vê a
   indicação de que se trata de paráfrase.
3. O campo `explanation` das histórias é **explicação educativa** (contexto,
   valores e aplicação para crianças), não é texto bíblico.
4. Falas de personagens nos diálogos são **narrativa do jogo**, não citações
   bíblicas. As referências bíblicas aparecem apenas nos campos próprios.
5. Se uma versão futura quiser usar **citações literais**, é obrigatório:
   - usar uma tradução cuja licença permita a reprodução (por exemplo, uma
     edição em domínio público, como a de João Ferreira de Almeida de 1819, ou
     outra com autorização expressa do detentor dos direitos);
   - indicar a tradução e a referência junto à citação;
   - manter o selo `verse_kind: "citação"` para diferenciar das paráfrases.
   Traduções modernas protegidas por direitos autorais **não** devem ser
   reproduzidas sem autorização.

## Referências por capítulo

| Capítulo | Referência | Tipo | Texto (paráfrase) |
| --- | --- | --- | --- |
| Éden | Gênesis 1:31 | paráfrase | Deus olhou para tudo o que havia feito e viu que era muito bom. |
| Arca de Noé | Gênesis 9:13 | paráfrase | Deus colocou o arco-íris nas nuvens como sinal da sua promessa. |
| Davi e Golias | 1 Samuel 17:45 | paráfrase | Davi disse que ia enfrentar o gigante em nome do Senhor dos Exércitos. |
| Moisés e o Mar Vermelho | Êxodo 14:21-22 | paráfrase | O mar se abriu e o povo atravessou em terra seca. |
| Ensinamentos de Jesus | Mateus 22:37-39 | paráfrase | Ame a Deus de todo o coração e ame o seu próximo como a si mesmo. |

## Passagens do Livro de histórias

O livro reúne **56 passagens** distribuídas em **15 coleções** (3 pergaminhos por
mundo). Cada pergaminho coletado abre a sua coleção inteira; a coluna "Coleção"
indica qual pergaminho abre a passagem. Todos os textos são paráfrases originais
com referência verificável.

| Mundo | Passagem | Referência | Coleção |
| --- | --- | --- | --- |
| Éden | A criação do mundo | Gênesis 1:1-31 | `criacao` |
| Éden | O dia de descanso | Gênesis 2:1-3 | `criacao` |
| Éden | Adão e Eva | Gênesis 2:21-24 | `criacao` |
| Éden | A árvore do conhecimento | Gênesis 2:15-17 | `criacao` |
| Éden | O jardim confiado a nós | Gênesis 2:8-15 | `eden_jardim` |
| Éden | Uma escolha difícil | Gênesis 3:1-13 | `eden_jardim` |
| Éden | Deus cuida mesmo assim | Gênesis 3:21 | `eden_jardim` |
| Éden | Um novo começo | Gênesis 4:25-26 | `eden_jardim` |
| Éden | Os animais do jardim | Gênesis 2:19-20 | `eden_animais` |
| Éden | Enoque caminhava com Deus | Gênesis 5:24 | `eden_animais` |
| Éden | Noé encontra graça | Gênesis 6:9 | `eden_animais` |
| Arca | A arca é construída | Gênesis 6:14-22 | `arca_construcao` |
| Arca | Animais em pares | Gênesis 6:19-20 | `arca_construcao` |
| Arca | Noé faz como Deus pediu | Gênesis 7:5 | `arca_construcao` |
| Arca | A entrada na arca | Gênesis 7:1-9 | `arca_construcao` |
| Arca | Os dias de chuva | Gênesis 7:11-24 | `diluvio` |
| Arca | As águas baixam | Gênesis 8:1-5 | `diluvio` |
| Arca | A pomba e a folha de oliveira | Gênesis 8:6-12 | `diluvio` |
| Arca | Gratidão ao sair da arca | Gênesis 8:20-22 | `diluvio` |
| Arca | A promessa no arco-íris | Gênesis 9:12-17 | `arco_iris` |
| Arca | Uma aliança com toda a vida | Gênesis 9:8-11 | `arco_iris` |
| Arca | A torre de Babel | Gênesis 11:1-9 | `arco_iris` |
| Davi | Davi, o pastor | 1 Samuel 16:11-13 | `davi_pastor` |
| Davi | A harpa de Davi | 1 Samuel 16:14-23 | `davi_pastor` |
| Davi | Davi protege o rebanho | 1 Samuel 17:34-37 | `davi_pastor` |
| Davi | A amizade de Jônatas | 1 Samuel 18:1-4 | `davi_pastor` |
| Davi | Davi e Golias | 1 Samuel 17:38-50 | `davi_golias` |
| Davi | Davi é reconhecido rei | 2 Samuel 5:1-5 | `davi_golias` |
| Davi | A arca chega a Jerusalém | 2 Samuel 6:12-15 | `davi_golias` |
| Davi | A promessa a Davi | 2 Samuel 7:8-16 | `davi_golias` |
| Davi | Coragem que confia | 1 Samuel 17:45-47 | `coragem_fe` |
| Davi | Davi perdoa Saul | 1 Samuel 24:1-12 | `coragem_fe` |
| Davi | O Senhor é meu pastor | Salmo 23:1-4 | `coragem_fe` |
| Davi | Um convite à gratidão | Salmo 100:1-5 | `coragem_fe` |
| Moisés | O chamado de Moisés | Êxodo 3:1-12 | `moses_chamado` |
| Moisés | A primeira Páscoa | Êxodo 12:1-13 | `moses_chamado` |
| Moisés | Os dez mandamentos | Êxodo 20:1-17 | `moses_chamado` |
| Moisés | A arca da aliança | Êxodo 25:10-22 | `moses_chamado` |
| Moisés | O mar se abre | Êxodo 14:21-22 | `mar_vermelho` |
| Moisés | O pão do céu | Êxodo 16:14-18 | `mar_vermelho` |
| Moisés | Água na rocha | Êxodo 17:5-6 | `mar_vermelho` |
| Moisés | Moisés, amigo de Deus | Êxodo 33:11 | `mar_vermelho` |
| Moisés | Um cântico de liberdade | Êxodo 15:1-2 | `povo_liberdade` |
| Moisés | Josué recebe a missão | Deuteronômio 31:7-8 | `povo_liberdade` |
| Moisés | O rosto que brilha | Êxodo 34:29-30 | `povo_liberdade` |
| Jesus | O bom samaritano | Lucas 10:30-37 | `bom_samaritano` |
| Jesus | Jesus, o bom pastor | João 10:11-15 | `bom_samaritano` |
| Jesus | Deixem as crianças virem | Marcos 10:13-16 | `bom_samaritano` |
| Jesus | O exemplo de servir | João 13:12-15 | `bom_samaritano` |
| Jesus | A ovelha perdida | Lucas 15:3-7 | `ovelha_perdida` |
| Jesus | Pão para todos | João 6:9-13 | `ovelha_perdida` |
| Jesus | Os lírios e os pássaros | Mateus 6:25-34 | `ovelha_perdida` |
| Jesus | Jesus ensina a orar | Mateus 6:9-13 | `ovelha_perdida` |
| Jesus | O filho que voltou | Lucas 15:11-24 | `filho_prodigo` |
| Jesus | Quantas vezes perdoar? | Mateus 18:21-22 | `filho_prodigo` |
| Jesus | Zaqueu sobe na árvore | Lucas 19:1-10 | `filho_prodigo` |

Os textos completos ficam em `data/bible_stories/stories.json`
(campos `title`, `reference`, `paraphrase`, `explanation`, `scroll`, `icon`).

## Segurança e adequação para crianças

- **Sem violência gráfica:** a Arca é vivida por dentro (chuva, cuidado com os
  animais, arco-íris); a luta de Davi é um **treino de funda em argolas**;
  a travessia do mar mostra a passagem segura, sem perigos ou mortes.
- **Sem sustos, terror ou temas adultos:** nenhuma cena de morte, ferimento,
  julgamento ou castigo é mostrada. Conflitos são resolvidos com ajuda,
  cooperação e escolhas de perdão.
- **Aprendizagem por exploração:** as atividades são cuidar, regar, encontrar,
  entregar, acompanhar e conversar. O desafio de memória é leve e pode ser
  refeito sem punição severa; o erro apenas mostra a resposta correta e permite
  tentar novamente.
- **Respeito à diversidade de leitores:** as paráfrases evitam linguagem
  doutrinária ou interpretações denominacionais; o foco é o texto bíblico
  referenciado, seus valores de cuidado, coragem, gratidão e amor ao próximo.

## Checklist de revisão de conteúdo

- [x] Toda referência aponta livro/capítulo/versículo verificável.
- [x] Nenhum texto de tradução protegida foi reproduzido.
- [x] Paráfrases e explicações estão em campos separados e rotulados.
- [x] Falas de personagens não se apresentam como citações bíblicas.
- [x] Nenhuma cena mostra violência gráfica, morte ou conteúdo assustador.
- [x] Os textos são compreensíveis para crianças em fase de alfabetização
      (frases curtas e vocabulário concreto), com apoio visual.
- [x] Revisão humana recomendada antes de publicação: conferir tom pastoral,
      adequação cultural local e precisão das referências na tradução escolhida
      pela família/igreja.

## Como alterar o conteúdo

1. Edite o JSON correspondente em `data/`.
2. Mantenha `reference` e o rótulo de paráfrase; se inserir uma citação literal,
   acrescente `verse_kind: "citação"` e a tradução utilizada.
3. Rode os testes (`docs/TESTES.md`): eles validam campos obrigatórios,
   referências e integridade dos textos.
