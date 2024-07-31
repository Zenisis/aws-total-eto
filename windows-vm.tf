resource "aws_instance" "windows_vm" {
  ami           = "ami-008137b3bc1bc9652"  # Windows Server 2022 base in us-west-2
  instance_type = "t3.micro"
  key_name      = aws_key_pair.this.key_name

  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  user_data              = data.template_file.user_data.rendered

  tags = {
    Name = "WindowsVM-Totaleto"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 30  # Adjust the size as needed
  }
}


# data "template_file" "user_data" {
#   template = <<-EOF
#               <powershell>
#               # Create the Totaleto folder
#               New-Item -Path "C:\Totaleto" -ItemType Directory -Force

#               # Install AWS CLI
#               Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\AWSCLIV2.msi"
#               Start-Process msiexec.exe -Wait -ArgumentList '/I C:\AWSCLIV2.msi /QN'

#               # Copy files from S3 bucket
#               aws s3 sync s3://totaleto C:\Totaleto
#               </powershell>
#               EOF
# }





data "template_file" "user_data" {
  template = <<-EOF
              <powershell>
              # Start transcript for logging
              Start-Transcript -Path C:\UserDataLog.txt -Append

              try {
                  # Create the Totaleto folder
                  New-Item -Path "C:\Totaleto" -ItemType Directory -Force
                  Write-Output "Totaleto folder created successfully"

                  # Install AWS CLI
                  Write-Output "Downloading AWS CLI..."
                  Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\AWSCLIV2.msi"
                  Write-Output "Installing AWS CLI..."
                  Start-Process msiexec.exe -Wait -ArgumentList '/I C:\AWSCLIV2.msi /QN'
                  Write-Output "AWS CLI installed successfully"

                  # Refresh environment variables
                  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

                  # Wait for IAM role to propagate
                  Write-Output "Waiting for IAM role to propagate..."
                  Start-Sleep -Seconds 60

                  # Copy files from S3 bucket
                  Write-Output "Starting S3 sync..."
                  & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' s3 sync s3://totaleto C:\Totaleto --debug
                  Write-Output "S3 sync completed"

                  # List contents of Totaleto folder
                  Write-Output "Contents of C:\Totaleto:"
                  Get-ChildItem C:\Totaleto | Format-Table Name, Length, LastWriteTime
              }
              catch {
                  Write-Output "An error occurred:"
                  Write-Output $_.Exception.Message
                  Write-Output $_.ScriptStackTrace
              }

              Stop-Transcript
              </powershell>
              EOF
}
output "public_ip"{
  value = aws_instance.windows_vm.public_ip
}