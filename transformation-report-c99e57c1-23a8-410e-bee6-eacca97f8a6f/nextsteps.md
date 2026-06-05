# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no legacy `<TargetFrameworkVersion>` elements referencing `.NET Framework` (e.g., `v4.8`) remain.

## 2. Review NuGet Package References

- Open each `.csproj` file and confirm all `<PackageReference>` entries are present and reference current, compatible package versions.
- Run the following command to restore packages and check for any resolution warnings:

```bash
dotnet restore
```

- Address any reported package version conflicts or deprecated package warnings.

## 3. Build the Solution

Perform a clean build to confirm there are no issues:

```bash
dotnet clean
dotnet build
```

Review the output for any warnings that may indicate compatibility concerns, even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original:

```bash
dotnet test
```

Review test results carefully. Any failures may indicate behavioral differences introduced by the framework migration.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in .NET Framework and may behave differently or be unavailable in cross-platform .NET, including:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslash separators)
- COM interop or P/Invoke calls targeting Windows libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Platforms

Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to identify any runtime issues that do not surface during compilation:

```bash
dotnet run
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

Review the contents of the `publish` output directory to confirm all required files are present before deploying to the target environment.