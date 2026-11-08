# CKA Practice (Simple Edition)

Straightforward CKA practice labs derived from the CKA-PREP playlist. Every question lives in its own folder with:

- `LabSetUp.bash` — copy/paste into Killercoda (or any Kubernetes cluster) to prep the environment.
- `Questions.bash` — the scenario text plus the YouTube link for the walkthrough.
- `SolutionNotes.bash` — a step-by-step solution when you need a hint.
- `validate.sh` — automated validator verifying your solution against the cluster.
- `cleanup.sh` — automated cleanup script resetting cluster resources for this lab.

## How to Use

1. Launch the CKA Killercoda playground or your own cluster.
2. Clone this repo inside the environment.
3. Use the helper scripts in `scripts/`:

### Viewing Questions & Solutions
- **Show question statement by number or name:**
  ```bash
  bash scripts/show.sh 1
  # or from repository root:
  bash show.sh 1
  ```
- **Show question statement with its solution notes:**
  ```bash
  bash show.sh 1 -s
  ```
- **List all questions:**
  ```bash
  bash show.sh --list
  ```

### Running Lab Setups
- **Run a single question:**
  ```bash
  bash scripts/run-question.sh 1
  # or
  bash scripts/run-question.sh "Question-1 MariaDB-Persistent volume"
  ```
- **Run all question setups sequentially:**
  ```bash
  bash scripts/run-all.sh
  # Options:
  #   --dry-run      Preview setups without executing
  #   --fail-fast    Stop at the first error
  #   --list         List discovered questions and scripts
  #   1 2 5          Run only questions 1, 2, and 5
  ```

### Validating Lab Solutions
- **Validate a single question solution:**
  ```bash
  bash scripts/validate-question.sh 1
  # or
  bash scripts/validate-question.sh "Question-1 MariaDB-Persistent volume"
  ```
- **Validate all solutions across all questions:**
  ```bash
  bash scripts/validate-all.sh
  # Options:
  #   --dry-run      Preview validations without executing
  #   --fail-fast    Stop at the first failing question
  #   --syntax       Run syntax check (bash -n) on all scripts
  #   --list         List validators for each question
  ```

### Cleaning Up Labs
- **Clean a single question environment:**
  ```bash
  bash scripts/clean-question.sh 1
  # or from repository root:
  bash clean.sh 1
  ```
- **Clean all question environments:**
  ```bash
  bash scripts/clean-all.sh
  # Options:
  #   --dry-run      Preview cleanups without executing
  #   --fail-fast    Stop at the first error
  #   --list         List cleanup scripts available
  ```

## Available Questions
| Question | Topic | Video |
|----------|-------|-------|
| Question-1 | MariaDB-Persistent volume | https://youtu.be/aXvvc1EB1zg |
| Question-2 | ArgoCD | https://youtu.be/e0YGRSjb8CU |
| Question-3 | Sidecar | https://youtu.be/3xraEGGQJDY |
| Question-4 | Resource-Allocation | https://youtu.be/ZqGDdETii8c |
| Question-5 | HPA | https://youtu.be/YGkARVFKtmM |
| Question-6 | CRDs | https://youtu.be/SA1DzLQaDJs |
| Question-7 | PriorityClass | https://youtu.be/CZzxGyF6OHc |
| Question-8 | CNI & Network Policy | https://youtu.be/Uc04Ui4x3EM |
| Question-9 | Cri-Dockerd | https://youtu.be/ybzo1vXiqjU |
| Question-10 | Taints-Tolerations | https://youtu.be/oy6Mdqt1-jk |
| Question-11 | Gateway-API | https://youtu.be/G9zispvOCHE |
| Question-12 | Ingress | https://youtu.be/sy9zABvDedQ |
| Question-13 | Network-Policy | https://youtu.be/rA8mXYTU0W8 |
| Question-14 | Storage-Class | https://youtu.be/di7X7OHn2fc |
| Question-15 | Etcd-Fix | https://youtu.be/IL448T6r8H4 |
| Question-16 | NodePort | |
| Question-17 | TLS-Config | |
