# 📦 EventDock Starter Publishing Guide

This document describes how to publish `eventdock-starter` to **Maven Central** via the **Sonatype Central Publishing Portal**.

---

## 1. Prerequisites for Maven Central

Maven Central has three mandatory requirements:

1. **Verified Namespace**:
   - The groupId `dev.swynx` must be claimed and verified on [Sonatype Central Portal](https://central.sonatype.com/namespace).
   - **Verification**: Add a DNS `TXT` record on `swynx.dev` with the verification token provided by Sonatype Central.

2. **Sonatype Central User Token**:
   - Go to [central.sonatype.com/account](https://central.sonatype.com/account).
   - Click **Generate User Token** to obtain your User Token Username and Password.

3. **GPG Key Pair & Keyserver Sync**:
   - All published files (`.jar`, `-sources.jar`, `-javadoc.jar`, `.pom`) must be cryptographically signed.
   - Your key (`414585D61425AEB6D7223AD793053C9B5AE9F568`) has already been published to:
     - `keyserver.ubuntu.com`
     - `keys.openpgp.org`

---

## 2. Option A: Automated Release via GitHub Actions (Recommended)

An automated GitHub Actions workflow is provided at [`.github/workflows/publish-starter.yml`](../.github/workflows/publish-starter.yml).

### Step 1: Add GitHub Repository Secrets
In your GitHub repository settings (**Settings > Secrets and variables > Actions > New repository secret**), add:

| Secret Name | Description |
| :--- | :--- |
| `CENTRAL_TOKEN_USER` | Sonatype Central User Token Username |
| `CENTRAL_TOKEN_PASSWORD` | Sonatype Central User Token Password |
| `GPG_PRIVATE_KEY` | Export of your ASCII-armored private key (`gpg --armor --export-secret-keys 93053C9B5AE9F568`) |
| `GPG_PASSPHRASE` | Passphrase used to unlock your GPG private key |

### Step 2: Trigger the Workflow
- **Automatic**: Create and publish a GitHub Release with tag `v0.1.0`.
- **Manual**: Go to **Actions > Publish EventDock Starter > Run workflow**.

---

## 3. Option B: Local Publishing via PowerShell / Bash

### Step 1: Configure `~/.m2/settings.xml`
Add your Central server credentials to `C:\Users\<username>\.m2\settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>central</id>
      <username>YOUR_CENTRAL_USER_TOKEN</username>
      <password>YOUR_CENTRAL_PASSWORD_TOKEN</password>
    </server>
  </servers>
</settings>
```

### Step 2: Run the Deployment Script

In PowerShell:
```powershell
.\scripts\publish-starter.ps1 -GpgPassphrase "YOUR_PASSPHRASE"
```

Or directly via Maven:
```powershell
mvn clean deploy -P release -Dgpg.passphrase="YOUR_PASSPHRASE"
```

---

## 4. How the Multi-Module Deploy Works

The root [`pom.xml`](../pom.xml) manages the entire EventDock platform reactor:
- Submodules not intended for public Maven Central consumption (`eventdock-api`, `eventdock-sample`, `eventdock-cli`) have `<maven.deploy.skip>true</maven.deploy.skip>`.
- The deploy step automatically signs and deploys only:
  1. `dev.swynx:eventdock-parent:0.1.0` (POM definition)
  2. `dev.swynx:eventdock-starter:0.1.0` (Binary JAR, Sources JAR, Javadoc JAR, and GPG `.asc` signatures)

---

## 5. Verification on Maven Central

Once deployed:
1. Log in to [central.sonatype.com/publishing](https://central.sonatype.com/publishing) to view the deployment state (`VALIDATING` -> `PUBLISHED`).
2. Within 15–30 minutes, the package will sync to the global Maven Central index:
   - [https://central.sonatype.com/artifact/dev.swynx/eventdock-starter](https://central.sonatype.com/artifact/dev.swynx/eventdock-starter)
3. Developers can then immediately include it in any Spring Boot application:
   ```xml
   <dependency>
       <groupId>dev.swynx</groupId>
       <artifactId>eventdock-starter</artifactId>
       <version>0.1.0</version>
   </dependency>
   ```
