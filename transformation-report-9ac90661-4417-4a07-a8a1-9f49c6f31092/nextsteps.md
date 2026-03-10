# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains a test project, execute all tests to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in `System.Data`, ADO.NET provider behavior, or culture/encoding defaults).

## 5. Validate ADO.NET Provider References

Because the project is named `AdoCore`, it likely depends on database connectivity. Confirm the following:

- The correct database provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Connection strings and provider factory registrations are compatible with cross-platform .NET.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have platform-specific limitations on non-Windows operating systems.

## 6. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to surface any APIs that are Windows-only or otherwise platform-restricted:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to warnings prefixed with `CA1416` (platform compatibility). If the project is intended to run on Windows only, annotate accordingly using `[SupportedOSPlatform("windows")]`. If cross-platform support is required, replace or abstract those APIs.

## 7. Run on Target Operating Systems

If cross-platform support is a goal, execute the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only issues that static analysis may not surface.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:

- `win-x64`
- `linux-x64`
- `osx-x64`

Review the publish output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.