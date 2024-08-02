```bash

rm -rf /tmp/aqua-dev/
rm -rf /tmp/aqua-dev-public
mkdir /tmp/aqua-dev-public

cd /tmp
git clone https://github.com/jan3dev/aqua-dev/
cd /tmp/aqua-dev/
git checkout  <branch>
rsync -rlp --exclude '.git' --exclude './android/android_keys' --exclude './crypto' --exclude './operational-tools' --exclude './boltz-rust' --exclude './public_repo_instructions.md' --exclude './doc' * /tmp/aqua-dev-public/
scp -r -i ~/.ssh/john-jan3.pem /tmp/aqua-dev-public/*  ec2-user@ec2-35-87-82-133.us-west-2.compute.amazonaws.com:/home/ec2-user/public_repos/aqua-wallet/

ssh -i ~/.ssh/john-jan3.pem ec2-user@ec2-35-87-82-133.us-west-2.compute.amazonaws.com

```
