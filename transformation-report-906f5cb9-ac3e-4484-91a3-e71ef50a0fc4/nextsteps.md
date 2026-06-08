# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even with a successful build, some APIs behave differently or are unsupported on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining platform-specific calls:

```bash
dotnet tool install -g dotnet-analyze
```

Pay particular attention to:
- `System.Drawing` (requires `System.Drawing.Common` and may need replacement on Linux/macOS)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-only libraries

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Verify each package supports the target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only support `net4x` with their cross-platform equivalents.

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used correctly. Verify connection strings, environment-specific settings, and any custom configuration sections.

## 7. Smoke Test Core Functionality

Manually exercise the primary entry points of the application to confirm expected behavior at runtime. Focus on:
- Data access layer (ADO.NET connections, queries, and transactions given the `AdoCore` project name)
- Exception handling paths
- Any file I/O or network operations

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required runtime assets and dependencies are present before deploying to the target environment.