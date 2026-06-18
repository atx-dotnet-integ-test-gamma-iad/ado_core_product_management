# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed if no longer needed.
- `<PackageReference>` entries are present for any NuGet dependencies that were previously managed via `packages.config`.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced after restore:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility issues at runtime.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failures. Pay particular attention to tests that exercise platform-specific behavior, file I/O paths, or interop code, as these areas are most likely to behave differently on non-Windows platforms.

## 5. Perform Runtime Validation on Target Platforms

Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) and verify core functionality manually or through integration tests. Areas to check include:

- File path handling (`Path.Combine` vs. hardcoded separators).
- Environment variable usage.
- Any use of the Windows registry or Windows-specific APIs.
- Database connection strings, if applicable.

## 6. Check for Remaining Platform-Specific Code

Use the .NET Compatibility Analyzer or review the code manually for any remaining calls to Windows-only APIs. You can enable the analyzer by ensuring the following is present in the `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild after adding these properties and review any new diagnostics.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. Replace `<runtime-identifier>` with the appropriate value (e.g., `linux-x64`, `win-x64`, `osx-x64`):

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Use `--self-contained true` if you require the .NET runtime to be bundled with the output. Review the published output directory to confirm all required files are present before deploying.