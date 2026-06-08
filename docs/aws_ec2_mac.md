# Running iOSWorld on AWS EC2 Mac

This guide is for users who do not own a Mac but want to run iOSWorld on a
cloud Mac host.

The recommended architecture is simple: run iOSWorld directly on an AWS EC2
Mac instance over SSH. Do not split the runner across a local machine and a
remote Simulator until this path is working. iOSWorld talks to iOS Simulator
through `xcrun simctl` and Appium, so the benchmark runner should live on the
same macOS host as the Simulator.

## Quick Path

This is the path we smoke-tested on EC2 Mac. It runs entirely on the cloud Mac
after Xcode is available there:

1. Launch one EC2 Mac instance on an existing or newly confirmed Dedicated
   Host.
2. Make full Xcode available on the instance. For non-Mac users, the preferred
   path is a user-provided Xcode `.xip` in private S3.
3. Run `CHECK_ONLY=1 scripts/setup_mac_host.sh`.
4. Run `scripts/setup_mac_host.sh` for the full bootstrap.
5. Run one smoke task with `scripts/run_task_by_id.sh teamchat-003`.
6. Terminate the instance when done. Release the Dedicated Host only after
   AWS allows release past the 24-hour minimum allocation.

Expected success signals:

- `xcodebuild -version` reports full Xcode, not just Command Line Tools.
- `CHECK_ONLY=1 scripts/setup_mac_host.sh` exits successfully.
- `xcrun simctl list runtimes` includes an iOS runtime.
- App bootstrap prints `Success: 26 | Failed: 0 | Skipped: 0 | Total: 26`.
- `curl http://127.0.0.1:4723/status` reports Appium ready.
- `scripts/run_task_by_id.sh teamchat-003 ...` writes a result directory under
  `results/`.
- The task result directory contains `trajectory.json`, `events.jsonl`, and
  per-step `actions.json`/screenshots. A model or CUA failure should also
  write `steps/NN/llm_error.txt` and include `llm_error` in `trajectory.json`.

## What AWS Provides

Use an EC2 Mac Dedicated Host and a macOS instance. EC2 Mac is bare-metal Mac
hardware, so it can run Xcode, iOS Simulator, Appium, and the iOSWorld app
bootstrap.

Important cost and lifecycle constraints:

- EC2 Mac uses Dedicated Hosts with a 24-hour minimum allocation.
- Quotas are region-specific; you may need to request a Dedicated Host quota
  increase before launching.
- Stopping or terminating a Mac instance triggers AWS host scrubbing before the
  host can be reused.
- Use an EBS volume large enough for Xcode, simulator runtimes, derived data,
  app builds, and result artifacts. Start with at least 200 GB.

## Xcode Requirement

Full Xcode is required. Apple's Command Line Tools alone are not enough for
iOSWorld because the benchmark needs `xcodebuild`, `xcrun simctl`, and iOS
Simulator runtimes.

The setup can be headless after Xcode is available, but iOSWorld should not
try to bypass Apple's Xcode acquisition and licensing flow. Use one of these
supported paths:

- Install Xcode at `/Applications/Xcode.app` before running the bootstrap.
- Provide a local Xcode `.xip` with `XCODE_XIP_PATH=/path/to/Xcode.xip`.
- Provide a private S3 object with `XCODE_XIP_S3=s3://bucket/Xcode.xip`.
- Bake a private AMI after a successful setup, then reuse that AMI for future
  no-login runs.

For EC2 `mac2-m2pro.metal`, prefer Apple's Apple silicon Xcode `.xip`. Use the
Universal `.xip` only if the same archive must support both Intel Macs and
Apple silicon Macs. The Apple silicon archive is smaller and is the path tested
here.

Do not commit or publish Xcode binaries in this repository.

## Xcode For Non-Mac Users

There is no fully open, repo-managed Xcode download path. Apple controls Xcode
distribution and license acceptance, so each user must obtain Xcode through
their own Apple account or an organization-managed internal process.

The VM installs and runs Xcode. The non-Mac user's job is only to provide a
licensed Xcode `.xip` to that VM.

Official Apple entry points:

- [Apple Developer Downloads](https://developer.apple.com/download/) - use this
  to download Xcode `.xip` archives after signing in.
- [Xcode resources](https://developer.apple.com/xcode/resources/) - Apple's
  Xcode landing page and related resources.

### Windows And Linux Controller Machines

Windows and Linux users cannot install Xcode locally. In this setup, that is
expected: the Windows/Linux machine is only the controller, and the EC2 Mac is
the machine that installs Xcode, runs Simulator, starts Appium, and runs the
benchmark.

From Windows or Linux, you need:

- A browser to download `Xcode.xip` from Apple under your Apple account or
  organization process.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  configured for your AWS account.
- An SSH client and an EC2 key pair.
- A private S3 bucket for the Xcode `.xip`.

Windows PowerShell example using native AWS CLI:

```powershell
$XcodePath = "$HOME\Downloads\Xcode_26.xip"
$XcodeS3 = "s3://my-private-bucket/xcode/Xcode_26.xip"

aws s3 cp $XcodePath $XcodeS3 --sse AES256
aws s3api head-object --bucket my-private-bucket --key xcode/Xcode_26.xip
```

Windows with Git Bash or WSL can also use the repo helper:

```powershell
$env:XCODE_XIP_PATH="$HOME\Downloads\Xcode_26.xip"
$env:XCODE_XIP_S3="s3://my-private-bucket/xcode/Xcode_26.xip"
bash scripts/aws/upload_xcode_xip_to_s3.sh

$env:VERIFY_ONLY="1"
bash scripts/aws/upload_xcode_xip_to_s3.sh
Remove-Item Env:\VERIFY_ONLY
```

Linux/macOS shell example:

```sh
XCODE_XIP_PATH=~/Downloads/Xcode_26.xip \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/aws/upload_xcode_xip_to_s3.sh

VERIFY_ONLY=1 \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/aws/upload_xcode_xip_to_s3.sh
```

Then launch or reuse an EC2 Mac and run the setup over SSH. Do not try to
expand or install the `.xip` on Windows or Linux; `xip --expand`,
`xcodebuild`, `xcrun simctl`, iOS Simulator, and Appium's XCUITest driver all
run on the EC2 Mac.

Official AWS references:

- [Amazon EC2 Mac instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html)
- [EC2 Mac FAQ](https://aws.amazon.com/ec2/instance-types/mac/faqs/)
- [AWS Pricing Calculator](https://calculator.aws/)
- [Dedicated Host pricing and billing](https://docs.aws.amazon.com/AWSEC2/latest/DeveloperGuide/dedicated-hosts-billing.html)

### Recommended: Private S3 `.xip`

This is the most repeatable OSS path for users without a personal Mac:

1. Download the matching Xcode `.xip` from Apple using a browser and your
   Apple account. This can be done from any computer.
2. Upload the `.xip` to a private S3 bucket in your AWS account.
3. Give the EC2 Mac instance an IAM instance profile with read access to that
   single S3 object.
4. Run the bootstrap with `XCODE_XIP_S3`.

From the computer where you downloaded the `.xip`:

```sh
XCODE_XIP_PATH=~/Downloads/Xcode_26.xip \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/aws/upload_xcode_xip_to_s3.sh

VERIFY_ONLY=1 \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/aws/upload_xcode_xip_to_s3.sh
```

Then, on the EC2 Mac:

```sh
CHECK_ONLY=1 \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/setup_mac_host.sh

XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/setup_mac_host.sh
```

The script downloads the private `.xip`, expands it with `xip --expand`,
installs `/Applications/Xcode.app`, selects it, accepts the license, and runs
first-launch setup.

The S3 path requires the EC2 Mac to have AWS CLI available before Xcode is
installed. AWS macOS AMIs commonly include it; if your image does not, install
AWS CLI first or use the local `.xip` path instead.

For a cheap VM-side Xcode check before downloading runtimes or building apps:

```sh
XCODE_ONLY=1 \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/setup_mac_host.sh
```

### Alternative: Copy The `.xip` To The EC2 Mac

If you already have the `.xip` on your workstation:

```sh
scp -i ~/.ssh/my-key.pem Xcode_26.xip ec2-user@<ec2-dns>:/Users/ec2-user/

ssh -i ~/.ssh/my-key.pem ec2-user@<ec2-dns>
cd iOSWorld
CHECK_ONLY=1 \
XCODE_XIP_PATH=/Users/ec2-user/Xcode_26.xip \
  scripts/setup_mac_host.sh

XCODE_XIP_PATH=/Users/ec2-user/Xcode_26.xip \
  scripts/setup_mac_host.sh
```

### Alternative: Already Installed Xcode

If Xcode is already installed at `/Applications/Xcode.app`, run:

```sh
CHECK_ONLY=1 scripts/setup_mac_host.sh
scripts/setup_mac_host.sh
```

### Best For Repeated Runs: Private AMI

For repeated runs, bootstrap once, verify it, then create a private AMI in your
AWS account. Future instances launched from that AMI avoid repeated Xcode
transfer and first-launch setup.

Do not publish an AMI containing Xcode publicly. Keep it private to your AWS
account or organization.

### What Is Not Supported

- The repository does not download Xcode from Apple for you.
- The repository does not include Xcode.
- The repository does not automate Apple ID login or App Store GUI flows.
- Copying an installed `/Applications/Xcode.app` between machines is useful
  for private smoke testing, but it is not the documented OSS installation
  path.

After any Xcode install path, verify:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
xcodebuild -version
xcrun simctl list runtimes
```

## One-Time Host Setup

You can create the EC2 Mac instance through the AWS Console or with AWS CLI.

### Provision With AWS CLI

First create or choose these AWS resources:

- An EC2 key pair.
- A VPC subnet in a region/AZ that supports your chosen EC2 Mac instance type.
- A security group that allows SSH from your IP.
- Optional: an instance profile with S3 read access if you will use
  `XCODE_XIP_S3`. This is the recommended way for the EC2 Mac to read a
  private Xcode `.xip` without copying AWS credentials onto the host.

Then run the provisioning helper from any machine with AWS CLI credentials:

```sh
ALLOW_NEW_HOST=1 \
CONFIRM_24H_MAC_HOST=YES \
KEY_NAME=my-key-pair \
SECURITY_GROUP_ID=sg-0123456789abcdef0 \
SUBNET_ID=subnet-0123456789abcdef0 \
AWS_REGION=us-west-2 \
INSTANCE_TYPE=mac2-m2pro.metal \
MACOS_VERSION=tahoe \
SSH_KEY_PATH=~/.ssh/my-key-pair.pem \
INSTANCE_PROFILE_NAME=iosworld-xcode-s3-read \
  scripts/aws/provision_ec2_mac.sh
```

To reuse an already-allocated Mac Dedicated Host instead of allocating a new
one, pass `HOST_ID` and `REUSE_HOST_ONLY=1`:

```sh
HOST_ID=h-0123456789abcdef0 \
REUSE_HOST_ONLY=1 \
KEY_NAME=my-key-pair \
SECURITY_GROUP_ID=sg-0123456789abcdef0 \
SUBNET_ID=subnet-0123456789abcdef0 \
AWS_REGION=us-west-2 \
INSTANCE_TYPE=mac2-m2pro.metal \
SSH_KEY_PATH=~/.ssh/my-key-pair.pem \
INSTANCE_PROFILE_NAME=iosworld-xcode-s3-read \
  scripts/aws/provision_ec2_mac.sh
```

To clean up a test without allocating anything new:

```sh
AWS_REGION=us-west-2 \
HOST_ID=h-0123456789abcdef0 \
INSTANCE_ID=i-0123456789abcdef0 \
SECURITY_GROUP_RULE_ID=sgr-0123456789abcdef0 \
KEY_NAME=iosworld-test-key \
DELETE_KEY_PAIR=1 \
  scripts/aws/cleanup_ec2_mac.sh
```

Only set `DELETE_KEY_PAIR=1` for temporary keys created for a smoke run. Omit
it for long-lived EC2 key pairs.

For a guarded smoke run on an already-allocated host, use the smoke helper. It
never allocates a Dedicated Host; it either reuses a running instance on
`HOST_ID` or launches one instance on that existing host when AWS reports the
host as `available`:

```sh
AWS_REGION=us-east-1 \
HOST_ID=h-0123456789abcdef0 \
AVAILABILITY_ZONE=us-east-1d \
SECURITY_GROUP_ID=sg-0123456789abcdef0 \
SUBNET_ID=subnet-0123456789abcdef0 \
KEY_NAME=my-key-pair \
SSH_KEY_PATH=~/.ssh/my-key-pair.pem \
INSTANCE_PROFILE_NAME=iosworld-xcode-s3-read \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
RUN_BOOTSTRAP=1 \
  scripts/aws/smoke_ec2_mac.sh
```

If you want the helper to import a temporary EC2 key from your default SSH
public key instead, omit `KEY_NAME` and keep `SSH_KEY_PATH=~/.ssh/id_rsa`; the
matching `~/.ssh/id_rsa.pub` must exist.

After a smoke run, terminate the instance and remove only temporary access
resources you created for the test:

```sh
AWS_REGION=us-east-1 \
HOST_ID=h-0123456789abcdef0 \
INSTANCE_ID=i-0123456789abcdef0 \
SECURITY_GROUP_RULE_ID=sgr-0123456789abcdef0 \
KEY_NAME=iosworld-smoke-YYYYMMDDHHMMSS \
DELETE_KEY_PAIR=1 \
  scripts/aws/cleanup_ec2_mac.sh
```

Omit `SECURITY_GROUP_RULE_ID`, `KEY_NAME`, and `DELETE_KEY_PAIR` when using
long-lived access resources. The cleanup helper attempts host release too, but
AWS may reject release until the 24-hour minimum and host scrubbing are done.

For the cheapest live VM validation of the non-Mac Xcode path, run the same
smoke helper with `RUN_XCODE_ONLY=1`. This verifies that the EC2 Mac can read
the private S3 `.xip`, expand it, install `/Applications/Xcode.app`, select
Xcode, accept the license, and run first-launch setup. It stops before iOS
runtime download, app builds, Appium, or agent execution:

```sh
AWS_REGION=us-east-1 \
HOST_ID=h-0123456789abcdef0 \
AVAILABILITY_ZONE=us-east-1d \
SECURITY_GROUP_ID=sg-0123456789abcdef0 \
SUBNET_ID=subnet-0123456789abcdef0 \
KEY_NAME=my-key-pair \
SSH_KEY_PATH=~/.ssh/my-key-pair.pem \
INSTANCE_PROFILE_NAME=iosworld-xcode-s3-read \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
RUN_XCODE_ONLY=1 \
  scripts/aws/smoke_ec2_mac.sh
```

Set `RUN_AGENT_SMOKE=1` only when the remote environment has the needed model
credentials. The smoke helper does not sync your local `.env` and does not
forward API keys through SSH command arguments. Configure `OPENAI_API_KEY` on
the EC2 Mac before agent smoke.

The smallest existing-host AWS flow is:

```sh
# 1. Launch one EC2 Mac instance on an existing Dedicated Host.
HOST_ID=h-0123456789abcdef0 \
REUSE_HOST_ONLY=1 \
KEY_NAME=my-key-pair \
SECURITY_GROUP_ID=sg-0123456789abcdef0 \
SUBNET_ID=subnet-0123456789abcdef0 \
AWS_REGION=us-west-2 \
INSTANCE_TYPE=mac2-m2pro.metal \
SSH_KEY_PATH=~/.ssh/my-key-pair.pem \
INSTANCE_PROFILE_NAME=iosworld-xcode-s3-read \
  scripts/aws/provision_ec2_mac.sh

# 2. SSH to the instance, clone the repo, provide Xcode, then run:
CHECK_ONLY=1 \
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/setup_mac_host.sh

XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/setup_mac_host.sh

# 3. Run one task smoke:
./scripts/run_task_by_id.sh teamchat-003 --provider openai --model gpt-5.4-mini
```

Use `DRY_RUN=1` to resolve the region, AZ, AMI, and config without allocating
a Dedicated Host:

```sh
DRY_RUN=1 KEY_NAME=my-key SECURITY_GROUP_ID=sg-... SUBNET_ID=subnet-... \
  scripts/aws/provision_ec2_mac.sh
```

The helper launches one EC2 Mac instance and prints the SSH/bootstrap commands.
If `HOST_ID` is set, it uses that existing Dedicated Host. If `HOST_ID` is not
set, it refuses to allocate a new Dedicated Host unless both `ALLOW_NEW_HOST=1`
and `CONFIRM_24H_MAC_HOST=YES` are set. EC2 Mac guest reachability checks can
lag actual SSH readiness, so `WAIT_FOR_STATUS_OK` defaults to `0`; set it to
`1` only if you want AWS's EC2 status checks to be a hard gate.

Before allocating a new host, check the current EC2 Mac Dedicated Host price in
the AWS Pricing Calculator for your region. Expect one 24-hour minimum charge
per allocated host, plus EBS, S3, data transfer, and model-provider costs.

## Cost-Efficient Test Ladder

Use this order when validating a new account or a non-Mac user's Xcode setup:

1. **No host cost:** upload and verify the private S3 `.xip`.

   ```sh
   XCODE_XIP_PATH=~/Downloads/Xcode_26.xip \
   XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
     scripts/aws/upload_xcode_xip_to_s3.sh

   VERIFY_ONLY=1 \
   XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
     scripts/aws/upload_xcode_xip_to_s3.sh
   ```

2. **No new host:** check whether an existing host is reusable.

   ```sh
   HOST_ID=h-0123456789abcdef0 \
   SECURITY_GROUP_ID=sg-0123456789abcdef0 \
   SUBNET_ID=subnet-0123456789abcdef0 \
   DRY_RUN=1 \
     scripts/aws/smoke_ec2_mac.sh
   ```

3. **First live VM pass:** run `RUN_XCODE_ONLY=1` to prove the S3 `.xip`
   installs correctly on macOS.

4. **Infrastructure pass:** run `RUN_BOOTSTRAP=1` to install the iOS runtime,
   build/install apps, and verify Appium.

5. **Agent pass:** add `RUN_AGENT_SMOKE=1` only after model credentials are
   available.

### Bootstrap Over SSH

SSH into the EC2 Mac instance, clone the repo, and run the AWS bootstrap:

```sh
git clone https://github.com/ljang0/iOSWorld.git
cd iOSWorld

# Edit .env first, or export the provider variables here.
# For a smoke run, the selected model endpoint must be reachable.
cp .env.example .env
vi .env

# If Xcode is already installed:
scripts/setup_mac_host.sh
```

If Xcode is available as a local `.xip`:

```sh
XCODE_XIP_PATH=/Users/ec2-user/Downloads/Xcode_26.xip \
  scripts/setup_mac_host.sh
```

If Xcode is in a private S3 bucket and the instance profile has access:

```sh
XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
  scripts/setup_mac_host.sh
```

The script performs these steps:

1. Selects Xcode with `xcode-select`.
2. Accepts Xcode license and runs first-launch setup.
3. Downloads an iOS Simulator runtime with `xcodebuild -downloadPlatform iOS`.
4. Creates and boots the configured iPhone simulator.
5. Runs `scripts/setup_env.sh`.
6. Builds and installs the 26 benchmark apps.
7. Starts Appium.
8. Optionally runs a single-task smoke when `RUN_SMOKE=1`.

## Useful Environment Variables

```sh
# Xcode install sources
XCODE_APP_PATH=/Applications/Xcode.app
XCODE_XIP_PATH=/path/to/Xcode.xip
XCODE_XIP_S3=s3://bucket/Xcode.xip

# Simulator
DEVICE_NAME="iPhone 17 Pro"
IOS_RUNTIME_VERSION=26.2
IOS_RUNTIME_BUILD_VERSION=
IOS_RUNTIME_ARCH=arm64
SIM_DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro

# Bootstrap behavior
CHECK_ONLY=0
ENSURE_AWS_CLI=auto
BOOTSTRAP_APPS=1
START_APPIUM=1
KEEP_APPIUM=1
APPIUM_PORT=4723

# Smoke behavior
RUN_SMOKE=0
SMOKE_TASK_ID=teamchat-003
```

Set `RUN_SMOKE=1` if you want the bootstrap to run a task after setup:

```sh
RUN_SMOKE=1 scripts/setup_mac_host.sh
```

Run a non-mutating preflight first if you want to verify the host without
selecting Xcode, downloading runtimes, booting simulators, building apps, or
starting Appium:

```sh
CHECK_ONLY=1 scripts/setup_mac_host.sh
```

Set `BOOTSTRAP_APPS=0` if the apps are already installed:

```sh
BOOTSTRAP_APPS=0 RUN_SMOKE=0 scripts/setup_mac_host.sh
```

## Running the Benchmark After Setup

For one task:

```sh
# scripts/setup_mac_host.sh starts Appium by default. If /status is not ready,
# start Appium in another SSH session before running the task.
curl -fsS http://127.0.0.1:4723/status >/dev/null
./scripts/run_task_by_id.sh teamchat-003 --provider vllm --model qwen3.5-35B-a3
```

On a headless EC2 Mac host, set `APPIUM_HEADLESS=1` for agent runs:

```sh
APPIUM_HEADLESS=1 \
  ./scripts/run_task_by_id.sh teamchat-003 --provider openai --model gpt-5.4-mini
```

For the full suite:

```sh
LLM_PROVIDER=vllm LLM_MODEL=qwen3.5-35B-a3 \
  scripts/bootstrap_release.sh --target phone --tasks tasks.json
```

For parallel workers, use a larger EC2 Mac instance and keep worker count
conservative. M1 and base M2 Mac minis are usually single-worker or low-worker
hosts. M2 Pro, M4 Pro, M4 Max, or larger hosts are better for parallel runs.

```sh
SOURCE_UDID=$(python3 scripts/find_latest_udid.py --bare)
LLM_PROVIDER=vllm LLM_MODEL=qwen3.5-35B-a3 \
  scripts/run_parallel.sh \
    --workers 4 \
    --source-udid "$SOURCE_UDID" \
    --tasks tasks.json
```

## Private AMI Workflow

For repeated use, bake a private AMI after a successful bootstrap:

1. Launch an EC2 Mac instance.
2. Install or provide Xcode.
3. Run `RUN_SMOKE=0 scripts/setup_mac_host.sh`.
4. Confirm `xcodebuild -version`, `xcrun simctl list runtimes`, and
   `appium --version` work.
5. Create a private EBS-backed AMI from the instance in your AWS account.
6. Launch future EC2 Mac instances from that AMI.

This is the recommended way to get no-GUI, no-login repeated benchmark runs
while keeping Xcode distribution under the user's AWS account and license.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Full Xcode is not installed` | Install Xcode at `/Applications/Xcode.app`, set `XCODE_XIP_PATH`, or set `XCODE_XIP_S3`. |
| `xcodebuild -downloadPlatform iOS` fails for a specific runtime | Try omitting `IOS_RUNTIME_VERSION` to install the latest supported runtime, set `IOS_RUNTIME_ARCH=arm64` on Apple Silicon, or set `IOS_RUNTIME_BUILD_VERSION` only when you know the Apple build number. |
| Simulator device type is missing | Run `xcrun simctl list devicetypes` and set `SIM_DEVICE_TYPE` to an installed iPhone type. |
| Bootstrap cannot find the simulator | Set `DEVICE_NAME` to the created simulator name and rerun. |
| Appium XCUITest driver missing | Rerun `scripts/setup_env.sh` or `appium driver install xcuitest`. |
| Host is too slow or unstable with parallel workers | Reduce `--workers`, close extra booted simulators, or use a larger EC2 Mac instance. |
