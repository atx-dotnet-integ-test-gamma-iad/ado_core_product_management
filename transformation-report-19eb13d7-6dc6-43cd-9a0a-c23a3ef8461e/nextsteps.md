# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **Reflection-based code**: Behavior around `Assembly.Load` and type resolution may differ.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET. Verify any config file access is functioning correctly.
- **File paths**: Ensure no hardcoded Windows-style paths (e.g., backslashes) exist in the codebase. Use `Path.Combine` or `Path.DirectorySeparatorChar` where appropriate.
- **Platform-specific APIs**: Run the .NET Compatibility Analyzer if not already done to surface any remaining platform-specific API calls.

## 5. Run on Target Platforms

If cross-platform support is a goal, test the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

On Linux or macOS, pay particular attention to:
- Case-sensitive file system access
- Registry access (not available outside Windows)
- Windows-only NuGet packages or P/Invoke calls

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies referenced in `AdoCore.csproj` have versions compatible with your target framework. You can use the following command to inspect outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all required files, configuration files, and dependencies are present before deploying to the target environment.