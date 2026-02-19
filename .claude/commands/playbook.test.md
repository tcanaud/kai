# Playbook Supervisor — Proof of Concept Test

Tu es un superviseur de playbook. Ce test valide 3 mécanismes : le chaînage de Task subagents, la prise de décision basée sur les résultats, et le gate humain.

## Instructions

Exécute les étapes suivantes **en séquence**. Ne saute aucune étape.

---

### STEP 1 — Lecture de l'état feature (inline)

Lis le fichier `.features/012-superviseur-autonome-boucle-complete.yaml`.
Extrais : `lifecycle.stage`, `lifecycle.progress`, `workflow_path`.
Affiche un résumé court de l'état.

---

### STEP 2 — Scan des artifacts (Task subagent)

Lance un **Task subagent** (type `Explore`, thoroughness `quick`) avec ce prompt :

> "Scanne les dossiers suivants et liste TOUS les fichiers trouvés :
> 1. `specs/012-superviseur-autonome-boucle-complete/`
> 2. `.bmad_output/planning-artifacts/012-superviseur-autonome-boucle-complete/`
> 3. `.agreements/012-superviseur-autonome-boucle-complete/`
> 4. `.qa/012-superviseur-autonome-boucle-complete/`
>
> Pour chaque dossier, indique : vide ou liste des fichiers."

Attends le retour du subagent avant de continuer.

---

### STEP 3 — Décision autonome

Basé sur le stage (step 1) et les artifacts trouvés (step 2), détermine le **next step** dans le feature workflow.

Utilise cette logique :
- Si pas de brief ni PRD dans `.bmad_output/planning-artifacts/` → next = "Brief"
- Si brief existe mais pas de PRD → next = "PRD"
- Si brief + PRD mais pas de spec → next = "Specify"
- Si spec mais pas de plan → next = "Plan"
- Si spec + plan mais pas de tasks → next = "Tasks"
- Sinon → next = "Implementation"

---

### STEP 4 — Écriture du rapport (inline)

Écris le fichier `/tmp/supervisor-test.md` avec :

```markdown
# Supervisor Test Report

**Date**: {today}
**Feature**: 012-superviseur-autonome-boucle-complete

## State
- Stage: {from step 1}
- Progress: {from step 1}
- Workflow: {from step 1}

## Artifacts Found
{from step 2}

## Decision
- Next step: {from step 3}
- Reasoning: {why}

## Mechanism Validation
- [x] Step 1: Inline read — OK
- [x] Step 2: Task subagent — OK
- [x] Step 3: Autonomous decision — OK
- [ ] Step 4: Report written — OK
- [ ] Step 5: Human gate — pending
```

---

### STEP 5 — Gate humain (HALT)

**ARRÊTE-TOI ICI.** Affiche ce message à l'utilisateur :

> **🚦 Gate humain atteint.**
>
> Le superviseur recommande d'exécuter : **{next step from step 3}**
>
> Voulez-vous :
> 1. **Continuer** — le superviseur exécuterait ce step (pas implémenté dans ce test)
> 2. **Voir le rapport** — afficher `/tmp/supervisor-test.md`
> 3. **Arrêter** — fin du test
>
> **Le test est validé si vous voyez ce message.**

Attends la réponse de l'utilisateur. Ne fais rien d'autre.
