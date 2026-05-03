# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay attention to the following areas:

- **`System.Data` and ADO.NET**: Since the project is named `AdoCore`, verify that all database provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are explicitly referenced and are compatible with the target framework.
- **Configuration**: Ensure any `app.config` or `web.config` based configuration has been migrated to `appsettings.json` or environment variables where applicable.
- **Platform-specific APIs**: Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining platform-specific calls.

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that:

- No packages still target `net45`, `net461`, or other legacy monikers exclusively.
- Packages have stable, non-prerelease versions unless a prerelease is intentionally required.

You can check for outdated packages with:

```bash
dotnet list package --outdated
```

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application and its tests on each intended operating system (Windows, Linux, macOS) to surface any OS-specific runtime issues that a build alone will not catch.

## 7. Review Output Artifacts

After a Release build, inspect the output in the `bin/Release/<targetframework>/` directory and confirm:

- The correct runtime assemblies are present.
- Any required configuration files or static assets are being copied to the output directory.
- If a self-contained deployment is needed, publish with the appropriate runtime identifier:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

## 8. Smoke Test the Application

Deploy the published output to a staging environment and perform a basic smoke test against all primary entry points or endpoints to confirm the application behaves as expected under the new runtime.