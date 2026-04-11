# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches the pre-migration state:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Compare test results against any recorded pre-migration baselines if available.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless explicitly required.

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to identify any remaining Windows-specific or platform-specific API calls that may cause runtime failures on non-Windows systems:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to diagnostics prefixed with `CA1416` (platform compatibility).

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Linux, macOS) to catch any platform-specific runtime issues not surfaced by the analyzer.

## 7. Review Configuration and File Paths

Inspect any hardcoded file paths, registry access, or Windows-specific configuration patterns (such as `app.config` transforms or COM interop) and replace them with cross-platform equivalents where necessary.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`).

Refer to the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported runtime identifiers.