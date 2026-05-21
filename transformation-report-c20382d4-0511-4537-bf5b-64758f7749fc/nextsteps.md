# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

Execute the test suite to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around:

- `System.Configuration` usage
- Windows-specific APIs (e.g., registry access, WCF, Windows Forms)
- Globalization and encoding defaults
- Reflection behavior changes

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the platform compatibility analyzer in your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any `CA1416` (platform compatibility) warnings.

## 6. Validate Runtime Behavior

Run the application manually or through integration tests against a representative set of inputs and scenarios. Pay particular attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Case sensitivity differences on Linux/macOS file systems
- Thread culture and locale behavior
- Any use of `AppDomain` or remoting APIs that may have changed

## 7. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the publish output directory to confirm all expected assets and dependencies are present before deploying to the target environment.