# Publishing & Release Guide

This document outlines the release process for publishing the **EventDock** artifacts:
1. `eventdock-starter` library to Maven Central.
2. `eventdock-cli` standalone executable binary and distribution archive.
3. `eventdock-api` container image to GitHub Container Registry (GHCR) / Docker Hub.
4. `eventdock-dashboard` web distribution bundle.

---

## 1. Publishing `eventdock-starter` to Maven Central

The `eventdock-starter` module is designed for distribution to developers as a drop-in Maven/Gradle dependency.

### GPG Signing & Sonatype Credentials
Ensure your `~/.m2/settings.xml` contains your Sonatype OSSRH server credentials and GPG key settings:

```xml
<settings>
  <servers>
    <server>
      <id>ossrh</id>
      <username>${env.OSSRH_JIRA_USERNAME}</username>
      <password>${env.OSSRH_JIRA_PASSWORD}</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>release</id>
      <activation>
        <activeByDefault>false</activeByDefault>
      </activation>
      <properties>
        <gpg.keyname>${env.GPG_KEY_ID}</gpg.keyname>
        <gpg.passphrase>${env.GPG_PASSPHRASE}</gpg.passphrase>
      </properties>
    </profile>
  </profiles>
</settings>
```

### Release Profile POM Configuration
The release profile activates `maven-javadoc-plugin`, `maven-source-plugin`, `maven-gpg-plugin`, and `nexus-staging-maven-plugin`:

```bash
# Build, sign, and stage to Sonatype OSSRH:
mvn clean deploy -P release -pl eventdock-starter -DskipTests
```

### Staging Repository Release
1. Log in to [Sonatype Nexus Repository Manager](https://oss.sonatype.org/).
2. Locate the staging repository in **Staging Repositories**.
3. Click **Close** to validate POM compliance, Javadoc, source JARs, and GPG signatures.
4. Click **Release** to promote artifacts to Maven Central.

---

## 2. Packaging & Distributing `eventdock-cli`

`eventdock-cli` uses Picocli and produces a fat/shaded executable JAR and native CLI scripts.

### Generating Executable JAR
```bash
mvn clean package -pl eventdock-cli -DskipTests
```
The output JAR is generated at `eventdock-cli/target/eventdock-cli-1.0.0.jar`.

### Native Image Binary via GraalVM (Optional)
To generate instantaneous-boot native CLI binaries without requiring a JVM:

```bash
mvn package -Pnative -pl eventdock-cli -DskipTests
```
Output:
- Linux / macOS: `eventdock-cli/target/eventdock`
- Windows: `eventdock-cli/target/eventdock.exe`

### Wrapper Scripts
Install the CLI to standard system path (`/usr/local/bin` or Windows `%USERPROFILE%\bin`):

```bash
#!/bin/sh
exec java -jar /usr/local/share/eventdock/eventdock-cli.jar "$@"
```

---

## 3. Container Images (`eventdock-api` & `eventdock-dashboard`)

### Backend API Image
Build and tag the production multi-stage Temurin 21 container:

```bash
docker build -t ghcr.io/eventdock/eventdock-api:1.0.0 -f eventdock-api/Dockerfile eventdock-api/
docker push ghcr.io/eventdock/eventdock-api:1.0.0
```

### Dashboard Web Image
Compile the production Flutter Web release and build the Nginx container:

```bash
# Build Flutter Web assets
cd eventdock-dashboard
flutter build web --release

# Build Nginx container
docker build -t ghcr.io/eventdock/eventdock-dashboard:1.0.0 .
docker push ghcr.io/eventdock/eventdock-dashboard:1.0.0
```

---

## 4. Semantic Versioning Checklist

When bumping versions:
1. Update `<version>` in root `pom.xml` and child modules:
   ```bash
   mvn versions:set -DnewVersion=1.1.0
   ```
2. Update `version` in `eventdock-dashboard/pubspec.yaml`.
3. Create git release tag:
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push origin v1.1.0
   ```
