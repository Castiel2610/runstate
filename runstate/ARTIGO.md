# Gerenciamento de Estado e Ciclo de Vida em Aplicativos Mobile Nativos: Um Estudo de Caso com Flutter e Riverpod

**Área:** Engenharia de Software Mobile  
**Tipo:** Artigo de Desenvolvimento de Aplicação  

---

## Resumo

O desenvolvimento de aplicativos mobile nativos envolve desafios específicos relacionados ao gerenciamento do ciclo de vida dos processos e à manutenção de estado consistente entre as transições de contexto impostas pelo sistema operacional. Este artigo apresenta o desenvolvimento do RunState, um aplicativo de rastreamento de corridas construído com o framework Flutter, que serve como demonstração aplicada dos conceitos de gerenciamento de estado reativo e observação do ciclo de vida mobile. A solução adota o padrão arquitetural MVVM combinado com o pacote Riverpod para gerenciamento de estado, SQLite para persistência local e a API AppLifecycleObserver do Flutter para resposta a transições de estado do sistema. Os resultados demonstram que a combinação de StateNotifier com WidgetsBindingObserver permite um controle preciso e desacoplado das reações do app às mudanças de contexto impostas pelo SO, preservando o estado da sessão de corrida mesmo em cenários de background, interrupção e retorno ao foreground.

**Palavras-chave:** Flutter, Riverpod, ciclo de vida mobile, gerenciamento de estado, StateNotifier, AppLifecycleObserver.

---

## 1. Introdução

Aplicativos mobile operam em um ambiente controlado pelo sistema operacional, que pode suspender, retomar ou encerrar processos a qualquer momento conforme a disponibilidade de memória, nível de bateria ou ação do usuário. Diferente de aplicações desktop ou web, onde o processo permanece em execução contínua, apps mobile precisam tratar transições de estado como eventos de primeira classe em sua arquitetura.

O ciclo de vida de um aplicativo mobile — a sequência de estados pelos quais um app transita desde sua inicialização até seu encerramento — determina diretamente a integridade dos dados em memória e a experiência do usuário. Um timer que para ao minimizar o app, um formulário que perde seus dados ao receber uma ligação ou um rastreador de atividade que não persiste seu progresso são sintomas clássicos de falhas no tratamento do ciclo de vida.

Este trabalho investiga como o framework Flutter, aliado ao pacote de gerenciamento de estado Riverpod, permite a construção de aplicativos que respondem corretamente às transições de ciclo de vida impostas pelo SO. Para isso, foi desenvolvido o **RunState**: um aplicativo de rastreamento de corridas cujos requisitos de manter uma sessão ativa mesmo com o app em background tornam o ciclo de vida um requisito central, não periférico.

### 1.1 Motivação

O domínio de rastreamento de atividades físicas é particularmente rico para o estudo do ciclo de vida mobile porque impõe restrições reais: o usuário não segura o telefone enquanto corre — ele o coloca no bolso, recebe ligações, troca de aplicativos. O app precisa sobreviver a essas transições sem perder o estado da sessão.

### 1.2 Objetivo

Demonstrar, por meio de uma aplicação funcional, como Flutter e Riverpod podem ser combinados para implementar gerenciamento de estado reativo e tratamento correto das transições do ciclo de vida mobile, seguindo o padrão arquitetural MVVM.

---

## 2. Referencial Teórico

### 2.1 Ciclo de Vida em Aplicativos Mobile

O ciclo de vida de uma aplicação mobile define os estados pelos quais ela transita desde sua criação até seu encerramento. No ecossistema Android, esses estados são gerenciados pelo ActivityManager e incluem: Created, Started, Resumed, Paused, Stopped e Destroyed (ANDROID DEVELOPERS, 2024). No iOS, o UIApplicationDelegate define estados equivalentes: Not Running, Inactive, Active, Background e Suspended.

O Flutter abstrai essas diferenças de plataforma por meio da enumeração `AppLifecycleState`, que define quatro estados relevantes para o desenvolvedor:

- **resumed**: o app está visível e em foco, recebendo eventos do usuário;
- **inactive**: o app está parcialmente visível, mas não recebe eventos (ex.: durante uma chamada);
- **paused**: o app foi movido para background;
- **detached**: o motor Flutter está sendo encerrado.

A API `WidgetsBindingObserver` permite que qualquer objeto Dart se registre para receber notificações dessas transições, tornando o tratamento do ciclo de vida uma responsabilidade explícita e testável (FLUTTER TEAM, 2024).

### 2.2 Gerenciamento de Estado Reativo

Gerenciamento de estado em aplicativos Flutter refere-se ao conjunto de padrões e ferramentas que determinam como dados são armazenados, atualizados e propagados para a interface. O Flutter oferece desde soluções simples como `setState` até arquiteturas reativas como BLoC, Provider e Riverpod.

O **Riverpod** (ROUSSELET, 2021) é um framework de injeção de dependência e gerenciamento de estado que resolve limitações do Provider original — em especial a dependência obrigatória da árvore de widgets. Seus principais conceitos são:

- **Provider**: unidade fundamental que expõe um valor ou serviço;
- **StateNotifierProvider**: expõe um `StateNotifier`, permitindo mutações de estado tipadas;
- **FutureProvider**: expõe operações assíncronas com estados de loading, data e error;
- **ProviderScope**: container raiz que mantém o ciclo de vida de todos os providers.

O `StateNotifier<T>` é uma classe imutável que emite novos estados ao invés de mutar o existente, facilitando rastreamento de mudanças e prevenindo bugs de estado compartilhado (ROUSSELET, 2021).

### 2.3 Padrão MVVM

O Model-View-ViewModel (MVVM) é um padrão arquitetural que separa a lógica de apresentação (ViewModel) da interface (View) e dos dados (Model). No contexto Flutter com Riverpod, o mapeamento é direto:

- **Model**: classes de domínio (`RunModel`, `RunSession`) e repositórios de dados (`RunRepository`);
- **ViewModel**: `StateNotifier` (`RunSessionNotifier`), que contém a lógica de negócio e expõe estado observável;
- **View**: widgets Flutter (`DashboardScreen`, `RunScreen`, `HistoryScreen`), que consomem o estado via `ConsumerWidget`.

### 2.4 Persistência Local com SQLite

O SQLite é um banco de dados relacional embarcado amplamente adotado em aplicativos mobile por sua leveza e confiabilidade. No Flutter, o pacote `sqflite` oferece uma interface assíncrona sobre o SQLite nativo de Android e iOS (FLUTTER COMMUNITY, 2024). A persistência local é essencial para garantir que dados sobrevivam ao encerramento do processo pelo SO — comportamento que não pode ser evitado em ambiente mobile.

---

## 3. Metodologia

### 3.1 Definição da Problemática

A problemática central investigada é: **como garantir que o estado de uma sessão de corrida ativa seja preservado corretamente quando o app transita entre os estados do ciclo de vida mobile?**

Três cenários de transição foram identificados como críticos:

1. **App → background**: usuário minimiza o app durante a corrida;
2. **Background → foreground**: usuário retorna ao app após outro aplicativo;
3. **Processo morto → relançamento**: SO encerra o processo por falta de memória.

### 3.2 Escolha das Tecnologias

| Decisão | Alternativas consideradas | Escolha | Justificativa |
|---|---|---|---|
| Framework | React Native, Kotlin Nativo | Flutter | Hot reload, única codebase, APIs de ciclo de vida bem documentadas |
| Estado | Provider, BLoC, GetX | Riverpod | Type-safe, sem dependência da árvore de widgets, testável |
| Persistência | SharedPreferences, Hive | sqflite | Suporte a queries complexas, padrão da indústria |
| Arquitetura | MVC, Clean Architecture | MVVM | Alinhamento natural com StateNotifier como ViewModel |

### 3.3 Arquitetura do Projeto

O projeto foi organizado em camadas seguindo o princípio de separação de responsabilidades:

```
lib/
├── core/
│   └── theme/          # Tema e design tokens
├── data/
│   ├── models/         # RunModel, RunSession (domínio)
│   └── repositories/   # RunRepository (SQLite)
├── state/
│   └── notifiers/      # RunSessionNotifier (lógica + ciclo de vida)
└── ui/
    ├── screens/        # Dashboard, Run, History (View)
    └── widgets/        # StatCard (componentes reutilizáveis)
```

### 3.4 Implementação do Ciclo de Vida

O componente central da solução é o `RunSessionNotifier`, que estende simultaneamente `StateNotifier<RunSession>` e implementa `WidgetsBindingObserver`. Esse design permite que a mesma classe que gerencia o estado da sessão também reaja às transições do ciclo de vida, sem acoplamento com a camada de interface.

O registro do observer ocorre no construtor:

```dart
RunSessionNotifier(this._repository) : super(const RunSession()) {
  WidgetsBinding.instance.addObserver(this);
}
```

E as reações às transições são implementadas em `didChangeAppLifecycleState`:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState appState) {
  switch (appState) {
    case AppLifecycleState.resumed:
      if (state.isActive) {
        _startTicker();
        _startGpsTicker();
      }
    case AppLifecycleState.paused:
      if (state.isActive) {
        _stopTicker();
        _stopGpsTicker();
        // Status permanece RunStatus.running
      }
    case AppLifecycleState.detached:
      _stopTicker();
      _stopGpsTicker();
    default:
      break;
  }
}
```

A decisão de não alterar o `RunStatus` ao ir para background é deliberada: o status (`running`) é o estado de negócio da sessão, enquanto os timers são apenas mecanismos de atualização da UI. Separar essas responsabilidades evita que o SO controle inadvertidamente o estado da corrida.

### 3.5 Simulação de GPS

Por limitações de hardware em ambiente de desenvolvimento e emulação, o incremento de distância foi implementado via gerador de números pseudo-aleatórios, simulando velocidade de corrida entre 9 e 12 km/h. Essa decisão é declarada explicitamente como limitação metodológica e não compromete a validade da demonstração dos conceitos de ciclo de vida.

Em uma versão de produção, o `_gpsTicker` seria substituído por um stream do pacote `geolocator`, com idêntica interface para o restante da arquitetura.

---

## 4. Resultados e Discussão

### 4.1 Comportamento observado nas transições

Os três cenários de transição foram testados em emulador Android e produziram o seguinte comportamento:

**Cenário 1 — App vai para background durante corrida:**
- `didChangeAppLifecycleState(paused)` é chamado
- Os timers são cancelados (economia de recursos)
- `state.status` permanece `RunStatus.running`
- Ao retornar, `didChangeAppLifecycleState(resumed)` relança os timers
- O tempo acumulado em `state.elapsedSeconds` é preservado

**Cenário 2 — Retorno ao foreground:**
- A UI reflete imediatamente o estado atual via Riverpod
- O timer retoma a partir do valor preservado
- Nenhuma intervenção explícita do widget é necessária

**Cenário 3 — Processo morto pelo SO:**
- O estado em memória é perdido (limitação inerente ao ambiente mobile)
- A última corrida salva permanece disponível via SQLite
- Esta limitação é o ponto de partida para a discussão sobre ForegroundService

### 4.2 Vantagens da Arquitetura Adotada

A separação entre `StateNotifier` (lógica + ciclo de vida) e `ConsumerWidget` (interface) permitiu que mudanças na UI não afetassem a lógica de negócio e vice-versa. O Riverpod propagou automaticamente as mudanças de estado para todos os widgets consumidores sem necessidade de `setState` manual.

A imutabilidade dos estados (`RunSession.copyWith`) facilitou o rastreamento de mudanças e tornaria a escrita de testes unitários direta — cada estado é um valor puro, sem efeitos colaterais ocultos.

### 4.3 Limitações e Trabalhos Futuros

A principal limitação da implementação atual é a ausência de um **ForegroundService** para Android, que permitiria que o timer continuasse incrementando mesmo com o processo em background. No Flutter, isso pode ser implementado via o pacote `flutter_foreground_task`. Sem ele, o tempo acumulado para de crescer enquanto o app está minimizado, embora o estado da sessão seja preservado.

Como trabalhos futuros, propõe-se:

1. Integração com `geolocator` para GPS real;
2. Implementação de ForegroundService para Android e background modes para iOS;
3. Exportação de corridas em formato GPX;
4. Integração com Firebase para sincronização de histórico entre dispositivos.

---

## 5. Conclusão

Este trabalho demonstrou que o Flutter, aliado ao Riverpod e ao padrão MVVM, oferece uma base sólida para o tratamento correto de ciclo de vida em aplicativos mobile. O RunState evidenciou que o uso de `WidgetsBindingObserver` dentro de um `StateNotifier` é uma abordagem eficaz e desacoplada para reagir às transições impostas pelo SO sem vazar responsabilidades para a camada de interface.

A principal lição prática é a distinção entre **estado de negócio** (o status da sessão de corrida) e **mecanismos de atualização** (os timers). Essa separação permite que o sistema operacional controle os recursos sem comprometer a integridade dos dados da aplicação.

---

## Referências

ANDROID DEVELOPERS. **Activity lifecycle**. Disponível em: https://developer.android.com/guide/components/activities/activity-lifecycle. Acesso em: 2025.

FLUTTER TEAM. **WidgetsBindingObserver class**. Flutter API Documentation. Disponível em: https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html. Acesso em: 2025.

FLUTTER TEAM. **AppLifecycleState enum**. Flutter API Documentation. Disponível em: https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html. Acesso em: 2025.

FLUTTER COMMUNITY. **sqflite package**. Disponível em: https://pub.dev/packages/sqflite. Acesso em: 2025.

ROUSSELET, Remi. **Riverpod documentation**. Disponível em: https://riverpod.dev. Acesso em: 2025.

GAMMA, E.; HELM, R.; JOHNSON, R.; VLISSIDES, J. **Design Patterns: Elements of Reusable Object-Oriented Software**. Addison-Wesley, 1994.

MARTIN, Robert C. **Clean Architecture: A Craftsman's Guide to Software Structure and Design**. Prentice Hall, 2017.

---

*RunState — Gerenciamento de Estado e Ciclo de Vida em Aplicativos Mobile*  
*Disciplina: Desenvolvimento Mobile Nativo*
