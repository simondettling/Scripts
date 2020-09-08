# Creating a MDT Reference VM with PowerShell

This PowerShell Script can be used to fully automate the creation process of a Reference VM for Microsoft Deployment Toolkit. The following things will be done by the script:

1. Copying the Boot-Image from the Deployment Share to the Hyper-V Host
2. Creating a Hyper-V VM with various options
3. Mounting the Boot-Image
4. Starting the VM
5. Connecting to the VM using Virtual Machine Connection
6. Checking every 15 seconds if the VM is still running
7. Removing the VM, when it stopped running

The Full Documentation of the Script can be found on my Blog: http://msitproblog.com/2016/02/17/how-to-create-a-reference-vm-with-powershell/
