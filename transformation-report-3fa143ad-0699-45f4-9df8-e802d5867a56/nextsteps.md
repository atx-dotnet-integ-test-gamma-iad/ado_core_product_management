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

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls may not function on non-Windows platforms. Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.
- **Configuration**: If the project previously used `System.Configuration.ConfigurationManager`, verify the `Microsoft.Extensions.Configuration` migration is complete or that the `System.Configuration.ConfigurationManager` NuGet package has been added.
- **Database/ADO.NET**: Given the project name (`AdoCore`), verify that all ADO.NET providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are updated to their cross-platform compatible NuGet equivalents.

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure:

- No packages reference `net45`, `net472`, or other legacy target framework monikers exclusively.
- All packages have stable, non-prerelease versions unless intentionally using a prerelease.

You can check for outdated packages with:

```bash
dotnet list package --outdated
```

## 6. Test on Target Platform

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime errors that would not appear during a build.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is required (no .NET runtime pre-installed on the target machine), use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`).

## 8. Review Application Output

After publishing, navigate to the output directory and verify that all expected assemblies, configuration files, and assets are present before deploying to the target environment.