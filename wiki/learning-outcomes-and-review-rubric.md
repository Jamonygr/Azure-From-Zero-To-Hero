# Learning Outcomes And Review Rubric

Use this guide to evaluate whether the curriculum teaches real Azure skills instead of only showing copy-and-paste commands.

## Learner Outcomes

| Phase | Lessons | Learner can demonstrate |
|---|---:|---|
| Workstation readiness | 090-110 | Install and verify Terraform, Azure CLI, Git, VS Code, and PowerShell tooling on Windows |
| Terraform foundation | 120-160 | Run init, format, validate, plan, apply, destroy, variables, locals, outputs, state, and locking basics |
| Network foundation | 170-180 | Design a VNet, subnets, address ranges, and NSG rules with explainable intent |
| Windows compute | 190-270 | Deploy Windows VMs, bootstrap IIS, use Bastion, configure load balancing, and scale VMSS workloads |
| Platform services | 280-350 | Add NAT Gateway, DNS, remote state, Key Vault, and private endpoints |
| Operations | 360-390 | Add monitoring, CI validation, Azure SQL private access, and a final reference architecture |

## Review Rubric

| Area | Strong evidence | Needs work |
|---|---|---|
| Learning clarity | The lesson explains what is being built, why it matters, and how to verify it | Steps work but the reason behind them is unclear |
| Safety | Secrets, public access, cleanup, and costs are called out before risky commands | Learners could create resources without understanding exposure or cost |
| Terraform quality | Code is formatted, validated, named consistently, and split only where it helps readability | Code works once but is hard to review or repeat |
| Azure accuracy | Resources match current Azure patterns and avoid obsolete defaults | Resource choices are unexplained or likely to drift quickly |
| Windows path | PowerShell commands are first-class and tested on the documented workstation path | Windows users must translate from another shell |
| Documentation | Diagrams, runbooks, validation, and cleanup sections are aligned with the code | README content and Terraform behavior disagree |
| Operations | CI, linting, scanning, and dependency updates are documented and repeatable | Quality checks exist but are difficult to run or interpret |

## Evidence Checklist

Before calling a lesson ready, verify:

1. The lesson README names the goal and expected result.
2. The Terraform files pass `terraform fmt -check`.
3. Backend-free validation passes where the lesson does not require existing remote state.
4. The sample variables avoid real names, real credentials, and private tenant data.
5. The cleanup path is clear and tested.
6. The next lesson pointer is correct.
7. Any diagram matches the deployed resource shape.

## Phase Review Questions

- Can a learner explain what changed from the previous phase?
- Can a learner predict what Azure resources will be created before running `terraform plan`?
- Can a learner identify which resources cost money while idle?
- Can a learner explain which traffic is public, private, inbound, and outbound?
- Can a learner recover safely from a partial apply or failed destroy?
