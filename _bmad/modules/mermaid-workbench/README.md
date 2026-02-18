# Mermaid Workbench

Module BMAD pour la generation, organisation et navigation de diagrammes Mermaid multi-couches.

## Structure

```
_bmad/modules/mermaid-workbench/
├── config.yaml          # Configuration et schemas de reference
├── README.md            # Ce fichier
├── templates/
│   ├── flowchart.md     # Template flowchart (TD/LR)
│   ├── architecture.md  # Template architecture (C4-like)
│   ├── state.md         # Template state diagram
│   └── sequence.md      # Template sequence diagram
└── tasks/
    ├── generate-diagram.md  # Task: generer un nouveau diagramme
    └── update-diagram.md    # Task: modifier un diagramme existant
```

## Utilisation rapide

### Generer un diagramme

Pendant une session BMAD, decrivez votre besoin :

> "Genere un diagramme d'architecture L0 pour le systeme de paiement"

L'agent lance une Task `generate-diagram` avec :
- `type: architecture`
- `layer: L0`
- `feature: 001-payment`

Resultat : `.bmad_output/mermaid/001-payment/L0-payment-system.mmd`

### Drill-down vers une couche inferieure

> "Zoom sur le composant Payment Gateway — genere un flowchart L1"

L'agent lance avec :
- `type: flowchart`
- `layer: L1`
- `parent: payment-system#payment-gateway`
- `feature: 001-payment`

Resultat : `L1-payment-gateway.mmd` avec relation vers le parent.

### Mettre a jour un diagramme

> "Ajoute un cas d'erreur timeout au flowchart payment-gateway"

L'agent lance `update-diagram` avec :
- `diagram_id: payment-gateway`
- `feature: 001-payment`
- `instructions: "Ajouter un cas d'erreur timeout apres l'appel au PSP"`

### Lister les diagrammes

> "Montre-moi l'index des diagrammes de la feature 001-payment"

L'agent lit `_index.yaml` et affiche l'arbre hierarchique.

## Types supportes

| Type | Directive | Usage |
|------|-----------|-------|
| `flowchart` | `flowchart TD/LR` | Process, decisions, user journeys |
| `architecture` | `flowchart TD` | Composants systeme, services, C4-like |
| `state` | `stateDiagram-v2` | Lifecycle, etats, transitions |
| `sequence` | `sequenceDiagram` | API calls, interactions multi-acteurs |

## Couches (Layers)

| Layer | Niveau | Description |
|-------|--------|-------------|
| `L0` | Macro | Vue systeme globale |
| `L1` | Process | Flux et composants |
| `L2` | Detail | Etats, validations, sous-processus |

## Sortie

```
.bmad_output/mermaid/<xxx-feature-name>/
├── _index.yaml          # Manifest avec arbre des relations
├── L0-*.mmd             # Diagrammes macro
├── L1-*.mmd             # Diagrammes process
└── L2-*.mmd             # Diagrammes detail
```

## Configuration

Voir `config.yaml` pour :
- Types et layers supportes
- Chemin de sortie
- Convention de nommage
- Schemas de reference (frontmatter .mmd, _index.yaml)
