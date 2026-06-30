# Cost Governance And Lab Safety

The labs are designed for hands-on Azure learning, so every applied lesson should be treated as a temporary environment unless the README says otherwise.

## Recommended Lab Subscription Setup

- Use a dedicated subscription for learning.
- Set a monthly budget and alert before running compute, load balancer, Bastion, SQL, or private endpoint lessons.
- Keep the default region only when quota is available there.
- Use the smallest practical instance counts.
- Tag every resource group through the lesson variables.
- Avoid mixing these labs with production resource groups.

## Before Apply

Run the standard local checks from the lesson folder:

~~~powershell
terraform fmt -check
terraform validate
terraform plan -out tfplan
~~~

Review the plan for:

- Public IP addresses.
- Open inbound ports.
- Bastion hosts.
- VM and VMSS instance counts.
- SQL, monitoring, DNS, and private endpoint resources.
- Resource group names and tags.

## During The Lab

- Keep the terminal output open until the apply finishes.
- Save any generated password only in a secure local location.
- Do not paste secrets into issues, pull requests, chats, screenshots, or docs.
- Validate the expected outcome before moving to the next lesson.
- Record any unexpected Azure quota, provider, or permission issue for troubleshooting updates.

## Cleanup

Destroy resources from the lesson folder unless another lesson explicitly depends on them:

~~~powershell
terraform destroy
~~~

After destroy:

- Confirm the resource group is gone or empty.
- Check for orphaned public IPs, disks, NICs, DNS records, and private endpoints.
- Remove local plan files if they are no longer needed.
- Keep generated reports under `artifacts/` local unless reviewed.

## Production Use

These examples are teaching material. Before adapting a pattern for production, review identity, network segmentation, logging retention, backup, disaster recovery, policy, naming, tagging, cost controls, and operational ownership.
