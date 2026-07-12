@{
  SchemaVersion = 1
  Lessons = @(
    @{
      Id = 'CLZ-090'; Folder = 'CLZ-090-optional-vscode-terraform-powershell-setup'; Title = 'Optional Windows Contributor Workstation Setup'
      Phase = 'Workstation'; Prerequisites = @(); Diagram = 'workstation-toolchain.svg'; CostTier = 'None'; DeploymentMode = 'Local only'
      Navigation = @{ Previous = $null; Next = 'CLZ-100' }
    }
    @{
      Id = 'CLZ-100'; Folder = 'CLZ-100-foundations'; Title = 'Terraform Foundations'
      Phase = 'Foundations'; Prerequisites = @(); Diagram = 'terraform-workflow.svg'; CostTier = 'None'; DeploymentMode = 'Local only'
      Navigation = @{ Previous = 'CLZ-090'; Next = 'CLZ-110' }
    }
    @{
      Id = 'CLZ-110'; Folder = 'CLZ-110-windows-workstation-setup'; Title = 'Azure CLI and Subscription Readiness'
      Phase = 'Foundations'; Prerequisites = @('CLZ-100'); Diagram = 'workstation-toolchain.svg'; CostTier = 'None'; DeploymentMode = 'Read-only Azure checks'
      Navigation = @{ Previous = 'CLZ-100'; Next = 'CLZ-120' }
    }
    @{
      Id = 'CLZ-120'; Folder = 'CLZ-120-terraform-core-workflow'; Title = 'First Azure Deployment and Terraform Workflow'
      Phase = 'Foundations'; Prerequisites = @('CLZ-110'); Diagram = 'terraform-workflow.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-110'; Next = 'CLZ-130' }
    }
    @{
      Id = 'CLZ-130'; Folder = 'CLZ-130-provider-authentication'; Title = 'Provider Authentication'
      Phase = 'Foundations'; Prerequisites = @('CLZ-120'); Diagram = 'terraform-workflow.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-120'; Next = 'CLZ-140' }
    }
    @{
      Id = 'CLZ-140'; Folder = 'CLZ-140-resource-groups-tags'; Title = 'Resource Groups and Tags'
      Phase = 'Foundations'; Prerequisites = @('CLZ-130'); Diagram = 'resource-naming.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-130'; Next = 'CLZ-150' }
    }
    @{
      Id = 'CLZ-150'; Folder = 'CLZ-150-variables-locals-outputs'; Title = 'Variables, Locals, and Outputs'
      Phase = 'Foundations'; Prerequisites = @('CLZ-140'); Diagram = 'resource-naming.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-140'; Next = 'CLZ-160' }
    }
    @{
      Id = 'CLZ-160'; Folder = 'CLZ-160-state-and-locking-basics'; Title = 'State and Locking Basics'
      Phase = 'Foundations'; Prerequisites = @('CLZ-150'); Diagram = 'remote-state.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-150'; Next = 'CLZ-170' }
    }
    @{
      Id = 'CLZ-170'; Folder = 'CLZ-170-virtual-network-foundation'; Title = 'Virtual Network Foundation'
      Phase = 'Networking'; Prerequisites = @('CLZ-160'); Diagram = 'network-foundation.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-160'; Next = 'CLZ-180' }
    }
    @{
      Id = 'CLZ-180'; Folder = 'CLZ-180-network-security-groups'; Title = 'Network Security Groups'
      Phase = 'Networking'; Prerequisites = @('CLZ-170'); Diagram = 'network-foundation.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-170'; Next = 'CLZ-190' }
    }
    @{
      Id = 'CLZ-190'; Folder = 'CLZ-190-windows-vm-basics'; Title = 'Windows VM Basics'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-180'); Diagram = 'windows-iis-vm.svg'; CostTier = 'Moderate'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-180'; Next = 'CLZ-200' }
    }
    @{
      Id = 'CLZ-200'; Folder = 'CLZ-200-windows-vm-iis-bootstrap'; Title = 'Windows VM IIS Bootstrap'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-190'); Diagram = 'windows-iis-vm.svg'; CostTier = 'Moderate'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-190'; Next = 'CLZ-210' }
    }
    @{
      Id = 'CLZ-210'; Folder = 'CLZ-210-azure-bastion-rdp'; Title = 'Azure Bastion RDP'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-200'); Diagram = 'bastion-rdp.svg'; CostTier = 'High'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-200'; Next = 'CLZ-220' }
    }
    @{
      Id = 'CLZ-220'; Folder = 'CLZ-220-standard-load-balancer-windows'; Title = 'Standard Load Balancer for Windows'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-210'); Diagram = 'load-balancer-vmss.svg'; CostTier = 'High'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-210'; Next = 'CLZ-230' }
    }
    @{
      Id = 'CLZ-230'; Folder = 'CLZ-230-load-balancer-nat-rules'; Title = 'Load Balancer NAT Rules'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-220'); Diagram = 'load-balancer-vmss.svg'; CostTier = 'Moderate'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-220'; Next = 'CLZ-240' }
    }
    @{
      Id = 'CLZ-240'; Folder = 'CLZ-240-count-windows-vms'; Title = 'Count with Windows VMs'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-230'); Diagram = 'windows-iis-vm.svg'; CostTier = 'High'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-230'; Next = 'CLZ-250' }
    }
    @{
      Id = 'CLZ-250'; Folder = 'CLZ-250-for-each-windows-vms'; Title = 'For Each with Windows VMs'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-240'); Diagram = 'windows-iis-vm.svg'; CostTier = 'High'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-240'; Next = 'CLZ-260' }
    }
    @{
      Id = 'CLZ-260'; Folder = 'CLZ-260-windows-vmss-manual-scaling'; Title = 'Windows VMSS Manual Scaling'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-250'); Diagram = 'load-balancer-vmss.svg'; CostTier = 'High'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-250'; Next = 'CLZ-270' }
    }
    @{
      Id = 'CLZ-270'; Folder = 'CLZ-270-windows-vmss-autoscaling'; Title = 'Windows VMSS Autoscaling'
      Phase = 'Windows compute'; Prerequisites = @('CLZ-260'); Diagram = 'load-balancer-vmss.svg'; CostTier = 'High'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-260'; Next = 'CLZ-280' }
    }
    @{
      Id = 'CLZ-280'; Folder = 'CLZ-280-nat-gateway-outbound'; Title = 'NAT Gateway Outbound'
      Phase = 'Platform services'; Prerequisites = @('CLZ-270'); Diagram = 'network-foundation.svg'; CostTier = 'Moderate'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-270'; Next = 'CLZ-290' }
    }
    @{
      Id = 'CLZ-290'; Folder = 'CLZ-290-private-dns'; Title = 'Private DNS'
      Phase = 'Platform services'; Prerequisites = @('CLZ-280'); Diagram = 'network-foundation.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-280'; Next = 'CLZ-300' }
    }
    @{
      Id = 'CLZ-300'; Folder = 'CLZ-300-public-dns-optional'; Title = 'Optional Public DNS'
      Phase = 'Platform services'; Prerequisites = @('CLZ-290'); Diagram = 'global-routing.svg'; CostTier = 'Low'; DeploymentMode = 'Optional Azure deployment'
      Navigation = @{ Previous = 'CLZ-290'; Next = 'CLZ-310' }
    }
    @{
      Id = 'CLZ-310'; Folder = 'CLZ-310-remote-state-storage'; Title = 'Remote State Storage'
      Phase = 'Platform services'; Prerequisites = @('CLZ-160'); Diagram = 'remote-state.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment with migration'
      Navigation = @{ Previous = 'CLZ-300'; Next = 'CLZ-320' }
    }
    @{
      Id = 'CLZ-320'; Folder = 'CLZ-320-cross-environment-state'; Title = 'Cross-Environment State'
      Phase = 'Platform services'; Prerequisites = @('CLZ-310'); Diagram = 'remote-state.svg'; CostTier = 'Low'; DeploymentMode = 'Dependent Azure deployment'
      Navigation = @{ Previous = 'CLZ-310'; Next = 'CLZ-330' }
    }
    @{
      Id = 'CLZ-330'; Folder = 'CLZ-330-traffic-manager-or-front-door'; Title = 'Traffic Manager Global Routing'
      Phase = 'Platform services'; Prerequisites = @('CLZ-200'); Diagram = 'global-routing.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-320'; Next = 'CLZ-340' }
    }
    @{
      Id = 'CLZ-340'; Folder = 'CLZ-340-key-vault-secrets'; Title = 'Key Vault Secrets'
      Phase = 'Platform services'; Prerequisites = @('CLZ-130'); Diagram = 'security-secrets.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-330'; Next = 'CLZ-350' }
    }
    @{
      Id = 'CLZ-350'; Folder = 'CLZ-350-private-endpoint-storage'; Title = 'Private Endpoint for Storage'
      Phase = 'Platform services'; Prerequisites = @('CLZ-290'); Diagram = 'private-endpoint-sql.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-340'; Next = 'CLZ-360' }
    }
    @{
      Id = 'CLZ-360'; Folder = 'CLZ-360-azure-monitor-log-analytics'; Title = 'Azure Monitor and Log Analytics'
      Phase = 'Operations'; Prerequisites = @('CLZ-120'); Diagram = 'monitoring.svg'; CostTier = 'Low'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-350'; Next = 'CLZ-370' }
    }
    @{
      Id = 'CLZ-370'; Folder = 'CLZ-370-github-actions-terraform'; Title = 'GitHub Actions for Terraform'
      Phase = 'Operations'; Prerequisites = @('CLZ-120'); Diagram = 'github-actions.svg'; CostTier = 'None'; DeploymentMode = 'CI examples'
      Navigation = @{ Previous = 'CLZ-360'; Next = 'CLZ-380' }
    }
    @{
      Id = 'CLZ-380'; Folder = 'CLZ-380-azure-sql-private-access'; Title = 'Azure SQL Private Access'
      Phase = 'Operations'; Prerequisites = @('CLZ-290', 'CLZ-350'); Diagram = 'private-endpoint-sql.svg'; CostTier = 'Moderate'; DeploymentMode = 'Azure deployment'
      Navigation = @{ Previous = 'CLZ-370'; Next = 'CLZ-390' }
    }
    @{
      Id = 'CLZ-390'; Folder = 'CLZ-390-final-windows-reference-architecture'; Title = 'Final Windows Reference Architecture'
      Phase = 'Operations'; Prerequisites = @('CLZ-210', 'CLZ-260', 'CLZ-340', 'CLZ-360'); Diagram = 'capstone-architecture.svg'; CostTier = 'High'; DeploymentMode = 'Capstone Azure deployment'
      Navigation = @{ Previous = 'CLZ-380'; Next = $null }
    }
  )
}
