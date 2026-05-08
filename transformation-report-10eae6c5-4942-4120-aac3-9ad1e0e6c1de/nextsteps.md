# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **Registry access** (`Microsoft.Win32.Registry`): Not available on Linux/macOS without the `Microsoft.Win32.Registry` NuGet package.
- **Windows-specific APIs**: Any use of `System.Drawing`, WCF, or remoting may require additional NuGet packages or refactoring.
- **Configuration**: If the project previously used `System.Configuration.ConfigurationManager`, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced.
- **AppDomain usage**: Some `AppDomain` APIs are no longer supported and will throw `PlatformNotSupportedException` at runtime.

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Run the following to identify any compatibility concerns:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught during the build phase.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected files are present, including configuration files, static assets, and dependencies. Verify that no legacy `.config` files that are no longer applicable have been inadvertently included.