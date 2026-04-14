# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines where the project will run or be built.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support your target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback and may not behave correctly at runtime.

## 3. Build the Solution

Perform a clean build to confirm there are no issues that only surface during a full compilation:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the output for any warnings that could indicate behavioral differences from the original .NET Framework build.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that cover database access, file I/O, or platform-specific APIs, as these are common areas where cross-platform differences surface at runtime rather than compile time.

## 5. Audit Platform-Specific API Usage

Even without build errors, certain APIs may compile successfully but throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any diagnostics it produces and replace or conditionally compile any Windows-only APIs if cross-platform execution is required.

## 6. Check Configuration and App Settings

If the project previously used `System.Configuration` (`app.config` / `web.config`), verify that configuration has been migrated to `appsettings.json` or another supported mechanism, and that all configuration keys are being read correctly at runtime.

## 7. Validate Data Access Layer

Given the `AdoCore` project name suggests ADO.NET usage, confirm the following at runtime:

- Connection strings are correctly defined in the new configuration system.
- The appropriate database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` where applicable).
- Any `DataSet`, `DataTable`, or `DataAdapter` usage behaves as expected, as some edge cases differ between .NET Framework and modern .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.