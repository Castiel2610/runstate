# RunState — Pitch Técnico
## Roteiro de Slides

---

### SLIDE 1 — Capa
**Título:** RunState
**Subtítulo:** Gerenciamento de Estado e Ciclo de Vida em Aplicativos Mobile
**Visual sugerido:** ícone de corredor + diagrama simplificado de estados do ciclo de vida
**Fala:** "Vamos falar sobre um dos problemas mais ignorados e mais prejudiciais no desenvolvimento mobile: o que acontece com seu app quando o usuário vai fazer outra coisa."

---

### SLIDE 2 — O Problema
**Título:** O que acontece quando o usuário minimiza o app?

**Bullet points:**
- O SO pode pausar, suspender ou matar o processo a qualquer momento
- Estado em memória pode ser perdido sem aviso
- Timers param, formulários somem, sessões são interrompidas

**Visual:** diagrama de estados: Running → Background → Killed, com ícone de app perdendo dados

**Fala:** "Qualquer app que precise manter algo rodando enquanto o usuário não está olhando — um timer, um rastreador, um formulário — precisa lidar com isso. E a maioria lida mal."

---

### SLIDE 3 — A Solução: RunState
**Título:** Um rastreador de corridas como caso de teste perfeito

**Por que corrida?**
- Usuário não olha pra tela enquanto corre
- Troca de apps, recebe ligações, bloqueia a tela
- O app PRECISA sobreviver a essas transições

**Visual:** mockup simplificado das 3 telas do app (Dashboard, Corrida, Histórico)

**Fala:** "Escolhemos o domínio de rastreamento de corridas porque ele torna o problema do ciclo de vida um requisito central, não periférico."

---

### SLIDE 4 — Stack Técnica
**Título:** As tecnologias e por que cada uma

| Tecnologia | Papel | Por quê |
|---|---|---|
| Flutter | Framework | Único código, ciclo de vida bem documentado |
| Riverpod | Estado | Type-safe, sem dependência da UI tree |
| StateNotifier | ViewModel | Estado imutável, reativo |
| sqflite | Persistência | SQL completo, dados sobrevivem ao processo |
| AppLifecycleObserver | Ciclo de vida | API nativa Flutter para observar transições |

**Fala:** "O Riverpod e o AppLifecycleObserver são os dois pilares. Um gerencia o que o usuário vê, o outro gerencia o que o SO faz."

---

### SLIDE 5 — Arquitetura MVVM
**Título:** Como o MVVM se aplica aqui

```
Model            ViewModel              View
─────────        ─────────────────      ─────────────────
RunModel    ←→   RunSessionNotifier →   DashboardScreen
RunSession       (StateNotifier +       RunScreen
RunRepository    LifecycleObserver)     HistoryScreen
```

**Ponto chave:** O ViewModel conhece o ciclo de vida. A View não sabe que o ciclo de vida existe.

**Fala:** "A separação é real: quando o app vai pro background, quem reage é o ViewModel. O widget só sabe que o estado mudou."

---

### SLIDE 6 — O Coração do Projeto
**Título:** didChangeAppLifecycleState — onde acontece a mágica

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      if (session.isActive) _startTimers(); // retoma
    case AppLifecycleState.paused:
      if (session.isActive) _stopTimers();  // pausa recursos
      // status da corrida NÃO muda — ela ainda está "running"
  }
}
```

**Insight chave:** Status de negócio ≠ mecanismo de atualização

**Fala:** "Essa distinção é fundamental. O SO pode parar os timers. O SO não pode dizer que a corrida foi pausada — só o usuário pode."

---

### SLIDE 7 — Fluxo de Estados
**Título:** Como o estado da sessão transita

```
[idle] ──iniciar──→ [running] ──pausar──→ [paused]
                        ↑                    │
                        └─────retomar────────┘
                        │
                      finalizar
                        ↓
                   [finished] ──salvo no SQLite──→ [idle]
```

**Visual sugerido:** diagrama com os 4 estados em círculos conectados por setas

**Fala:** "Cada transição é explícita. Não há estado implícito ou ambíguo. Isso é o que o StateNotifier com enums nos dá."

---

### SLIDE 8 — Persistência e Sobrevivência
**Título:** O que persiste e o que não persiste

| Dado | Armazenamento | Sobrevive ao background? | Sobrevive ao kill? |
|---|---|---|---|
| Tempo decorrido | memória (StateNotifier) | ✅ | ❌ |
| Status da sessão | memória (StateNotifier) | ✅ | ❌ |
| Corridas finalizadas | SQLite | ✅ | ✅ |
| Estatísticas acumuladas | SQLite (query) | ✅ | ✅ |

**Próximo passo:** ForegroundService para persistir estado de sessão mesmo com processo morto

**Fala:** "Somos honestos sobre as limitações. Em produção, um ForegroundService resolveria o caso do processo morto."

---

### SLIDE 9 — Demo
**Título:** RunState em ação

**Roteiro de demo (ao vivo ou gravado):**
1. Abrir o app — dashboard com estatísticas zeradas
2. Iniciar corrida — timer começa, distância cresce
3. Minimizar o app — mostrar que o estado é preservado
4. Retornar — timer continua do ponto exato
5. Pausar — status muda, timer para
6. Finalizar — corrida aparece no histórico
7. Mostrar histórico com a corrida salva

**Fala:** "Vamos ver na prática."

---

### SLIDE 10 — Conclusão
**Título:** O que aprendemos

**3 takeaways:**
1. **Ciclo de vida é um requisito de negócio**, não um detalhe técnico
2. **Estado de negócio e mecanismos de atualização** devem ser separados
3. **Riverpod + WidgetsBindingObserver** é uma combinação eficaz e testável para o problema

**Visual:** diagrama final da arquitetura completa

**Fala:** "O RunState é pequeno, mas o problema que ele resolve é real. Qualquer app com mais de uma tela e dados que precisam persistir vai enfrentar esse desafio."

---

### SLIDE 11 — Encerramento
**Título:** RunState
**Subtítulo:** Código disponível no GitHub
**Membros do grupo**
**Obrigado — perguntas?**

---

## Notas de apresentação

- **Tempo total recomendado:** 12–15 minutos + 5 min perguntas
- **Demo:** prepare uma gravação de fallback caso o emulador falhe
- **Slide 6 (código):** não leia o código — explique o conceito, o código é ilustração
- **Slide 8 (tabela):** antecipe a pergunta "e se o processo morrer?" — a resposta está na tabela
