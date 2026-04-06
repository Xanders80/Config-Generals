
---

## 🏗️ Estructura de Directorio Completa

```
project-root/
├── .opencode/                          # Configuración core de OpenCode
│   ├── config.yaml                     # Configuración principal
│   ├── agents.md                       # Documentación de agentes del proyecto
│   └── sessions/                       # Historial de sesiones persistentes
│       └── [session-id].json
│
├── agents/                             # AGENTES PRINCIPALES (Core Agents)
│   ├── core/                           # Agentes fundamentales del sistema
│   │   ├── architect/                  # 🏛️ Arquitecto de Software
│   │   │   ├── agent.yaml              # Definición del agente
│   │   │   ├── prompts/
│   │   │   │   ├── system.md           # Prompt sistema
│   │   │   │   ├── planning.md         # Prompt para planificación
│   │   │   │   └── review.md           # Prompt para revisión arquitectura
│   │   │   ├── tools/
│   │   │   │   ├── diagram-generator.ts
│   │   │   │   └── dependency-analyzer.ts
│   │   │   └── memory/                 # Memoria persistente del agente
│   │   │
│   │   ├── product-manager/            # 📋 Product Manager
│   │   │   ├── agent.yaml
│   │   │   ├── prompts/
│   │   │   │   ├── prd-generator.md    # Generación de PRDs
│   │   │   │   ├── user-stories.md
│   │   │   │   └── acceptance-criteria.md
│   │   │   └── tools/
│   │   │       ├── jira-integration.ts
│   │   │       └── notion-sync.ts
│   │   │
│   │   └── tech-lead/                  # 👨‍💼 Tech Lead
│   │       ├── agent.yaml
│   │       ├── prompts/
│   │       │   ├── code-review.md
│   │       │   ├── tech-decisions.md
│   │       │   └── mentoring.md
│   │       └── tools/
│   │           ├── pr-evaluator.ts
│   │           └── standards-checker.ts
│   │
│   ├── specialized/                    # Agentes especializados por dominio
│   │   ├── frontend/                   # 🎨 Especialista Frontend
│   │   │   ├── agent.yaml
│   │   │   ├── prompts/
│   │   │   │   ├── react-patterns.md
│   │   │   │   ├── accessibility.md
│   │   │   │   ├── performance.md
│   │   │   │   └── testing.md
│   │   │   ├── tools/
│   │   │   │   ├── component-scaffolder.ts
│   │   │   │   ├── storybook-generator.ts
│   │   │   │   └── css-analyzer.ts
│   │   │   └── templates/              # Plantillas de componentes
│   │   │       ├── component.tsx.template
│   │   │       ├── test.tsx.template
│   │   │       └── styles.module.css.template
│   │   │
│   │   ├── backend/                    # ⚙️ Especialista Backend
│   │   │   ├── agent.yaml
│   │   │   ├── prompts/
│   │   │   │   ├── api-design.md
│   │   │   │   ├── database-schema.md
│   │   │   │   ├── security.md
│   │   │   │   └── optimization.md
│   │   │   ├── tools/
│   │   │   │   ├── endpoint-generator.ts
│   │   │   │   ├── migration-creator.ts
│   │   │   │   └── swagger-generator.ts
│   │   │   └── templates/
│   │   │       ├── controller.template
│   │   │       ├── service.template
│   │   │       └── model.template
│   │   │
│   │   ├── devops/                     # 🚀 Especialista DevOps
│   │   │   ├── agent.yaml
│   │   │   ├── prompts/
│   │   │   │   ├── ci-cd.md
│   │   │   │   ├── infrastructure.md
│   │   │   │   └── monitoring.md
│   │   │   └── tools/
│   │   │       ├── docker-generator.ts
│   │   │       ├── k8s-manifest.ts
│   │   │       └── terraform-scaffolder.ts
│   │   │
│   │   ├── security/                   # 🔒 Especialista Seguridad
│   │   │   ├── agent.yaml
│   │   │   ├── prompts/
│   │   │   │   ├── vulnerability-scan.md
│   │   │   │   ├── auth-implementation.md
│   │   │   │   └── compliance.md
│   │   │   └── tools/
│   │   │       ├── dependency-checker.ts
│   │   │       └── secrets-scanner.ts
│   │   │
│   │   └── qa/                         # 🧪 Especialista QA
│   │       ├── agent.yaml
│   │       ├── prompts/
│   │       │   ├── test-strategy.md
│   │       │   ├── e2e-generation.md
│   │       │   └── bug-analysis.md
│   │       └── tools/
│   │           ├── test-generator.ts
│   │           └── coverage-analyzer.ts
│   │
│   └── orchestrators/                  # 🎼 ORQUESTADORES (Coordinadores)
│       ├── master/                     # Orquestador Principal
│       │   ├── agent.yaml
│       │   ├── prompts/
│       │   │   ├── delegation.md       # Cómo delegar a subagentes
│       │   │   ├── synthesis.md        # Síntesis de resultados
│       │   │   └── conflict-resolution.md
│       │   └── workflows/
│       │       ├── feature-development.yaml
│       │       ├── bug-fix.yaml
│       │       └── refactoring.yaml
│       │
│       └── context-manager/            # Gestor de Contexto
│           ├── agent.yaml
│           └── prompts/
│               ├── context-pruning.md
│               └── priority-management.md
│
├── subagents/                          # SUBAGENTES (Unidades de trabajo específicas)
│   ├── code-generators/                # Generadores de código
│   │   ├── react-component/
│   │   │   ├── subagent.yaml
│   │   │   └── prompt.md
│   │   ├── api-endpoint/
│   │   ├── database-migration/
│   │   └── test-suite/
│   │
│   ├── analyzers/                      # Analizadores especializados
│   │   ├── complexity-analyzer/
│   │   ├── dependency-analyzer/
│   │   ├── performance-analyzer/
│   │   └── security-analyzer/
│   │
│   ├── refactorers/                    # Refactorizadores
│   │   ├── code-simplifier/
│   │   ├── pattern-matcher/
│   │   └── dead-code-eliminator/
│   │
│   └── validators/                     # Validadores
│       ├── syntax-validator/
│       ├── type-checker/
│       └── lint-enforcer/
│
├── killers/                            # 🔪 KILLERS (Agentes de control/corrección)
│   ├── error-handler/                  # Gestor de errores
│   │   ├── killer.yaml
│   │   ├── prompts/
│   │   │   ├── error-diagnosis.md
│   │   │   ├── recovery-strategy.md
│   │   │   └── rollback-procedure.md
│   │   └── triggers/
│   │       ├── build-failure.yaml
│   │       ├── test-failure.yaml
│   │       └── runtime-error.yaml
│   │
│   ├── loop-detector/                  # Detector de bucles infinitos
│   │   ├── killer.yaml
│   │   ├── prompts/
│   │   │   ├── pattern-recognition.md
│   │   │   └── termination-logic.md
│   │   └── config/
│   │       └── max-iterations.yaml
│   │
│   ├── hallucination-guard/            # Guardián contra alucinaciones
│   │   ├── killer.yaml
│   │   ├── prompts/
│   │   │   ├── fact-checking.md
│   │   │   ├── code-verification.md
│   │   │   └── confidence-scoring.md
│   │   └── validators/
│   │       ├── syntax-validator.ts
│   │       └── logic-checker.ts
│   │
│   ├── timeout-enforcer/               # Control de timeouts
│   │   ├── killer.yaml
│   │   └── config/
│   │       └── timeout-rules.yaml
│   │
│   ├── resource-guard/                 # 🛡️ Guardián de recursos
│   │   ├── killer.yaml
│   │   ├── prompts/
│   │   │   ├── cost-monitor.md         # Monitoreo de costos API
│   │   │   ├── token-optimization.md
│   │   │   └── rate-limit-handler.md
│   │   └── thresholds/
│   │       ├── cost-limits.yaml
│   │       └── token-budgets.yaml
│   │
│   └── safety-guard/                   # 🔐 Guardián de seguridad
│       ├── killer.yaml
│       ├── prompts/
│       │   ├── injection-detection.md
│       │   ├── secret-leakage.md
│       │   └── dangerous-operations.md
│       └── blocklists/
│           ├── forbidden-commands.yaml
│           └── sensitive-patterns.yaml
│
├── tools/                              # 🧰 HERRAMIENTAS COMPARTIDAS
│   ├── shared/                         # Utilidades comunes
│   │   ├── file-operations.ts
│   │   ├── git-wrapper.ts
│   │   ├── search-engine.ts
│   │   ├── parser/
│   │   │   ├── ast-parser.ts
│   │   │   ├── comment-extractor.ts
│   │   │   └── dependency-parser.ts
│   │   └── llm-client.ts               # Cliente unificado LLM
│   │
│   ├── integrations/                   # Integraciones externas
│   │   ├── github/
│   │   │   ├── pr-creator.ts
│   │   │   ├── issue-manager.ts
│   │   │   └── webhook-handler.ts
│   │   ├── jira/
│   │   ├── slack/
│   │   ├── notion/
│   │   └── linear/
│   │
│   └── code-execution/                 # Ejecución de código sandbox
│       ├── docker-runner.ts
│       ├── test-runner.ts
│       └── linter-runner.ts
│
├── memory/                             # 🧠 SISTEMA DE MEMORIA
│   ├── short-term/                     # Memoria de sesión
│   │   ├── context-window/
│   │   │   └── current-session.json
│   │   └── working-memory/
│   │       └── active-tasks.yaml
│   │
│   ├── long-term/                      # Memoria persistente
│   │   ├── project-knowledge/
│   │   │   ├── architecture-decisions/
│   │   │   ├── patterns-catalog/
│   │   │   └── conventions/
│   │   ├── agent-experiences/
│   │   │   ├── success-patterns/
│   │   │   └── failure-lessons/
│   │   └── codebase-index/
│   │       ├── embeddings/
│   │       └── vector-store/
│   │
│   └── episodic/                       # Memoria de eventos
│       ├── sessions/
│       ├── decisions/
│       └── outcomes/
│
├── workflows/                          # 🔄 FLUJOS DE TRABAJO DEFINIDOS
│   ├── feature-development/
│   │   ├── workflow.yaml               # Definición del flujo
│   │   ├── stages/
│   │   │   ├── 01-requirements.yaml    # PM analiza requisitos
│   │   │   ├── 02-architecture.yaml    # Arquitecto diseña
│   │   │   ├── 03-implementation.yaml  # Devs implementan
│   │   │   ├── 04-review.yaml          # Tech Lead revisa
│   │   │   ├── 05-testing.yaml         # QA valida
│   │   │   └── 06-deployment.yaml      # DevOps despliega
│   │   └── transitions/
│   │       └── approval-gates.yaml
│   │
│   ├── bug-fix/
│   ├── refactoring/
│   ├── code-review/
│   └── hotfix/
│
├── prompts/                            # 📚 BIBLIOTECA DE PROMPTS
│   ├── system-prompts/                 # Prompts base por rol
│   │   ├── developer.md
│   │   ├── reviewer.md
│   │   ├── architect.md
│   │   └── manager.md
│   │
│   ├── task-prompts/                   # Prompts específicos por tarea
│   │   ├── generate/
│   │   ├── refactor/
│   │   ├── analyze/
│   │   ├── document/
│   │   └── test/
│   │
│   ├── few-shot-examples/              # Ejemplos few-shot
│   │   ├── react-components/
│   │   ├── api-endpoints/
│   │   └── database-queries/
│   │
│   └── prompt-templates/               # Plantillas dinámicas
│       └── handlebars/
│
├── config/                             # ⚙️ CONFIGURACIÓN GLOBAL
│   ├── agents-registry.yaml            # Registro de todos los agentes
│   ├── llm-providers.yaml              # Configuración de proveedores
│   ├── security-policies.yaml
│   ├── cost-limits.yaml
│   └── project-conventions.yaml
│
└── logs/                               # 📊 REGISTROS Y TELEMETRÍA
    ├── agent-logs/                     # Logs por agente
    ├── execution-traces/               # Trazas de ejecución
    ├── performance-metrics/
    └── audit-trail/                    # Registro de auditoría
```

---

## 🔧 Especificación de Componentes Clave

### 1. **AGENTES CORE** (`agents/core/`)

#### 🏛️ Architect Agent
```yaml
# agents/core/architect/agent.yaml
name: "software-architect"
version: "1.0.0"
role: "Arquitecto de Software Senior"
responsibilities:
  - Diseño de arquitectura de sistemas
  - Definición de patrones y estándares
  - Review de decisiones técnicas críticas
  - Documentación de ADRs (Architecture Decision Records)

llm_config:
  model: "claude-opus-4"
  temperature: 0.2
  max_tokens: 8000

capabilities:
  - diagram_generation
  - dependency_analysis
  - pattern_recommendation
  - tech_stack_evaluation

delegation_rules:
  can_delegate_to:
    - "frontend-specialist"
    - "backend-specialist"
    - "devops-specialist"
  must_escalate_to: "tech-lead"
```

#### 📋 Product Manager Agent
```yaml
# agents/core/product-manager/agent.yaml
name: "product-manager"
role: "Product Manager Técnico"
responsibilities:
  - Generación de PRDs (Product Requirements Documents)
  - Definición de user stories y criterios de aceptación
  - Priorización de features
  - Comunicación con stakeholders

workflows:
  - prd_creation
  - story_breakdown
  - acceptance_criteria_definition
```

#### 👨‍💼 Tech Lead Agent
```yaml
# agents/core/tech-lead/agent.yaml
name: "tech-lead"
role: "Líder Técnico"
responsibilities:
  - Code reviews de alta complejidad
  - Mentoría de desarrolladores
  - Decisiones técnicas de arquitectura
  - Resolución de conflictos técnicos

approval_gates:
  - architecture_changes
  - breaking_changes
  - security_implementations
```

---

### 2. **SUBAGENTES** (`subagents/`)

Los subagentes son **unidades especializadas de trabajo** que ejecutan tareas atómicas:

```yaml
# subagents/code-generators/react-component/subagent.yaml
name: "react-component-generator"
parent_agent: "frontend-specialist"
task_scope: "single_component"
max_execution_time: 120  # segundos
max_tokens: 4000

inputs:
  - component_name
  - props_interface
  - styling_approach
  - test_coverage_required

outputs:
  - component_file
  - styles_file
  - test_file
  - storybook_file
  - index_export

validation:
  - eslint_pass
  - typescript_compile
  - test_pass
```

**Características de Subagentes:**
- **Scope limitado**: Una sola responsabilidad bien definida
- **Timeout estricto**: Ejecución rápida y predecible
- **Validación automática**: Salida verificada antes de entregar
- **No persistencia**: Stateless, reciben contexto del orquestador

---

### 3. **KILLERS** (`killers/`)

Los killers son **agentes de control** que monitorean y detienen ejecuciones problemáticas:

#### 🔪 Error Handler Killer
```yaml
# killers/error-handler/killer.yaml
name: "error-handler"
trigger_conditions:
  - build_failure
  - test_failure
  - runtime_exception
  - syntax_error

actions:
  1_diagnose:
    - analyze_stack_trace
    - identify_root_cause
    - classify_error_type
  
  2_recover:
    - attempt_auto_fix: true
    - max_attempts: 3
    - rollback_on_failure: true
  
  3_escalate:
    - notify: "tech-lead"
    - create_incident_report: true
    - preserve_context: true
```

#### 🔪 Hallucination Guard
```yaml
# killers/hallucination-guard/killer.yaml
name: "hallucination-guard"
detection_methods:
  - syntax_validation: "parse_generated_code"
  - reference_check: "verify_against_docs"
  - confidence_scoring: "llm_self_evaluation"
  - consistency_check: "cross_reference_outputs"

intervention_levels:
  warning:
    - confidence < 0.8
    - unverified_api_usage
  block:
    - confidence < 0.5
    - syntax_errors_detected
    - security_risk_identified
  terminate:
    - repeated_hallucinations > 3
    - dangerous_code_generation
```

#### 🔪 Loop Detector
```yaml
# killers/loop-detector/killer.yaml
name: "loop-detector"
detection_patterns:
  - identical_outputs
  - cyclic_references
  - repeated_failed_attempts
  - token_count_explosion

limits:
  max_iterations: 10
  max_similarity_threshold: 0.95
  max_time_without_progress: 300  # segundos

action_on_detection:
  - interrupt_execution
  - analyze_cause
  - suggest_alternative_approach
  - escalate_to_orchestrator
```

---

### 4. **ORQUESTADORES** (`agents/orchestrators/`)

#### 🎼 Master Orchestrator
```yaml
# agents/orchestrators/master/agent.yaml
name: "master-orchestrator"
role: "Coordinador Principal de Agentes"

responsibilities:
  - Route tasks to appropriate agents
  - Manage inter-agent communication
  - Synthesize multi-agent outputs
  - Handle conflicts and dependencies
  - Maintain project state

workflow_engine:
  type: "state_machine"
  supported_patterns:
    - sequential
    - parallel
    - conditional
    - iterative

delegation_strategy:
  simple_task: "direct_to_specialist"
  complex_task: "plan_then_delegate"
  critical_task: "architect_review_then_delegate"
  emergency: "killers_first_then_assess"
```

---

## 🔄 Flujo de Trabajo Ejemplo: Feature Development

```yaml
# workflows/feature-development/workflow.yaml
name: "feature-development"
version: "2.0.0"

stages:
  01_requirements:
    agent: "product-manager"
    output: "prd.md"
    gates:
      - stakeholder_approval
      
  02_architecture:
    agent: "architect"
    input: "prd.md"
    output: "tech-spec.md"
    gates:
      - tech_lead_review
      
  03_planning:
    agent: "master-orchestrator"
    mode: "plan"
    output: "implementation-plan.json"
    
  04_implementation:
    parallel:
      frontend:
        agent: "frontend-specialist"
        subagents:
          - "react-component-generator"
          - "test-generator"
      backend:
        agent: "backend-specialist"
        subagents:
          - "api-endpoint-generator"
          - "migration-generator"
    synchronization: "api_contract_first"
    
  05_integration:
    agent: "master-orchestrator"
    action: "merge_and_validate"
    
  06_review:
    agent: "tech-lead"
    checks:
      - code_quality
      - test_coverage
      - security_scan
    on_failure: "return_to_implementation"
    
  07_qa:
    agent: "qa-specialist"
    validation:
      - functional_tests
      - e2e_tests
      - performance_tests
      
  08_deployment:
    agent: "devops-specialist"
    steps:
      - staging_deploy
      - smoke_tests
      - production_deploy

killers_active:
  - error-handler
  - loop-detector
  - hallucination-guard
  - resource-guard
```

---

## 🧠 Sistema de Memoria

### Jerarquía de Memoria

| Tipo | Alcance | Persistencia | Uso |
|------|---------|--------------|-----|
| **Context Window** | Sesión actual | Volátil | Conversación activa |
| **Working Memory** | Tarea actual | Temporal | Estado de ejecución |
| **Short-term** | Día/Semana | Persistente | Contexto reciente |
| **Long-term** | Proyecto completo | Permanente | Conocimiento acumulado |
| **Episodic** | Eventos históricos | Permanente | Lecciones aprendidas |

### Ejemplo: Almacenamiento de Experiencias

```yaml
# memory/long-term/agent-experiences/success-patterns/react-hooks.yaml
pattern: "custom-hook-extraction"
context: "frontend-component-refactoring"
success_rate: 0.94
conditions:
  - component_lines > 150
  - repeated_logic > 2
  - state_complexity: "high"
  
approach:
  1: "identify_stateful_logic"
  2: "extract_to_hook_file"
  3: "update_component_imports"
  4: "verify_tests_still_pass"
  
lessons_learned:
  - "Always preserve hook naming convention: use[Feature]"
  - "Export hook from index.ts for discoverability"
  - "Add JSDoc comments for complex state logic"
```

---

## 📊 Métricas y Observabilidad

```yaml
# logs/performance-metrics/agent-efficiency.yaml
metrics_collected:
  - token_usage_per_agent
  - execution_time_per_task
  - success_rate_by_agent_type
  - inter_agent_communication_overhead
  - killer_intervention_frequency
  
alerts:
  - cost_threshold_exceeded
  - latency_degradation
  - error_rate_spike
  - hallucination_pattern_detected
```

---
