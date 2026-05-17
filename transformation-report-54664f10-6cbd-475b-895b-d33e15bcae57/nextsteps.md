# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support your target framework. If any packages are flagged, check NuGet.org for updated versions that support the target TFM.

## 3. Build the Solution

Perform a clean build to confirm no errors or warnings are introduced at compile time:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the output. While warnings do not prevent a build, they may indicate deprecated APIs or compatibility concerns worth addressing.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Configuration` usage
- Windows-specific APIs (registry, WCF, etc.)
- Globalization and encoding defaults

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable platform compatibility warnings in the `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild after adding these settings and review any new diagnostics.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File I/O paths (avoid hardcoded Windows-style paths)
- Database connectivity if ADO.NET is in use (verify connection strings and driver compatibility)
- Any reflection-based code, which may behave differently under the new runtime

## 7. Publish the Application

Once validation is complete, publish the application for your target platform:

**Framework-dependent (requires .NET runtime on target machine):**

```bash
dotnet publish -c Release -f net8.0
```

**Self-contained (bundles the runtime):**

```bash
dotnet publish -c Release -f net8.0 --self-contained true -r win-x64
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Review Output Artifacts

Check the `publish` output folder to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.