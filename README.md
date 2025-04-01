# AWS Role Refresh Script

This script helps you refresh AWS role credentials for the AIInfraDev role in the specified AWS account.

## Prerequisites

- AWS CLI installed
- `jq` command-line tool installed
- AWS credentials configured with permission to assume the AIInfraDev role

## Usage

1. Make the script executable:
   ```bash
   chmod +x refresh-aws-role.sh
   ```

2. Run the script to refresh credentials:
   ```bash
   ./refresh-aws-role.sh
   ```

3. Use the refreshed credentials with AWS CLI:
   ```bash
   aws --profile aiinfra <command>
   ```

## What the Script Does

1. Assumes the AIInfraDev role in AWS account 881490132681
2. Gets temporary credentials
3. Updates the 'aiinfra' AWS CLI profile with the new credentials

## Security Note

- The script uses temporary credentials that expire after a certain period
- You'll need to run the script again when the credentials expire
- Make sure to keep your AWS credentials secure and never commit them to version control

## Troubleshooting

If you encounter any issues:
1. Ensure you have the correct AWS credentials configured
2. Check that you have permission to assume the AIInfraDev role
3. Verify that the AWS CLI and jq are properly installed 