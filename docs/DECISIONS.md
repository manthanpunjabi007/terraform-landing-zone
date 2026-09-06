# Decision log

A record of choices made while building this landing zone: what was chosen, what was
rejected, and why. Written as decisions rather than documentation, so the reasoning
survives after the code becomes obvious.

---

## Day 1 — Foundations

### Pin the AWS provider with a pessimistic constraint

**Chose** `version = "~> 6.0"` on the `hashicorp/aws` provider.

**Rejected** leaving it unconstrained, and pinning to an exact version like `= 6.63.0`.

**Why.** Unconstrained means a provider release months from now could break this repo
without anyone touching a line of code — AWS provider major versions ship genuinely
breaking changes, with published upgrade guides listing renamed and removed arguments.
Pinning exactly is the opposite failure: you never receive bug fixes or new resource
types without a manual bump. `~> 6.0` allows any 6.x and blocks 7.0, which is the
balance between reproducibility and maintenance.

**Trade-off.** A breaking change within the 6.x line would still reach us. The
`.terraform.lock.hcl` file covers that gap — it records the exact resolved version plus
checksums, so a clone gets a byte-identical provider rather than "some 6.x". The
constraint says what is acceptable; the lock file says what was actually used.

*Connects to: dependency management, reproducible builds, supply chain.*

---

### Keep credentials out of the configuration entirely

**Chose** to leave the `provider "aws"` block with no `access_key` or `secret_key`,
relying on the default credential chain.

**Rejected** hardcoding credentials, and passing them in as Terraform variables.

**Why.** The provider resolves credentials in a defined order: environment variables,
then the shared credentials file written by `aws configure`, then an instance or
container role. Because nothing sensitive is ever expressed in the configuration, there
is nothing to leak when the repo is pushed publicly. Passing them as variables would
be worse than useless — they would land in state in plaintext.

**Trade-off.** The configuration is not self-contained; whoever runs it must have
credentials configured out of band. That is the correct trade: the alternative is
secrets in version control.

*Connects to: secrets management, credential chain, why state is sensitive.*

---

### Treat state as sensitive and keep it out of Git

**Chose** to gitignore `*.tfstate` and `.terraform/`, and to commit `.terraform.lock.hcl`.

**Rejected** committing state so it is "backed up".

**Why.** State is not just a list of resource names. It records resource IDs, ARNs, and
for some resource types the attribute values themselves — which can include secrets in
plaintext. Committing it is a security incident rather than a style mistake. Separately,
two people holding divergent copies of state will make contradictory decisions about the
same infrastructure, because state is what Terraform compares against reality.

**Trade-off.** Local state means no backup, no locking, and no collaboration. Acceptable
for a single-operator demo project; not acceptable in a team. The production answer is
an S3 backend with DynamoDB state locking, which is the first upgrade this project
should receive.

*Connects to: state fundamentals, remote backends, team workflows.*

---

### Bootstrap with an admin identity despite the project being about least privilege

**Chose** a dedicated IAM user, `terraform-admin`, with `AdministratorAccess` and no
console password, as the identity that runs Terraform.

**Rejected** running as root, and scoping the bootstrap identity tightly.

**Why.** Root should never be used for API calls — this landing zone specifically alarms
on root usage, so using it to build the landing zone would be incoherent. Scoping the
runner tightly is impractical here because it creates IAM roles, VPCs, CloudTrail and
Config; you cannot enumerate the required API calls in advance without significant
iteration. The least-privilege work in this project lives in the roles authored *inside*
the landing zone, which is a separate concern from the identity that deploys it.

**Trade-off, and the better answer.** A static admin access key is a long-lived
unrestricted credential, and MFA does not protect API calls made with one. In production
there would be no static key at all: CI would assume a scoped deployment role via OIDC,
so no durable credential exists anywhere. A static key is used here because this is a
solo project with no CI. The key is deleted at project close.

*Connects to: least privilege, bootstrap problem, OIDC federation, why root MFA is not enough.*

---

### Deploy to ap-southeast-2 rather than the nearer ap-southeast-4

**Chose** Sydney over Melbourne, despite operating from Melbourne.

**Rejected** the geographically closer region.

**Why.** Sydney is the older and fuller region. Every service this project depends on —
CloudTrail, Config, VPC endpoints — is guaranteed available there. Newer regions
occasionally lag on service availability, and discovering a gap mid-project would cost
time that a demo timeline does not have. Latency is irrelevant for infrastructure that
serves no user traffic.

**Trade-off.** For a workload with Melbourne users, the calculus reverses — data
residency and latency would favour ap-southeast-4. The choice is driven by the workload,
not by the map.

*Connects to: region selection, service availability, data residency.*

---

### Apply tags at the provider level rather than per resource

**Chose** `default_tags` on the provider block, stamping Project, ManagedBy and
Environment onto every taggable resource.

**Rejected** tagging each resource individually.

**Why.** Per-resource tagging is correct exactly once and then decays — the resource
added under time pressure is the one that goes untagged. Untagged resources are how cost
allocation breaks and how ownership becomes unknowable. Applying tags at the provider
level makes the correct behaviour the default rather than a discipline.

**Trade-off.** Resource-specific tags still need to be set individually, and they merge
with rather than replace the defaults.

*Connects to: cost allocation, resource ownership, tagging strategy.*

---

### Compensating controls for an account with no credit ceiling

**Chose** a $5 monthly budget with alerts at 20% actual, 80% forecast and 100% actual,
plus free tier usage alerts, configured before any resource was created.

**Context.** The AWS Free plan was unavailable — the signup was recognised as belonging
to an existing customer and upgraded to pay-as-you-go. The Free plan's hard spending
floor was therefore not available as a safety net.

**Why.** With no credit ceiling, spend is bounded by attention rather than by the
platform. The forecast threshold matters more than the actual one: it fires based on
run-rate rather than accumulated spend, so a resource left running is caught early
rather than at month end. Configuring budgets before the first resource means the
control exists before the risk does.

**Trade-off.** Budget data refreshes roughly three times daily, so alerts lag real spend
by hours. Budgets are a safety net, not a monitor. Cost Explorer grouped by service is
the tool for answering "what is costing money right now".

*Connects to: cost controls, detective vs preventive controls, forecast alerting.*

---

### Incident: CLI authenticating against a decommissioned account

**Symptom.** `aws sts get-caller-identity` returned `InvalidClientTokenId`.

**Diagnosis.** The error was the useful part. `InvalidClientTokenId` means AWS does not
recognise the key at all; `AccessDenied` would have meant the identity exists but lacks
permission. That distinction narrowed the problem immediately to a credential that had
been deleted or belonged to a different account, rather than a policy issue.

`aws configure list` confirmed it: credentials were resolving from
`shared-credentials-file` with a region of `eu-west-2`, which was inconsistent with an
operator in Melbourne. Checking environment variables ruled out an override higher in
the credential chain. The credentials were leftovers from an unrelated project whose
account was no longer accessible.

**Resolution.** Removed `~/.aws/credentials` and `~/.aws/config` before re-running
`aws configure`, rather than overwriting in place — deleting first eliminates the
possibility of accepting a stale bracketed default by pressing Enter through a prompt.
Verified by checking that the returned account ID matched the intended account, not
merely that the command succeeded.

**Takeaway.** Read the specific error rather than the category. AWS distinguishes
"unknown credential" from "insufficient permission", and the two have entirely different
remediation paths.

*Connects to: credential chain resolution, debugging methodology, why the account ID in the ARN is worth reading.*