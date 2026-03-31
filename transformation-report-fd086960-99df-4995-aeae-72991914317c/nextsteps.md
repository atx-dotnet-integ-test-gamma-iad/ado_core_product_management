# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that were downgraded. Address any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, particularly those related to platform compatibility (e.g., `CA1416`) or obsolete APIs.

## 4. Run the Existing Test Suite

Execute any existing unit or integration tests to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

If tests are failing, compare the failure output against the behavior of the original .NET Framework project to determine if the failures are pre-existing or introduced by the migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that may behave differently or are unavailable on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Drawing` (requires `System.Drawing.Common` and may need replacement on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server usage
- Any P/Invoke calls to Windows-specific native libraries

## 6. Validate Configuration Files

Check that `app.config` or `web.config` settings have been correctly migrated to `appsettings.json` or equivalent .NET configuration providers. Confirm that connection strings, logging settings, and environment-specific values are present and correct.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and verify that file paths, line endings, and environment-specific behavior are handled correctly.

```bash
dotnet run --configuration Release
```

## 8. Review Output Artifacts

Confirm the output directory contains the expected assemblies and that no legacy `.dll` references from the old `packages` folder are being copied instead of NuGet-resolved binaries.

## 9. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed. Review the published output to confirm all required files are present before deploying to the target environment.