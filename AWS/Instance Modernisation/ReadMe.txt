The script requires a csv table detailing Virtual Machine modernisation paths.

The csv will need to be kept up to date with any new instance/VM  types that are released although this is not that regular for the majority of machine types.

Steps to run the script:
1.	Save the CSV table locally
2.	Run the script.
3.	Specify the directory path to the CSV table file for example – C:\Users\rfroggatt\Desktop\Instance Modernisation
4.	Specify Login Credentials to Azure or AWS.
5.	Specify subscription ID (Azure Only)

The script will output 2 files to the directory you specified in Step 3:
-	CSV containing all instance modernisation recommendations.
-	Log file showing all the instances/VMs that were checked by the script along with its recommendation if there was one
