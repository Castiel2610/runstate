# RunState 🏃

Aplicativo de rastreamento de corridas desenvolvido em Flutter como demonstração aplicada de **gerenciamento de estado e ciclo de vida mobile**.

## Estrutura do projeto

```
runstate/
├── lib/
│   ├── main.dart                          # Entry point + ProviderScope
│   ├── core/theme/app_theme.dart          # Tema Material 3
│   ├── data/
│   │   ├── models/run_model.dart          # Modelo de corrida finalizada
│   │   ├── models/run_session.dart        # Estado da sessão ativa
│   │   └── repositories/run_repository.dart  # SQLite
│   ├── state/notifiers/
│   │   └── run_session_notifier.dart      # ViewModel + LifecycleObserver
│   └── ui/
│       ├── screens/dashboard_screen.dart  # Tela principal
│       ├── screens/run_screen.dart        # Tela de corrida ativa
│       ├── screens/history_screen.dart    # Histórico de corridas
│       └── widgets/stat_card.dart        # Componente reutilizável
├── ARTIGO.md                              # Artigo científico completo
└── PITCH.md                              # Roteiro do pitch técnico
```

## Setup

### Pré-requisitos
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio ou VS Code com extensão Flutter

### Instalação

```bash
# Clone o repositório
git clone <url-do-repo>
cd runstate

# Instale as dependências
flutter pub get

# Rode no emulador ou dispositivo
flutter run
```

### Executar no Chrome (web)

```bash
flutter run -d chrome
```

> **Nota:** No modo web, o sqflite usa uma implementação em memória. Para persistência real, use um dispositivo Android/iOS ou emulador.

## Conceitos demonstrados

| Conceito | Onde no código |
|---|---|
| AppLifecycleObserver | `RunSessionNotifier.didChangeAppLifecycleState` |
| StateNotifier (Riverpod) | `RunSessionNotifier` |
| Estado imutável | `RunSession.copyWith` |
| MVVM | Separação entre `*_notifier.dart` e `*_screen.dart` |
| Persistência SQLite | `RunRepository` |
| FutureProvider | `runHistoryProvider`, `runStatsProvider` |
| Invalidação reativa | `ref.invalidate(runHistoryProvider)` ao salvar corrida |

## Fluxo de estados da sessão

```
idle → running → paused → running → finished → idle
                    ↑__________________________|
```

## Decisões de design

**GPS simulado:** Em vez de depender do hardware GPS (instável em emuladores), a distância é simulada com incrementos pseudo-aleatórios equivalentes a um pace de ~5–6 min/km. Em produção, substituir `_gpsTicker` por um stream do pacote `geolocator`.

**Timers param no background, status não:** O `didChangeAppLifecycleState(paused)` cancela os timers para economizar bateria, mas não altera `RunStatus`. Isso distingue estado de negócio (a corrida está acontecendo) de mecanismo de atualização (o timer que conta os segundos).
